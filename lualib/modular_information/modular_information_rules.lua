-- modular_information_rules sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_information module, it shows players the rules

--
--	VARIABLES
--

global.modular_information_rules = global.modular_information_rules or {} 
global.modular_information_rules.list = global.modular_information_rules.list or { 
					nice = { nr = 1, short = "Don’t be a dick.", long = "fMMO is a co-op multiplayer environment, the idea is to work together. We try to provide an open sandbox environment, and (other than scenario rules) there aren’t many actual rules about behavior, but it’s important to us that every player has the opportunity to enjoy the game, so our first rule is simple: Don’t be a dick. The following rules are example cases of how not to be a dick, but are not an exhaustive list. The admins reserve the right to enforce any rules required to prevent disruption to other players"},
					harm = { nr = 2, short = "Don’t harm other players in any way.", long = "including but not limited to the use of text, voice, weapons, vehicles, audio or any other game-mechanic in such a way as to harm the factory, other players, or their ability to enjoy the game. (The only exception to this rule can be a PVP scenario)"},
					ups = { nr = 3, short = "Don’t deliberately slow the server down unnecessarily", long = "Don’t create contraptions that slow the server down unnecessarily and/or create noise, visually, auditory or otherwise. This includes, but is not limited to: making fast-flashing lights, ANY global sounds not approved in writing on discord by a moderator, or any unnecessarily complicated circuit networks or belt systems that can slow the server down."},
					trains = { nr = 4, short = "Don’t drive trains manually", long = "on tracks that are in use by automatic trains. If you want to take the train to somewhere where there’s currently no train stops, please use the automatic feature to drive the train to the closest station and create a separate player-station if needed.. Driving on tracks that are under construction and/or are not connected to the rail-network is fine, as long as you don’t break any other rules while doing so. See (rule 2)"},
					listen = { nr = 5, short = "Don’t disregard directions given by admins.", long = " In the event you disagree with admin decisions, asking for help in moderation requests is likely to lead to an intelligent discussion of the issue, swearing at the admin or calling them names is more likely to end with you receiving a global ban. The admins are volunteers, and give up their time freely to moderate the server: abuse towards them will not be tolerated. That said, we’re aware that the admins are as human as anyone else and can make mistakes, so please do feel that you can raise an issue if you see one. If you disagree with an admin, discuss the issue with them or on discord: Ignoring them is likely to lead to a kick or ban."},
					change = { nr = 6, short = "Don’t make changes for the sake of change.", long = "There’s many ways to do things in the game, and unless you know you’re improving something, don’t make changes. Respect your fellow player’s creations, even those that are new to the game: just because their method is sub-optimal, or different to your own, does not mean it should be removed if it works “well enough”"},
					structures = { nr = 7, short = "Don’t build offensive structures.", long = "This is not the correct server to make a political statement. While ‘offensive’ is very wide, we hope and assume that most players knows what is and isn’t ‘ok’ to build on a public server, and if in doubt, please ask. If you wouldn’t draw it and show your grandmother, we probably don’t want to see it."},
					hoover = { nr = 8, short = "Don’t ‘hoover’ belts.", long = "This is normally fine a few hours into a game, and we know this can be a tricky judgement call: when is a resource too low to scoop resources from the belt.. Early on, hoovering can completely halt a factories progress, yet later, it truly doesn’t matter. A good rule of thumb is to avoid picking resources off the belts for the first hour of a new game, and to avoid taking resources from belts that are less than half full. You will not be instantly banned for belt hoovering, but apply common sense, and obey admin warnings. Ignoring admin warnings for any rule is likely to lead to being kicked or banned."},
					mainbus = { nr = 9, short = "Don't build too close to the main bus.", long = "Most of the factories usually end up with a main bus of some kind (main bus is the area of the factory where belts run though and resources are being transported). Please take into account the initial bus markings that are usually laid out at the start of the game and leave ample space between the bus and your production setup - most likely than not the required bus size is going to be underestimated. To facilitate mid to late game expansion please leave 10 to 15 tiles between the bus and the production setups."},
					explore = { nr = 10, short = "Don’t explore excessively early-game.", long = "the first 30min of an event is when we are getting the most downloads of 'lower end' pc users and not all of them have access to a high-speed connection. To make sure that as many as possible can join our servers, a restraint on MASSIVE exploring is advised. This does not mean you can’t scout for enemy bases; it means please don’t travel aimlessly out in the distance for no reason as it makes it harder for users to connect."}
					}
