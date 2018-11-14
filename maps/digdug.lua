-- Redmew's diggy, but Mylon
-- Written Oct 2018
-- MIT License

digdug = {
    DEBUG = true,
    ORE_CHANCE = 0.20,
    ORE_MIN = 100,
    ORE_MAX = 600,
    ORE_DISTANCE_FACTOR = 0.7,
    COLLAPSE_THRESHHOLD = 250
}
global.digdug = {scheduled_collapse= {}}

--Prepare the surface.
function digdug.init()
    --Debug
    if digdug.DEBUG then
        game.forces.player.manual_mining_speed_modifier = 100
    end
    local surface = game.surfaces[1]
    surface.daytime = 0.5
    surface.freeze_daytime = true

    for x = -14, 14 do
        for y = -14, 14 do
            if surface.is_chunk_generated{x,y} and not ((x == 0 or x == -1) and (y == 0 or y == -1)) then
                local tiles = {}
                for xx = x * 32, x * 32 + 31 do
                    for yy = y * 32, y * 32  + 31 do
                        table.insert(tiles, {position={xx, yy}, name="out-of-map"})
                    end
                end
                surface.set_tiles(tiles)
            else
                surface.set_chunk_generated_status({x,y}, defines.chunk_generated_status.entities)
            end
        end
    end

    --Initial rock ring
    for x = -32, 32 do
        surface.create_entity{name="rock-big", position={x, -32}}
        surface.create_entity{name="rock-big", position={x, 32}}
    end
    for y = -31, 31 do
        surface.create_entity{name="rock-big", position={32, -y}}
        surface.create_entity{name="rock-big", position={32, y}}
    end

    --non-uranium, non-oil, non-stone is 4x more likely to appear.
    global.digdug.ore_list = {}
    for _, proto in pairs(game.entity_prototypes) do
        if proto.type == "resource" then
            if proto.resource_category == "basic-solid" and proto.mineable_properties.required_fluid == nil and proto.name ~= "stone" then
                for i = 1, 3 do
                    table.insert(global.digdug.ore_list, proto.name)
                end
            end
            table.insert(global.digdug.ore_list, proto.name)
        end
    end

end

