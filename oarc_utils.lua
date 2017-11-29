-- oarc_utils.lua
-- Nov 2016
-- 
-- My general purpose utility functions for factorio
-- Also contains some constants and gui styles


--------------------------------------------------------------------------------
-- Useful constants
--------------------------------------------------------------------------------
CHUNK_SIZE = 32
MAX_FORCES = 64
TICKS_PER_SECOND = 60
TICKS_PER_MINUTE = TICKS_PER_SECOND * 60
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- GUI Label Styles
--------------------------------------------------------------------------------
my_fixed_width_style = {
    minimal_width = 500,
    maximal_width = 500
}
my_label_style = {
    minimal_width = 500,
    maximal_width = 500,
    maximal_height = 10,
    font_color = {r=1,g=1,b=1},
    top_padding = 0,
    bottom_padding = 0
}
my_note_style = {
    minimal_width = 500,
    maximal_height = 10,
    font = "default-small-semibold",
    font_color = {r=1,g=0.5,b=0.5},
    top_padding = 0,
    bottom_padding = 0
}
my_warning_style = {
    minimal_width = 500,
    maximal_width = 500,
    maximal_height = 10,
    font_color = {r=1,g=0.1,b=0.1},
    top_padding = 0,
    bottom_padding = 0
}
my_spacer_style = {
    minimal_width = 500,
    maximal_width = 500,
    minimal_height = 20,
    maximal_height = 20,
    font_color = {r=0,g=0,b=0},
    top_padding = 0,
    bottom_padding = 0
}
my_small_button_style = {
    font = "default-small-semibold"
}
my_player_list_fixed_width_style = {
    minimal_width = 200,
    maximal_width = 200,
    maximal_height = 200
}
my_player_list_admin_style = {
    font = "default-semibold",
    font_color = {r=1,g=0.5,b=0.5},
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    maximal_height = 15
}
my_player_list_style = {
    font = "default-semibold",
    minimal_width = 200,
    top_padding = 0,
    bottom_padding = 0,
    maximal_height = 15
}
my_player_list_style_spacer = {
    maximal_height = 15
}
my_color_red = {r=1,g=0.1,b=0.1}


--------------------------------------------------------------------------------
-- General Helper Functions
--------------------------------------------------------------------------------

-- Print debug only to me while testing.
-- Should remove this if you are hosting it yourself.
function DebugPrint(msg)
    if ((game.players["Oarc"] ~= nil) and (global.oarcDebugEnabled)) then
        game.players["Oarc"].print("DEBUG: " .. msg)
    end
end

-- Prints flying text.
-- Color is optional
function FlyingText(msg, pos, color) 
    local surface = game.surfaces[GAME_SURFACE_NAME]
    if color == nil then
        surface.create_entity({ name = "flying-text", position = pos, text = msg })
    else
        surface.create_entity({ name = "flying-text", position = pos, text = msg, color = color })
    end
end

-- Broadcast messages
function SendBroadcastMsg(msg)
    for name,player in pairs(game.connected_players) do
        player.print(msg)
    end
end

