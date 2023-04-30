## Modifications
Movement is confined to a grid
Only objects directly in front of the agent can be interacted with
Objects can only be placed directly in front of the agent
Furnaces are treated as assembly machines - they have recipes and then only accept items that are ingredients in the recipe
All research is completed on start
Agent can see within viewport, a square grid centered around their location
Inserting items into and extracting items from objects happens one at a time, and only with the object currently in front of the agent

## Variables
[viewport] = 16
[tile_count] = 7 (ground, water, stone, coal, iron, copper, uranium)
[object_count] = 14 (wooden chest, transport belt, underground belt, splitter, inserter, power pole, pipe, underground_pipe, boiler, steam engine, burner miner, stone furnace, offshore pump, assembly machine)
[item_count] = 26 (14 + 12) ([object_count] + wood, stone, iron_ore, copper_ore, coal, iron plate, copper plate, steel plate, copper cable, iron gear, iron stick, electronic circuit)

## Observation space
### World Grid
**[[viewport], [viewport], [tile_count]], [[viewport], [viewport], [object_count]], [[viewport], [viewport], [item_count]]**
~11776 (16 * 16 * 46)
Three 2D grids containing information about the world.
1. One-hot list of what tile occupies each location
2. One-hot list of what object occupies each location
3. One-hot list of what the object is producing at each location.  All left as 0 if the location doesn't contain a crafting machine

### Items info
~50
**[item_count], [item_count, 2]**
Two lists containing information about all items
1. Integer list of how many of each item is within the agent's inventory
2. One-hot list of whether each item is craftable

### Object Info
~68
**[object_count], [item_count], [item_count], [3]**
Four lists contianing information about the object being faced
1. One-hot list of what the object is
2. Integer list of what items the object contains
3. One-hot list of what item the object is crafting.  All left as 0 if it's not a crafting machine
3. Boolean list of what items the object needs to craft.  All left as 0 if it's not a crafting machine.  For furnaces, initially blank, then set once a recipe was used
4. Boolean list of statuses of the object.  [0] = Low on item, [1] = Output Full, [2] = No Power

## Action space
### Actions
**[9]**
One-hot list of five actions - [0] = move north, [1] = move east, [2] = move south, [3] = move west, [4] = destroy, [5] = craft, [6] = place, [7] = insert, [8] = extract

## Item decision
**[item_count]**
2. One-hot list of items, used to select what the action should be done on.  Move & Destroy don't care about this list, craft uses it to decide what item to craft, and place, insert, and extract use it to decide what to use for their respective actions.