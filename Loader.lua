local universeId = game.GameId

print("UniverseId:", universeId)

local games = {

    [1202096104] = "https://raw.githubusercontent.com/Natakorn1234/NyxHub/refs/heads/main/games/drivingEmpire.lua"

}

local scriptUrl = games[universeId]

if not scriptUrl then
    return warn("Game not supported:", universeId)
end

print("Loading game script...")

local success, err = pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)

if not success then
    warn("Script failed:", err)
end
