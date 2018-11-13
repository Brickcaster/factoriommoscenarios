--Factorio RPG, written by Mylon

--Offline testing:
--/c script.raise_event(rpg.on_rpg_gui_created, {player_index=1})

--Utility command for griefing.
-- /silent-command do local hoarder = {amount=0} for k,v in pairs(game.players) do if v.get_item_count("uranium-235") > hoarder.amount then hoarder.name = v.name hoarder.amount = v.get_item_count("uranium-235") end end game.print(hoarder.name .. " is hoarding " .. hoarder.amount .. " uranium-235!") end
-- /c for k,v in pairs(game.player.surface.find_entities_filtered{name="programmable-speaker"}) do game.print(v.last_user.name .. "is making noise.") end

--Idea: Only mine ore if a valid requester is in the network.
--To do that, need to do iterate over logistic_network.requester_points and then iterate over each of those to find a filter that matches an ore.

--require "rpg_beastmaster" --New class gets its own file for class-related events.
--require "rpg_stats" --Keep track of silly stats
--require "rpg_builder" --Very unfinished.  Adds a limited number of higher level turrets for builders.
require "rpg_permissions" --Limit certain actions to players level 5 or greater
	
rpg = {}
rpg.classes = {"Engineer", "Miner", "Builder", "Soldier", "Scientist", "Beastmaster"}

--This event gets called often.  Event is of form: {force=force}
rpg.on_reset_technology_effects = script.generate_event_name()

--Other gui-related 
rpg.on_rpg_gui_created = script.generate_event_name()

--Savedata is of form: player_name = {bank = exp, class1 = exp, class2 = exp, etc}
--Remote commands
commands.add_command("heartbeat", "Regular heartbeat to let the game know that the character data server is online.", function()
	for i = 1, 3 do
		global.rpg.heartbeat[i] = true
	end
end)

commands.add_command("loaddata", "Loads rpg data", function(data)
	--Only the server is allowed to use this command
	if game.player then
		return
	end
	--Incoming string is of form: {name=player.name, class=exp}
	--rpg_tmp stores value on load so we can do a diff and store only the diff.
	--Let's convert it from type string to type table
	--game.print(serpent.line(str))
	if not data.parameter then
		log("Loaddata error: Parameter was blank.")
		return
	end

	local data = loadstring('return ' .. data.parameter)() --Warning: This is insecure.  I don't like it one bit.
	
	--game.print(serpent.line(data))
	if not data.playername then
		log("Invalid data.")
		--Invalid data
		return
	end

	local player = game.players[data.playername]
	if not player then
		--Stale load data file
		log("Player ''" .. data.playername .. "'' is not playing.")		
		return
	end
	
	if not global.rpg_data[player.name] then
		log("Error!  Player Created Event skipped!")
		return
	end

	for k,v in pairs(rpg.classes) do
		if data[v] then
			if global.rpg_data[player.name][v] then
				if data[v] > global.rpg_data[player.name][v] then
					global.rpg_data[player.name][v] = data[v]
					global.rpg_tmp[player.name][v] = data[v]
				else
					log("Tried to load stale data for an existing player.")
				end
			else
				global.rpg_data[player.name][v] = data[v]
				global.rpg_tmp[player.name][v] = data[v]
			end
			--global.rpg_tmp[player.name][v] = data[v] --Changing this will prevent overwriting current exp if the data server goes down.
		end
	end
	if data.bank and not global.rpg_tmp[player.name].bank_loaded then
		global.rpg_data[player.name].bank = data.bank
		global.rpg_tmp[player.name].bank = data.bank
		global.rpg_tmp[player.name].bank_loaded = true
	end
	if global.rpg_data[player.name].class == "Engineer" then
		rpg_class_picker(player)
		rpg_starting_resources(player)
	end
	--Let's do the oarc spawns on this step.
	if ENABLE_SEPARATE_SPAWNS then
		if not global.rpg_tmp[player.name].oarc then
			global.rpg_tmp[player.name].oarc = true
			SeparateSpawnsPlayerCreated({player_index=player.index})
		end
	end
	--Give bonuses on login.
	rpg_give_bonuses(player)
	rpg_give_team_bonuses(player.force)

	player.print("RPG data loaded.")
	log("Loaded RPG data for " .. player.name)
end)

function rpg.heartbeat(event)
	if not (game.tick % (60 * 60 * 5) == 0) then
		return
	end
	for k, v in pairs(global.rpg.heartbeat) do
		if v then
			global.rpg.heartbeat[k] = false
			return
		end
	end
	--Still here?  Then external script is offline.
	log("RPG: data server offline.")
end

--On player join, set default values
function rpg_loadsave(event)
	if not global.rpg_data then rpg_init() end

	local player = game.players[event.player_index]
	if player.name == "" then
		game.print("Error, player.name is empty.")
		return
	end
	global.rpg_data[player.name] = {}
	global.rpg_tmp[player.name] = {}
	--global.rpg_data[player.name] = {level=1, class="Engineer", Engineer=0, bank=0}
	for k,v in pairs(rpg.classes) do
		global.rpg_data[player.name][v] = 0
		global.rpg_tmp[player.name][v] = 0
	end
	global.rpg_tmp[player.name].level = 1
	global.rpg_data[player.name].class = "Engineer"
	global.rpg_data[player.name].bank = 0

	global.rpg_tmp[player.name].bank = 0
	global.rpg_tmp[player.name].class_timer = -20*60*60


	-- if rpg_save[player.name] then
	-- 	--Load bank (legacy) and class exp
	-- 	for k,v in pairs(rpg_save[player.name]) do
	-- 		global.rpg_data[player.name][k] = v
	-- 	end
	-- 	if not rpg_save[player.name].bank then 
	-- 		rpg_save[player.name].bank = 0
	-- 	end
	-- end
	--Set class timer to a negative value so the timer function does not interrupt the first class selection.
	--global.rpg_tmp[player.name] = {class_timer=-20*60*60}

	--Check combined levels to determine permissions.
	-- local total_levels = rpg_level_sum(player)
	-- if total_levels >= 5 then
	-- 	player.permission_group = game.permissions.get_group("trusted")
	-- end
