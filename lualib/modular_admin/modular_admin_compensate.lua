-- modular_admin_compensate sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows admins to "compensate" their time spent as an admin

--
--	VARIABLES
--

global.modular_admin_compensate = global.modular_admin_compensate or {}
global.modular_admin_compensate.players = global.modular_admin_compensate.players or {}
global.modular_admin_compensate.enabled = true

--
--	FUNCTIONS
--
function modular_admin_compensate_enable()
	modular_admin_add_submodule("modular_admin_compensate")
	if not global.modular_admin_compensate.enabled then
		global.modular_admin_compensate.enabled = true
		for i, p in pairs(game.connected_players) do
			if p.admin then
				if global.modular_admin_compensate.players[p.name] == true then
					modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Stop compensation", order = 30, color = {r = 1, g = 0, b = 0}})
				else
					modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Start compensation", order = 30, color = {r = 0, g = 1, b = 0}})
				end
			end
		end
	else 
		return false
	end
end

function modular_admin_compensate_disable()
	modular_admin_remove_submodule("modular_admin_compensate")
	if global.modular_admin_compensate.enabled then
		global.modular_admin_compensate.enabled = false
		for i, p in pairs(game.connected_players) do
			if p.admin then
				modular_admin_remove_button(p.name, "modular_admin_compensate_button")
			end
		end
	else 
		return false
	end
end

function modular_admin_compensate_player(p)
	if p.admin then
		if global.modular_admin_compensate.players[p.name] == true then
			global.modular_admin_compensate.players[p.name] = false
			modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Start compensation", order = 30, color = {r = 0, g = 1, b = 0}})
			if global.char_mod ~= nil then
				char_mod_remove_bonus(p, "character_build_distance_bonus", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_item_drop_distance_bonus", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_reach_distance_bonus", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_resource_reach_distance_bonus", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_crafting_speed_modifier", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_mining_speed_modifier", "modular_admin_compensate")
				char_mod_remove_bonus(p, "character_running_speed_modifier", "modular_admin_compensate")
			else
				p.print("Char_Mod Module not found!")
			end
		else
			global.modular_admin_compensate.players[p.name] = true
			modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Stop compensation", order = 30, color = {r = 1, g = 0, b = 0}})
			if global.char_mod ~= nil then
				char_mod_add_bonus(p, "character_build_distance_bonus", {name = "modular_admin_compensate", op = "add", val = 5})
				char_mod_add_bonus(p, "character_item_drop_distance_bonus", {name = "modular_admin_compensate", op = "add", val = 5})
				char_mod_add_bonus(p, "character_reach_distance_bonus", {name = "modular_admin_compensate", op = "add", val = 5})
				char_mod_add_bonus(p, "character_resource_reach_distance_bonus", {name = "modular_admin_compensate", op = "add", val = 5})
				char_mod_add_bonus(p, "character_crafting_speed_modifier", {name = "modular_admin_compensate", op = "add", val = 0.5})
				char_mod_add_bonus(p, "character_mining_speed_modifier", {name = "modular_admin_compensate", op = "add", val = 1})
				char_mod_add_bonus(p, "character_running_speed_modifier", {name = "modular_admin_compensate", op = "add", val = 0.5})
			else
				p.print("Char_Mod Module not found!")
			end
		end
	end
end

function modular_admin_compensate_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if p.admin then
			if e.parent.name == modular_admin_get_menu(p).name then
				if e.name == "modular_admin_compensate_button" then
					if global.modular_admin_compensate.enabled then
						modular_admin_compensate_player(p)
					else
						modular_admin_remove_button(p.name, "modular_admin_compensate_button")
						p.print("Sorry, this sub-module has just been disabled")
					end
				end
			end
		end
	end
end


--
--	EVENTS
--
Event.register(Event.core_events.init, function(event)
		modular_admin_add_submodule("modular_admin_compensate")
	end)
	
Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	if p.admin then
		if global.modular_admin_compensate.enabled then
			if global.modular_admin_compensate.players[p.name] == true then
				modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Stop compensation", order = 30, color = {r = 1, g = 0, b = 0}})
			else
				modular_admin_add_button(p.name, {name="modular_admin_compensate_button", caption="Start compensation", order = 30, color = {r = 0, g = 1, b = 0}})
			end
		else 
			modular_admin_remove_button(p.name, "modular_admin_compensate_button")
		end
	end
end)
	
Event.register(defines.events.on_gui_click, modular_admin_compensate_gui_clicked)