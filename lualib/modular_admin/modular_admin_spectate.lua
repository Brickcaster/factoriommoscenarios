-- modular_admin_spectate sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows sub-modules set the player to spectator mode or follow players

--
--	VARIABLES
--

global.modular_admin_spectate = global.modular_admin_spectate or {}
global.modular_admin_spectate.enabled = true
global.modular_admin_spectate.follow_enabled = true
global.modular_admin_spectate.spectate_enabled = true
global.modular_admin_spectate.visible = global.modular_admin_spectate.visible or {}
global.modular_admin_spectate.follow_target = global.modular_admin_spectate.follow_target or {}
global.modular_admin_spectate.player_spectator_state = global.modular_admin_spectate.player_spectator_state or {}
global.modular_admin_spectate.player_spectator_force = global.modular_admin_spectate.player_spectator_force or {}
global.modular_admin_spectate.player_spectator_character = global.modular_admin_spectate.player_spectator_character or {}
global.modular_admin_spectate.player_spectator_logistics_slots = global.modular_admin_spectate.player_spectator_logistics_slots or {}

--
--	FUNCTIONS
--

function modular_admin_spectate_enable(mod)
	if mod == "module" then
		global.modular_admin_spectate.enabled = true
		modular_admin_add_submodule("modular_admin_spectate")
		if global.modular_admin_spectate.follow_enabled == true then
			modular_admin_add_submodule("modular_admin_spectate_follow")
		end
		if global.modular_admin_spectate.spectate_enabled == true then
			modular_admin_add_submodule("modular_admin_spectate_spectate")
		end
		for i, p in pairs(game.connected_players) do
			modular_admin_spectate_update_menu_button(p)
		end
	elseif mod == "follow" then
		global.modular_admin_spectate.follow_enabled = true
		modular_admin_add_submodule("modular_admin_spectate_follow")
	elseif mod == "spectate" then
		global.modular_admin_spectate.spectate_enabled = true
		modular_admin_add_submodule("modular_admin_spectate_spectate")
	end
end

function modular_admin_spectate_disable(mod)
	if mod == "module" then
		for index, trgt in pairs(global.modular_admin_spectate.follow_target) do
			modular_admin_spectate_stop_follow(game.players[index])
		end
		for index, bool in pairs(global.modular_admin_spectate.player_spectator_state) do
			if bool then
				modular_admin_spectate_set_normal(game.players[index])
			end
		end
		global.modular_admin_spectate.enabled = false
		for i, p in pairs(game.connected_players) do
			modular_admin_spectate_update_menu_button(p)
		end
		modular_admin_remove_submodule("modular_admin_spectate")
		modular_admin_remove_submodule("modular_admin_spectate_follow")
		modular_admin_remove_submodule("modular_admin_spectate_spectate")
	elseif mod == "follow" then
		for index, trgt in pairs(global.modular_admin_spectate.follow_target) do
			modular_admin_spectate_stop_follow(game.players[index])
		end
		modular_admin_remove_submodule("modular_admin_spectate_follow")
		global.modular_admin_spectate.follow_enabled = false
	elseif mod == "spectate" then
		for index, bool in pairs(global.modular_admin_spectate.player_spectator_state) do
			if bool then
				modular_admin_spectate_set_normal(game.players[index])
			end
		end
		modular_admin_remove_submodule("modular_admin_spectate_spectate")
		global.modular_admin_spectate.spectate_enabled = false
	end
end


function modular_admin_spectate_set_follow_target(p, target)
	if global.modular_admin_spectate.follow_enabled and global.modular_admin_spectate.enabled then
		if p.connected and target.connected and p.admin then
			if global.modular_admin_spectate.follow_target[p.index] == target.index then
				modular_admin_spectate_stop_follow(p)
			else
				global.modular_admin_spectate.follow_target[p.index] = target.index
				p.print("You are now following " .. target.name)
				modular_admin_spectate_gui_changed(p)
			end
		end
	else
		p.print("Following is disabled")
	end
end

function modular_admin_spectate_stop_follow(p)
	global.modular_admin_spectate.follow_target[p.index] = nil
	modular_admin_spectate_gui_changed(p)
	p.print("You are no longer following")
end


function modular_admin_spectate_update_position(event)
	if global.modular_admin_spectate.follow_enabled and global.modular_admin_spectate.enabled then
		for player_index, follow_target_index in pairs(global.modular_admin_spectate.follow_target) do
			if follow_target_index then
				player = game.players[player_index]
				follow_target = game.players[follow_target_index]
				if player and follow_target then
					player.teleport(follow_target.position, follow_target.surface)
				end
			end
		end
	end
