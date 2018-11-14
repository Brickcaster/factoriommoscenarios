-- modular_admin_boost sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows admins to boost their character

--
--	PLAN
--	
--	This module is going to replace the character menu in the old admin tools
--	Admins will be able to increase their reach, speed, crafting, mining and be invincible
--	The gui will present a list of buttons to toggle each of the above
--

--
--	VARIABLES
--

global.modular_admin_boost = global.modular_admin_boost or {}
global.modular_admin_boost.enabled = true
global.modular_admin_boost.visible = global.modular_admin_boost.visible or {}
global.modular_admin_boost.bonus_state = global.modular_admin_boost.bonus_state or {}
global.modular_admin_boost.active_color = {r = 1, b = 0, g = 0}
global.modular_admin_boost.inactive_color = {r = 0, b = 0, g = 1}

--
--	FUNCTIONS
--

function modular_admin_boost_enable(mod)
	global.modular_admin_boost.enabled = true
	modular_admin_add_submodule("modular_admin_boost")
	for i, p in pairs(game.connected_players) do
		modular_admin_boost_update_menu_button(p)
	end
end

function modular_admin_boost_disable(mod)
	global.modular_admin_boost.enabled = false
	for i, p in pairs(game.connected_players) do
		modular_admin_boost_update_menu_button(p)
	end
	modular_admin_remove_submodule("modular_admin_boost")
end


function modular_admin_boost_update_menu_button(p)
	if p.admin then
		if global.modular_admin_boost.enabled then
			if global.modular_admin_boost.visible[p.name] then
				modular_admin_add_button(p.name, {name="modular_admin_boost_button", caption="Close character", order = 50, color = {r = 1, b = 0, g = 0}})
			else
				modular_admin_add_button(p.name, {name="modular_admin_boost_button", caption="Open character", order = 50, color = {r = 0, b = 0, g = 1}})
			end
		else 
			modular_admin_remove_button(p.name, "modular_admin_boost_button")
		end
		modular_admin_boost_gui_changed(p)
	end
end

function modular_admin_boost_gui_changed(p)
	if p.admin then
		local bf = modular_admin_get_flow(p)
		if global.modular_admin_boost.enabled then
			local mabpa
			if bf.modular_admin_boost_pane ~= nil then
				mabpa = bf.modular_admin_boost_pane
			else
				mabpa = bf.add {type = "frame", name = "modular_admin_boost_pane", caption = "Character Menu", direction = "vertical"}
			end
			local mabp
			if mabpa.modular_admin_boost_flow ~= nil then
				mabp = mabpa.modular_admin_boost_flow
				mabp.clear()
			else
				mabp = mabpa.add {type = "flow", name = "modular_admin_boost_flow", direction = "vertical",  style = "slot_table_spacing_vertical_flow"}
			end
			mabpa.style.visible = global.modular_admin_boost.visible[p.name]
			local pbs = global.modular_admin_boost.bonus_state[p.name]
			local bpb
			if pbs.pickup then
				bpb = mabp.add {type = "button", name = "modular_admin_boost_pickup_button", caption = "Reset Pickup"}
				bpb.style.font_color = global.modular_admin_boost.active_color
			else
				bpb = mabp.add {type = "button", name = "modular_admin_boost_pickup_button", caption = "Boost Pickup"}
				bpb.style.font_color = global.modular_admin_boost.inactive_color 
			end
			local bmb
			if pbs.mining then
				bmb = mabp.add {type = "button", name = "modular_admin_boost_mining_button", caption = "Reset Mining"}
				bmb.style.font_color = global.modular_admin_boost.active_color
			else
				bmb = mabp.add {type = "button", name = "modular_admin_boost_mining_button", caption = "Boost Mining"}
				bmb.style.font_color = global.modular_admin_boost.inactive_color 
			end
			local bcb
			if pbs.crafting then
				bcb = mabp.add {type = "button", name = "modular_admin_boost_crafting_button", caption = "Reset Crafting"}
				bcb.style.font_color = global.modular_admin_boost.active_color
			else
				bcb = mabp.add {type = "button", name = "modular_admin_boost_crafting_button", caption = "Boost Crafting"}
				bcb.style.font_color = global.modular_admin_boost.inactive_color 
			end
			local brb
			if pbs.reach then
				brb = mabp.add {type = "button", name = "modular_admin_boost_reach_button", caption = "Reset Reach"}
				brb.style.font_color = global.modular_admin_boost.active_color
			else
				brb = mabp.add {type = "button", name = "modular_admin_boost_reach_button", caption = "Boost Reach"}
				brb.style.font_color = global.modular_admin_boost.inactive_color 
			end
			local bib
			if pbs.invincible then
				bib = mabp.add {type = "button", name = "modular_admin_boost_invincible_button", caption = "Disable Invincible"}
				bib.style.font_color = global.modular_admin_boost.active_color
			else
				bib = mabp.add {type = "button", name = "modular_admin_boost_invincible_button", caption = "Enable Invincible"}
				bib.style.font_color = global.modular_admin_boost.inactive_color 
			end
			local bwl = mabp.add {type = "label", name = "modular_admin_boost_walking_label", caption = "Walking"}
			local bwt = mabp.add {type = "table", name = "modular_admin_boost_walking_table", column_count = 3}
			local bwdb = bwt.add {type = "button", name = "modular_admin_boost_walking_decrease_button", caption = "-"}
			local bwrb = bwt.add {type = "button", name = "modular_admin_boost_walking_reset_button", caption = pbs.walking}
			local bwib = bwt.add {type = "button", name = "modular_admin_boost_walking_increase_button", caption = "+"}
			if pbs.walking == 0 then
				bwrb.style.font_color = global.modular_admin_boost.inactive_color 
			else
				bwrb.style.font_color = global.modular_admin_boost.active_color
			end
			bpb.style.minimal_width = 175
			bmb.style.minimal_width = 175
			bcb.style.minimal_width = 175
			brb.style.minimal_width = 175
			bib.style.minimal_width = 175
			bwl.style.minimal_width = 175
			bwdb.style.minimal_width = 35
			bwrb.style.minimal_width = 95
			bwib.style.minimal_width = 35
		else
			if bf.modular_admin_boost_pane ~= nil then
				bf.modular_admin_boost_pane.destroy()
			end
		end
	end
