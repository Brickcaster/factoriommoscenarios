-- modular_admin_tag sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_admin module, it allows admins to set their tag to [Admin]

--
--	VARIABLES
--

global.modular_admin_tag = global.modular_admin_tag or {}
global.modular_admin_tag.tag = "[Admin]"
global.modular_admin_tag.enabled = true

--
--	FUNCTIONS
--
function modular_admin_tag_enable()
	modular_admin_add_submodule("modular_admin_tag")
	if not global.modular_admin_tag.enabled then
		global.modular_admin_tag.enabled = true
		for i, p in pairs(game.connected_players) do
			if p.admin then
				modular_admin_add_button(p.name, {name="modular_admin_tag_button", caption="Apply Admin Tag", order = 100})
			end
		end
	else 
		return false
	end
end

function modular_admin_tag_disable()
	modular_admin_remove_submodule("modular_admin_tag")
	if global.modular_admin_tag.enabled then
		global.modular_admin_tag.enabled = false
		for i, p in pairs(game.connected_players) do
			if p.admin then
				modular_admin_remove_button(p.name, "modular_admin_tag_button")
			end
		end
	else 
		return false
	end
end

function modular_admin_tag_player(p)
	if p.admin then
		if p.tag == global.modular_admin_tag.tag then
			p.tag = ""
			p.print("Removed Admin tag")
		else
			p.tag = global.modular_admin_tag.tag
			p.print("Admin tag applied")
		end
	end
end

function modular_admin_tag_set_tag(tag)
	global.modular_admin_tag.tag = tag
end

function modular_admin_tag_get_tag()
	if global.modular_admin_tag.enabled then
		return global.modular_admin_tag.tag
	else
		return false
	end
end

function modular_admin_tag_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then
		if p.admin then
			if e.parent.name == modular_admin_get_menu(p).name then
				if e.name == "modular_admin_tag_button" then
					if global.modular_admin_tag.enabled then
						modular_admin_tag_player(p)
					else
						modular_admin_remove_button(p.name, "modular_admin_tag_button")
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
		modular_admin_add_submodule("modular_admin_tag")
	end)
	
Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	if p.admin then
		if global.modular_admin_tag.enabled then
			modular_admin_add_button(p.name, {name="modular_admin_tag_button", caption="Admin Tag", order = 100})
		else 
			modular_admin_remove_button(p.name, "modular_admin_tag_button")
		end
	end
end)
	
Event.register(defines.events.on_gui_click, modular_admin_tag_gui_clicked)