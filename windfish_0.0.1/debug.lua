-- debug.lua
local debug = {}

function debug.debug_inventory(event)
	--? Debug the name and count of each item within the player inventory
	local player = game.players[1]
    local player_inventory = player.get_main_inventory()
    
    for name, count in pairs(player_inventory.get_contents()) do
        if count > 0 then
            game.print(name .. ": " .. count)
        end
    end
end

return debug