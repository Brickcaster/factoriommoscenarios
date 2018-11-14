-- modular_admin_players sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows admins to see player online time, and follow or teleport to them.

--
--	VARIABLES
--

global.modular_admin_players = global.modular_admin_players or {}
global.modular_admin_players.enabled = true
global.modular_admin_players.visable = global.modular_admin_players.visable or {}

--
--	FUNCTIONS
--
function modular_admin_players_enable()
	if not global.modular_admin_players.enabled then
		global.modular_admin_players.enabled = true
		for i, p in pairs(game.connected_players) do
			if p.admin then
				modular_admin_add_button(p.name, {name="modular_admin_players_button", caption="Open player manager", order = 90, color = {r = 0, b = 0, g = 1}})
				global.modular_admin_players.visable[p.name] = false
			end
		end
	else 
		return false
	end
end

function modular_admin_players_disable()
	if global.modular_admin_players.enabled then
		global.modular_admin_players.enabled = false
		for i, p in pairs(game.connected_players) do
			if p.admin then
				modular_admin_remove_button(p.name, "modular_admin_players_button")
			end
		end
	else 
		return false
	end
end

function modular_admin_players_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if p.admin then
			if e.parent.name == modular_admin_get_menu(p).name then
				if e.name == "modular_admin_players_button" then
					if global.modular_admin_players.enabled then
						if global.modular_admin_players.visable[p.name] then
							global.modular_admin_players.visable[p.name] = false
							modular_admin_change_button_caption(p.name, "modular_admin_players_button", "Open player manager")
							modular_admin_change_button_color(p.name, "modular_admin_players_button", {r=0, g=1, b=0})
						else
							global.modular_admin_players.visable[p.name] = true
							modular_admin_change_button_caption(p.name, "modular_admin_players_button", "Close player manager")
							modular_admin_change_button_color(p.name, "modular_admin_players_button", {r=1, g=0, b=0})
						end
						modular_admin_players_gui_changed(p)
					else 
						p.print("Sorry, this sub-module has just been disabled")
					end
				end
			end
			if e.name == "modular_admin_players_search_refresh" then
				modular_admin_players_update_player_list(p)
			end
			if not (e.valid) then return end
			for _, player in pairs(game.connected_players) do
                if e.name == "modular_admin_players_label_player_list_teleport_" .. player.name then
                    p.teleport(player.surface.find_non_colliding_position("player", player.position, 0, 1))
                elseif e.name == "modular_admin_players_label_player_list_follow_" .. player.name then
                    if modular_admin_submodule_state("modular_admin_spectate_follow") then
                        modular_admin_spectate_set_spectator(p)
                        modular_admin_spectate_set_follow_target(p, player)
                    end
                end
            end
		end
	end
end

function modular_admin_players_format_online_time(ticks)
	local seconds = math.floor(ticks / 60)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	local days = math.floor(hours / 24)
	return string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60)
end



function modular_admin_players_gui_changed(p)
	local bf = modular_admin_get_flow(p)
	if bf.modular_admin_players_pane ~= nil then
		bf.modular_admin_players_pane.destroy()
	end
	if global.modular_admin_players.enabled and global.modular_admin_players.visable[p.name] and p.admin then
		local mapp = bf.add {name = "modular_admin_players_pane", type = "frame", caption = "Player manager", direction = "vertical"}
		local mapts = mapp.add {name = "modular_admin_players_table_search", type = "table", column_count = 3}
		mapts.add {name = "modular_admin_players_search_label", type = "label", caption = "Name: "}
		mapts.add {name = "modular_admin_players_search", type = "textfield"}
		mapts.add {name = "modular_admin_players_search_refresh", type = "button", caption = "refresh list"}
		modular_admin_players_update_player_list(p)
	end
end