end

--Write a file.  Script will monitor this output file and consume events and pass data back via rcon.
--Simple method: rcon: /silent-command global.rpg_data[name] = data; global.rpg_tmp[name] = data
--Hard method: rcon: /loaddata {playername=name, class1=exp, class2=exp...}
function rpg_remote_load(event)
	local player = game.players[event.player_index]
	game.write_file("loadsave", player.name .. "\n", true, 0)
end

--Write data to a file.  Script will monitor this output file and consume lines.
--Each object is a difference of exp.
function rpg_remote_save(event)
	local player = game.players[event.player_index]
	local data = '{"name":"' .. player.name .. '",'
	for k, v in pairs(rpg.classes) do
		if global.rpg_data[player.name][v] > global.rpg_tmp[player.name][v] then
			data = data .. '"' .. v .. '":' .. global.rpg_data[player.name][v]-global.rpg_tmp[player.name][v] ..","
		end	
	end
	--Set tmp value to current value so we don't try to save the delta exp twice.
	for k, v in pairs(rpg.classes) do
		global.rpg_tmp[player.name][v] = global.rpg_data[player.name][v]
	end
	--Now repeat for the bank.
	if global.rpg_data[player.name].bank < global.rpg_tmp[player.name].bank then
		data = data .. '"bank":' .. global.rpg_data[player.name].bank - global.rpg_tmp[player.name].bank ..","
		global.rpg_tmp[player.name].bank = global.rpg_data[player.name].bank
	end

	data = data .. "}\n"
	--Trim the trailing comma
	data = string.gsub(data, ",}", "}")
	game.write_file("savedata", data, true, 0)
end

--Save the persistent data.
-- Single line command for manual export:
-- /silent-command game.write_file("rpgdata - 2017-05-19.txt", serpent.block(global.rpg_data, {comment=false}), true, 1)
function rpg_savedata()
	local filename = "rpgdata - " .. game.tick .. ".txt"
	local target
	--Are we on a dedicated server?
	if game.player then
		target = game.player.index
	else
		target = 0
	end
	game.write_file(filename, serpent.block(global.rpg_data), true, target)
end

-- SPAWN AND RESPAWN --
--Higher level players get more starting resources for an accelerated start!
function rpg_starting_resources(player)
	-- Sum all exp and calculate what level that would be.
	if global.rpg_tmp[player.name].ready then
		return
	else
		global.rpg_tmp[player.name].ready = true --And continue
	end
	local total_level = rpg_level_sum(player)
	-- global.rpg_tmp[player.name].maxlevel = math.max(global.rpg_data[player.name].level, global.rpg_tmp[player.name].maxlevel)
	local bonuslevel = total_level - 1
	if bonuslevel > 0 then
		player.insert{name="iron-plate", count=bonuslevel * 20}
		player.insert{name="copper-plate", count=math.max(1, math.floor(bonuslevel / 4) * 10) }
		player.insert{name="stone", count=math.max(1, math.floor(bonuslevel / 4) * 10) }
	end
end

function rpg_respawn(event)
	local player = game.players[event.player_index]
	rpg_give_bonuses(player)
end

-- GUI STUFF --
--Add/rebuild class/level gui
function rpg_add_gui(event)
	local player = game.players[event.player_index]
	local flow = mod_gui.get_button_flow(player)
	if flow.rpg then
		flow.rpg.destroy()
	end
	flow.add{type="frame", name="rpg"}
	flow.rpg.add{type="flow", name="container", direction="vertical"}
	flow.rpg.container.add{type="button", name="class", caption="Class: " .. global.rpg_data[player.name].class, tooltip="Open character panel"}
	flow.rpg.container.add{type="label", name="level", caption="Level 1"}
	flow.rpg.container.add{type="progressbar", name="exp", size=200}
	flow.rpg.container.tooltip="Kill biter bases, research tech, or launch rockets to level up."

	script.raise_event(rpg.on_rpg_gui_created, event) --Make other guis wait until this is drawn first.
	--rpg_post_rpg_gui(event) --re-add admin and tag guis
end

