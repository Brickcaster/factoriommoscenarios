-- modular_information_popup sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_information module, it shows players information about the scenario
--
--	VARIABLES
--

global.modular_information_popup = global.modular_information_popup or {} 
global.modular_information_popup.popups = global.modular_information_popup.popups or {{button = "Welcome", text = "Welcome to this new game, enjoy!"}}


--
--	FUNCTIONS
--
function modular_information_popup_create_gui(p, i)
	modular_information_popup_update_popup(p, i)
	modular_information_popup_update_menu(p)
end
	
function modular_information_popup_update_popup(p, i)
	local miip = modular_information_get_information_pane(p)
	modular_information_set_information_pane_caption_color(p, "IMPORTANT INFORMATION", {r=1,b=0,g=0})
	miip.clear()
	local mipp = global.modular_information_popup.popups[i]
	local miipl = miip.add {type="label", caption = mipp.text}
	miipl.style.maximal_width = 480
	miipl.style.single_line = false
	if(p.admin) then
		local mipnc = miip.add {type="button", name = "modular_information_popup_repop_" .. i, caption = "Repop"}
		mipnc.style.font_color = {r=0, g=0.5, b=0}
		mipnc.style.minimal_width = 140
		mipnc.style.maximal_width = 140
	end
end	

function modular_information_popup_add(b, t)
	local popup = {button = b, text = t}
	table.insert(global.modular_information_popup.popups, popup)
	for i, x in ipairs(game.connected_players) do
		modular_information_popup_show(x, #global.modular_information_popup.popups)
	end
end

function modular_information_popup_show(p, i)
	modular_information_set_active_button(p, "modular_information_popup")
	modular_information_gui_show(p)
	modular_information_popup_create_gui(p, i)
end


function modular_information_popup_update_menu(p)
	local mimc = modular_information_get_menu_canvas(p)
	mimc.style.visible = true
	mimc.caption = "Popup"
	--Create a button for each popup
	local mimcsp = mimc.add {type="scroll-pane", name="modular_information_popup_scroll_pane"}
	mimcsp.style.top_padding = 0
	mimcsp.style.left_padding = 0
	mimcsp.style.right_padding = 0
	mimcsp.style.bottom_padding = 0
	mimcsp.style.maximal_height = 255
	local mimcf = mimcsp.add {type="flow", direction="vertical", name="modular_information_popup_flow", style="slot_table_spacing_vertical_flow"}
	mimcf.style.top_padding = 0
	mimcf.style.left_padding = 0
	mimcf.style.right_padding = 0
	mimcf.style.bottom_padding = 0
	if p.admin then
		local mimcb = mimcf.add {type="button", name = "modular_information_popup_create", caption = "New"}
		mimcb.style.font_color = {r=0, g=0.5, b=0}
		mimcb.style.minimal_width = 140
		mimcb.style.maximal_width = 140
	end
	for i = #global.modular_information_popup.popups, 1, -1 do
		local p = global.modular_information_popup.popups[i]
		local mimcb = mimcf.add {type="button", name = "modular_information_popup_button_" .. i, caption = p.button}
		mimcb.style.minimal_width = 140
		mimcb.style.maximal_width = 140
	end
end

function modular_information_popup_show_creator(p) 
	if p.admin then
		local miip = modular_information_get_information_pane(p)
		modular_information_set_information_pane_caption_color(p, "Popup Creator", {r=0.8,b=0,g=0})
		miip.clear()
		local mipntl = miip.add {type="label", name = "modular_information_popup_new_title_label" ,caption = "Popup title"}
		local mipnt = miip.add {type="text-box", name = "modular_information_popup_new_title"}
		mipnt.style.minimal_width = 105
		mipnt.style.maximal_width = 105
		local mipnml = miip.add {type="label", name = "modular_information_popup_new_message_label" ,caption = "Popup message"}
		local mipnm = miip.add {type="text-box", name="modular_information_popup_new_message"}
		mipnm.style.minimal_width = 400
		mipnm.style.maximal_width = 400
		mipnm.style.minimal_height = 50
		local mipnc = miip.add {type="button", name = "modular_information_popup_new_create", caption = "Create"}
		mipnc.style.font_color = {r=0, g=0.5, b=0}
		mipnc.style.minimal_width = 140
		mipnc.style.maximal_width = 140

	end
end
	
function modular_information_popup_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then		
		if e.name == "modular_information_popup" then
			if modular_information_get_active_button(p) == "modular_information_popup" then
				modular_information_set_active_button(p, "none")
			else
				modular_information_set_active_button(p, "modular_information_popup")
				modular_information_popup_create_gui(p, #global.modular_information_popup.popups)
			end
		elseif e.name:find("modular_information_popup_button_") ~= nil then
			i = tonumber(e.name:sub(34))
			modular_information_popup_update_popup(p, i)
		elseif e.name:find("modular_information_popup_repop_") ~= nil and p.admin then
			i = tonumber(e.name:sub(33))
			for _, x in ipairs(game.connected_players) do
				modular_information_popup_show(x, i)
			end
		elseif e.name == "modular_information_popup_create" then
			modular_information_popup_show_creator(p)
		elseif e.name == "modular_information_popup_new_create" then
			local miip = modular_information_get_information_pane(p)
			modular_information_popup_add(miip.modular_information_popup_new_title.text, miip.modular_information_popup_new_message.text)
		end
	end
end
	
--
--	EVENTS
--

Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	modular_information_add_button(p.name, {name="modular_information_popup", order = 5, caption = "Popup"})
end)

Event.register(Event.core_events.init, function(event)
	modular_information_enable_submodule("modular_information_popup")
end)


Event.register(defines.events.on_gui_click, modular_information_popup_gui_clicked)