function modular_admin_players_update_player_list(p)
	if modular_admin_get_flow(p).modular_admin_players_pane ~= nil then
		local mapp = modular_admin_get_flow(p).modular_admin_players_pane
		if mapp.modular_admin_players_scrolllist ~= nil then
			mapp.modular_admin_players_scrolllist.destroy()
		end
		if mapp.modular_admin_players_table_header ~= nil then
			mapp.modular_admin_players_table_header.destroy()
		end
		local mapth = mapp.add {name = "modular_admin_players_table_header", type = "table", column_count = 4}
		mapth.add {name = "modular_admin_players_label_player_name", type = "label", caption = "Player name"}
		mapth.add {name = "modular_admin_players_label_online_time", type = "label", caption = "Online time"}
		mapth.add {name = "modular_admin_players_label_follow", type = "label", caption = "Follow"}
		mapth.add {name = "modular_admin_players_label_teleport", type = "label", caption = "Teleport"}
		local mapps = mapp.add {name = "modular_admin_players_scrolllist", type = "scroll-pane", vertical_scroll_policy = "auto", horizontal_scroll_policy = "never"}
		mapps.style.maximal_height = 300
		local mapt = mapps.add {name = "modular_admin_players_table", type = "table", column_count = 4}
		mapt.style.horizontal_spacing = 8
		for k, player in pairs(game.connected_players) do
			if player.index ~= p.index then
				if mapp.modular_admin_players_table_search.modular_admin_players_search.text ~= "" then
					if string.find(string.lower(player.name), string.lower(mapp.modular_admin_players_table_search.modular_admin_players_search.text)) ~= nil then
						local label = mapt.add{name = "modular_admin_players_label_player_list_name_" .. player.name, type = "label", caption = player.name}
						local online_time = mapt.add{name = "modular_admin_players_label_player_list_time_" .. player.name, type = "label", caption = modular_admin_players_format_online_time(player.online_time)}
						local follow = mapt.add{name = "modular_admin_players_label_player_list_follow_" .. player.name, type = "button", caption = "F"}
						follow.enabled = modular_admin_submodule_state("modular_admin_spectate_follow")
						local teleport = mapt.add{name = "modular_admin_players_label_player_list_teleport_" .. player.name, type = "button", caption = "T"}
					end
				else
					local label = mapt.add{name = "modular_admin_players_label_player_list_name_" .. player.name, type = "label", caption = player.name}
					local online_time = mapt.add{name = "modular_admin_players_label_player_list_time_" .. player.name, type = "label", caption = modular_admin_players_format_online_time(player.online_time)}
					local follow = mapt.add{name = "modular_admin_players_label_player_list_follow_" .. player.name, type = "button", caption = "F"}
					follow.enabled = modular_admin_submodule_state("modular_admin_spectate_follow")
					local teleport = mapt.add{name = "modular_admin_players_label_player_list_teleport_" .. player.name, type = "button", caption = "T"}
				end
			end
		end
		mapt.add {name = "modular_admin_players_label_player_name", type = "label", caption = "Player name"}
		mapt.add {name = "modular_admin_players_label_online_time", type = "label", caption = "Online time"}
		mapt.add {name = "modular_admin_players_label_follow", type = "label", caption = "Follow"}
		mapt.add {name = "modular_admin_players_label_teleport", type = "label", caption = "Teleport"}
	end
end

function modular_admin_players_search_changed(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "modular_admin_players_search" then
			modular_admin_players_update_player_list(p)
		end
	end
end

--
--	EVENTS
--
Event.register(Event.core_events.init, function(event)
		modular_admin_add_submodule("modular_admin_players")
	end)
	
Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	if p.admin then
		if global.modular_admin_players.enabled then
			if global.modular_admin_players.visable[p.name] then
				modular_admin_add_button(p.name, {name="modular_admin_players_button", caption="Close player manager", order = 90, color = {r = 1, b = 0, g = 0}})
			else
				modular_admin_add_button(p.name, {name="modular_admin_players_button", caption="Open player manager", order = 90, color = {r = 0, b = 0, g = 1}})
			end
		else 
			modular_admin_remove_button(p.name, "modular_admin_players_button")
		end
	end
end)

Event.register(defines.events.on_gui_text_changed, modular_admin_players_search_changed)
	
Event.register(defines.events.on_gui_click, modular_admin_players_gui_clicked)