end

function modular_admin_boost_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.parent then
			
		else	
			print("output$" .. e.name .. " has no parent! Is this a top-level GUI?")
		end
		if e.name == "modular_admin_boost_button" then
			global.modular_admin_boost.visible[p.name] = (not global.modular_admin_boost.visible[p.name])
			modular_admin_boost_update_menu_button(p)
		elseif e.parent ~= nil and (e.parent.name == "modular_admin_boost_pane" or e.parent.name == "modular_admin_boost_walking_table" or e.parent.name == "modular_admin_boost_flow") then
			if e.name == "modular_admin_boost_pickup_button" then
				if global.modular_admin_boost.bonus_state[p.name].pickup then
					global.modular_admin_boost.bonus_state[p.name].pickup = false
				else
					global.modular_admin_boost.bonus_state[p.name].pickup = true
				end
				if global.char_mod ~= nil then
					if global.modular_admin_boost.bonus_state[p.name].pickup then
						char_mod_add_bonus(p, "character_loot_pickup_distance_bonus", {name = "modular_admin_boost", op = "add", val = 5})
						char_mod_add_bonus(p, "character_item_pickup_distance_bonus", {name = "modular_admin_boost", op = "add", val = 5})
					else
						char_mod_remove_bonus(p, "character_item_pickup_distance_bonus", "modular_admin_boost")
						char_mod_remove_bonus(p, "character_loot_pickup_distance_bonus", "modular_admin_boost")
					end
				end
			elseif e.name == "modular_admin_boost_mining_button" then
				if global.modular_admin_boost.bonus_state[p.name].mining then
					global.modular_admin_boost.bonus_state[p.name].mining = false
				else
					global.modular_admin_boost.bonus_state[p.name].mining = true
				end
				if global.char_mod ~= nil then
					if global.modular_admin_boost.bonus_state[p.name].mining then
						char_mod_add_bonus(p, "character_mining_speed_modifier", {name = "modular_admin_boost", op = "add", val = 150})
					else
						char_mod_remove_bonus(p, "character_mining_speed_modifier", "modular_admin_boost")
					end
				end
			elseif e.name == "modular_admin_boost_crafting_button" then
				if global.modular_admin_boost.bonus_state[p.name].crafting then
					global.modular_admin_boost.bonus_state[p.name].crafting = false
				else
					global.modular_admin_boost.bonus_state[p.name].crafting = true
				end
				if global.char_mod ~= nil then
					if global.modular_admin_boost.bonus_state[p.name].crafting then
						char_mod_add_bonus(p, "character_crafting_speed_modifier", {name = "modular_admin_boost", op = "add", val = 60})
					else
						char_mod_remove_bonus(p, "character_crafting_speed_modifier", "modular_admin_boost")
					end
				end
			elseif e.name == "modular_admin_boost_reach_button" then
				if global.modular_admin_boost.bonus_state[p.name].reach then
					global.modular_admin_boost.bonus_state[p.name].reach = false
				else
					global.modular_admin_boost.bonus_state[p.name].reach = true
				end
				if global.char_mod ~= nil then
					if global.modular_admin_boost.bonus_state[p.name].reach then
						char_mod_add_bonus(p, "character_build_distance_bonus", {name = "modular_admin_boost", op = "add", val = 125})
						char_mod_add_bonus(p, "character_item_drop_distance_bonus", {name = "modular_admin_boost", op = "add", val = 125})
						char_mod_add_bonus(p, "character_reach_distance_bonus", {name = "modular_admin_boost", op = "add", val = 125})
						char_mod_add_bonus(p, "character_resource_reach_distance_bonus", {name = "modular_admin_boost", op = "add", val = 125})
					else
						char_mod_remove_bonus(p, "character_build_distance_bonus", "modular_admin_boost")
						char_mod_remove_bonus(p, "character_item_drop_distance_bonus", "modular_admin_boost")
						char_mod_remove_bonus(p, "character_reach_distance_bonus", "modular_admin_boost")
						char_mod_remove_bonus(p, "character_resource_reach_distance_bonus", "modular_admin_boost")
					end
				end
			elseif e.name == "modular_admin_boost_invincible_button" then
				if global.modular_admin_boost.bonus_state[p.name].invincible then
					global.modular_admin_boost.bonus_state[p.name].invincible = false
				else
					global.modular_admin_boost.bonus_state[p.name].invincible = true
				end
				if global.char_mod ~= nil then
					if p.character ~= nil then
						if global.modular_admin_boost.bonus_state[p.name].invincible then
							p.character.destructible = false
						else
							p.character.destructible = true
						end
					end
				end
			elseif e.name == "modular_admin_boost_walking_increase_button" then
				global.modular_admin_boost.bonus_state[p.name].walking = global.modular_admin_boost.bonus_state[p.name].walking + 0.5
				if global.char_mod ~= nil then
					char_mod_add_bonus(p, "character_running_speed_modifier", {name = "modular_admin_boost", op = "add", val = global.modular_admin_boost.bonus_state[p.name].walking})
				end
			elseif e.name == "modular_admin_boost_walking_reset_button" then
				global.modular_admin_boost.bonus_state[p.name].walking = 0
				if global.char_mod ~= nil then
					char_mod_add_bonus(p, "character_running_speed_modifier", {name = "modular_admin_boost", op = "add", val = global.modular_admin_boost.bonus_state[p.name].walking})
				end
			elseif e.name == "modular_admin_boost_walking_decrease_button" then
				global.modular_admin_boost.bonus_state[p.name].walking = global.modular_admin_boost.bonus_state[p.name].walking - 0.5
				if global.char_mod ~= nil then
					char_mod_add_bonus(p, "character_running_speed_modifier", {name = "modular_admin_boost", op = "add", val = global.modular_admin_boost.bonus_state[p.name].walking})
				end
			end
			modular_admin_boost_gui_changed(p)
		end
	end
end

--
--	EVENTS
--

Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	if p.admin then
		global.modular_admin_boost.bonus_state[p.name] = global.modular_admin_boost.bonus_state[p.name] or {pickup = false, mining = false, crafting = false, reach = false, invincible = false, walking = 0}
		if global.modular_admin_boost.enabled then
			if global.modular_admin_boost.visible[p.name] then
				modular_admin_add_button(p.name, {name="modular_admin_boost_button", caption="Close character", order = 50, color = {r = 1, b = 0, g = 0}})
			else
				modular_admin_add_button(p.name, {name="modular_admin_boost_button", caption="Open character", order = 50, color = {r = 0, b = 0, g = 1}})
			end
		else 
			modular_admin_remove_button(p.name, "modular_admin_boost_button")
		end
	end
end)

Event.register(Event.core_events.init, function(event)
	if(global.modular_admin_boost.enabled) then
		modular_admin_add_submodule("modular_admin_boost")
	else
		modular_admin_remove_submodule("modular_admin_boost")
	end
end)

Event.register(defines.events.on_gui_click, modular_admin_boost_gui_clicked)
