local placeId = game.PlaceId

print("PlaceId:", placeId)

local places = {

    -- Lobby
    [3351674303] = "https://raw.githubusercontent.com/Natakorn1234/NyxHub/refs/heads/main/scripts/Auto%20ATM.lua"

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
