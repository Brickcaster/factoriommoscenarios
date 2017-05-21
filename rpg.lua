--Factorio RPG, written by Mylon
--Utility command for griefing.
-- /silent-command do local hoarder = {amount=0} for k,v in pairs(game.players) do if v.get_item_count("uranium-235") > hoarder.amount then hoarder.name = v.name hoarder.amount = v.get_item_count("uranium-235") end end game.print(hoarder.name .. " is hoarding " .. hoarder.amount .. " uranium-235!") end

require "rpgdata" --Savedata.  This is externally generated.
--Savedata is of form: player_name = {bank = exp, class1 = exp, class2 = exp, etc}

--On player join, fetch exp.
function rpg_loadsave(event)
	local player = game.players[event.player_index]
	if not global.rpg_exp[player.name] then
		global.rpg_exp[player.name] = {level=1, class="Engineer", Engineer=0}
		if rpg_save[player.name] then
			--Load bank (legacy) and class exp
			for k,v in pairs(rpg_save[player.name]) do
				global.rpg_exp[player.name][k] = v
			end
		end
	end
end

-- SPAWN AND RESPAWN --
--Higher level players get more starting resources for an accelerated start!
function rpg_starting_resources(player)
	--local player = game.players[event.player_index]
	local bonuslevel = global.rpg_exp[player.name].level - 1
	if bonuslevel > 0 then
		player.insert{name="iron-plate", count=bonuslevel * 10}
		player.insert{name="copper-plate", count=math.floor(bonuslevel / 4) * 10}
		player.insert{name="stone", count=math.floor(bonuslevel / 4) * 10}
	end
end

function rpg_respawn(event)
	local player = game.players[event.player_index]
	rpg_give_bonuses(player)
end

--Save the persistent data.

function rpg_savedata()
	local filename = "rpgdata - " .. game.tick .. ".txt"
	local target
	--Are we on a dedicated server?
	if game.players[0] then
		target = 0
	else
		target = 1
	end
	game.write_file(filename, serpent.block(global.rpg_exp), true, target)
end

-- GUI STUFF --
--Add/rebuild class/level gui
function rpg_add_gui(event)
	local player = game.players[event.player_index]
	if player.gui.top.rpg then
		player.gui.top.clear()
	end
	player.gui.top.add{type="frame", name="rpg"}
	player.gui.top.rpg.add{type="flow", name="container", direction="vertical"}
	player.gui.top.rpg.container.add{type="button", name="class", caption="Class: " .. global.rpg_exp[player.name].class}
	player.gui.top.rpg.container.add{type="label", name="level", caption="Level 1"}
	player.gui.top.rpg.container.add{type="progressbar", name="exp", size=200, tooltip="Kill biter bases, research tech, or launch rockets to level up."}
	rpg_post_rpg_gui(event) --re-add admin and tag guis
end

--Create class pick / change gui
function rpg_class_picker(event)
	local player = game.players[event.player_index]
	if not player.gui.center.picker then
		player.gui.center.add{type="frame", name="picker", caption="Choose a class"}
		player.gui.center.picker.add{type="flow", name="container", direction="vertical"}
		player.gui.center.picker.container.add{type="button", name="Soldier", caption="Soldier", tooltip="Enhance the combat abilities of your team, larger radar radius"}
		player.gui.center.picker.container.add{type="button", name="Builder", caption="Builder", tooltip="Extra reach, team turret damage, additional quickbars (at 20 and 50)"}
		player.gui.center.picker.container.add{type="button", name="Scientist", caption="Scientist", tooltip="Boost combat robots, science speed, team health, team movement speed"}
		player.gui.center.picker.container.add{type="button", name="Miner", caption="Miner", tooltip="Incrase explosive damage and mining productivity of your team"}
		player.gui.center.picker.container.add{type="button", name="None", caption="None", tooltip="No bonuses are given to team."}
		player.gui.center.picker.add{type="button", name="pickerclose", caption="x"}
	end
end

