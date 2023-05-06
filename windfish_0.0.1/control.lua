utils = require("utils")
debug = require("debug")
json = require("json")

--* INITIALIZATION -----------------------------------------------------------------------
-- All items that the agent can have in their inventory
items = {
	"wood",
	"stone",
	"coal",
	"iron-ore",
	"copper-ore",
	"iron-plate",
	"copper-plate",
	"steel-plate",
	"copper-cable",
	"iron-stick",
	"iron-gear-wheel",
	"electronic-circuit",
	"wooden-chest",
	"transport-belt",
	"underground-belt",
	"splitter",
	"inserter",
	"small-electric-pole",
	"pipe",
	"pipe-to-ground",
	"boiler",
	"steam-engine",
	"burner-mining-drill",
	"stone-furnace",
	"offshore-pump",
	"assembling-machine-1",
	"water"
}

-- All placable objects
placable_objects = {
	"wooden-chest",
	"transport-belt",
	"underground-belt",
	"splitter",
	"inserter",
	"small-electric-pole",
	"pipe",
	"pipe-to-ground",
	"boiler",
	"steam-engine",
	"burner-mining-drill",
	"stone-furnace",
	"offshore-pump",
	"assembling-machine-1"
}

crafting_machines = {
	"assembling-machine-1",
    "assembling-machine-2",
    "assembling-machine-3",
    "stone-furnace",
    "steel-furnace",
    "electric-furnace"
}

objects = {
	"wooden-chest",
	"transport-belt",
	"underground-belt",
	"splitter",
	"inserter",
	"small-electric-pole",
	"pipe",
	"pipe-to-ground",
	"boiler",
	"steam-engine",
	"burner-mining-drill",
	"stone-furnace",
	"offshore-pump",
	"assembling-machine-1",
	"cliff",
	"tree-*",
	"item-on-ground"
}

-- All Tiles
tiles = {
	"ground",
	"water",
	"stone",
	"coal",
	"iron-ore",
	"copper-ore",
}

--? Global variables
VIEWPORT_SIZE = 32
OUTPUT_PATH = "windfish-data/"
BOT_MODE = false

--? World variables
world_grid = {}
object_info = {}

--? Agent variables
agent_x = 0
agent_y = 0
agent_dir_x = 0
agent_dir_y = 1

agent_inventory = {}
-- One inventory slot per item
for _, item in ipairs(items) do
	agent_inventory[item] = 0
end

--* RETURN FUNCTION ----------------------------------------------------------------------
function generate_state(event)
	--? Generates the current state, then prints it to RCON for the interface to parse
	data_world()
	data_object()
	data_inventory()

	rcon.print(json.encode(world_grid))
	rcon.print(json.encode(object_info))
	rcon.print(json.encode(agent_inventory))
end

