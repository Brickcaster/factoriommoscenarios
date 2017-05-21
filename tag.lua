--[[
-- Gives players the option to set their preferred role as a tag
-- A 3Ra Gaming creation
Contributors: 
	I_IBlackI_I
	Mylon
	R3fr3Sh
]]

function tag_create_gui(event)
	local player = game.players[event.player_index]
	if not player.gui.top.tag_button then
		player.gui.top.add { name = "tag-button", type = "button", caption = "Tags" }
	end
end

-- Tag list
global.tag = global.tag or {}
global.tag.tags = {
	{ display_name = "Mining" },
	{ display_name = "Smelting" },
	{ display_name = "Oil" },
	{ display_name = "Pest Control" },
	{ display_name = "Automation" },
	{ display_name = "Quality Control" },
	{ display_name = "Power" },
	{ display_name = "Trains" },
	{ display_name = "Science" },
	{ display_name = "AFK" },
	{ display_name = "Clear" },
}

function tag_expand_gui(player)
	local frame = player.gui.left["tag-panel"]
	if (frame) then
		frame.destroy()
	else
		local frame = player.gui.left.add { type = "frame", name = "tag-panel", caption = "Choose Tag"}
		local scroll = frame.add { type = "scroll-pane", name = "tag-panel-scroll"}
		scroll.style.maximal_height = 250
		local list = scroll.add { name="tag_table", type = "table", colspan = 1}
		for _, role in pairs(global.tag.tags) do
			list.add { type = "button", caption = role.display_name, name = "tag_" .. role.display_name }
		end
		if player.name == "SortaN3W" then
			list.add { type = "button", caption = "Mylon's Favorite Slave", name = "tag_" .. "Mylon's Favorite Slave" }
		end
	end
end

function tag_on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if (name == "tag-button") then
		tag_expand_gui(player)
	end
	if string.find(name, "tag_") then
		local tag = ""
		if (name ~= "tag_Clear") then --if player doesn't clean his tag we get caption of the button as the tag
			tag = event.element.caption
		end
		global.rpg_exp[player.name].tag = tag
		tag_expand_gui(player) 
		tag_refresh(player)  --refreshes tag of a player
	end
end

-- Handles the logic of tag changing
-- Triggered after:
-- changing class
-- changing tag
-- leveling up
function tag_refresh(player)
	local class = global.rpg_exp[player.name].class --gets player class
	if ()not class) or (class == "None")) then  --if he has no class then he is a spectator
		class = "Spectator"
	end
	local new_tag = class.." - "..(global.rpg_exp[player.name].class.level or 1)  --concatenates player class and level (current level or 1) with "-" between
	old_tag = global.rpg_exp[player.name].tag --We are getting the task of a player
	if ((old_tag) and (old_tag ~= "")) then --if he has any tasks selected then we concatenate them with new_tag using "-"
		new_tag = new_tag.." - "..old_tag
	end
	player.tag = "["..new_tag.."]" --we encapsulate our tag within square bracets
end

Event.register(defines.events.on_gui_click, tag_on_gui_click)
--Event.register(defines.events.on_player_joined_game, tag_create_gui) --This is called manually.