--Create class pick / change gui
--function rpg_class_picker(event)
function rpg_class_picker(player)
	--local player = game.players[event.player_index]
	--Check if player is eligible to change classes.
	--15 minute cooldown	
	if global.rpg_tmp[player.name].class_timer and game.tick > global.rpg_tmp[player.name].class_timer + 60 * 60 * 15 then
		if player.gui.center.sheet then
			player.gui.center.sheet.destroy()
		end
		
		--Iterate over each class to find out what level they are before the player picks.
		local levels = {Soldier = 1, Builder = 1, Scientist = 1, Miner = 1, Beastmaster = 1, None = 1}
		for k, v in pairs(levels) do
			if global.rpg_data[player.name][k] then
				while global.rpg_data[player.name][k] >= rpg_exp_tnl(levels[k]) do
					levels[k] = levels[k]+1
				end
				--game.print("Class: " ..k .. " Level: "..v) --This works
			end
			--game.print("Class: " ..k .. " Level: "..v) --This works
		end	
	
		if not player.gui.center.picker then
			player.gui.center.add{type="frame", name="picker", caption="Choose a class"}
			player.gui.center.picker.add{type="flow", name="container", direction="vertical"}
			player.gui.center.picker.container.add{type="button", name="Soldier", caption="Soldier", tooltip="Enhance the combat abilities of your team, larger radar radius"}
			player.gui.center.picker.container.add{type="button", name="Builder", caption="Builder", tooltip="Extra reach, team turret damage, additional quickbars (at 20 and 50)"}
			player.gui.center.picker.container.add{type="button", name="Scientist", caption="Scientist", tooltip="Boost combat robots, laboratory speed and productivity, team health, team movement speed, worker robot speed/battery"}
			player.gui.center.picker.container.add{type="button", name="Miner", caption="Miner", tooltip="Increase explosive damage and mining productivity of your team"}
			--player.gui.center.picker.container.add{type="button", name="Beastmaster", caption="Beastmaster", tooltip="Gain biter pets on nest kills. Reduces evolution scaling.(BETA)"}
			player.gui.center.picker.container.add{type="button", name="None", caption="None", tooltip="No bonuses are given to team."}
			
			for k, v in pairs(player.gui.center.picker.container.children) do
				if levels[v.name] > 1 then
					v.caption = v.caption .. " : " .. levels[v.name]
				end
			end
			
			player.gui.center.picker.add{type="button", name="pickerclose", caption="x"}
		end
	else
		player.print("You cannot change class for " .. math.ceil( 15 - ( (game.tick - global.rpg_tmp[player.name].class_timer) / 60 / 60) ) .. " more minutes.")
	end
end

--rpg gui handler
function rpg_class_click(event)
	local player = game.players[event.player_index]
	if not (event.element and event.element.name) then
		return
	end
	if event.element.name == "class_picker" then
		rpg_class_picker(player)
		return
	end
	if event.element.name == "team_bonuses" then
		player.opened = defines.gui_type.bonus
		return
	end
	if event.element.name == "class" then
		rpg_character_sheet(player)
		return
	end
	if event.element.name == "Soldier" or event.element.name == "Builder" or event.element.name == "Scientist" or event.element.name == "Miner" or event.element.name == "None" or event.element.name == "Beastmaster" then
		rpg_set_class(player, event.element.name)
		player.gui.center.picker.destroy()
		rpg_update_gui(player)
		return
	end
	if event.element.name == "pickerclose" then
		if global.rpg_data[player.name].class == "Engineer" then
			rpg_set_class(player, "None")
			rpg_update_gui(player)
		end
		player.gui.center.picker.destroy()
		return
	end
	if event.element.name == "close_character" then
		player.gui.center.sheet.destroy()
		return
	end
end

--Create the gui for other mods.
function rpg_post_rpg_gui(event)
	if CreateSpawnCtrlGui then
		CreateSpawnCtrlGui(game.players[event.player_index])
	end
--	admin_joined(event)
	tag_create_gui(event)
end

--Update gui
function rpg_update_gui(player)
	local flow = mod_gui.get_button_flow(player)
	if not flow.rpg then
		rpg_add_gui({player_index=player.index})
	end
	local level = global.rpg_tmp[player.name].level
	--Update progress bar.
	local class = global.rpg_data[player.name].class
	flow.rpg.container.class.caption = "Class: " .. global.rpg_data[player.name].class
	flow.rpg.container.exp.value = (global.rpg_data[player.name][class] - rpg_exp_tnl(level-1)) / ( rpg_exp_tnl(level) - rpg_exp_tnl(level-1) )
	flow.rpg.container.exp.tooltip = math.floor(flow.rpg.container.exp.value * 10000)/100 .. "% to next level ( " .. math.floor(global.rpg_data[player.name][class]) - rpg_exp_tnl(level-1) .. " / " .. rpg_exp_tnl(level) - rpg_exp_tnl(level-1) .. " )"
	flow.rpg.container.level.caption = "Level " .. level
	--game.print("Updating exp bar value to " .. flow.rpg.exp.value)
end

function rpg_character_sheet(player)
	if not player.gui.center.sheet then
		if player.controller_type == defines.controllers.character then --Make sure player has a character
			player.gui.center.add{type="frame", name="sheet", caption="Level " ..global.rpg_tmp[player.name].level .. " " .. global.rpg_data[player.name].class}
			player.gui.center.sheet.add{type="flow", name="container", direction="vertical"}
			player.gui.center.sheet.container.add{type="flow", name="control", direction="horizontal"}
			player.gui.center.sheet.container.add{type="flow", name="stats", direction="horizontal"}
			player.gui.center.sheet.container.control.add{type="button", name="class_picker", caption="Change Class"}
			player.gui.center.sheet.container.control.add{type="button", name="team_bonuses", caption="Team Bonuses"}
			player.gui.center.sheet.container.control.add{type="button", name="close_character", caption="x"}
			
			local column_one = player.gui.center.sheet.container.stats.add{type="flow", name="column_one", direction="vertical"} --Label
			local column_two = player.gui.center.sheet.container.stats.add{type="flow", name="column_two", direction="vertical"} --Total bonus
			local column_three = player.gui.center.sheet.container.stats.add{type="flow", name="column_three", direction="vertical"} --Personal bonus
			
			--Header
			column_one.add{type="label", name="header_one", caption="-*-"}
			column_two.add{type="label", name="header_two", caption="Bonus:"}
			column_three.add{type="label", name="header_three", caption="(personal)"}
			
			--Start info
			column_one.add{type="label", caption="Health:"}
			column_two.add{type="label", caption=math.floor(player.character.prototype.max_health+player.character_health_bonus + player.force.character_health_bonus)}
			column_three.add{type="label", caption=math.floor(player.character_health_bonus)}
			
			column_one.add{type="label", caption="Running Speed:"}
			column_two.add{type="label",  caption="+" .. math.floor(((1+player.character_running_speed_modifier)*(1+player.force.character_running_speed_modifier)-1) * 100) .. "%" }
			column_three.add{type="label", caption="+" .. math.floor(player.character_running_speed_modifier * 100) .. "%"}
			
			column_one.add{type="label", caption="Crafting Speed:"}
			column_two.add{type="label", caption="+" .. math.floor(((1+player.character_crafting_speed_modifier)*(1+player.force.manual_crafting_speed_modifier)-1) * 100) .. "%" }
			--This one can be negative so...
			if player.character_crafting_speed_modifier >= 0 then
				column_three.add{type="label", caption="+" .. math.floor(player.character_crafting_speed_modifier * 100) .. "%"}
			else
				column_three.add{type="label", caption=math.floor(player.character_crafting_speed_modifier * 100) .. "%"}
			end
			
			column_one.add{type="label", caption="Mining Speed:"}
			column_two.add{type="label", caption="+" .. math.floor(((1+player.character_mining_speed_modifier)-1) * 100 ) .. "%" }
			column_three.add{type="label", caption="+" .. math.floor(player.character_mining_speed_modifier*100) .. "%"}
			
			column_one.add{type="label", caption="Reach:"}
			column_two.add{type="label", caption="+" .. (player.character_reach_distance_bonus + player.force.character_reach_distance_bonus)}
			column_three.add{type="label", caption="+" .. player.character_reach_distance_bonus}
			
			column_one.add{type="label", caption="Bonus Inventory:"}
			column_two.add{type="label", caption="+" .. player.character_inventory_slots_bonus + player.force.character_inventory_slots_bonus}
			column_three.add{type="label", caption="+" .. player.character_inventory_slots_bonus }
			
			column_one.add{type="label", caption="Combat Robots:"}
			column_two.add{type="label", caption=player.character_maximum_following_robot_count_bonus + player.force.maximum_following_robot_count}
			column_three.add{type="label", caption=player.character_maximum_following_robot_count_bonus }
		end
		
	else
		player.gui.center.sheet.destroy()
	end