function formattime(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%dm:%02ds", minutes, seconds)
end

-- Simple function to get total number of items in table
function TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Chart area for a force
function ChartArea(force, position, chunkDist)
    force.chart(game.surfaces[GAME_SURFACE_NAME],
        {{position.x-(CHUNK_SIZE*chunkDist),
        position.y-(CHUNK_SIZE*chunkDist)},
        {position.x+(CHUNK_SIZE*chunkDist),
        position.y+(CHUNK_SIZE*chunkDist)}})
end

-- Give player these default items on restart.
function GivePlayerItems(player)
end

-- Additional starter only items
function GivePlayerStarterItems(player)
    for _,item in pairs(scenario.config.startKit) do
        player.insert(item);
        if item.equipment ~= nil then
            local p_armor = player.get_inventory(5)[1].grid --defines.inventory.player_armor = 5?
            if p_armor ~= nil then
                for _,equip in pairs(item.equipment) do
                    local count = equip.count
                    if count == nil then
                        count = 1
                    end
                    for i = 1,count do
                        p_armor.put(equip);
                    end
                end
            end
        end
    end
end

-- Create area given point and radius-distance
function GetAreaFromPointAndDistance(point, dist)
    local area = {left_top=
                    {x=point.x-dist,
                     y=point.y-dist},
                  right_bottom=
                    {x=point.x+dist,
                     y=point.y+dist}}
    return area
end

-- Check if given position is in area bounding box
function CheckIfInArea(point, area)
    if ((point.x >= area.left_top.x) and (point.x < area.right_bottom.x)) then
        if ((point.y >= area.left_top.y) and (point.y < area.right_bottom.y)) then
            return true
        end
    end
    return false
end

-- Returns true if two areas intersect
function CheckIfChunkIntersects(chunkArea, area)
    if (area.left_top.x >= chunkArea.right_bottom.x) then
        return false
    end
    if (area.left_top.y >= chunkArea.right_bottom.y) then
        return false
    end
    if (chunkArea.left_top.x >= area.right_bottom.x) then
        return false
    end
    if (chunkArea.left_top.y >= area.right_bottom.y) then
        return false
    end
    return true
end

-- Ceasefire
-- All forces are always neutral
function SetCeaseFireBetweenAllForces()
    for name,team in pairs(game.forces) do
        if name ~= "neutral" and name ~= "enemy" then
            for x,y in pairs(game.forces) do
                if x ~= "neutral" and x ~= "enemy" then
                    team.set_cease_fire(x,true)
                end
            end
        end
    end
end

-- Undecorator
function RemoveDecorationsArea(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="decorative"}) do
        entity.destroy()
    end
end

-- Remove fish
function RemoveFish(surface, area)
    for _, entity in pairs(surface.find_entities_filtered{area = area, type="fish"}) do
        entity.destroy()
    end
end

-- Apply a style option to a GUI
function ApplyStyle (guiIn, styleIn)
    for k,v in pairs(styleIn) do
        guiIn.style[k]=v
    end 
end

-- Get a random 1 or -1
function RandomNegPos()
    if (math.random(0,1) == 1) then
        return 1
    else
        return -1
    end
end

-- Create a random direction vector to look in
function GetRandomVector()
    local randVec = {x=0,y=0}   
    while ((randVec.x == 0) and (randVec.y == 0)) do
        randVec.x = math.random(-3,3)
        randVec.y = math.random(-3,3)
    end
    DebugPrint("direction: x=" .. randVec.x .. ", y=" .. randVec.y)
    return randVec
end

-- Check for ungenerated chunks around a specific chunk
-- +/- chunkDist in x and y directions
function IsChunkAreaUngenerated(chunkPos, chunkDist)
    for x=-chunkDist, chunkDist do
        for y=-chunkDist, chunkDist do
            local checkPos = {x=chunkPos.x+x,
                             y=chunkPos.y+y}
            if (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated(checkPos)) then
                return false
            end
        end
    end
    return true
end

-- Clear out enemies around an area with a certain distance
function ClearNearbyEnemies(player, safeDist)
    local safeArea = {left_top=
                    {x=player.position.x-safeDist,
                     y=player.position.y-safeDist},
                  right_bottom=
                    {x=player.position.x+safeDist,
                     y=player.position.y+safeDist}}

    for _, entity in pairs(player.surface.find_entities_filtered{area = safeArea, force = "enemy"}) do
        entity.destroy()
    end
end