end

function modular_admin_spectate_set_normal(p)
	local index = p.index
	if global.modular_admin_spectate.player_spectator_state[index] == true then
		p.cheat_mode = false
		if p.character == nil then
			-- local pos = p.position
			if global.modular_admin_spectate.player_spectator_character[index] and global.modular_admin_spectate.player_spectator_character[index].valid then
				if not teleport then p.print("Returning you to your character.") end
				p.set_controller { type = defines.controllers.character, character = global.modular_admin_spectate.player_spectator_character[index] }
				p.character.destructible = true
				if global.modular_admin_boost ~= nil then
					global.modular_admin_boost.bonus_state[p.name].invincible = false
					modular_admin_boost_update_menu_button(p)
				end
			else
				p.print("Character missing, will create new character at spawn.")
				p.set_controller { type = defines.controllers.character, character = p.surface.create_entity { name = "player", position = { 0, 0 }, force = global.modular_admin_spectate.player_spectator_force[index] } }
				p.insert { name = "pistol", count = 1 }
				p.insert { name = "firearm-magazine", count = 10 }
			end
			--restore character logistics slots due to bug in base game that clears them after returning from spectator mode
			for slot=1, p.character.request_slot_count do
				if global.modular_admin_spectate.player_spectator_logistics_slots[index][slot] then
					p.character.set_request_slot(global.modular_admin_spectate.player_spectator_logistics_slots[index][slot], slot)
				end
			end
		end
		if global.char_mod ~= nil then
			char_mod_apply_all_bonus(p)
		end
		p.force = game.forces[global.modular_admin_spectate.player_spectator_force[index].name]
		global.modular_admin_spectate.player_spectator_state[index] = false
		modular_admin_spectate_gui_changed(p)
	end
end

function modular_admin_spectate_set_normal_teleport(p)
	local pos = p.position
	modular_admin_spectate_set_normal(p)
	if global.modular_admin_spectate.player_spectator_state[p.index] == false then
		p.print("Teleporting you to the location you are currently looking at.")
		p.teleport(pos)
	end
end

function modular_admin_spectate_set_spectator(p)
	local index = p.index
	if global.modular_admin_spectate.spectate_enabled and global.modular_admin_spectate.enabled then
		if global.modular_admin_spectate.player_spectator_state[index] ~= true then
			if p.character then
				p.character.destructible = false
				p.walking_state = { walking = false, direction = defines.direction.north }
				global.modular_admin_spectate.player_spectator_character[index] = p.character
				--store character logistics slots due to an apparent bug in the base game that discards them when returning from spectate
				global.modular_admin_spectate.player_spectator_logistics_slots[index] = {}
				for slot=1, p.character.request_slot_count do
					global.modular_admin_spectate.player_spectator_logistics_slots[index][slot] = p.character.get_request_slot(slot)
				end
				p.set_controller { type = defines.controllers.god }
				
			end
			global.modular_admin_spectate.player_spectator_force[index] = p.force
			p.cheat_mode = true
			if game.forces.Admins ~= nil then
				p.force = game.forces["Admins"]
			end
			global.modular_admin_spectate.player_spectator_state[index] = true
			p.print("You are now a spectator")
			modular_admin_spectate_gui_changed(p)
		end
	else
		game.print("Spectating is disabled")
	end
end

function modular_admin_spectate_get_state(p)
	local index = p.index
	if global.modular_admin_spectate.player_spectator_state[index] == true and global.modular_admin_spectate.spectate_enabled and global.modular_admin_spectate.enabled then
		return true
	else
		return false
	end
end

function modular_admin_spectate_connected_players_changed(event)
	if global.modular_admin_spectate.follow_enabled and global.modular_admin_spectate.enabled then
		for player_index, follow_target_index in pairs(global.modular_admin_spectate.follow_target) do
			if player_index == event.player_index or follow_target_index == event.player_index then
				modular_admin_spectate_stop_follow(game.players[player_index])
				if follow_target_index == event.player_index then
					game.players[player_index].print("Follow target disconnected.")
				end
			end
		end
	end
end