end

-- END GUI STUFF --

-- UTILITY FUNCTIONS --
--Load exp value, calculate value, set bonuses.
function rpg_set_class(player, class)
	global.rpg_tmp[player.name].level = 1
	global.rpg_data[player.name].class = class
	global.rpg_tmp[player.name].class_timer = game.tick
	if not global.rpg_data[player.name][class] then
		global.rpg_data[player.name][class] = 0
	end
	while rpg_ready_to_level(player) do
		rpg_levelup(player)
	end
	if not global.rpg_data[player.name].bank then --Something went wrong
		log("RPG: Bank does not exist.  Something went wrong.")
		return
	end
	if global.rpg_data[player.name].bank > 0 then
		player.print("Banked experience: " .. math.floor(global.rpg_data[player.name].bank) .. " detected.  Leveling will be accelerated.")
	end
	--global.rpg_data[player.name].ready = math.max(global.rpg_data[player.name].level, global.rpg_data[player.name].ready)
	rpg_give_bonuses(player)
	rpg_give_team_bonuses(player.force)
	--rpg_starting_resources(player)
end

-- PLAYERS JOINING AND LEAVING --
--Rejoining will re-calculate bonuses.  Specifically for rocket launches.
function rpg_connect(event)
	local player = game.players[event.player_index]
	--This should be obsolete
	if not global.rpg_data then
		--Init did not fire.  This is due to oarc not liking the 3ra event handler.
		rpg_init()
	end
	--This no longer fires.  We should do this on the load data command.
	-- if global.rpg_tmp[player.name] and global.rpg_tmp[player.name].ready then
	-- 	rpg_give_bonuses(player)
	-- 	rpg_give_team_bonuses(player.force)
	-- end
end

--Leaving the game causes team bonuses to be re-calculated
function rpg_left(event)
	rpg_give_team_bonuses(game.players[event.player_index].force)
end

-- Produces format { "player-name"=total exp }
-- function rpg_export()
	-- for name, data in pairs(global.rpg_data) do
		-- game.write_file("rpgsave.txt", "{ '" .. name .."'=" .. data.exp .. ",\n", true, 1)
	-- end
-- end

--TODO: During merge script, check if old exp is greater than new exp to prevent possible data loss.

-- EXP STUFF --
function rpg_nest_killed(event)
	--game.print("Entity died.")
	if not (event.entity and event.entity.valid) then
		return
	end

	--Check all 4 directions around to see if any are in pollution cloud.  Spawners consume pollution so their own position may not count, even if they should.
	local function is_in_pollution()
		if event.entity.surface.get_pollution{event.entity.position.x + 128, event.entity.position.y} >= 20 or
			event.entity.surface.get_pollution{event.entity.position.x, event.entity.position.y + 128} >= 20 or
			event.entity.surface.get_pollution{event.entity.position.x - 128, event.entity.position.y} >= 20 or
			event.entity.surface.get_pollution{event.entity.position.x, event.entity.position.y - 128} >= 20 or
			event.entity.surface.get_pollution{event.entity.position.x, event.entity.position.y} >= 20 then
			return true
		else
			return false
		end
	end

	if event.entity.type == "unit-spawner" then
		--game.print("Spawner died.")
		if event.cause and event.cause.type == "player" and is_in_pollution() then
			--game.print("Spawner died by player.  Awarding exp.")
			rpg_nearby_exp(event.entity.position, event.cause.force, 100)
			return
		else
			if event.cause and event.cause.last_user and is_in_pollution() then
				rpg_nearby_exp(event.entity.position, event.cause.force, 100)
				return
			end
		end		
	end

	if event.entity.type == "turret" and string.find(event.entity.name, "worm") then
		--Worm turret died.
		if not is_in_pollution() then
			return
		end

		--Temporary measure.  This can cause players on different teams to get exp.  Super edge-case stuff.
		local radius = 64
		local position = event.entity.position
		for __, player in pairs(game.connected_players) do
			if player.position.x < position.x + radius and player.position.x > position.x - radius and player.position.y < position.y + radius and player.position.y > position.y - radius then
				rpg_add_exp(player, 50)
			end
		end
	end
