
jvm = {}
--------------------------------------------------------------------------------
-- Rocket Launch Event Code
-- Controls the "win condition"
--------------------------------------------------------------------------------
function RocketLaunchEvent(event)
    local force = event.rocket.force
    
    if event.rocket.get_item_count("satellite") == 0 then
        for index, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    if not global.satellite_sent then
        global.satellite_sent = {}
    end

    if global.satellite_sent[force.name] then
        global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1   
    else
        game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        global.satellite_sent[force.name] = 1
    end
    
    for index, player in pairs(force.players) do
        if player.gui.left.rocket_score then
            player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
        else
            local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
            frame.add{name="rocket_count_label", type = "label", caption={"", "Satellites launched", ":"}}
            frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
        end
    end
end

----------------------------------------
-- On Init - only runs once the first 
--   time the game starts
----------------------------------------
function jvm.on_init(event)
    -- Configures the map settings for enemies
    -- This controls evolution growth factors and enemy expansion settings.
    if ENABLE_RSO then
        CreateGameSurface(RSO_MODE)
    else
        CreateGameSurface(VANILLA_MODE)
    end
    
    if spawnGenerator.ConfigureGameSurface then
        spawnGenerator.ConfigureGameSurface()
    end
    
    ConfigureAlienStartingParams()

    if ENABLE_SEPARATE_SPAWNS then
        InitSpawnGlobalsAndForces()
    end

    -- Exported.
    -- if ENABLE_RANDOM_SILO_POSITION then
    --     SetRandomSiloPosition()
    -- else
    --     SetFixedSiloPosition()
    -- end

    -- Exported.
    -- if FRONTIER_ROCKET_SILO_MODE then
    --     ChartRocketSiloArea(game.forces[MAIN_FORCE])
    -- end

    if scenario.config.research.coalLiquefactionResearched then
        game.forces[MAIN_FORCE].technologies['coal-liquefaction'].researched=true;
    end
    
    if ENABLE_ALL_RESEARCH_DONE then
        game.forces[MAIN_FORCE].research_all_technologies()
    end

    -- if scenario.config.wipespawn.enabled then
        wipespawn.init()
    -- elseif scenario.config.regrow.enabled then
        -- regrow.init()
    -- end
    
end

Event.register(-1, jvm.on_init)
    

----------------------------------------
-- Freeplay rocket launch info
-- Slightly modified for my purposes
----------------------------------------
function jvm.on_rocket_launch(event)
    -- Mylon's Note: This is more scenario related than frontier silo related.
    if FRONTIER_ROCKET_SILO_MODE then
        RocketLaunchEvent(event)
    end
end

Event.register(defines.events.on_rocket_launched, jvm.on_rocket_launch)

----------------------------------------
-- Chunk Generation
----------------------------------------
function jvm.on_chunk_generated(event)
    local shouldGenerateResources = true
    -- if scenario.config.wipespawn.enabled then
        -- regrow.onChunkGenerated(event)
    -- elseif scenario.config.regrow.enabled then
        -- shouldGenerateResources = regrow.shouldGenerateResources(event);
        -- regrow.onChunkGenerated(event)
    -- end

    -- Exported to undecorator.lua
    -- if ENABLE_UNDECORATOR then
    --     UndecorateOnChunkGenerate(event)
    -- end
    
    if scenario.config.riverworld.enabled then
        spawnGenerator.ChunkGenerated(event);
    end

    if scenario.config.toxicJungle.enabled then
        toxicJungle.ChunkGenerated(event);
    end    

    if scenario.config.riverworld.enabled then
        spawnGenerator.ChunkGenerated(event);
    end

    if ENABLE_RSO then
        if shouldGenerateResources then
            RSO_ChunkGenerated(event)
        end
    end

    -- if FRONTIER_ROCKET_SILO_MODE then
    --     GenerateRocketSiloChunk(event)
    -- end

    -- This MUST come after RSO generation!
    if ENABLE_SEPARATE_SPAWNS then
        SeparateSpawnsGenerateChunk(event)
    end
    
    -- if scenario.config.regrow.enabled then
        -- regrow.afterResourceGeneration(event)
    -- end
end

Event.register(defines.events.on_chunk_generated, jvm.on_chunk_generated)