--* DATA FUNCTIONS -----------------------------------------------------------------------
function data_world()
	--? Update the world_info table to reflect the tiles and objects surrounding the player

	local player = game.players[1]

	local surface = player.surface
    local position = player.position
    local start_x = math.floor(position.x - VIEWPORT_SIZE / 2)
    local start_y = math.floor(position.y - VIEWPORT_SIZE / 2)

	local item_count = #items

	world_grid = {
		tiles = {},
		objects = {},
		production = {},
		state = {}
	}

	-- Initialize and populate the 2D grids
    for i = 1, VIEWPORT_SIZE do
        world_grid.tiles[i] = {}
        world_grid.objects[i] = {}
        world_grid.production[i] = {}
		world_grid.state[i] = {}

        for j = 1, VIEWPORT_SIZE do
            world_grid.tiles[i][j] = {}
            world_grid.objects[i][j] = {}
            world_grid.production[i][j] = {}
			world_grid.state[i][j] = {}

            -- Get tile and object information at the current position
            local x, y = start_x + i - 1, start_y + j - 1
            local current_tile = surface.get_tile(x, y)
            local current_objects = surface.find_entities_filtered({area = {{x, y}, {x + 1, y + 1}}})

            -- Populate the one-hot list for tiles
			tile_found = false
            for k, tile in ipairs(tiles) do
				-- Check for resource entities in case the tile is an ore patch
				entity_found = false
				for _, entity in ipairs(current_objects) do
					if entity.type == "resource" and entity.name == tile then
						world_grid.tiles[i][j][k] = 1
						tile_found = true
						entity_found = true
						break
					end
				end
				
				-- If an entity was found, avoid overwriting it with a tile and exit the loop
				if entity_found then
					break
				end

				-- If no resource tiles are found, then use the tile
				if current_tile.name == tile then
                	world_grid.tiles[i][j][k] = 1
					tile_found = true
					break
				end
				
				-- If nothing is found, set this one-hot item to zero since there were no 
				-- matches for this tile at this location
				world_grid.tiles[i][j][k] = 0
            end
			
			--! As a fallback, if not tile is matched, use the ground tile
			if tile_found == false then
				world_grid.tiles[i][j][1] = 1
			end

            -- Populate the encoding list for objects
            for k, object in ipairs(objects) do
                local found_object = false
                for _, entity in ipairs(current_objects) do

                    if entity.name == object then
						-- generic test to see if the entity is within the objects list
                        found_object = true
                        break
					elseif object == "tree-*" and utils.split_string(entity.name, "-")[1] == "tree" then
						-- specific test to see if the entity is a tree
						found_object = true
						break
					end
                end
				if found_object then
                	world_grid.objects[i][j][k] = 1
				else
					world_grid.objects[i][j][k] = 0
				end
            end

            -- Populate the one-hot list for production
			local crafting_entity = nil
			for _, entity in ipairs(current_objects) do
				if utils.contains(crafting_machines, entity.name) then
					crafting_entity = entity
					break
				end
			end

			if crafting_entity then
				local current_recipe = crafting_entity.get_recipe()
				if current_recipe then
					local product_name = current_recipe.products[1].name
					for k, item in ipairs(items) do
						if product_name == item then
							world_grid.production[i][j][k] = 1
						else
							world_grid.production[i][j][k] = 0
						end
					end
				else
					for k = 1, #items do
						world_grid.production[i][j][k] = 0
					end
				end
			else
				for k = 1, #items do
					world_grid.production[i][j][k] = 0
				end
			end

			-- Populate the state table
			for k = 1, 8 do
				world_grid.state[i][j][k] = 0
			end

			local target_entity = nil
			for _, entity in ipairs(current_objects) do
				if entity.name ~= "character" then
					target_entity = entity
				end
			end

			if target_entity then
				local direction = target_entity.direction

				-- Set orientation
				if direction == defines.direction.north then
					world_grid.state[i][j][1] = 1
				elseif direction == defines.direction.east then
					world_grid.state[i][j][2] = 1
				elseif direction == defines.direction.south then
					world_grid.state[i][j][3] = 1
				elseif direction == defines.direction.west then
					world_grid.state[i][j][4] = 1
				end
	
				-- Check if low on item
				if utils.contains(crafting_machines, target_entity.name) and target_entity.get_item_count() < 10 then
					world_grid.state[i][j][5] = 1
				end
	
				-- Check if output is full
				if target_entity.get_output_inventory() and target_entity.get_output_inventory().is_full() then
					world_grid.state[i][j][6] = 1
				end
	
				-- Check if no fuel
				if target_entity.burner and not target_entity.burner.currently_burning then
					world_grid.state[i][j][7] = 1
				end
	
				-- Check if no power
				if target_entity.energy and target_entity.electric_buffer_size and target_entity.energy < target_entity.electric_buffer_size then
					world_grid.state[i][j][8] = 1
				end
			end
        end
    end
end

function data_inventory()
	--? Update the agent_inventory table to reflect how many of each item are within the player's inventory 
	agent_inventory = {}

	local player = game.players[1]
	local player_inventory = player.get_main_inventory().get_contents()

	for item, value in pairs(player_inventory) do
		if utils.contains(items, item) then
			agent_inventory[item] = value
		end
	end
end

