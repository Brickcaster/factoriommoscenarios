-- modular_information_dummy sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_information module, it shows players information about the scenario
--
--	VARIABLES
--

global.modular_information_dummy = global.modular_information_dummy or {} 

--
--	FUNCTIONS
--
function modular_information_dummy_create_gui(p)
	local miip = modular_information_get_information_pane(p)
	miip.clear()
	miip.add {type="label", caption = "This is here to test only!"}
	local mimc = modular_information_get_menu_canvas(p)
	mimc.style.visible = true
	mimc.add {type="label", caption = "Hello World!"}
	mimc.caption = "Dummy Module"
	local mimctb = mimc.add {type="text-box", name = "modular_information_dummy_text-box"}
	mimctb.style.minimal_width = 105
	mimctb.style.maximal_width = 105
	local mimcb = mimc.add {type="button", name = "modular_information_dummy_button", caption = "1234567890123"}
	mimcb.style.minimal_width = 140
	mimcb.style.maximal_width = 140
end
	
function modular_information_dummy_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then		
		if e.name == "modular_information_dummy" then
			if modular_information_get_active_button(p) == "modular_information_dummy" then
				modular_information_set_active_button(p, "none")
			else
				modular_information_set_active_button(p, "modular_information_dummy")
				modular_information_dummy_create_gui(p)
			end
		elseif e.name == "modular_information_dummy_button" then
			local mimc = modular_information_get_menu_canvas(p)
			mimc.modular_information_dummy_button.caption = mimc["modular_information_dummy_text-box"].text
		end
	end
end
	
--
--	EVENTS
--

Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	modular_information_add_button(p.name, {name="modular_information_dummy", order = 1, caption = "Test"})
end)

Event.register(Event.core_events.init, function(event)
	modular_information_enable_submodule("modular_information_dummy")
end)


Event.register(defines.events.on_gui_click, modular_information_dummy_gui_clicked)