--Pepperming Mining, logistic mining intended for use in scenarios.
--Written by Mylon, 2017
--MIT License
--Forked from Nougat Mining on 05/12/2017

if MODULE_LIST then
	module_list_add("Peppermint Mining")
end

peppermint = { MAX_ITEMS=400, --If this goes too high, it gets laggy.
    POLLUTION= 9 * 0.9 --See math below.
}

--Persistent data is of form { forcename = { ores={}, picker={}, lastkey } }
global.peppermint = {}

-- function peppermint.brew()
--     --Reused from Nougat Mining
--     if game.entity_prototypes["electric-mining-drill"] then
--         local proto  = game.entity_prototypes["electric-mining-drill"]
--         --How much pollution to create per stack of products.
--         --This assumes a mining hardness of 0.9
--         global.peppermint.pollution = (proto.electric_energy_source_prototype.emissions * proto.energy_usage * 60) / proto.mining_power / proto.mining_speed * 0.9
--     else
--         --Fallback if "electric-mining-drill" doesn't exist.
--         global.peppermint.pollution = 9 * 0.9
--     end
-- end

function peppermint.mark(event)
    local player = game.players[event.player_index]
    local force = player.force
    if not global.peppermint[force.name] then
        global.peppermint[force.name] = {ores={}, picker={}}
    end
    local minty = global.peppermint[force.name]

    if event.area.left_top.x == event.area.right_bottom.x or event.area.left_top.y == event.area.right_bottom.y then
        --log("Selected area of size 0")
        return
    end

    local ores = player.surface.find_entities_filtered{type="resource", area=event.area}
    if #ores == 0 then return end

    if event.alt then --Remove, not add.
        local removed = false
        for k,v in pairs(ores) do
            if peppermint.remove(v, force.name) then
                removed = true
            end
        end
        if removed then
            player.print("Peppermint mining: Ores no longer flagged for mining.")
            peppermint.reset_picker(force.name)
        end
        return
    end
    -- if event.alt then --Remove, not add.
    --     local removed = false
    --     for _, ore in pairs(ores) do
    --         for n = #minty.ores, 1, -1 do
    --             if ore == minty.ores[n] then
    --                 table.remove(minty.ores, n)
    --                 removed = true
    --             end
    --         end
    --     end
    --     if removed then
    --         player.print("Peppermint mining: Ores no longer flagged for mining.")
    --     end
    --     return
    -- end

    --Check to see if a miner got deconned.  If so, let's assume the player does NOT want to mark the ore for mining.
    local miners = player.surface.find_entities_filtered{type="mining-drill", area=event.area, force=player.force}
    for k, v in pairs(miners) do
        if v.to_be_deconstructed(player.force) then
            return
        end
    end

    --Filter out non-mineable ores.
    for i = #ores, 1, -1 do
        if ores[i].prototype.resource_category == "basic-fluid"
            or ores[i].prototype.mineable_properties.required_fluid
            or ores[i].prototype.infinite_resource
            or ores[i].prototype.mineable_properties.hardness > 100 then
                table.remove(ores, i)
        end
    end
    
    --Ensure that a roboport is in range and it's not a player roboport.
    for i = #ores, 1, -1 do
        local networks = player.surface.find_logistic_networks_by_construction_area(ores[i].position, force)
        if #networks == 0 then
            table.remove(ores, i)
        else
            local only_mobile = true
            for _, network in pairs(networks) do
                if not (network.valid and network.cells[1].valid) then
                    table.remove(ores, i)
                elseif not network.cells[1].mobile then
                    only_mobile = false
                    break
                end
            end
            if only_mobile then --The only network in range is the player's network.
                table.remove(ores, i)
            end
        end
    end

    --Check for duplicates and insert into table
    --Note, this is o(n^2)
    local added = false
    for k,v in pairs(ores) do
        if peppermint.add(v, force.name) then
            added = true
        end
    end
    -- for i = #ores, 1, -1 do
    --     local dupe = false
    --     for n = #minty.ores, 1, -1 do
    --         if ores[i] == minty.ores[n] then
    --             table.remove(ores, i)
    --             dupe = true
    --             break
    --         end
    --     end
    --     if not dupe then
    --         table.insert(minty.ores, ores[i])
    --         added = true
    --     end
    -- end
    if added then
        player.print("Peppermint Mining: Ores added for mining.")
    end
end

--Iterate over each force.
function peppermint.stretch(event)
    if (game.tick + 13) % 60 ~= 0 then
        return
    end 
    for name, minty in pairs(global.peppermint) do
        peppermint.mine(name, minty)
    end
end