function data_object()
	--? Update the object_info table to reflect the state of the object currently being faced
	object_info = {
		object = {},
		items = {},
		needed_items = {}
	}

	local player = game.players[1]
	local surface = player.surface
    local position = player.position

	local x = agent_x + agent_dir_x
	local y = agent_y + agent_dir_y

	local facing_entities = surface.find_entities_filtered({area = {{x, y}, {x + 1, y + 1}}})
	local target_entity = nil
	for _, entity in ipairs(facing_entities) do
		if entity.name ~= "character" then
			target_entity = entity
		end
	end

	if target_entity then
		-- 1. One-hot list of what the object is
		for i, obj in ipairs(objects) do
			object_info.object[i] = target_entity.name == obj and 1 or 0
		end
	
		-- 2. Integer list of what items the object contains
		if target_entity.type == "container" then
			local contents = target_entity.get_inventory(defines.inventory.chest).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or 0
			end

		elseif target_entity.type == "furnace" then
			local contents = target_entity.get_inventory(defines.inventory.fuel).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or 0
			end

			contents = target_entity.get_inventory(defines.inventory.furnace_source).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or object_info.items[i]
			end

			contents = target_entity.get_inventory(defines.inventory.furnace_result).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or object_info.items[i]
			end

		elseif target_entity.type == "assembling-machine" then
			local contents = target_entity.get_inventory(defines.inventory.assembling_machine_input).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or 0
			end

			contents = target_entity.get_inventory(defines.inventory.assembling_machine_output).get_contents()
			for i, item in ipairs(items) do
				object_info.items[i] = contents[item] or object_info.items[i]
			end

		elseif target_entity.type == "transport-belt" then
			local left_line = target_entity.get_transport_line(1)
			local right_line = target_entity.get_transport_line(2)

			local left_line_contents = left_line.get_contents()
			local right_line_contents = right_line.get_contents()

			for i, item in ipairs(items) do
				object_info.items[i] = left_line_contents[item] or 0
			end

			for i, item in ipairs(items) do
				if right_line_contents[item] then
					object_info.items[i] = object_info.items[i] + right_line_contents[item]
				end
			end

		elseif target_entity.type == "pipe-to-ground" or target_entity.type == "pipe" then
			local fluid = target_entity.fluidbox[1]

			for i, item in ipairs(items) do
				if fluid.name == item then
					object_info.items[i] = fluid.amount
				else
					object_info.items[i] = 0
				end
			end

		end
	
		-- 4. Integer list of what items the object needs to craft
		if target_entity.type == "assembling-machine" or target_entity.type == "furnace" then
			local recipe = target_entity.get_recipe()
			if recipe then
				for i, item in ipairs(items) do
					object_info.needed_items[i] = 0
					for j, ingredient in ipairs(recipe.ingredients) do
						if ingredient.name == item then
							object_info.needed_items[i] = ingredient.amount
							break
						end
					end
				end
			end
		end
	end
end

--* RCON FUNCTIONS -----------------------------------------------------------------------
function rcon_test(foo)
	game.print("RCON Test successful: "..foo)
	return foo
end

function move(action_id)
	--? Update the agent's direction based on the passed action_id integer, then move the agent
	if action_id == 0 then -- North
		agent_dir_x = 0
		agent_dir_y = 1
	elseif action_id == 1 then -- East
		agent_dir_x = 1
		agent_dir_y = 0
	elseif action_id == 2 then -- South
		agent_dir_x = 0
		agent_dir_y = -1
	elseif action_id == 3 then -- West
		agent_dir_x = -1
		agent_dir_y = 0
	end

	agent_x = agent_x + agent_dir_x
	agent_y = agent_y + agent_dir_y
end

function mine()
	--? Check if there's an object or tile in front of the agent, then mine it if so
	local player = game.players[1]
    local surface = player.surface

	-- mine an entity
	local x = agent_x + agent_dir_x
	local y = agent_y + agent_dir_y
	local found_entities = surface.find_entities_filtered({area = {{x, y}, {x + 1, y + 1}}})
	for _, entity in ipairs(found_entities) do
        if entity.name ~= "character" and entity.valid and entity.destructible then
            local result = player.mine_entity(entity)
			return
        end
    end

	-- mine a tile
	local found_tile = surface.get_tile(x, y)
	local result = player.mine_tile(found_tile)
		
	if result then
		return
	end

	rcon.print("Mine Failed")
end

function craft(item_id)
	--? Try to craft the provided item
	local player = game.players[1]
    local item = items[item_id]

	if player.force.recipes[item] then
    	player.begin_crafting({count = 1, recipe = item})
		return
	end
	rcon.print("Craft Failed")
end