end

function rpg_nearby_exp(position, force, amount)
	local radius = 64
	if force.name == "beasts" then --Check all online players.
		for __, player in pairs(game.connected_players) do
			if player.position.x < position.x + radius and player.position.x > position.x - radius and player.position.y < position.y + radius and player.position.y > position.y - radius then
				rpg_add_exp(player, amount)
			end
		end
	else
		for __, player in pairs(force.connected_players) do
			if player.position.x < position.x + radius and player.position.x > position.x - radius and player.position.y < position.y + radius and player.position.y > position.y - radius then
				rpg_add_exp(player, amount)
			end
		end
	end
end

--Award exp based on number of beakers
--This respects research multiplier setting
function rpg_tech_researched(event)
	--rpg_give_team_bonuses calls this event a lot.
	if event.by_script then
		return
	end
	local value = 0
	--Space science packs aren't worth anything.  You already got exp for the rocket!
	for _, ingredient in pairs(event.research.research_unit_ingredients) do
		if ingredient.name == "science-pack-1" then
			value = value + ingredient.amount * event.research.research_unit_count
		elseif ingredient.name == "science-pack-2" then
			value = value + ingredient.amount * event.research.research_unit_count
		elseif ingredient.name == "science-pack-3" then
			value = value + ingredient.amount * event.research.research_unit_count
		elseif ingredient.name == "military-science-pack" then
			value = value + ingredient.amount * event.research.research_unit_count
		elseif ingredient.name == "production-science-pack" then
			value = value + ingredient.amount * event.research.research_unit_count
		elseif ingredient.name == "high-tech-science-pack" then
			value = value + ingredient.amount * event.research.research_unit_count
		end
	end
	--value = value ^ 0.85 --Old formula
	value = 20 * value ^0.55
	for _, player in pairs(event.research.force.players) do
		if player.connected then
			rpg_add_exp(player, value)
		end
	end
end

function rpg_satellite_launched(event)
	local bonus = 40000
	if game.difficulty_settings.recipe_difficulty == 1 then
		bonus = 2 * bonus
	end
	if game.difficulty_settings.technology_difficulty == 1 then
		bonus = 2 * bonus
	end
	if event.rocket.get_item_count("satellite") > 0 then
		global.satellites_launched = global.satellites_launched + 1
		bonus = math.max(100, bonus / (global.satellites_launched^1.5))
		for n, player in pairs(game.players) do
			--Scale this so players only need to be online for 80% of the time to achieve full reward.
			local fraction_online = math.min(1, player.online_time / game.tick / 0.8)
			rpg_add_exp(player, bonus * fraction_online)
		end
	end
end

--Display exp, check for level up, update gui
function rpg_add_exp(player, amount)
	
	--local level = global.rpg_data[player.name].level
	local class = global.rpg_data[player.name].class
	
	--Bonus exp from legacy
	if global.rpg_data[player.name].bank and global.rpg_data[player.name].bank > 0 then
		local bonus = math.ceil(math.min(global.rpg_data[player.name].bank, amount))
		if bonus > 0 then
			global.rpg_data[player.name].bank = global.rpg_data[player.name].bank - bonus
			amount = amount + bonus
		end
	end
	global.rpg_data[player.name][class] = math.floor(global.rpg_data[player.name][class] + amount)	
	--Now check for levelup.
	local levelled = false
	while rpg_ready_to_level(player) do
		rpg_levelup(player)
		levelled = true
	end
	if player.connected then
		if levelled == false then
			player.surface.create_entity{name="flying-text", text="+" .. math.floor(amount) .. " exp", position={player.position.x, player.position.y - 3}}
		else
			rpg_give_bonuses(player)
			rpg_give_team_bonuses(player.force)
		end
	end
	--Parent value updated so update our local value.
	--level = global.rpg_data[player.name].level
	
	rpg_update_gui(player)
end
	
--Free exp.  For testing.
function rpg_exp_tick(event)
	if event.tick % (60 * 10) == 0 then
		for n, player in pairs(game.players) do
			game.print("Adding auto-exp")
			rpg_add_exp(player, 600)
		end
	end
end

--The EXP curve function
function rpg_exp_tnl(level)
	if level == 0 then
		return 0
	end
	return (math.ceil( (3.6 + level)^3 / 10) * 100)
end

--Possible benefits from leveling up:
--Personal:
--Increased health
--Nearby ore deposits are enriched.
--Increased reach/build distance
--Bonus logistics slots
--Bonus trash slots
--Bonus combat robot slots
--Bonus run speed.
--Forcewide: (This is when I add classes)
--Increased health (function of cumulative bonuses of online players)
--Force gets a damage boost (function of cumulative offense bonus of online players)
--Increased ore.

--Functions for handling levels
function rpg_ready_to_level(player)
	local class = global.rpg_data[player.name].class
	if global.rpg_data[player.name][class] >= rpg_exp_tnl(global.rpg_tmp[player.name].level) then
		return true
	end
end

function rpg_levelup(player)
	if player.connected then
		player.surface.create_entity{name="flying-text", text="Level up!", position={player.position.x, player.position.y-3}}
	end
	global.rpg_tmp[player.name].level = global.rpg_tmp[player.name].level + 1
	
	--Promote and allow decon planners
	if global.rpg_tmp[player.name].level >= 5 then
		if not player.permission_group or player.permission_group.name == "Default" then
			player.permission_group = game.permissions.get_group("trusted")
		end
	end
	
	--Award bonuses
	-- if player.connected then
		-- rpg_give_bonuses(player)
		-- rpg_give_team_bonuses(player.force)
	-- end