function digdug.mine(rock)
    --local rock = event.entity
    if not (rock.name == "rock-big" or rock.name == "stone-wall") then return end
    local surface=rock.surface
    local adj = {}
    table.insert(adj, surface.get_tile(rock.position.x, rock.position.y-1))
    table.insert(adj, surface.get_tile(rock.position.x+1, rock.position.y))
    table.insert(adj, surface.get_tile(rock.position.x, rock.position.y+1))
    table.insert(adj, surface.get_tile(rock.position.x-1, rock.position.y))

    for _, tile in pairs(adj) do
        if tile.name == "out-of-map" then
            surface.set_tiles{{position=tile.position, name="dirt-1"}}
            surface.create_entity{name="rock-big", position=tile.position}
        end
    end

    if math.random() < digdug.ORE_CHANCE then
        local amount = math.random(digdug.ORE_MIN, digdug.ORE_MAX)
        local res = surface.create_entity{position=rock.position, name=global.digdug.ore_list[math.random(#global.digdug.ore_list)], amount=amount}
        if res.prototype.resource_category == "basic-fluid" then
            res.amount = 100 * res.amount
        end
    end

    for x = -14, 14 do
        surface.set_chunk_generated_status({math.floor(rock.position.x / 32) + x, math.floor(rock.position.y / 32) - 14}, defines.chunk_generated_status.entities)
        surface.set_chunk_generated_status({math.floor(rock.position.x / 32) + x, math.floor(rock.position.y / 32) + 14}, defines.chunk_generated_status.entities)
    end
    for y = -13, 13 do
        surface.set_chunk_generated_status({math.floor(rock.position.x / 32) - 14, math.floor(rock.position.y / 32) + y}, defines.chunk_generated_status.entities)
        surface.set_chunk_generated_status({math.floor(rock.position.x / 32) + 14, math.floor(rock.position.y / 32) + y}, defines.chunk_generated_status.entities)
    end

    digdug.stress_check(rock.position.x, rock.position.y)

end

-- Check differing distances around x,y.  If stress > THRESHHOLD then collapse
function digdug.check_support(x, y)
    local surface = game.surfaces[1]
    local support = 0
    -- local function check_collapse()
    --     if support < digdug.COLLAPSE_THRESHHOLD then
    --         return true
    --     end
    -- end

    --Stress is a function of distance squared.
    local function distance(entity)
        return ((entity.position.x - x)^2 + (entity.position.y - y)^2)^0.05
    end

    local area1 = {{x-2, y-2}, {x+3, y+3}}
    local area2 = {{x-5, y-5}, {x+6, y+6}}
    local area3 = {{x-11, y-11}, {x+12, y+12}}
    for _, pillar in pairs(surface.find_entities_filtered{name={"rock-big", "stone-wall"}, area=area3}) do
        support = support + distance(pillar)
    end

    for _, faux_pillar in pairs(surface.find_tiles_filtered{name="out-of-map", area=area3}) do
        support = support + distance(faux_pillar)
    end

    support = support - surface.count_tiles_filtered{has_hidden_tile=false, area=area2}
    support = support - 0.5 * surface.count_tiles_filtered{name="stone-path", area=area2}
    support = support - 0.25 * surface.count_tiles_filtered{name="concrete", area=area2}

    if digdug.DEBUG then
        surface.create_entity{name="flying-text", position={x,y}, text=math.floor(support)}
        --game.print(support)
    end

    if support < digdug.COLLAPSE_THRESHHOLD then
        table.insert(global.digdug.scheduled_collapse, {tick = game.tick + 60, x = x, y = y})
        --digdug.collapse(x, y)
    end
    return support

end

--Raycast in 4 directions.
function digdug.stress_check(x, y)
    local last_support = 1000000
    for yy = 0, -11, -1 do
        local support = digdug.check_support(x, y + yy)
        if support > last_support then
            break
        else
            last_support = support
        end
    end
    local last_support = 1000000
    for xx = 0, 12 do
        local support = digdug.check_support(x + xx, y)
        if support > last_support then
            break
        else
            last_support = support
        end
    end
    local last_support = 1000000
    for yy = 0, 12 do
        local support = digdug.check_support(x, y + yy)
        if support > last_support then
            break
        else
            last_support = support
        end
    end
    local last_support = 1000000
    for xx = 0, -11, -1 do
        local support = digdug.check_support(x + xx, y)
        if support > last_support then
            break
        else
            last_support = support
        end
    end
    

end

function digdug.collapse()
    if #global.digdug.scheduled_collapse == 0 then return end
    for i = #global.digdug.scheduled_collapse, 1, -1 do
        local schedule = global.digdug.scheduled_collapse[i]
        if game.tick >= schedule.tick then
            local x, y = schedule.x, schedule.y
            local area = {{x-1, y-1}, {x+1, y+1}}
            local surface = game.surfaces[1]
            -- for xx = x-size, x+size+1 do
            --     for yy = y-size, y+size+1 do
                    surface.create_entity{name="rock-big", position={x, y}}
            --     end
            -- end
            table.remove(global.digdug.scheduled_collapse, i)
            if digdug.DEBUG then return end
            for _, doomed in pairs(surface.find_entities_filtered{force=game.forces.player, area=area}) do
                if doomed.name ~= "stone-wall" then
                    doomed.die()
                end
            end
        end
    end
end

-- function digdug.find_rock(x, y)
--     local surface = game.surfaces[1]
--     local rock = surface.create_entity{name="rock-big", position={x,y}}
-- end

Event.register('on_init', digdug.init)
Event.register(defines.events.on_player_mined_entity, function(event) digdug.mine(event.entity) end)
Event.register(defines.events.on_entity_died, function(event) digdug.mine(event.entity) end)
Event.register(-1, digdug.collapse)