--Magic happens here.
function peppermint.mine(name, minty)
    local force = game.forces[name]
    if not (force and force.valid) then
        log("Force died!")
        minty = nil
    end
    local ore = peppermint.pick(name)
    if not (ore and ore.valid) then
       --log("Picker chose invalid entity.")
        return
    end
    local surface = ore.surface
    local networks = surface.find_logistic_networks_by_construction_area(ore.position, force)
    if not networks then --Power died?  Roboport died?
        return
    end
    local network
    for k,v in pairs(networks) do
        if v.valid and not v.cells[1].mobile then
            network = v
            break
        end
    end
    if not (network and network.valid) then
        return
    end
    --Check for low power
    local roboport = network.find_cell_closest_to(ore.position) and network.find_cell_closest_to(ore.position).owner
    if not roboport then --Something went wrong.
        log("Roboport or network invalid.")
        return
    end
    if roboport.prototype.electric_energy_source_prototype.buffer_capacity ~= roboport.energy then
        return
    end
    
    local count = math.floor(network.available_construction_robots / 2)

    --Reused from Nougat Mining
    local position = ore.position --Just in case we kill the ore.
    local productivity = force.mining_drill_productivity_bonus + 1
    local cargo_multiplier = force.worker_robots_storage_bonus + 1
    local products = {}
    
    count = math.min(math.ceil(ore.amount / cargo_multiplier), peppermint.MAX_ITEMS, count)

    for k,v in pairs(ore.prototype.mineable_properties.products) do
        local product
        if v.probability then
            if math.random < v.probability then
                product = {name=v.name, count=math.random(v.amount_min, v.amount_max)}
            end
        elseif v.amount then
            product = {name=v.name, count=v.amount}
        else
            product = {name=v.name, count=1}
        end
        --Stack ore according to force.worker_robots_storage_bonus

        product.count = product.count * cargo_multiplier

        table.insert(products, {name=product.name, count=product.count})
    end 
    for i = 1, count do
        for k, v in pairs(products) do
            local oreitem = surface.create_entity{name="item-on-ground", stack=v, position=position}
            if oreitem and oreitem.valid then --Why is oreitem sometimes nil or invalid?
                oreitem.order_deconstruction(force)
                --game.print(oreitem.stack.name .. " #"..i.." created for pickup. ")
            end
        end
    end
    --Also add pollution.  Mining productivity is omitted.
    surface.pollute(position, peppermint.POLLUTION * count * cargo_multiplier)
    --game.print("Created " .. #products .. " for pickup.")

    --Deplete the ore.
    if ore.amount > math.ceil(count * cargo_multiplier / productivity) then
        ore.amount = ore.amount - math.ceil(count * cargo_multiplier / productivity)
    else
        script.raise_event(defines.events.on_resource_depleted, {entity=ore, name=defines.events.on_resource_depleted})
        if ore and ore.valid then
            ore.destroy()
        end
    end
end

--Shuffle the table whenever we reset the index.
-- function peppermint.cook(ores)
--     local n = #ores
--     while n > 2 do
--         local k = math.random(n)
--         ores[n], ores[k] = ores[k], ores[n]
--         n = n - 1
--     end
-- end

--Getter/setters
--Primary table indexed by coords.
function peppermint.add(ore, forcename)
    local minty = global.peppermint[forcename]
    local x, y = math.floor(ore.position.x), math.floor(ore.position.y)
    if not minty.ores[x] then
        minty.ores[x] = {}
    end
    if not minty.ores[x][y] then
        minty.ores[x][y] = ore
        return true
    else
        return false
    end
end

function peppermint.remove(ore, forcename)
    local forcetable = global.peppermint[forcename]
    local x, y = math.floor(ore.position.x), math.floor(ore.position.y)
    local removed = false
    if forcetable.ores[x] and forcetable.ores[x][y] then
        forcetable.ores[x][y] = nil
        removed = true
    end
    if forcetable.ores[x] and nil == next(forcetable.ores[x]) then
        forcetable.ores[x] = nil
    end
    return removed
end

function peppermint.depleted(event)
    if not event.entity and not event.entity.valid then return end
    local x, y = math.floor(event.entity.position.x), math.floor(event.entity.position.y)
    for name, minty in pairs(global.peppermint) do
        if minty.ores[x] and minty.ores[x][y] then
            peppermint.remove(event.entity, name)
        end
    end
end

--Secondary table is maintained as a shuffled array.
function peppermint.pick(forcename)
    if not global.peppermint[forcename] then
        return
    end

    local picker = global.peppermint[forcename].picker
    
    --global.peppermint[forcename].lastkey = next(picker, global.peppermint[forcename].lastkey)

    local value = table.remove(picker)
    if value and value.valid then
        return value
    end

    -- if global.peppermint[forcename].lastkey ~= nil then
    --     --We're not yet at the end of the table.  Maybe an ore got depleted but will get cleaned on next shuffle.
    --     return
    -- end

    --Still here?
    peppermint.reset_picker(forcename)
    picker = global.peppermint[forcename].picker

    --global.peppermint[forcename].lastkey = nil
    --Check if table is empty, if not retry.
    if #picker > 1 then --Checking if > 0 should be safe, but let's not.
        return peppermint.pick(forcename)
    end
end

function peppermint.reset_picker(forcename)
    
    global.peppermint[forcename].picker = {}
    local picker = global.peppermint[forcename].picker

    for x, tablex in pairs(global.peppermint[forcename].ores) do
        for y, ore in pairs(tablex) do
            if ore and ore.valid then
                table.insert(picker, ore)
                --game.print("Shuffled table")
            else
                --Ore was depleted or otherwise destroyed.
                tablex[y] = nil
                if next(tablex) == nil then
                    global.peppermint[forcename].ores[x] = nil
                end
            end
        end
    end
    --Now shuffle the table.
    local n = #picker
    while n > 2 do
        local k = math.random(n)
        picker[n], picker[k] = picker[k], picker[n]
        n = n - 1
    end
end

Event.register(defines.events.on_player_deconstructed_area, peppermint.mark)
Event.register(defines.events.on_tick, peppermint.stretch)
Event.register(defines.events.on_resource_depleted, peppermint.depleted)
--Event.register(-1, peppermint.brew)