end

--Sum all exp values and return level as if player stuck to one class.
function rpg_level_sum(player)
	local sum_exp = 0
	local total_level = 1
	if global.rpg_data[player.name].bank then
		sum_exp = sum_exp + global.rpg_data[player.name].bank
	end
	if global.rpg_data[player.name].Soldier then
		sum_exp = sum_exp + global.rpg_data[player.name].Soldier 
	end
	if global.rpg_data[player.name].Builder then
		sum_exp = sum_exp + global.rpg_data[player.name].Builder 
	end
	if global.rpg_data[player.name].Scientist then
		sum_exp = sum_exp + global.rpg_data[player.name].Scientist 
	end
	if global.rpg_data[player.name].Miner then
		sum_exp = sum_exp + global.rpg_data[player.name].Miner 
	end
	if global.rpg_data[player.name].Beastmaster then
		sum_exp = sum_exp + global.rpg_data[player.name].Beastmaster 
	end
	while rpg_exp_tnl(total_level) < sum_exp do
		total_level = total_level + 1
	end
	return total_level
end

--Award bonuses
function rpg_give_bonuses(player)
	if not global.rpg_data[player.name] then
		--Data not yet loaded.
		return
	end
	local bonuslevel = global.rpg_tmp[player.name].level - 1
	if player.controller_type == defines.controllers.character then --Just in case player is in spectate mode or some other weird stuff is happening
		player.character_health_bonus = 8 * bonuslevel
		player.character_running_speed_modifier = 0.005 * bonuslevel -- This seems multiplicative
		player.character_mining_speed_modifier = 0.06 * bonuslevel
		player.character_crafting_speed_modifier = 0.06 * bonuslevel
		if global.rpg_data[player.name].class == "Soldier" then
			player.character_health_bonus = 12 * bonuslevel
		else
			player.character_health_bonus = 8 * bonuslevel
		end
		if global.rpg_data[player.name].class == "Builder" then
			player.character_reach_distance_bonus = math.floor(bonuslevel/3)
			player.character_resource_reach_distance_bonus = math.floor(bonuslevel/8)
			player.character_build_distance_bonus = math.floor(bonuslevel/3)
			player.character_inventory_slots_bonus = math.floor(bonuslevel/3)
			if global.rpg_tmp[player.name].level >= 50 then
				player.quickbar_count_bonus = 2
			elseif global.rpg_tmp[player.name].level >= 20 then
				player.quickbar_count_bonus = 1
			end
		else
			player.character_reach_distance_bonus = math.floor(bonuslevel/6)
			player.character_build_distance_bonus = math.floor(bonuslevel/6)
			player.character_resource_reach_distance_bonus = math.floor(bonuslevel/12)
			player.character_inventory_slots_bonus = math.floor(bonuslevel/6)
			player.quickbar_count_bonus = 0
		end
		if global.rpg_data[player.name].class == "Scientist" then
			player.character_maximum_following_robot_count_bonus = math.floor(bonuslevel/2.5)
		else
			player.character_maximum_following_robot_count_bonus = math.floor(bonuslevel/5)
		end
	end
end