--Picker gui handler
function rpg_class_click(event)
	player = game.players[event.player_index]
	if event.element.name == "class" then --TODO: This opens the character sheet instead of class picker
		rpg_class_picker(event)
	end
	if event.element.name == "Soldier" or event.element.name == "Builder" or event.element.name == "Scientist" or event.element.name == "Miner" or event.element.name == "None" then
		rpg_set_class(player, event.element.name)
		player.gui.center.picker.destroy()
		rpg_add_gui(event)
		tag_refresh(player) --refreshes tag of a player
	end
	if event.element.name == "pickerclose" then
		if global.rpg_exp[player.name].class == "Engineer" then
			rpg_set_class(player, "None")
			rpg_add_gui(event)
		end
		rpg_add_gui(event)
		tag_refresh(player) --refreshes tag of a player
		player.gui.center.picker.destroy()
	end
end

--Create the gui for other mods.
function rpg_post_rpg_gui(event)
	admin_joined(event)
	tag_create_gui(event)
end
-- END GUI STUFF --

-- UTILITY FUNCTIONS --
--Load exp value, calculate value, set bonuses.
function rpg_set_class(player, class)
	global.rpg_exp[player.name].level = 1
	global.rpg_exp[player.name].class = class
	while rpg_ready_to_level(player) do
		rpg_levelup(player)
	end
	if global.rpg_exp[player.name].bank > 0 then
		player.print("Banked experience: " .. global.rpg_exp[player.name].bank .. " detected.  Leveling will be accelerated.")
	end
	global.rpg_exp[player.name].ready = true
	rpg_starting_resources(player)
end

-- PLAYERS JOINING AND LEAVING --
--Rejoining will re-calculate bonuses.  Specifically for rocket launches.
function rpg_connect(event)
	local player = game.players[event.player_index]
	rpg_give_bonuses(player)
	rpg_give_team_bonuses(player.force)
end

--Leaving the game causes team bonuses to be re-calculated
function rpg_left(event)
	rpg_give_team_bonuses(game.players[event.player_index].force)
end

-- Produces format { "player-name"=total exp }
-- function rpg_export()
	-- for name, data in pairs(global.rpg_exp) do
		-- game.write_file("rpgsave.txt", "{ '" .. name .."'=" .. data.exp .. ",\n", true, 1)
	-- end
-- end

--TODO: During merge script, check if old exp is greater than new exp to prevent possible data loss.

-- EXP STUFF --
function rpg_nest_killed(event)
	--game.print("Entity died.")
	if event.entity.type == "unit-spawner" then
		--game.print("Spawner died.")
		if event.cause and event.cause.type == "player" then
			--game.print("Spawner died by player.  Awarding exp.")
			rpg_add_exp(event.cause.player, 100)
		else
			if event.cause and event.cause.last_user then
				rpg_add_exp(event.cause.last_user, 100)
			end
		end
	end
	if event.entity.type == "turret" and event.entity.force.name == "enemy" then
		--Worm turret died.
		if event.cause and event.cause.player then
			rpg_add_exp(event.cause.player, 50)
		else
			if event.cause and event.cause.last_user then
				rpg_add_exp(event.cause.last_user, 50)
			end
		end
	end
end

--Award exp based on number of beakers
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
	value = value ^ 0.85
	for _, player in pairs(game.players) do
		if player.connected then
			rpg_add_exp(player, value)
		end
	end
end

function rpg_satellite_launched(event)
	local bonus = 0
	--Todo: Check for hard recipes mode.
	if event.rocket.get_item_count("satellite") > 0 then
		global.satellites_launched = global.satellites_launched + 1
		bonus = math.max(10, 20000 / (global.satellites_launched^1.5))
		for n, player in pairs(game.players) do
			local fraction_online = player.online_time / game.tick
			rpg_add_exp(player, bonus * fraction_online)
		end
	end
end

--Display exp, check for level up, update gui
function rpg_add_exp(player, amount)
	--Bonus exp from legacy
	if global.rpg_exp[player.name].bank > 0 then
		local bonus = math.min(global.rpg_exp[player.name].bank, amount)
		if bonus > 0 then
			global.rpg_exp[player.name].bank = global.rpg_exp[player.name].bank - bonus
			amount = amount + bonus
		end
	end
	global.rpg_exp[player.name][global.rpg_exp.class] = math.floor(global.rpg_exp[player.name][global.rpg_exp.class] + amount)
	local level = global.rpg_exp[player.name].level
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
	level = global.rpg_exp[player.name].level
	class = global.rpg_exp[player.name].class
	--Update progress bar.
	player.gui.top.rpg.container.exp.value = (global.rpg_exp[player.name][class] - rpg_exp_tnl(level-1)) / ( rpg_exp_tnl(level) - rpg_exp_tnl(level-1) )
	player.gui.top.rpg.tooltip = math.floor(player.gui.top.rpg.exp.value * 10000)/100 .. "% to next level ( " .. math.floor(global.rpg_exp[player.name][class]) - rpg_exp_tnl(level-1) .. " / " .. rpg_exp_tnl(level) - rpg_exp_tnl(level-1) .. " )"
	--game.print("Updating exp bar value to " .. player.gui.top.rpg.exp.value)
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

