local universeId = game.GameId
local placeId = game.PlaceId

print("UniverseId:", universeId)
print("PlaceId:", placeId)

local games = {

    [1202096104] = { -- Driving Empire
        places = {

            [3351674303] = "https://raw.githubusercontent.com/YOURNAME/hub/main/scriptLobby.lua",

        }
    }

}

local gameData = games[universeId]

if gameData then

    local scriptUrl = gameData.places[placeId]

    if scriptUrl then

        print("Loading script...")

        local success, err = pcall(function()
            task.spawn(function()
                loadstring(game:HttpGet(scriptUrl))()
            end)
        end)

        if not success then
            warn("Script failed:", err)
        end

    else
        warn("Place not supported:", placeId)
    end

else
    warn("Game not supported:", universeId)
end
