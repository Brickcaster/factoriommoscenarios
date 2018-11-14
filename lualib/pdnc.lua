-- Third itteration of programmable day-night cycle for Factorio
-- Developed by Zr4g0n with help
-- Features needed:
-- Set 'maximum brightness' from rocket launches cluster wide
-- Set 'time until doomsday' to any time, in minutes. 
-- Set 'evolution target' to any number [0.0, 1.0]
-- Changing day-night cycle based on days
-- Handle 'next time' elegantly

-- lamps enable darkness: [0.595 - 0.425] scaled to [0.0 - 0.85] range from [0.0 - 1.0] range

global.pdnc_stepsize = 21 -- also used for script.on_nth_tick
global.pdnc_surface = 1
global.pdnc_current_time = 0
global.pdnc_current_point = {x = 0, y = 1.0}
global.pdnc_last_point = {x = -1, y = 0.0}
global.pdnc_max_brightness = 0.5 -- for clusterio
global.pdnc_debug = false
global.pdnc_enable_brightness_limit = false
global.pdnc_enable_rocket_darkness = true
global.pdnc_rockets_launched = 0
global.pdnc_rockets_launched_step_size = 0.025
global.pdnc_rockets_launched_smooth = 0
global.pdnc_alt_program = -1


--[[
function pdnc_setup()
	game.surfaces[global.pdnc_surface].ticks_per_day = pdnc_min_to_ticks(10.0)
end
]]

function pdnc_core()
	pdnc_freeze_check()
	game.surfaces[global.pdnc_surface].ticks_per_day = pdnc_min_to_ticks(10.0)
	local s = global.pdnc_surface
	global.pdnc_current_time = game.tick / game.surfaces[s].ticks_per_day
	global.pdnc_last_point = global.pdnc_current_point
	global.pdnc_current_point = {x = global.pdnc_current_time, y = pdnc_program()}

	local top_point = pdnc_intersection_top (global.pdnc_last_point, global.pdnc_current_point)
	local bot_point = pdnc_intersection_bot (global.pdnc_last_point, global.pdnc_current_point)

	-- the order is dusk - evening - morning - dawn. They *must* be in that order and they cannot be equal
	if(top_point < bot_point) then -- dusk -> evening
		pdnc_cleanup_last_tick(s)
		game.surfaces[s].evening = bot_point - global.pdnc_current_time
		game.surfaces[s].dusk = top_point - global.pdnc_current_time
	elseif(top_point > bot_point) then -- morning -> dawn
		pdnc_cleanup_last_tick(s)
		game.surfaces[s].morning = bot_point - global.pdnc_current_time
		game.surfaces[s].dawn = top_point - global.pdnc_current_time
	elseif(top_point == bot_point) then
		pdnc_debug_message("PDNC: Top and bot point equal")
		-- no cleanup is done here
		-- if the points are equal, use last value until not equal
		-- this should never be reached unless the pdnc_program() is broken.
	else
		pdnc_debug_message("Top and bot not different nor equal. probably a NaN error")
		pdnc_debug_message("bot_point: " .. bot_point)
		pdnc_debug_message("top_point: " .. top_point)
		-- this should never be reached.
	end
end

function pdnc_cleanup_last_tick(s)
	game.surfaces[s].daytime = 0
	-- must be in this  spesific order to
	-- preserve the order at all times
	-- dusk < evening < morning < dawn.
	game.surfaces[s].dusk = -999999999999
	game.surfaces[s].dawn = 999999999999
	game.surfaces[s].evening = -999999999998
	game.surfaces[s].morning = 999999999998
end


function pdnc_freeze_check()
	if(game.surfaces[1].freeze_daytime)then
		game.surfaces[1].freeze_daytime = false
		game.print("Can't use freeze_daytime while programmable day-night cycle is active; time has been unfrozen")
	end
end

function pdnc_program()
	local x = global.pdnc_current_time * math.pi * 2
	return pdnc_scaler(pdnc_c_boxy(x))
end

function pdnc_c_boxy(x)
	return pdnc_normalize((math.sin(x) + (0.111 * math.sin(3 * x))) * 1.124859392575928)
	-- magic numbers to make it scale to (-1, 1)
end

function pdnc_normalize(n)
	return (n + 1)/2
end

function pdnc_scaler(r) -- a bit messy, but simplifies a lot elsewhere
	if(pdnc_check_valid(r, "pdnc_scaler"))then

		local a = 1
		local b = 1

		if(global.pdnc_enable_brightness_limit) then
			a = global.pdnc_max_brightness
		end

		if(global.pdnc_enable_rocket_darkness) then
			b = 1 -  pdnc_rocket_launch_darkness()
		end

		return r * 0.85 * a * b	-- 0.85 is the 'brightness range' of factorio
	end
end

function pdnc_intersection (s1, e1, s2, e2)
	local d = (s1.x - e1.x) * (s2.y - e2.y) - (s1.y - e1.y) * (s2.x - e2.x)
	local a = s1.x * e1.y - s1.y * e1.x
	local b = s2.x * e2.y - s2.y * e2.x
	local x = (a * (s2.x - e2.x) - (s1.x - e1.x) * b) / d
	--local y = (a * (s2.y - e2.y) - (s1.y - e1.y) * b) / d
	return x--, y
end

function pdnc_intersection_top (s2, e2)
	local s1, e1 = {x = -999999999, y = 0.85}, {x = 999999999, y = 0.85}
	return pdnc_intersection (s1, e1, s2, e2)
end

function pdnc_intersection_bot (s2, e2)
	local s1, e1 = {x = -999999999, y = 0.0}, {x = 999999999, y = 0.0}
	return pdnc_intersection (s1, e1, s2, e2)
end

function pdnc_set_max_brightness(n)
	if(pdnc_check_valid(n, "pdnc_set_max_brightness")) then
		global.pdnc_max_brightness = n
		pdnc_debug_message("global.pdnc_max_brightness set to " .. global.pdnc_max_brightness)
	end
end

function pdnc_min_to_ticks(m)
	return 60*60*m
end

function pdnc_rocket_launch_counter()
	global.pdnc_rockets_launched = 1 + global.pdnc_rockets_launched
end

function pdnc_rocket_launch_darkness()
	if (global.pdnc_rockets_launched_smooth < global.pdnc_rockets_launched)then
		global.pdnc_rockets_launched_smooth = global.pdnc_rockets_launched_step_size + global.pdnc_rockets_launched_smooth
	end
	return (1 - (50/(global.pdnc_rockets_launched_smooth+50)))
end

function pdnc_check_valid(n, s)
	if (n == nil) then
		pdnc_debug_message(s .. " set to nil! Set to 1.0 instead")
		return false
	elseif (n < 0) then
		pdnc_debug_message(s .. " cannot be " .. n .. " limited to 0.0 instead")
		return false
	elseif (n > 1) then
		pdnc_debug_message(s .. " cannot be " .. n .. " limited to 1.0 instead")
		return false
	elseif (n ~= n) then
		pdnc_debug_message(s .. " cannot be " .. n .. " since it's not a valid number!")
	else return true
	end
end

function pdnc_debug_message(s)
	if(global.pdnc_debug) then
		game.print(s)
	end
end

Event.register(-global.pdnc_stepsize, pdnc_core)
--Event.register(Event.core_events.init, pdnc_setup)
--Event.register(Event.core_events.load,pdnc_on_load)
Event.register(defines.events.on_rocket_launched, function(event)
	pdnc_rocket_launch_counter()
end)
