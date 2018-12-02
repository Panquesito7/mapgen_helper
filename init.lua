mapgen_helper = {}

mapgen_helper.mapgen_seed = tonumber(minetest.get_mapgen_setting("seed"))

-- The "sidelen" used in almost every mapgen
mapgen_helper.block_size = tonumber(minetest.get_mapgen_setting("chunksize")) * 16

local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP.."/voxelarea_iterator.lua")
dofile(MP.."/voxeldata.lua")
dofile(MP.."/region_functions.lua")


mapgen_helper.biome_defs = nil
mapgen_helper.get_biome_def = function(biome_id) -- given an id from the biome map, returns a biome definition.
	if mapgen_helper.biome_defs == nil then
		-- First time this was asked for, populate the table.
		-- Biome registration is only done at load time so we don't have to worry about new biomes invalidating this table
		mapgen_helper.biome_defs = {}
		for name, desc in pairs(minetest.registered_biomes) do
			local i = minetest.get_biome_id(desc.name)
			mapgen_helper.biome_defs[i] = desc
		end
	end
	return mapgen_helper.biome_defs[biome_id]
end

-- Returns a consistent list of random points within a volume.
-- Each call to this method will give the same set of points if the same parameters are provided
mapgen_helper.get_random_points = function(minp, maxp, min_output_size, max_output_size)
	local next_seed = math.random(1, 1000000000)
	math.randomseed(minetest.hash_node_position(minp) + mapgen_helper.mapgen_seed)
	
	local count = math.random(min_output_size, max_output_size)
	local result = {}
	while count > 0 do
		local point = {}
		point.x = math.random(minp.x, maxp.x)
		point.y = math.random(minp.y, maxp.y)
		point.z = math.random(minp.z, maxp.z)
		table.insert(result, point)
		count = count - 1
	end
	
	math.randomseed(next_seed)
	return result
end

-- A cheap nearness test, using Manhattan distance.
mapgen_helper.is_within_distance = function(pos1, pos2, distance)
	return math.abs(pos1.x-pos2.x) <= distance and
		math.abs(pos1.y-pos2.y) <= distance and
		math.abs(pos1.z-pos2.z) <= distance
end

-- Finds an intersection between two axis-aligned bounding boxes (AABB)s, or nil if there's no overlap
mapgen_helper.intersect = function(minpos1, maxpos1, minpos2, maxpos2)
	--checking x and z first since they're more likely to fail to overlap
	if minpos1.x <= maxpos2.x and maxpos1.x >= minpos2.x and
		minpos1.z <= maxpos2.z and maxpos1.z >= minpos2.z and
		minpos1.y <= maxpos2.y and maxpos1.y >= minpos2.y then
		
		return {
				x = math.max(minpos1.x, minpos2.x),
				y = math.max(minpos1.y, minpos2.y),
				z = math.max(minpos1.z, minpos2.z)
			},
			{
				x = math.min(maxpos1.x, maxpos2.x),
				y = math.min(maxpos1.y, maxpos2.y),
				z = math.min(maxpos1.z, maxpos2.z)
			}
	end
	return nil, nil
end
