local placeId = game.PlaceId

print("PlaceId:", placeId)

local places = {

    -- Lobby
    [3351674303] = "https://raw.githubusercontent.com/YOURNAME/hub/main/scripts/atmFarm.lua"

}

local scriptUrl = places[placeId]

if not scriptUrl then
    return warn("Place not supported:", placeId)
end

print("Loading place script...")

local success, err = pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)

if not success then
    warn("Script failed:", err)
end