--Calculate and assign team bonuses.  Check on player levelup and player connect and player disconnect
function rpg_give_team_bonuses(force)
	local soldierbonus = 0
	local scientistbonus = 0
	local builderbonus = 0
	local minerbonus = 0
	local beastmasterbonus = 0
	for k,v in pairs(force.players) do
		if v.connected then
			if global.rpg_data[v.name].class == "Soldier" then
				soldierbonus = soldierbonus + global.rpg_tmp[v.name].level
			end
			if global.rpg_data[v.name].class == "Scientist" then
				scientistbonus = scientistbonus + global.rpg_tmp[v.name].level
			end
			if global.rpg_data[v.name].class == "Builder" then
				builderbonus = builderbonus + global.rpg_tmp[v.name].level
			end
			if global.rpg_data[v.name].class == "Miner" then
				minerbonus = minerbonus + global.rpg_tmp[v.name].level
			end
			if global.rpg_data[v.name].class == "Beastmaster" then
				beastmasterbonus = beastmasterbonus + global.rpg_tmp[v.name].level
			end
		end
	end
	
	local inventory_bonus = force.character_inventory_slots_bonus
	--That entire code block for calculating base bonus can be replaced by this:
	force.reset_technology_effects()
		
	--For some reason this stops current research.  So let's save and reset it.
	-- Made obsolete by 0.15.13
	-- if force.current_research then
		-- --global.force_to_fix = force
		-- global.current_research = force.current_research.name
		-- global.research_progress = force.research_progress
		-- force.reset_technology_effects()
		-- force.current_research = global.current_research
		-- force.research_progress = global.research_progress
	-- else
		-- force.reset_technology_effects()
	-- end
	--This step must be done next tick.
	--force.research_progress = research_progress
	
	--Calculate base bonuses.
	-- local baseammobonus = {}
	-- local baseturretbonus = {}
	-- local basemining = 0
	-- local baselabspeed = 0
	-- local baseworkerspeed = 0
	-- for k,v in pairs(force.technologies) do
		-- if v.researched then	
			-- for n, p in pairs(v.effects) do
				-- if p.type=="ammo-damage" then
					-- if not baseammobonus[p.ammo_category] then
						-- baseammobonus[p.ammo_category] = 0
					-- end
					-- if p.level > 0 then
						-- baseammobonus[p.ammo_category] = baseammobonus[p.ammo_category] + p.modifier * p.level
					-- else
						-- baseammobonus[p.ammo_category] = baseammobonus[p.ammo_category] + p.modifier
					-- end
				-- end
				-- --Gun turrets are weird.
				-- if p.type=="turret-attack" then
					-- if not baseturretbonus[p.turret_id] then
						-- baseturretbonus[p.turret_id] = 0
					-- end
					-- if p.level > 0 then
						-- baseturretbonus[p.turret_id] = baseturretbonus[p.turret_id] + p.modifier * p.level
					-- else
						-- baseturretbonus[p.turret_id] = baseturretbonus[p.turret_id] + p.modifier
					-- end
				-- end
				-- if p.type=="laboratory-speed" then
					-- baselabspeed = baselabspeed + p.modifier
				-- end
				-- if p.type=="mining-drill-productivity-bonus" then
					-- basemining = basemining + p.modifier * p.level
				-- end
				-- if p.type=="worker-robot-speed" then
					-- if p.level > 0
						-- baseworkerspeed = baseworkerspeed + p.modifier * p.level
					-- else
						-- baseworkerspeed = baseworkerspeed + p.modifier
					-- end
				-- end
			-- end
		-- end
	-- end
	
	--Now apply bonuses
	soldierbonus = math.floor(soldierbonus^0.85)
	scientistbonus = math.floor(scientistbonus^0.85)
	builderbonus = math.floor(builderbonus^0.85)
	minerbonus = math.floor(minerbonus^0.85)
	--Beastmaster
	
	--I do need that block after all to find the list of ammo types and gun types
	-- Obsoleted by game.ammo_category_prototypes
	-- local ammotypes = {}
	-- local turrettypes = {}
	-- for k,v in pairs(force.technologies) do
	-- 	--if v.researched then
	-- 		for n, p in pairs(v.effects) do
	-- 			if p.type=="ammo-damage" then
	-- 				ammotypes[p.ammo_category]=true
	-- 			end
	-- 			if p.type=="turret-attack" then
	-- 				turrettypes[p.turret_id]=true
	-- 			end
	-- 		end
	-- 	--end
	-- end

	-- Malus for ammo is base * 0.8 - 0.2
	for k, v in pairs(game.ammo_category_prototypes) do
		if string.find(k, "turret") then
			force.set_ammo_damage_modifier(k, builderbonus / 100 + force.get_ammo_damage_modifier(k) * 0.85 - 0.15)
		--Note, this does NOT include laser turrets!  Those were already buffed by builders!
		elseif string.find(k, "robot") or string.find(k, "capsule") or string.find(k, "laser")  then
			force.set_ammo_damage_modifier(k, scientistbonus / 100 + force.get_ammo_damage_modifier(k) * 0.8 - 0.2)
		elseif string.find(k, "grenade") or string.find(k, "rocket") or string.find(k, "arti") then
			force.set_ammo_damage_modifier(k, minerbonus / 100 + force.get_ammo_damage_modifier(k) * 0.8 - 0.2)
		else --Bullets, shells, flamethrower
			force.set_ammo_damage_modifier(k, soldierbonus / 50 + force.get_ammo_damage_modifier(k) * 0.8 - 0.2)
		end
	end

	-- Gun-turrets are handled separately
	force.set_turret_attack_modifier("gun-turret", force.get_turret_attack_modifier("gun-turret") * 0.85 - 0.15 + builderbonus / 100)
	
	--Just for you, Tux0n0
	force.set_ammo_damage_modifier("railgun", soldierbonus / 25)

	-- for k,v in pairs(turrettypes) do
	-- 	force.set_turret_attack_modifier(k, builderbonus / 100 + force.get_turret_attack_modifier(k) * 0.8 - 0.2)
	-- end
	
	force.character_health_bonus = scientistbonus / 3 --Base health is 250, so this is scaled up similarly
	force.character_running_speed_modifier = scientistbonus / 400
	force.worker_robots_speed_modifier = scientistbonus / 40 + force.worker_robots_speed_modifier * 0.80 - 0.4
	force.worker_robots_battery_modifier = scientistbonus / 50
	if scientistbonus > 50 then
		force.worker_robots_storage_bonus =  force.worker_robots_storage_bonus + 1
	end
	
	--This one can't decrease, or players logging out would cause stuff to drop!
	--Disabling this because I can't make it stop dropping stuff.
	--force.character_inventory_slots_bonus = math.max(inventory_bonus, math.floor(builderbonus / 20))
	
	-- Malus is 0.5 * base bonus - 0.5
	-- Science bonus
	force.laboratory_speed_modifier = scientistbonus / 100 + 0.5 * force.laboratory_speed_modifier - 0.5
	force.laboratory_productivity_bonus = scientistbonus / 1000 + force.laboratory_productivity_bonus
	
	--Crafting speed penalty.
	force.manual_crafting_speed_modifier = -0.3
	
	--Mining bonus
	force.mining_drill_productivity_bonus = minerbonus / 50 + force.mining_drill_productivity_bonus
	
	--Beastmaster bonus
	--Let's turn this into a factor for easier application
	beastmasterbonus = 100 / (100 + beastmasterbonus)
	game.map_settings.enemy_evolution.destroy_factor = global.base_evolution_destroy * beastmasterbonus
	game.map_settings.enemy_evolution.pollution_factor = global.base_evolution_pollution * beastmasterbonus
	game.map_settings.enemy_evolution.time_factor = global.base_evolution_time * beastmasterbonus
	
	--So I can notify other modules when this happens:
	script.raise_event(rpg.on_reset_technology_effects, {force=force})

	--Fix for frontier silo:
	if frontier_silo then
		force.recipes["rocket-silo"].enabled = false
	end
end

