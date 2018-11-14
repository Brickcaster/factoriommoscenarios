-- modular_information Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This module allows the information tools to be easily expandable

--
--	At the bottom of this file there is a list of sub-modules you can enable.
--

--
--	PLAN
--	

--	This module will show the player a information screen on join. This screen will be modular. It will for example be able to have a submodule which can show players the rules.

--
--	VARIABLES
--

global.modular_information = global.modular_information or {}
global.modular_information.button_must_be_selected = true
global.modular_information.use_sprite_button_open = true
global.modular_information.use_sprite_button_close = false
global.modular_information.sprite_button_open_sprite = "utility/side_menu_tutorials_icon"
global.modular_information.sprite_button_close_sprite = "utility/side_menu_tutorials_icon"
global.modular_information.sprite_button_open_tooltip = "Open information menu"
global.modular_information.sprite_button_close_tooltip = "Close information menu"
global.modular_information.button_open_caption = "Open Information Screen"
global.modular_information.button_close_caption = "Close Information Screen"

global.modular_information.raw = global.modular_information.raw or {}
global.modular_information.sorted = global.modular_information.sorted or {}
global.modular_information.modules = global.modular_information.modules or {} 
global.modular_information.visible = global.modular_information.visible or {}
global.modular_information.active_button = global.modular_information.active_button or {}
global.modular_information.style = mod_gui.button_style

--
--	FUNCTIONS
--
function modular_information_add_button(player_name, button)
	global.modular_information.raw[player_name] = global.modular_information.raw[player_name] or {}
	if button.name ~= nil then
		local nb = {}
		if button.caption ~= nil then
			nb.caption = button.caption
		else
			nb.caption = "NO CAPTION"
		end
		if button.order ~= nil then
			nb.order = button.order
		else
			nb.order = 10
		end
		global.modular_information.raw[player_name][button.name] = nb
		modular_information_gui_changed(game.players[player_name])
	end
end

function modular_information_remove_button(player_name, button_name)
	global.modular_information.raw[player_name][button_name] = nil
	modular_information_get_menu(game.players[player_name])[button_name].destroy()
end

function modular_information_change_button_caption(player_name, button_name, caption)
	global.modular_information.raw[player_name][button_name].caption = caption
	modular_information_get_menu(game.players[player_name])[button_name].caption = caption
end

function modular_information_change_button_order(player_name, button_name, order)
	global.modular_information.raw[player_name][button_name].order = order
	modular_information_gui_changed(game.players[player_name])
end

function modular_information_gui_changed(p)
	local mimt = modular_information_get_menu(p)
	mimt.clear()
	modular_information_sort_table(p)
	local tot = 0
	for i, button in pairs(global.modular_information.sorted[p.name]) do
		local b = mimt.add {name=button.name, type="button", caption=button.caption}
		if global.modular_information.active_button[p.name] == button.name then
			b.style.font_color = {r=0, g=1, b=0}
		else
			b.style.font_color = {r=1, g=0, b=0}
		end
		b.style.minimal_width = 140
		tot = tot + 1
	end
	if tot == 0 then
		local b = mimt.add {type="label", name="modular_information_no_info", caption="No information available."}
		b.style.font_color = {r=1,g=0,b=0}
	end
	if global.modular_information.active_button[p.name] == "none" then
		local miip = modular_information_get_information_pane(p)
		miip.clear()
		local mini = miip.add {type="label", name="modular_information_no_info", caption="No information selected, use a button on the left to select."}
		mini.style.font_color = {r=1,g=0,b=0}
	end
	modular_information_set_information_pane_caption_color(p, "Information pane", {r=1,g=1,b=1})
	local mimc = modular_information_get_menu_canvas(p)
	mimc.caption = "NOT SET"
	mimc.clear()
	mimc.style.visible = false
	mimc.style.minimal_width = 160
	mimc.style.maximal_width = 185
	mimc.style.minimal_height = 255
	mimc.style.maximal_height = 255
end

