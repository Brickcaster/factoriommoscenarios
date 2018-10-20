-- Grid Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This module devides the world in a grid, with a connecting piece inbetween.

global.grid = global.grid or {}
global.grid.seed = 1
global.grid.size = 64
global.grid.x_border_width = 5
global.grid.y_border_width = 5
global.grid.x_bridge_width = 3 -- width * 1.5 ?? 
global.grid.y_bridge_width = 3

local function normalize(n) --keep numbers at (positive) 32 bits
	return n % 0x80000000
end

-- Grid Ore Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This module is an extention to the grid module and is able to place ores / oil in certain "Grid chunks"
global.grid_ore = global.grid_ore or {}
global.grid_ore.resource_chance = 40
global.grid_ore.ore_start_amount = 225
global.grid_ore.ore_random_addition_amount = 600
global.grid_ore.oil_start_amount = 10000
global.grid_ore.oil_random_addition_amount = 20000
global.grid_ore.oil_spout_chance = 1


function grid_ore_place_ore_in_grid_chunck(location, ore)
	xoffset = (math.floor(location.x/global.grid.size))*global.grid.size
	yoffset = (math.floor(location.y/global.grid.size))*global.grid.size
	for y=global.grid.y_border_width,global.grid.size-1 do
		for x=global.grid.x_border_width,global.grid.size-1 do
			local distance_factor = ((x+xoffset)^2 + (y+yoffset)^2) ^ 0.8
			local amount = math.random(global.grid_ore.ore_random_addition_amount)+global.grid_ore.ore_start_amount + distance_factor
			game.surfaces["nauvis"].create_entity({name=ore, amount=math.random(global.grid_ore.ore_random_addition_amount)+global.grid_ore.ore_start_amount, position={x+xoffset, y+yoffset}})
		end
	end
end

function grid_ore_place_oil_in_grid_chunck(location)
	xoffset = (math.floor(location.x/global.grid.size))*global.grid.size
	yoffset = (math.floor(location.y/global.grid.size))*global.grid.size
	for y=global.grid.y_border_width,global.grid.size-1 do
		for x=global.grid.x_border_width,global.grid.size-1 do
			if math.random(100) < global.grid_ore.oil_spout_chance then
				game.surfaces["nauvis"].create_entity({name="crude-oil", amount=global.grid_ore.oil_start_amount+math.random(global.grid_ore.oil_random_addition_amount), position={x+xoffset, y+yoffset}})
			end
		end
	end
end

function grid_ore_generate_resources(location)
	if(math.random(global.grid_ore.resource_chance ) == 1) then
		rndm = math.random(10)-1
		if(rndm < 1) then
			grid_ore_place_ore_in_grid_chunck(location, "stone")
		elseif (0 < rndm and rndm < 3) then
			grid_ore_place_ore_in_grid_chunck(location, "iron-ore")
		elseif (2 < rndm and rndm < 5) then
			grid_ore_place_ore_in_grid_chunck(location, "copper-ore")
		elseif (4 < rndm and rndm < 6) then
			grid_ore_place_ore_in_grid_chunck(location, "coal")
		elseif (5 < rndm and rndm < 7) then
			grid_ore_place_oil_in_grid_chunck(location)
		elseif (8 < rndm and rndm < 10) then
			grid_ore_place_oil_in_grid_chunck(location, "uranium-ore")
		end
	end
end

function grid_replace_tiles_in_chunk(area)
	local topleftx = area.left_top.x
	local toplefty = area.left_top.y
	local bottomrightx = area.right_bottom.x
	local bottomrighty = area.right_bottom.y
	local tileTable = {}
	for i=toplefty,bottomrighty do
		for j=topleftx,bottomrightx do
			for k=0,global.grid.x_border_width-1 do
				if(j % global.grid.size == k and 
				(((i+global.grid.size/2) % global.grid.size)-(math.floor(global.grid.x_bridge_width/2))) >= global.grid.x_bridge_width) then
					table.insert(tileTable,{ name = "out-of-map", position = {j, i}})
				end
			end
			for k=0,global.grid.y_border_width-1 do
				if(i % global.grid.size == k and 
				(((j+global.grid.size/2) % global.grid.size)-(math.floor(global.grid.y_bridge_width/2))) >= global.grid.y_bridge_width) then
					table.insert(tileTable,{ name = "out-of-map", position = {j, i}})
				end
			end
		end
	end
	game.surfaces["nauvis"].set_tiles(tileTable)
	--Suppress normal resource generation.  Doesn't work because the grid ore is spawned in one big pass.
	-- for _, ore in pairs(game.surfaces[1].find_entities_filtered{type="resource", area=area}) do
	-- 	ore.destroy()
	-- end
	grid_ore_generate_resources({x = topleftx, y=toplefty})
end

Event.register(defines.events.on_chunk_generated, function(event)
	grid_replace_tiles_in_chunk(event.area)
end)

Event.register(defines.events.on_player_created, function(event)
	local p = game.players[event.player_index]
	p.teleport({x = math.floor(global.grid.size/2), y = math.floor(global.grid.size/2)})
end)
-- Event.register('on_init', function(event)
	-- --global.grid_module.seed = normalize(os.time())
	-- randomseed(global.grid_module.seed)
-- end)