----------------------------------------
-- Gui Click
----------------------------------------
function jvm.on_gui_click(event)
    -- if ENABLE_TAGS then
    --     TagGuiClick(event)
    -- end

    -- if ENABLE_PLAYER_LIST then
    --     PlayerListGuiClick(event)
    -- end

    if ENABLE_SEPARATE_SPAWNS then
        WelcomeTextGuiClick(event)
        SpawnOptsGuiClick(event)
        SpawnCtrlGuiClick(event)
        SharedSpwnOptsGuiClick(event)
    end

end

Event.register(defines.events.on_gui_click, jvm.on_gui_click)

----------------------------------------
-- Player Events
----------------------------------------
function jvm.on_player_joined_game(event)
    
    PlayerJoinedMessages(event)

    -- if ENABLE_TAGS then
    --     CreateTagGui(event)
    -- end

    -- if ENABLE_PLAYER_LIST then
    --     CreatePlayerListGui(event)
    -- end
end

Event.register(defines.events.on_player_joined_game, jvm.on_player_joined_game)

function jvm.on_player_created(event)
    if ENABLE_SPAWN_SURFACE then
        AssignPlayerToStartSurface(game.players[event.player_index])
    end
--    if ENABLE_RSO then
--      RSO_PlayerCreated(event)
--  end

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end

    GivePlayerBonuses(game.players[event.player_index])

    if not ENABLE_SEPARATE_SPAWNS then
        PlayerSpawnItems(event)
    else
        SeparateSpawnsPlayerCreated(event)
    end

    -- Not sure if this should be here or in player joined....
    if ENABLE_BLUEPRINT_STRING then
        bps_player_joined(event)
    end
end

Event.register(defines.events.on_player_created, jvm.on_player_created)


-- function jvm.on_player_died(event)
--     if ENABLE_GRAVESTONE_CHESTS then
--         CreateGravestoneChestsOnDeath(event)
--     end
-- end

-- Event.register(defines.events.on_player_died, jvm.on_player_died)

function jvm.on_player_respawned(event)
    if not ENABLE_SEPARATE_SPAWNS then
        PlayerRespawnItems(event)
    else 
        SeparateSpawnsPlayerRespawned(event)
    end

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end
    GivePlayerBonuses(game.players[event.player_index])
end

Event.register(defines.events.on_player_respawned, jvm.on_player_respawned)

function jvm.on_player_left_game(event)
    if ENABLE_SEPARATE_SPAWNS then
        FindUnusedSpawns(event)
    end
end

Event.register(defines.events.on_player_left_game, jvm.on_player_left_game)

function jvm.on_built_entity(event)
    -- if ENABLE_AUTOFILL then
    --     Autofill(event)
    -- end

    -- if scenario.config.regrow.enabled then
        -- regrow.onBuiltEntity(event);
    -- end

    local type = event.created_entity.type    
    if type == "entity-ghost" or type == "tile-ghost" or type == "item-request-proxy" then
        if GHOST_TIME_TO_LIVE ~= 0 then
            event.created_entity.time_to_live = GHOST_TIME_TO_LIVE
        end
    end
end

Event.register(defines.events.on_built_entity, jvm.on_built_entity)

function jvm.on_tick(event)
    -- if scenario.config.wipespawn.enabled then
        wipespawn.onTick(event)
    -- elseif scenario.config.regrow.enabled then
        -- regrow.onTick(event)
    -- end
end

--Event.register(defines.events.on_tick, jvm.on_tick)

function jvm.teleporter(event)
    local player = game.players[event.player_index];
    TeleportPlayer(player)
end

if scenario.config.teleporter.enabled then
    Event.register(defines.events.on_player_driving_changed_state, jvm.teleporter)
end

----------------------------------------
-- On Research Finished
----------------------------------------
function jvm.on_research_finished(event)
    -- if FRONTIER_ROCKET_SILO_MODE then
    --     RemoveRocketSiloRecipe(event)
    -- end

    if ENABLE_BLUEPRINT_STRING then
        bps_on_research_finished(event)
    end

end

Event.register(defines.events.on_research_finished, jvm.on_research_finished)

-- if scenario.config.regrow.enabled then
    -- Event.register(defines.events.on_sector_scanned, regrow.onSectorScan)

    -- Event.register(defines.events.on_robot_built_entity, regrow.onRobotBuiltEntity)
    
    -- Event.register(defines.events.on_player_mined_entity, regrow.onPlayerMinedEntity)
    
    -- Event.register(defines.events.on_robot_mined_entity, regrow.onRobotMinedEntity)
    
-- end

----------------------------------------
-- BPS Specific Event
----------------------------------------
--script.on_event(defines.events.on_robot_built_entity, function(event)
--end)