function place(action_id, item_id)
	--? Try to place the provided item in front of the agent
	local player = game.players[1]
    local surface = player.surface

	local x = agent_x + agent_dir_x
	local y = agent_y + agent_dir_y
	local place_position = {x=x, y=y}

	local direction = defines.direction.north
	if action_id == 7 then
		direction = defines.direction.east
	elseif action_id == 8 then
		direction = defines.direction.south
	elseif action_id == 9 then
		direction = defines.direction.west
	end

	local item = items[item_id]
	if player.get_item_count(item) > 0 then
        local created_entity = surface.create_entity({name = item, direction = direction, position = place_position, force = player.force})
        if created_entity then
            player.remove_item({name = item, count = 1})
			return
        end
    end

	rcon.print("Failed place")
end

function insert(item_id)
	--? Try to insert one of the provided item into the object in front of the agent
	local player = game.players[1]
    local surface = player.surface

	local x = agent_x + agent_dir_x
	local y = agent_y + agent_dir_y
	local found_entities = surface.find_entities_filtered({area = {{x, y}, {x + 1, y + 1}}})

	local item = items[item_id]
	if player.get_item_count(item) == 0 then
		rcon.print("Failed insert")
		return
	end

    for _, entity in ipairs(found_entities) do
		if entity.type == "container" or
			entity.type == "furnace" or
			entity.type == "assembling-machine" 
		then
			local inserted = entity.insert({name = item, count = 1})
			if inserted > 0 then
				player.remove_item({name = item, count = inserted})
				return
			end

		end
    end

	rcon.print("Failed insert")
end

function extract(item_id)
	--? Try to extract one of the provided items from the object in front of the agent
	local player = game.players[1]
    local surface = player.surface

	local x = agent_x + agent_dir_x
	local y = agent_y + agent_dir_y
	local found_entities = surface.find_entities_filtered({area = {{x, y}, {x + 1, y + 1}}})
	
	local item = items[item_id]

	for _, entity in ipairs(found_entities) do
		if entity.type == "container" or
			entity.type == "furnace" or
			entity.type == "assembling-machine" 
		then
			local extracted = entity.remove_item({name = item, count = 1})
            if extracted > 0 then
                player.insert({name = item, count = extracted})
				return
            end
		end
    end

	rcon.print("Failed extract")
end

function tick()
	local player = game.players[1]
	player.teleport({x= agent_x, y= agent_y})

	if BOT_MODE then
		game.ticks_to_run = 30
	end
end

function rcon_act(event)
	local params = utils.split_string(event.parameter, " ")
	local action_id = tonumber(params[1])
	local item_id = tonumber(params[2])

	if action_id <= 3 then
		move(action_id)
	elseif action_id == 4 then
		mine()
	elseif action_id == 5 then
		craft(item_id)
	elseif action_id <= 9 then
		place(action_id, item_id)
	elseif action_id == 10 then
		insert(item_id)
	elseif action_id == 11 then
		extract(item_id)
	else
		rcon.print("Unknown action")
	end	

	tick()
end

function rcon_toggle_bot(event)
	--? Toggle bot mode - game speed is increased and ticks progress manually

	local param = event.parameter

	if param == "true" then
		game.speed = 10000
		game.tick_paused = true
		game.autosave_enabled = false
		BOT_MODE = true
	else
		game.speed = 1
		game.tick_paused = false
		game.autosave_enabled = true
		BOT_MODE = false
	end
end

function rcon_reset_pos(event)
	local player = game.players[1]
	agent_x = math.floor(player.position.x)
	agent_y = math.floor(player.position.y)
	agent_dir_x = 0
	agent_dir_y = 1
end

--* Registration -------------------------------------------------------------------------
remote.add_interface("windfish", {
	test=rcon_test,
})

commands.add_command(
	"debug-inventory", 
	"Print out the names and counts of each item within the player inventory", 
	debug.debug_inventory
)

commands.add_command(
	"windfish-state", 
	"Generate the current agent state, then print the results to rcon", 
	generate_state
)

commands.add_command(
	"windfish-act", 
	"Attempt to preform an action.  RCON return is used to signify failure to preform the action", 
	rcon_act
)

commands.add_command(
	"windfish-toggle-botmode", 
	"Toggle botmode. Botmode pauses ticks and makes game.speed very high", 
	rcon_toggle_bot
)

commands.add_command(
	"windfish-reset-pos",
	"Reset the agent position to the current player position, snapped to grid",
	rcon_reset_pos
)