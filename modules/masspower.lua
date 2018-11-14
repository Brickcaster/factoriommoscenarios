--Mass to Power converter.  Better than a mass energy converter!
--Written by Mylon, 2018-10
--MIT License

if MODULE_LIST then
	module_list_add("Mass to Power")
end

require ("production-score")
mass_power = {FOOD_SCALE = 0.0006} --Not actually using this yet because balance tweaks.
global.mass_power = {power = 0, targets = {}, food_sources = {}, target_index=1, FOOD_SCALE = 0.1}

--Create the converter and input chest
function mass_power.init()
    local eei = game.surfaces[1].create_entity{name="electric-energy-interface", position={-5, 0}, force=game.forces.player}
    eei.operable = false
    eei.minable = false
    eei.destructible = false
    eei.power_production = 0
    global.mass_power.eei = eei
    global.mass_power.food_values = production_score.generate_price_list()
end

--Consume goods in the sacrifice chests and set power.
function mass_power.feed()
    local food_value = 0
    for i = 1, #global.mass_power.food_sources do
        local ent = global.mass_power.food_sources[i]
        if not (ent and ent.valid) then
            table.remove(global.mass_power.food_sources, i)
        else
            for item, count in pairs(ent.get_inventory(1).get_contents()) do
                if global.mass_power.food_values[item] then
                    food_value = food_value + global.mass_power.food_values[item] * count * global.mass_power.FOOD_SCALE
                end
            end
            ent.get_inventory(1).clear()
        end
    end
    global.mass_power.eei.power_production = global.mass_power.eei.power_production + food_value
    global.mass_power.eei.electric_buffer_size = global.mass_power.eei.power_production
end

--Converter is angry!  Attacks other generators.
function mass_power.acquire(event)
    if not(event.created_entity.type == "solar-panel" or event.created_entity.type == "generator") then
        return
    end
    table.insert(global.mass_power.targets, {entity=event.created_entity, retries=0})
end

--Add nearby containers to a list for consumption.
function mass_power.feeding(event)
    if not (event.created_entity.type == "container" or event.created_entity.type == "logistic-container") then return end
    local reference_position = global.mass_power.eei.position
    local event_position = event.created_entity.position
    if math.abs(event_position.x - reference_position.x) > 2 or math.abs(event_position.y - reference_position.y) > 2 then return end
    table.insert(global.mass_power.food_sources, event.created_entity)

end

function mass_power.checker(event)
    -- Iterate ovre up to 30 entities
    for i = 0, 29 do
        if i >= #global.mass_power.targets then
            return
        end
        if global.mass_power.target_index + i > #global.mass_power.targets then
            global.mass_power.target_index = 1
        end
        local entity = global.mass_power.targets[global.mass_power.target_index + i].entity
        if entity.valid then
            if global.mass_power.targets[global.mass_power.target_index + i].retries > 5 then
                mass_power.angry(entity, true)
            else
                mass_power.angry(entity)
            end
            global.mass_power.targets[global.mass_power.target_index + i].retries = global.mass_power.targets[global.mass_power.target_index + i].retries + 1
        else
            table.remove(global.mass_power.targets, global.mass_power.target_index + i)
        end
        global.mass_power.target_index = global.mass_power.target_index + 1
    end
end

function mass_power.angry(entity, very_angry)
    local eei = global.mass_power.eei
    --log("Angry!")
    if very_angry then
        --log("Very angry!")
        eei.surface.create_entity{name="grenade", force="enemy", position=entity.position, target=entity, speed=0.1}
        eei.surface.create_entity{name="grenade", force="enemy", position=entity.position, target=entity, speed=0.1}
    else
        eei.surface.create_entity{name="rocket", force="enemy", position=eei.position, target=entity, speed=0.1}
    end
    --Target might be out of range, so let's force the issue.
end

Event.register('on_init', mass_power.init)
Event.register(-300, mass_power.checker)
Event.register(-300, mass_power.feed)
Event.register(defines.events.on_built_entity, mass_power.feeding)
Event.register(defines.events.on_built_entity, mass_power.acquire)
Event.register(defines.events.on_robot_built_entity, mass_power.feeding)
Event.register(defines.events.on_robot_built_entity, mass_power.acquire)
