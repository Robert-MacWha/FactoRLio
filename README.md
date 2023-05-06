## Factorio Setup
In order to use RCON with factorio, you need to enable the option:
1. On the main menu enter "the rest" by selecting settings while *ctrl+alt* are held. 
2. Scroll down to the local-rcon options and set the following:
    - local-rcon-socket: "127.0.0.1:41941"
    - local-rcon-password: "rcon"
3. Confirm and exit
4. Test the connecting by sending the command `"/c remote.call('windfish', 'test', 'Hello World!')"` with factorio_rcon

From there launch a new or existing world.  Rcon seems to work in both singleplayer and local multiplayer.

## Modifications
Movement is confined to a grid
Only objects directly in front of the agent can be interacted with
Objects can only be placed directly in front of the agent
Furnaces are treated as assembly machines - they have recipes and then only accept items that are ingredients in the recipe
All research is completed on start
Agent can see within viewport, a square grid centered around their location
Inserting items into and extracting items from objects happens one at a time, and only with the object currently in front of the agent
Uranium is not currently included, so uranium tiles are treated as regular ground tiles

## Variables
[viewport] = 16
[tile_count] = 7 (ground, water, stone, coal, iron, copper, uranium)
[object_count] = 14 (wooden chest, transport belt, underground belt, splitter, inserter, power pole, pipe, underground_pipe, boiler, steam engine, burner miner, stone furnace, offshore pump, assembly machine)
[item_count] = 26 (14 + 12) ([object_count] + wood, stone, iron_ore, copper_ore, coal, iron plate, copper plate, steel plate, copper cable, iron gear, iron stick, electronic circuit)

## Observation space
### World Grid
**[[viewport], [viewport], [tile_count]], [[viewport], [viewport], [object_count]], [[viewport], [viewport], [4]], [[viewport], [viewport], [item_count]], [[viewport], [viewport], [4]]**
~14080 (16 * 16 * 55)
2D grids containing information about the world.
1. One-hot list of what tile occupies each location
2. One-hot list of what object occupies each location
3. One-hot list of what is being produced by an object at each location
5. Boolean list of orientation & statuses of the placed objects at each location.  [1] = North, [2] = East, [3] = South, [4] = West, [5] = Low on item, [6] = Output Full, [7] = No Fuel, [8] = No Power

### Items info
~50
**[item_count], [item_count, 2]**
Two lists containing information about all items
1. Integer list of how many of each item is within the agent's inventory
2. One-hot list of whether each item is craftable

### Object Info
~68
**[object_count], [item_count], [item_count]**
Four lists contianing information about the object being faced
1. One-hot list of what the object is
2. Integer list of what items the object contains
3. One-hot list of what item the object is crafting.  All left as 0 if it's not a crafting machine
4. Integer list of what items the object needs to craft.  All left as 0 if it's not a crafting machine.  For furnaces, initially blank, then set once a recipe was used


## Action space
### Actions
**[9]**
One-hot list of five actions - [0] = move north, [1] = move east, [2] = move south, [3] = move west, [4] = destroy, [5] = craft, [6] = place, [7] = insert, [8] = extract

## Item decision
**[item_count]**
2. One-hot list of items, used to select what the action should be done on.  Move & Destroy don't care about this list, craft uses it to decide what item to craft, and place, insert, and extract use it to decide what to use for their respective actions.