-- Function to find coordinates of ungenerated map area in a given direction
-- starting from the center of the map
function FindMapEdge(directionVec)
    local position = {x=0,y=0}
    local chunkPos = {x=0,y=0}

    -- Keep checking chunks in the direction of the vector
    while(true) do
            
        -- Set some absolute limits.
        if ((math.abs(chunkPos.x) > 1000) or (math.abs(chunkPos.y) > 1000)) then
            break
        
        -- If chunk is already generated, keep looking
        elseif (game.surfaces[GAME_SURFACE_NAME].is_chunk_generated(chunkPos)) then
            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y
        
        -- Found a possible ungenerated area
        else
            
            chunkPos.x = chunkPos.x + directionVec.x
            chunkPos.y = chunkPos.y + directionVec.y

            -- Check there are no generated chunks in a 10x10 area.
            if IsChunkAreaUngenerated(chunkPos, 5) then
                position.x = (chunkPos.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
                position.y = (chunkPos.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
                break
            end
        end
    end

    DebugPrint("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

-- Find random coordinates within a given distance away
-- maxTries is the recursion limit basically.
function FindUngeneratedCoordinates(minDistChunks, maxDistChunks)
    local position = {x=0,y=0}
    local chunkPos = {x=0,y=0}

    local maxTries = 100
    local tryCounter = 0

    local minDistSqr = minDistChunks^2
    local maxDistSqr = maxDistChunks^2

    while(true) do
        chunkPos.x = math.random(0,maxDistChunks) * RandomNegPos()
        chunkPos.y = math.random(0,maxDistChunks) * RandomNegPos()

        local distSqrd = chunkPos.x^2 + chunkPos.y^2

        -- Enforce a max number of tries
        tryCounter = tryCounter + 1
        if (tryCounter > maxTries) then
            DebugPrint("FindUngeneratedCoordinates - Max Tries Hit!")
            break
 
        -- Check that the distance is within the min,max specified
        elseif ((distSqrd < minDistSqr) or (distSqrd > maxDistSqr)) then
            -- Keep searching!
        
        -- Check there are no generated chunks in a 10x10 area.
        elseif IsChunkAreaUngenerated(chunkPos, 5) then
            position.x = (chunkPos.x*CHUNK_SIZE) + (CHUNK_SIZE/2)
            position.y = (chunkPos.y*CHUNK_SIZE) + (CHUNK_SIZE/2)
            break -- SUCCESS
        end       
    end

    DebugPrint("spawn: x=" .. position.x .. ", y=" .. position.y)
    return position
end

--------------------------------------------------------------------------------
-- Anti-griefing Stuff
--------------------------------------------------------------------------------
function AntiGriefing(force)
    force.zoom_to_world_deconstruction_planner_enabled=false
    force.friendly_fire=false
end

function SetForceGhostTimeToLive(force)
    if GHOST_TIME_TO_LIVE ~= 0 then
        force.ghost_time_to_live = GHOST_TIME_TO_LIVE+1
    end
end

-- Return steel chest entity (or nil)
-- function DropEmptySteelChest(player)
--     local pos = player.surface.find_non_colliding_position("steel-chest", player.position, 15, 1)
--     if not pos then
--         return nil
--     end
--     local grave = player.surface.create_entity{name="steel-chest", position=pos, force="neutral"}
--     return grave
-- end

-- Gravestone soft mod. With my own modifications/improvements.
-- function DropGravestoneChests(player)

--     local grave
--     local count = 0

--     -- Use "game.player.cursorstack" to get items in player's hand.

--     -- Loop through a players different inventories
--     -- Put it all into the chest
--     -- If the chest is full, create a new chest.
--     for i, id in ipairs{
--     defines.inventory.player_armor,
--     defines.inventory.player_main,
--     defines.inventory.player_quickbar,
--     defines.inventory.player_guns,
--     defines.inventory.player_ammo,
--     defines.inventory.player_tools,
--     defines.inventory.player_trash} do
--         local inv = player.get_inventory(id)
--         if (not inv.is_empty()) then
--             for j = 1, #inv do
--                 if inv[j].valid_for_read then
                    
--                     -- Create a chest when counter is reset
--                     if (count == 0) then
--                         grave = DropEmptySteelChest(player)
--                         if (grave == nil) then
--                             player.print("Not able to place a chest nearby! Some items lost!")
--                             return
--                         end
--                         grave_inv = grave.get_inventory(defines.inventory.chest)
--                     end
--                     count = count + 1

--                     grave_inv[count].set_stack(inv[j])

--                     -- Reset counter when chest is full
--                     if (count == #grave_inv) then
--                         count = 0
--                     end
--                 end
--             end
--         end
--     end

--     if (grave ~= nil) then
--         player.print("Successfully dropped your items into a chest! Go get them quick!")
--     end
-- end


-- Enforce a circle of land, also adds trees in a ring around the area.
function CreateCropCircle(surface, centerPos, chunkArea, tileRadius)

    local tileRadSqr = tileRadius^2

    local dirtTiles = {}
    for i=chunkArea.left_top.x,chunkArea.right_bottom.x,1 do
        for j=chunkArea.left_top.y,chunkArea.right_bottom.y,1 do

            -- This ( X^2 + Y^2 ) is used to calculate if something
            -- is inside a circle area.
            local distVar = math.floor((centerPos.x - i)^2 + (centerPos.y - j)^2)

            -- Fill in all unexpected water in a circle
            if (distVar < tileRadSqr) then
                if (surface.get_tile(i,j).collides_with("water-tile") or ENABLE_SPAWN_FORCE_GRASS) then
                    table.insert(dirtTiles, {name = "grass", position ={i,j}})
                end
            end

            -- Create a circle of trees around the spawn point.
            if ((distVar < tileRadSqr-200) and 
                (distVar > tileRadSqr-260)) then
                surface.create_entity({name="tree-01", amount=1, position={i, j}})
            end
        end
    end


    surface.set_tiles(dirtTiles)
end

-- Adjust alien params
function ConfigureAlienStartingParams()
    game.map_settings.enemy_evolution.time_factor=0
    game.map_settings.enemy_evolution.destroy_factor = game.map_settings.enemy_evolution.destroy_factor / ENEMY_DESTROY_FACTOR_DIVISOR
    game.map_settings.enemy_evolution.pollution_factor = game.map_settings.enemy_evolution.pollution_factor / ENEMY_POLLUTION_FACTOR_DIVISOR
    game.map_settings.enemy_expansion.enabled = ENEMY_EXPANSION
end

-- Add Long Reach to Character
-- Exported.
-- function GivePlayerLongReach(player)
--     player.character.character_build_distance_bonus = BUILD_DIST_BONUS
--     player.character.character_reach_distance_bonus = REACH_DIST_BONUS
--     player.character.character_resource_reach_distance_bonus  = RESOURCE_DIST_BONUS
-- end
    
function GivePlayerBonuses(player)
    player.character.character_crafting_speed_modifier = scenario.config.playerBonus.character_crafting_speed_modifier;
end


-- --------------------------------------------------------------------------------
-- -- Autofill Stuff
-- --------------------------------------------------------------------------------

-- -- Transfer Items Between Inventory
-- -- Returns the number of items that were successfully transferred.
-- -- Returns -1 if item not available.
-- -- Returns -2 if can't place item into destInv (ERROR)
-- function TransferItems(result, srcInv, destEntity, itemStack)
--     -- Check if item is in srcInv
--     if (srcInv.get_item_count(itemStack.name) == 0) then
--         return -1
--     end

--     -- Check if can insert into destInv
--     if (not destEntity.can_insert(itemStack)) then
--         return -2
--     end
    
--     -- Insert items
--     local itemTotal = srcInv.get_item_count(itemStack.name)
--     local itemsRemoved = srcInv.remove(itemStack)
--     itemStack.count = itemsRemoved
--     result.autofillItemRemaining = itemTotal - itemsRemoved
--     result.autofillItemName = itemStack.name
--     return destEntity.insert(itemStack)
-- end

-- -- Attempts to transfer at least some of one type of item from an array of items.
-- -- Use this to try transferring several items in order
-- -- It returns once it successfully inserts at least some of one type.
-- function TransferItemMultipleTypes(result, srcInv, destEntity, itemNameArray, itemCount)
--     local ret = 0
--     for _,itemName in pairs(itemNameArray) do
--         ret = TransferItems(result, srcInv, destEntity, {name=itemName, count=itemCount})
--         if (ret > 0) then
--             return ret -- Return the value succesfully transferred
--         end
--     end
--     return ret -- Return the last error code
-- end

-- local vehicleFuel = {"rocket-fuel", "solid-fuel", "raw-wood", "coal"}
-- local machineGunAmmo = {"uranium-rounds-magazine", "piercing-rounds-magazine","firearm-magazine"}
-- local tankCannonAmmo = {"explosive-uranium-cannon-shell", "uranium-cannon-shell", "explosive-cannon-shell", "cannon-shell"}
-- local tankFlamethrowerAmmo = {"flamethrower-ammo"}

-- local localizedName = {
--     -- fuel
--     ["rocket-fuel"] = "Rocket Fuel", 
--     ["solid-fuel"] = "Solid Fuel",
--     ["raw-wood"] = "Raw Wood",
--     ["coal"] = "Coal",

--     -- machine gun / turret ammo
--     ["uranium-rounds-magazine"] = "Uranium Rounds Magazine", 
--     ["piercing-rounds-magazine"] = "Piercing Rounds Magazine",
--     ["firearm-magazine"] = "Firearm Magazine",

--     -- tank gun ammo
--     ["explosive-uranium-cannon-shell"] = "Explosive Uranium Cannon Shell",
--     ["uranium-cannon-shell"] = "Uranium Cannon Shell",
--     ["explosive-cannon-shell"] = "Explosive Cannon Shell",
--     ["cannon-shell"] = "Cannon Shell",
    
--     -- flamethrower ammo
--     ["flamethrower-ammo"] = "Flamethrower Ammo"
-- }

-- local function ShowAutofillResult( ret, result, itemKind, position, offset)
--     -- Check the result and print the right text to inform the user what happened.
--     if (ret > 0) then
--         -- Inserted ammo successfully
--         local color = {r=255,g=255,b=255}
--         local ammoName = localizedName[ result.autofillItemName ];
--         if ammoName ~= nil then
--             FlyingText("+" .. ret .. " " .. ammoName .. " (" .. result.autofillItemRemaining .. ")", { position.x, position.y + offset}, color)
--         end
--     elseif (ret == -1) then
--         local color = {r=255,g=255,b=255}
--         FlyingText("No " .. itemKind .. " in Main Inventory to Transfer", { position.x, position.y + offset}, color) 
--     elseif (ret == -2) then
--         local color = {r=255,g=255,b=255}
--         FlyingText("Autofill ERROR! - Report this bug!", { position.x, position.y + offset}, color )
--     end
-- end

-- -- Autofills a turret with ammo
-- function AutofillTurret(player, turret)
--     local mainInv = player.get_inventory(defines.inventory.player_main)
--     local result = {}

--     -- Attempt to transfer some ammo
--     local ret = TransferItemMultipleTypes(result, mainInv, turret, machineGunAmmo, AUTOFILL_TURRET_AMMO_QUANTITY)
--     ShowAutofillResult( ret, result, "Ammo", turret.position, 0 );
-- end

-- -- Autofills a vehicle with fuel, bullets and shells where applicable
-- function AutoFillVehicle(player, vehicle)
--     local mainInv = player.get_inventory(defines.inventory.player_main)
--     local result = {}

--     -- Attempt to transfer some fuel
--     if ((vehicle.name == "car") or (vehicle.name == "tank") or (vehicle.name == "locomotive")) then
--       local ret = TransferItemMultipleTypes(result, mainInv, vehicle, vehicleFuel, AUTOFILL_FUEL_QUANTITY)
--       ShowAutofillResult( ret, result, "Fuel", vehicle.position, 0);
--     end

--     -- Attempt to transfer some ammo
--     if ((vehicle.name == "car") or (vehicle.name == "tank")) then
--       local ret = TransferItemMultipleTypes(result, mainInv, vehicle, machineGunAmmo, AUTOFILL_MACHINEGUN_AMMO_QUANTITY)
--       ShowAutofillResult( ret, result, "Ammo", vehicle.position, 1 );
--     end

--     -- Attempt to transfer some tank shells
--     if (vehicle.name == "tank") then
--       local ret = TransferItemMultipleTypes(result, mainInv, vehicle, tankCannonAmmo, AUTOFILL_CANNON_AMMO_QUANTITY)
--       ShowAutofillResult( ret, result, "Shells", vehicle.position, 2);
--       local ret = TransferItemMultipleTypes(result, mainInv, vehicle, tankFlamethrowerAmmo, AUTOFILL_FLAMETHROWER_AMMO_QUANTITY)
--       ShowAutofillResult( ret, result, "Flamethrower Ammo", vehicle.position, 3);
--     end
-- end

RSO_MODE = 1
VANILLA_MODE = 2

function CreateGameSurface(mode)
    local mapSettings =  game.surfaces["nauvis"].map_gen_settings
    if (mode == RSO_MODE) then
        mapSettings.terrain_segmentation=scenario.config.mapSettings.RSO_TERRAIN_SEGMENTATION
        mapSettings.water=scenario.config.mapSettings.RSO_WATER
        mapSettings.starting_area=scenario.config.mapSettings.STARTING_AREA
        mapSettings.peaceful_mode=scenario.config.mapSettings.RSO_PEACEFUL
        -- mapSettings.seed=math.random(999999999);
        mapSettings.autoplace_controls = {
            ["coal"]={ size="none" },
            ["copper-ore"]={ size="none" },
            ["iron-ore"]={ size="none" },
            ["stone"]={ size="none" },
            ["uranium-ore"]={ size="none" },
            ["crude-oil"]={ size="none" },
            ["enemy-base"]={ size="none" }
        }
    end

    local surface = game.create_surface(GAME_SURFACE_NAME,mapSettings)
    -- surface.set_tiles({{name = "out-of-map",position = {1,1}}})
end

--------------------------------------------------------------------------------
-- EVENT SPECIFIC FUNCTIONS
--------------------------------------------------------------------------------

-- Display messages to a user everytime they join
function PlayerJoinedMessages(event)
    local player = game.players[event.player_index]
    for _,msg in pairs(scenario.config.joinedMessages) do
        player.print(msg)
    end
end

-- Create the gravestone chests for a player when they die
-- function CreateGravestoneChestsOnDeath(event)
--     DropGravestoneChests(game.players[event.player_index])
-- end

-- Remove decor to save on file size
-- function UndecorateOnChunkGenerate(event)
--     local surface = event.surface
--     local chunkArea = event.area
--     RemoveDecorationsArea(surface, chunkArea)
--     RemoveFish(surface, chunkArea)
-- end

-- Give player items on respawn
-- Intended to be the default behavior when not using separate spawns
function PlayerRespawnItems(event)
    GivePlayerItems(game.players[event.player_index])
end

function PlayerSpawnItems(event)
    GivePlayerStarterItems(game.players[event.player_index])
end

-- Autofill softmod
function Autofill(event)
    local player = game.players[event.player_index]
    local eventEntity = event.created_entity

    if (eventEntity.name == "gun-turret") then
        AutofillTurret(player, eventEntity)
    end

    if ((eventEntity.name == "car") or (eventEntity.name == "tank") or (eventEntity.name == "locomotive")) then
        AutoFillVehicle(player, eventEntity)
    end
end

-- Moved to frontier_silo, wasn't used anywhere else.
-- General purpose event function for removing a particular recipe
-- function RemoveRecipe(event, recipeName)
--     local recipes = event.research.force.recipes
--     if recipes[recipeName] then
--         recipes[recipeName].enabled = false
--     end
-- end

--------------------------------------------------------------------------------
-- UNUSED CODE
-- Either didn't work, or not used or not tested....
--------------------------------------------------------------------------------


-- THIS DOES NOT WORK IN SCENARIOS!
-- function DisableVanillaResouresAndEnemies()

--     local map_gen_ctrls = game.surfaces[GAME_SURFACE_NAME].map_gen_settings.autoplace_controls

--     map_gen_ctrls["coal"].size = "none"
--     map_gen_ctrls["stone"].size = "none"
--     map_gen_ctrls["iron-ore"].size = "none"
--     map_gen_ctrls["copper-ore"].size = "none"
--     map_gen_ctrls["crude-oil"].size = "none"
--     map_gen_ctrls["enemy-base"].size = "none"
-- end



-- Shared vision for other forces? UNTESTED
-- function ShareVisionForAllForces()
--     for _,f in pairs(game.forces) do
--         for _,p in pairs(game.connected_players) do
--             if (f.name ~= p.force.name) then
--                 local visionArea = {left_top=
--                             {x=p.x-(CHUNK_SIZE*3),
--                              y=p.y-(CHUNK_SIZE*3)},
--                           right_bottom=
--                             {x=p.x+(CHUNK_SIZE*3),
--                              y=p.y+(CHUNK_SIZE*3)}}
--                 f.chart(game.surfaces[GAME_SURFACE_NAME], visionArea)
--             end
--         end
--     end
-- end