function rpg_ready_to_level(player)
	local class = global.rpg_exp[player.name].class
	if global.rpg_exp[player.name][class] >= rpg_exp_tnl(global.rpg_exp[player.name].level) then
		return true
	end
end

function rpg_levelup(player)
	if player.connected then
		player.surface.create_entity{name="flying-text", text="Level up!", position={player.position.x, player.position.y-3}}
	end
	global.rpg_exp[player.name].level = global.rpg_exp[player.name].level + 1
	
	--Award bonuses
	--Update GUI
	if player.connected then
		player.gui.top.rpg.container.level.caption = "Level " .. global.rpg_exp[player.name].level
		rpg_give_bonuses(player)
	end
	tag_refresh(player) --refreshes tag of a player
end

--Award bonuses
function rpg_give_bonuses(player)
	local bonuslevel = global.rpg_exp[player.name].level - 1
	if player.controller_type == defines.controllers.character then --Just in case player is in spectate mode or some other weird stuff is happening
		player.character_health_bonus = 8 * bonuslevel
		player.character_running_speed_modifier = 0.005 * bonuslevel -- This seems multiplicative
		player.character_mining_speed_modifier = 0.06 * bonuslevel
		player.character_crafting_speed_modifier = 0.06 * bonuslevel
		if global.rpg_exp[player.name].class == "Soldier" then
			player.character_health_bonus = 12 * bonuslevel
		else
			player.character_health_bonus = 8 * bonuslevel
		end
		if global.rpg_exp[player.name].class == "Builder" then
			player.character_reach_distance_bonus = math.floor(bonuslevel/3)
			player.character_build_distance_bonus = math.floor(bonuslevel/3)
			player.character_inventory_slots_bonus = math.floor(bonuslevel/3)
			if global.rpg_exp[player.name].level >= 50 then
				player.quickbar_count_bonus = 2
			elseif global.rpg_exp[player.name].level >= 20 then
				player.quickbar_count_bonus = 1
			end
		else
			player.character_reach_distance_bonus = math.floor(bonuslevel/6)
			player.character_build_distance_bonus = math.floor(bonuslevel/6)
			player.character_inventory_slots_bonus = math.floor(bonuslevel/6)
		end
		if global.rpg_exp[player.name].class == "Scientist" then
			player.character_maximum_following_robot_count_bonus = math.floor(bonuslevel/4)
		else
			player.character_maximum_following_robot_count_bonus = math.floor(bonuslevel/8)
		end
	end
end