-- Soldier reward: Bonus radius to radar scanning
function rpg_bonus_scan(event)
	if not (event.radar and event.radar.valid) then
		log("RPG: Radar not valid.")
		return
	end
	
	local soldierbonus = 0
	local force = event.radar.force
	for k,v in pairs(force.players) do
		if v.connected then
			if global.rpg_data[v.name].class == "Soldier" then
				soldierbonus = soldierbonus + global.rpg_tmp[v.name].level
			end
		end
	end
	local bonus = 32 * (soldierbonus ^ 0.25) --This is height and width of the area we're scanning.
	
	local bbox = {{}, {}}
	if event.radar.position.x < event.chunk_position.x * 32 then
		bbox[1][1] = event.chunk_position.x * 32
		bbox[2][1] = event.chunk_position.x * 32 + bonus
	else
		bbox[1][1] = event.chunk_position.x * 32 - bonus + 32
		bbox[2][1] = event.chunk_position.x * 32
	end
	if event.radar.position.y < event.chunk_position.y * 32 then
		bbox[1][2] = event.chunk_position.y * 32
		bbox[2][2] = event.chunk_position.y * 32 + bonus
	else
		bbox[1][2] = event.chunk_position.y * 32 - bonus + 32
		bbox[2][2] = event.chunk_position.y * 32
	end
	
	--local position = { x=event.chunk_position.x * 32 + 16, y=event.chunk_position.y * 32 + 16 }

	-- Extend scan in the same direction as the radar.
	--Default case, bottom-right quadrant
	--local bbox = {{position.x-bonus/2, position.y-bonus/2}, {position.x+bonus/2, position.y+bonus/2}}

	--local bbox = {{event.chunk_position.x * 32, event.chunk_position.y * 32}, {event.chunk_position.x * 32 + bonus}
		
	event.radar.force.chart(event.radar.surface, bbox)
end

--Scientist reward: No corpse running!
function rpg_im_too_smart_to_die(event)
	local player = game.players[event.player_index]
	if global.rpg_data[player.name].class == "Scientist" and global.rpg_tmp[player.name].level >= 50 then
		if not global.rpg_tmp[player.name].clonejump then
			global.rpg_tmp[player.name].clonejump = game.tick
		elseif global.rpg_tmp[player.name].clonejump + 60 * 60 * 60 > game.tick then --1 hour cooldown
			return
		end

		global.rpg_tmp[player.name].clonejump = game.tick
		player.character.health = 1
		player.print("Emergency teleporter activated.")
		
		--This interacts with Oarc.  Need to use player's spawn location.
		if ENABLE_SEPARATE_SPAWNS then
			player.teleport(global.playerSpawns[player.name])
		else
			--Non Oarc respawn:
			player.teleport(player.force.get_spawn_position(player.surface))
		end
	end
end

-- Obsolete as of 0.15.13
-- function rpg_fix_tech()
	-- if global.force_to_fix then
		-- if global.current_research then
			-- global.force_to_fix.current_research = global.current_research
			-- global.force_to_fix.research_progress = global.research_progress
			-- global.force_to_fix = nil
			-- global.current_research = nil
			-- global.research_progress = nil
		-- end
	-- end	
-- end

function rpg_init()
	if global.rpg_data then return end
	global.rpg_data = {}
	global.rpg_tmp = {} --For non-persistent data.

	--global.rpg = {}
	--global.rpg.heartbeat = {}
	
	global.base_evolution_destroy = game.map_settings.enemy_evolution.destroy_factor
	global.base_evolution_pollution = game.map_settings.enemy_evolution.pollution_factor
	global.base_evolution_time = game.map_settings.enemy_evolution.time_factor
	--Players can give bonuses to the team, so let's nerf the base values so players can re-buff them.
	
	--Doh, can't have a negative bonus.  This does not work.
	--game.forces.player.character_health_bonus = -50

	--Scenario stuff.
	global.satellites_launched = 0
	--game.forces.Admins.chart(player.surface, {{-400, -400}, {400, 400}}) --This doesn't work.  Admins is not created at the time?
	
end

--Utility function.
--UNUSED
-- function rpg_is_sanitary(name)
-- 	local sanitary = true
-- 	if string.find(name, "\\") or
-- 		string.find(name, "{") or
-- 		string.find(name, "}") or
-- 		string.find(name, "'") or
-- 		string.find(name, ",") or
-- 		string.find(name, "\"")
-- 	then
-- 		sanitary = false
-- 	end
-- 	if sanitary == false then
-- 		log("rpg save: Name was not sanitary!")
-- 		return false
-- 	end
-- 	--Still here?  Good!
-- 	return true
-- end

--Event.register(defines.events.on_player_created, rpg_add_gui) --We'll do this after a class is chosen.
Event.register(defines.events.on_player_created, rpg_loadsave) --This doesn't actually load anything anymore, just gives us some defaults.
--Event.register(defines.events.on_player_created, rpg_class_picker) --Wait for data to load.
--Event.register(defines.events.on_player_created, rpg_starting_resources)
Event.register(defines.events.on_gui_click, rpg_class_click)
Event.register(defines.events.on_player_joined_game, rpg_connect)
Event.register(defines.events.on_player_joined_game, rpg_remote_load)
Event.register(defines.events.on_player_left_game, rpg_remote_save)
Event.register(defines.events.on_player_respawned, rpg_respawn)
Event.register(defines.events.on_rocket_launched, rpg_satellite_launched)
Event.register(defines.events.on_entity_died, rpg_nest_killed)
Event.register(defines.events.on_research_finished, rpg_tech_researched)
Event.register(defines.events.on_sector_scanned, rpg_bonus_scan)
Event.register(defines.events.on_pre_player_died, rpg_im_too_smart_to_die)
--Event.register(defines.events.on_tick, rpg.heartbeat)
--Event.register(defines.events.on_research_finished, rpg_nerf_tech)
--Event.register(defines.events.on_tick, rpg_exp_tick) --For debug
Event.register(Event.core_events.init, rpg_init)