function modular_information_get_menu(p)
	local bf = modular_information_get_flow(p)
	local mimt
	if (bf.modular_information_menu ~= nil) and  (bf.modular_information_menu.modular_information_menu_scroll ~= nil) and (bf.modular_information_menu.modular_information_menu_scroll.modular_information_menu_table ~= nil) then
		mimt = bf.modular_information_menu.modular_information_menu_scroll.modular_information_menu_table
	else
		local mim = bf.add {name = "modular_information_menu", type = "frame", direction = "vertical", caption = "Information Menu"}
		local mims = mim.add {name = "modular_information_menu_scroll", type = "scroll-pane"}
		mims.style.top_padding = 0
		mims.style.left_padding = 0
		mims.style.right_padding = 0
		mims.style.bottom_padding = 0
		mims.style.maximal_height = 175
		mims.style.minimal_height = 175
		mimt = mims.add {name = "modular_information_menu_table", type = "table", column_count = 1}
		mimt.style.vertical_spacing = 0
		mimt.style.top_padding = 0
		mimt.style.left_padding = 0
		mimt.style.right_padding = 0
		mimt.style.bottom_padding = 0
		local mict = mim.add {name = "modular_information_close_text", type = "label", caption = "Close Menu"}
		mict.style.font_color = {r=1,g=0,b=0}
	end
	return mimt
end

function modular_information_get_menu_canvas(p)
	local bf = modular_information_get_flow(p)
	local mim
	if (bf.modular_information_menu_canvas ~= nil) then
		mim = bf.modular_information_menu_canvas
	else
		mim = bf.add {name = "modular_information_menu_canvas", type = "frame", direction = "vertical", caption = "Submodule Menu"}
	end
	return mim
end

function modular_information_get_information_pane(p)
	local mif = modular_information_get_flow(p)
	local mips
	if (mif.modular_information_pane ~= nil) and (mif.modular_information_pane.modular_information_pane_scroll ~= nil) then
		mips = mif.modular_information_pane.modular_information_pane_scroll
	else 
		local mip = mif.add {name = "modular_information_pane", type = "frame", direction = "vertical", caption = "Information pane"}
		mips = mip.add {name = "modular_information_pane_scroll", type = "scroll-pane"}
		mips.style.maximal_height = 200
		mips.style.minimal_height = 200
		mips.style.minimal_width = 500
		mips.style.maximal_width = 500
	end
	return mips
end

function modular_information_gui_toggle_visibility(p)
	global.modular_information.visible[p.name] = global.modular_information.visible[p.name] or false
	if global.modular_information.visible[p.name] then
		modular_information_gui_hide(p)
	else
		modular_information_gui_show(p)
	end
end

function modular_information_gui_show(p)
	global.modular_information.visible[p.name] = true
	if global.modular_information.use_sprite_button_close then
		topgui_add_button(p.name, {type="sprite-button", name = "modular_information_toggle_button", sprite = global.modular_information.sprite_button_close_sprite, tooltip=global.modular_information.sprite_button_close_tooltip})
	else 
		topgui_add_button(p.name, {name = "modular_information_toggle_button", caption = global.modular_information.button_close_caption, color = {r=1, g=0, b=0}})
	end
	local mif = modular_information_get_flow(p)
	mif.style.visible = global.modular_information.visible[p.name]
end

function modular_information_gui_hide(p)
	global.modular_information.visible[p.name] = false
	if global.modular_information.use_sprite_button_open then
		topgui_add_button(p.name, {type="sprite-button", name = "modular_information_toggle_button", sprite = global.modular_information.sprite_button_open_sprite, tooltip=global.modular_information.sprite_button_open_tooltip})
	else 
		topgui_add_button(p.name, {name = "modular_information_toggle_button", caption = global.modular_information.button_open_caption, color = {r=0, g=1, b=0}})
	end
	local mif = modular_information_get_flow(p)
	mif.style.visible = global.modular_information.visible[p.name]
end

