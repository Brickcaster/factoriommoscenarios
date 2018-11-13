-- modular_admin_alert sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows modules to display alerts in this gui, 
-- and optionally set a location so that the admin can teleport to the alert

--
--	PLAN
--	
--	This module is going to have a function to add alerts to it.
--	It will also have a button in the modular_admin menu to open a GUI
--	The gui will present a list of the last x alerts with options, for example teleport to the position of the alert
--

--
--	VARIABLES
--

global.modular_admin_alert = global.modular_admin_alert or {}
global.modular_admin_alert.enabled = true

--
--	FUNCTIONS
--
function modular_admin_alert_enable(mod)
	global.modular_admin_alert.enabled = true
	modular_admin_add_submodule("modular_admin_alert")
	for i, p in pairs(game.connected_players) do
		modular_admin_alert_update_menu_button(p)
	end
end

function modular_admin_alert_disable(mod)
	global.modular_admin_alert.enabled = false
	for i, p in pairs(game.connected_players) do
		modular_admin_alert_update_menu_button(p)
	end
	modular_admin_remove_submodule("modular_admin_alert")
end

--
--	EVENTS
--

Event.register(Event.core_events.init, function(event)
	if(global.modular_admin_alert.enabled) then
		modular_admin_add_submodule("modular_admin_alert")
	else
		modular_admin_remove_submodule("modular_admin_alert")
	end
end)