function modular_admin_spectate_update_menu_button(p)
	if p.admin then
		if global.modular_admin_spectate.enabled then
			if global.modular_admin_spectate.visible[p.name] then
				modular_admin_add_button(p.name, {name="modular_admin_spectate_button", caption="Close spectate menu", order = 110, color = {r = 1, b = 0, g = 0}})
			else
				modular_admin_add_button(p.name, {name="modular_admin_spectate_button", caption="Open spectate menu", order = 110, color = {r = 0, b = 0, g = 1}})
			end
		else 
			modular_admin_remove_button(p.name, "modular_admin_spectate_button")
		end
		modular_admin_spectate_gui_changed(p)
	end
end

function modular_admin_spectate_gui_changed(p)
	if p.admin then
		local bf = modular_admin_get_flow(p)
		if global.modular_admin_spectate.enabled then
			local st
			if bf.modular_admin_spectate_pane ~= nil then
				st = bf.modular_admin_spectate_pane
				st.clear()
			else
				st = bf.add {type = "frame", name = "modular_admin_spectate_pane", caption = "Specate Menu", direction = "vertical"}
			end
			st.style.visible = global.modular_admin_spectate.visible[p.name]
			local sm = st
			if global.modular_admin_spectate.player_spectator_state[p.index] == true then
				local srb = sm.add {type = "button", name = "modular_admin_spectate_return_button", caption = "Return"}
				local stb = sm.add {type = "button", name = "modular_admin_spectate_teleport_button", caption = "Teleport"}
				srb.style.minimal_width = 150
				stb.style.minimal_width = 150
				if global.modular_admin_spectate.follow_target[p.index] ~= nil then
					srb.enabled = false
					stb.enabled = false
				else
					srb.style.font_color = {r = 1, b = 0, g = 0}
					stb.style.font_color = {r = 1, b = 0, g = 0}
				end
			else
				local ssb = sm.add {type = "button", name = "modular_admin_spectate_spectate_button", caption = "Start spectating"}
				ssb.style.font_color = {r = 0, b = 0, g = 1}
				ssb.style.minimal_width = 150
			end
			if global.modular_admin_spectate.follow_target[p.index] ~= nil then
				local labeltext = "You are spectating: " .. game.players[global.modular_admin_spectate.follow_target[p.index]].name
				local sfl = sm.add {type = "label", name = "modular_admin_spectate_follow_label", caption = labeltext}
				sfl.style.maximal_width = 150
				sfl.style.single_line = false
				local ssfb = sm.add {type = "button", name = "modular_admin_spectate_stop_follow_button", caption = "Stop following"}
				ssfb.style.font_color = {r = 1, b = 0, g = 0}
				ssfb.style.minimal_width = 150
			end
		else
			if bf.modular_admin_spectate_pane ~= nil then
				bf.modular_admin_spectate_pane.destroy()
			end
		end
	end
end
	
function modular_admin_spectate_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "modular_admin_spectate_button" then
			global.modular_admin_spectate.visible[p.name] = (not global.modular_admin_spectate.visible[p.name])
			modular_admin_spectate_update_menu_button(p)
		elseif e.name == "modular_admin_spectate_stop_follow_button" then
			modular_admin_spectate_stop_follow(p)
		elseif e.name == "modular_admin_spectate_spectate_button" then
			modular_admin_spectate_set_spectator(p)
		elseif e.name == "modular_admin_spectate_teleport_button" then
			modular_admin_spectate_set_normal_teleport(p)
		elseif e.name == "modular_admin_spectate_return_button" then
			modular_admin_spectate_set_normal(p)
		end
	end
end
--
--	EVENTS
--

Event.register(defines.events.on_tick, modular_admin_spectate_update_position)
Event.register(defines.events.on_player_left_game, modular_admin_spectate_connected_players_changed)
Event.register(defines.events.on_player_joined_game, modular_admin_spectate_connected_players_changed)
Event.register(defines.events.on_gui_click, modular_admin_spectate_gui_clicked)

Event.register(Event.core_events.init, function(event)
		if(global.modular_admin_spectate.enabled) then
			modular_admin_add_submodule("modular_admin_spectate")
			if global.modular_admin_spectate.follow_enabled then
				modular_admin_add_submodule("modular_admin_spectate_follow")			
			end
			if global.modular_admin_spectate.spectate_enabled then
				modular_admin_add_submodule("modular_admin_spectate_spectate")
			end
		else
			modular_admin_remove_submodule("modular_admin_spectate")
			modular_admin_remove_submodule("modular_admin_spectate_follow")
			modular_admin_remove_submodule("modular_admin_spectate_spectate")
		end
	end)
	
Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	global.modular_admin_spectate.visible[p.name] = global.modular_admin_spectate.visible[p.name] or false
	modular_admin_spectate_update_menu_button(p)
end)