function modular_information_sort_table(p)
	global.modular_information.sorted[p.name] = {}
	for i, b in pairs(global.modular_information.raw[p.name]) do
		local newtable = {name = i, caption = b.caption, order = b.order, color = b.color}
		table.insert(global.modular_information.sorted[p.name], newtable)
	end
	table.sort(global.modular_information.sorted[p.name], function(t1, t2)
			return t1.order < t2.order
		end)
	
end

function modular_information_get_flow(p)
	local f = p.gui.center.modular_information_flow
	if f ~= nil then
		return f
	else 
		local pgc = p.gui.center
		local mif = pgc.add {type = "table", name = "modular_information_flow", column_count = 3}
		mif.style.horizontal_spacing = 0
		mif.style.top_padding = 0
		mif.style.left_padding = 0
		mif.style.right_padding = 0
		mif.style.bottom_padding = 0
		mif.style.visible = global.modular_information.visible[p.name]
		return mif
	end
end

function modular_information_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if e.name == "modular_information_toggle_button" or e.name == "modular_information_close_text" then
			modular_information_gui_toggle_visibility(p)
		end
	end
end

function modular_information_set_active_button(p, b)
	if not (global.modular_information.button_must_be_selected and b == "none") then
		global.modular_information.active_button[p.name] = b
		modular_information_gui_changed(p)
	end
end

function modular_information_set_information_pane_caption(p, c)
	if modular_information_get_flow(p).modular_information_pane ~= nil then
		modular_information_get_flow(p).modular_information_pane.caption = c
	end
end

function modular_information_set_information_pane_caption_color(p, t, c)
	if modular_information_get_flow(p).modular_information_pane ~= nil then
		modular_information_get_flow(p).modular_information_pane.caption = t
		modular_information_get_flow(p).modular_information_pane.style.font_color = c
	end
end

function modular_information_get_active_button(p)
	return global.modular_information.active_button[p.name]
end


function modular_information_enable_submodule(modulename)
	global.modular_information.modules[modulename] = true
end

function modular_information_disable_submodule(modulename)
	global.modular_information.modules[modulename] = false
end
	
function modular_information_submodule_state(mn)
	if global.modular_information.modules[mn] ~= nil then
		return global.modular_information.modules[mn]
	else
		return false
	end
end



--
--	EVENTS
--
Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	global.modular_information.raw[p.name] = global.modular_information.raw[p.name] or {}
	global.modular_information.visible[p.name] = global.modular_information.visible[p.name] or false
	global.modular_information.active_button[p.name] = global.modular_information.active_button[p.name] or "none"
	modular_information_gui_changed(p)
	if global.modular_information.visible[p.name] then
		if global.modular_information.use_sprite_button_close then
				topgui_add_button(p.name, {type="sprite-button", name = "modular_information_toggle_button", sprite = global.modular_information.sprite_button_close_sprite, tooltip=global.modular_information.sprite_button_close_tooltip})
			else 
				topgui_add_button(p.name, {name = "modular_information_toggle_button", caption = global.modular_information.button_close_caption, color = {r=1, g=0, b=0}})
			end
		else
			if global.modular_information.use_sprite_button_open then
				topgui_add_button(p.name, {type="sprite-button", name = "modular_information_toggle_button", sprite = global.modular_information.sprite_button_open_sprite, tooltip=global.modular_information.sprite_button_open_tooltip})
			else 
				topgui_add_button(p.name, {name = "modular_information_toggle_button", caption = global.modular_information.button_open_caption, color = {r=0, g=1, b=0}})
			end
		end
	modular_information_get_information_pane(p)
	p.opened = modular_information_get_flow(p)
end)

Event.register(defines.events.on_gui_click, modular_information_gui_clicked)

--
--	SUB-MODULES
--
require "modular_information_rules"
--require "modular_information_dummy"
--require "modular_information_team"  --NOT DONE
require "modular_information_scenario"
require "modular_information_popup"
--require "modular_information_about"--NOT DONE
--require "modular_information_stats"--NOT DONE