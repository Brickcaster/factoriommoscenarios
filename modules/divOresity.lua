--divOresity
--Written by Mylon
--MIT licensed
--Inspired by Ore Chaos

DIVERSITY_QUOTA = 0.25
EXEMPT_AREA = 0
STONE_BYPRODUCT = false
STONE_BYPRODUCT_RATIO = 0.30

EXTRA_DIVORESITY = true

--Build a table of potential ores to pick from.  Uranium is exempt from popping up randomly.
function divOresity_init()
	global.diverse_ores = {}
	global.extra_diverse_ores = {}
	for k,v in pairs(game.entity_prototypes) do
		if v.type == "resource"
		and v.resource_category == "basic-solid"
		and v.autoplace_specification then
			table.insert(global.extra_diverse_ores, v.name)
			if v.mineable_properties.required_fluid == nil then
				table.insert(global.diverse_ores, v.name)
			end
		end
	end
end

function diversify(event)
	local ores = {}
	if global.grid ~= nil then
		ores = event.surface.find_entities_filtered({type="resource", area={{event.area.left_top.x - 32, event.area.left_top.y - 32},{event.area.right_bottom.x + 32, event.area.right_bottom.y + 32}}})
	else 
		ores = event.surface.find_entities_filtered({type="resource", area=event.area})
	end
	for k,v in pairs(ores) do
		if math.abs(v.position.x) > EXEMPT_AREA or math.abs(v.position.y) > EXEMPT_AREA then
			if v.prototype.resource_category == "basic-solid" then
				local random = math.random()
				if v.name == "stone" and STONE_BYPRODUCT then
					v.destroy()
				elseif random < DIVERSITY_QUOTA then --Replace!
					local refugee
					if v.prototype.mineable_properties.required_fluid and EXTRA_DIVORESITY then
						refugee = global.extra_diverse_ores[math.random(#global.extra_diverse_ores)]
					else
						refugee = global.diverse_ores[math.random(#global.diverse_ores)]
					end
					event.surface.create_entity{name=refugee, position=v.position, amount=v.amount}
					v.destroy()
				elseif STONE_BYPRODUCT and random < STONE_BYPRODUCT_RATIO then --Replace with stone!
					event.surface.create_entity{name="stone", position=v.position, amount=v.amount}
					v.destroy()
				end
			end
		end
	end
end

function get_sign(number)
	if (number >= 0) then
		return 1
	else 
		return -1
	end
end

Event.register(defines.events.on_chunk_generated, diversify)
Event.register('on_init', divOresity_init)