--Calculate and assign team bonuses.  Check on player levelup and player connect and player disconnect
function rpg_give_team_bonuses(force)
	local soldierbonus = 0
	local scientistbonus = 0
	local builderbonus = 0
	local minerbonus = 0
	for k,v in pairs(game.players) do
		if v.connected and v.force == force then
			if global.rpg_exp[v.name].class == "Soldier" then
				soldierbonus = soldierbonus + global.rpg_exp[v.name].level
			end
			if global.rpg_exp[v.name].class == "Scientist" then
				scientistbonus = scientistbonus + global.rpg_exp[v.name].level
			end
			if global.rpg_exp[v.name].class == "Builder" then
				builderbonus = builderbonus + global.rpg_exp[v.name].level
			end
			if global.rpg_exp[v.name].class == "Miner" then
				minerbonus = minerbonus + global.rpg_exp[v.name].level
			end
		end
	end
	
	--That entire code block for calculating base bonus can be replaced by this:
	force.reset_technology_effects()
	
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
	
	--I do need that block after all to find the list of ammo types and gun types
	local ammotypes = {}
	local turrettypes = {}
	for k,v in pairs(force.technologies) do
		if v.researched then
			for n, p in pairs(v.effects) do
				if p.type=="ammo-damage" then
					table.insert(ammotypes, p.ammo_category)
				end
				if p.type=="turret-attack" then
					table.insert(turrettypes, p.turret_id)
				end
			end
		end
	end
		
	
	-- Malus for ammo is base * 0.8 - 0.2
	for k, v in pairs(ammotypes) do
		if string.find(v, "turret") then
			force.set_ammo_damage_modifier(v, builderbonus / 100 + force.get_ammo_damage_modifier(v) * 0.8 - 0.2)
		elseif string.find(v, "robot") then
			force.set_ammo_damage_modifier(v, scientistbonus / 100 + force.get_ammo_damage_modifier(v) * 0.8 - 0.2)
		elseif string.find(v, "grenade") then
			force.set_ammo_damage_modifier(v, minerbonus / 100 + force.get_ammo_damage_modifier(v) * 0.8 - 0.2)
		else --Bullets, shells, flamethrower
			force.set_ammo_damage_modifier(v, soldierbonus / 100 + force.get_ammo_damage_modifier(v) * 0.8 - 0.2)
		end
	end
	for k,v in pairs(turrettypes) do
		force.set_turret_attack_modifier(v, builderbonus / 100 + force.set_turret_attack_modifier(v) * 0.8 - 0.2)
	end
	
	force.character_health_bonus = scientistbonus / 40 --Base health is 250, so this is caled up similarly
	force.character_running_speed_modifier = scientistbonus / 400
	force.worker_robots_speed_modifier = scientistbonus / 100 + force.worker_robots_speed_modifier * 0.6 - 0.4
	
	--This one can't decrease, or players logging out would cause stuff to drop!
	force.character_inventory_slots_bonus = math.max(force.character_inventory_slots_bonus, math.floor(builderbonus / 40))
	
	-- Malus is 0.5 * base bonus - 0.5
	force.laboratory_speed_modifier = builderbonus / 100 + 0.5 * force.laboratory_speed_modifier - 0.5 --add base value
		
	force.mining_drill_productivity_bonus = minerbonus / 50 + force.mining_drill_productivity_bonus * 0.5
	
end

function rpg_init()
	global.rpg_exp = {}
	--Players can give bonuses to the team, so let's nerf the base values so players can re-buff them.
	game.forces.player.manual_crafting_speed_modifier = -0.3

	--Doh, can't have a negative bonus.  This does not work.
	--game.forces.player.character_health_bonus = -50

	--Scenario stuff.
	global.satellites_launched = 0
	--game.forces.Admins.chart(player.surface, {{-400, -400}, {400, 400}}) --This doesn't work.  Admins is not created at the time?
	
end

--Utility function.
function rpg_is_sanitary(name)
	local sanitary = true
	if string.find(name, "\\") or
		string.find(name, "{") or
		string.find(name, "}") or
		string.find(name, "'") or
		string.find(name, ",") or
		string.find(name, "\"")
	then
		sanitary = false
	end
	if sanitary == false then
		log("rpg save: Name was not sanitary!")
		return false
	end
	--Still here?  Good!
	return true
end

--Replaced with serpent.block(global.rpg_data)
-- commands.add_command("export", "Export exp table for processing", function()
	-- rpg_savedata()
-- end)

--Event.register(defines.events.on_player_created, rpg_add_gui) --We'll do this after a class is chosen.
Event.register(defines.events.on_player_created, rpg_class_picker)
Event.register(defines.events.on_gui_click, rpg_class_click)
Event.register(defines.events.on_player_created, rpg_loadsave)
--Event.register(defines.events.on_player_created, rpg_starting_resources)
Event.register(defines.events.on_player_joined_game, rpg_connect)
Event.register(defines.events.on_player_respawned, rpg_respawn)
Event.register(defines.events.on_rocket_launched, rpg_satellite_launched)
Event.register(defines.events.on_entity_died, rpg_nest_killed)
Event.register(defines.events.on_research_finished, rpg_tech_researched)
--Event.register(defines.events.on_research_finished, rpg_nerf_tech)
--Event.register(defines.events.on_tick, rpg_exp_tick) --For debug
Event.register(-1, rpg_init)