--
--	FUNCTIONS
--
function modular_information_rules_show_rule(p, r)
	if global.modular_information_rules.list[r] ~= nil then
		local rule = global.modular_information_rules.list[r]
		if rule.short ~= nil then
			local miip = modular_information_get_information_pane(p)
			miip.clear()
			if rule.nr ~= nil then
				modular_information_set_information_pane_caption(p, "Rule number " .. rule.nr)
			else 
				modular_information_set_information_pane_caption(p, "Rules Pane")
			end
			local mirt = miip.add{type="table", name="modular_information_rules_table", column_count=1}
			mirt.style.vertical_spacing = 0
			mirt.style.top_padding = 0
			mirt.style.left_padding = 0
			mirt.style.right_padding = 0
			mirt.style.bottom_padding = 0
			local short  = mirt.add{type="label", name="modular_information_rules_short_label", caption = rule.short}
			short.style.single_line = false
			local long
			if rule.long ~= nil then
				long = mirt.add{type="label", name="modular_information_rules_long_label", caption = rule.long}
				long.style.single_line = false
			end
			short.style.font_color = {r=1,b=0,g=0}
			short.style.font = "default-large-semibold"
			short.style.maximal_width = 480
			long.style.maximal_width = 480
			mirt.add{type="button", name="modular_information_rules_back_button", caption = "Back"}
		end
	end
end

function modular_information_rules_create_gui(p)
	local miip = modular_information_get_information_pane(p)
	miip.clear()
	modular_information_set_information_pane_caption(p, "Rules Pane")
	local mirt = miip.add{type="table", name="modular_information_rules_table", column_count=1}
	mirt.style.vertical_spacing = 0
	mirt.style.top_padding = 0
	mirt.style.left_padding = 0
	mirt.style.right_padding = 0
	mirt.style.bottom_padding = 0
	local i = 1
	for k, r in pairs(global.modular_information_rules.list) do
		local b = mirt.add{type="button", caption= i .. ". " .. r.short, name = "modular_information_rules_button_" .. k}
		b.style.top_padding = 0
		b.style.left_padding = 5
		b.style.right_padding = 0
		b.style.bottom_padding = 0
		b.style.minimal_width = 470
		b.style.align = "left"
		i = i + 1
	end
end
	
function modular_information_rules_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then		
		if e.name == "modular_information_rules" then
			if modular_information_get_active_button(p) == "modular_information_rules" then
				modular_information_set_active_button(p, "none")
			else
				modular_information_set_active_button(p, "modular_information_rules")
				modular_information_rules_create_gui(p)
			end
		elseif e.name:find("modular_information_rules_button_") ~= nil then
			local r = e.name:sub(34)
			if global.modular_information_rules.list[r] ~= nil then
				modular_information_rules_show_rule(p, r)
			end
		elseif e.name == "modular_information_rules_back_button" then
			modular_information_rules_create_gui(p)
		end
	end
end
	
--
--	EVENTS
--

Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	modular_information_add_button(p.name, {name="modular_information_rules", order = 1, caption = "Rules"})
	modular_information_set_active_button(p, "modular_information_rules")
	modular_information_gui_show(p)
	modular_information_rules_create_gui(p)
end)

Event.register(Event.core_events.init, function(event)
	modular_information_enable_submodule("modular_information_rules")
end)


Event.register(defines.events.on_gui_click, modular_information_rules_gui_clicked)