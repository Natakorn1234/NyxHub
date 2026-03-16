_G.AutoFarm = not _G.AutoFarm
print("_G.AutoFarm =", _G.AutoFarm)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
humanoid.AutoRotate = false

plr.CharacterAdded:Connect(function(c)
    char = c
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    humanoid.AutoRotate = false
end)

local spawner = workspace.Game.Jobs.CriminalATMSpawners

-- safe spot
local waitCFrame = CFrame.new(
-885.639526,243.493607,-1564.73035,
0.944067478,0.232263952,-0.23407279,
4.33200587e-09,0.709844172,0.704358757,
0.329752356,-0.664962173,0.670140803
)

local atSafeSpot = false

-- noclip
RunService.Stepped:Connect(function()
    if _G.AutoFarm then
        for _,v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if _G.AutoFarm and targetATM then
        local camPos = targetATM.CFrame * CFrame.new(0,3,-6)

        camera.CFrame = CFrame.lookAt(
            camPos.Position,
            targetATM.Position
        )
    end
end)

-------------------------------------------------
-- ATM CACHE SYSTEM (เร็วกว่า GetDescendants)
-------------------------------------------------

local atmList = {}
local targetATM = nil
local skipATM = {}

local function addATM(model)

    local pos = model:FindFirstChild("Position")

    if not pos then
        pos = model:FindFirstChild("Position", true)
    end

    if pos then
        table.insert(atmList,pos)
    end
end

for _,v in pairs(spawner:GetDescendants()) do
    if v.Name == "CriminalATM" then
        addATM(v)
    end
end

spawner.DescendantAdded:Connect(function(v)
    if v.Name == "CriminalATM" then
        task.wait()
        addATM(v)
    end
end)

-------------------------------------------------

local function getATM()

    for i = #atmList,1,-1 do
        local pos = atmList[i]

        if not pos or not pos.Parent then
            table.remove(atmList, i)
        end 
    end

    local closest = nil
    local closestDist = math.huge

    for _,pos in ipairs(atmList) do

        if pos.Parent then

            local atm = pos.Parent:FindFirstChild("ATM")

            if atm and not atm:FindFirstChild("BrokenSurfaceAppearance") and not skipATM[pos] then

                local dist = (hrp.Position - pos.Position).Magnitude

                if dist < closestDist then
                    closestDist = dist
                    closest = pos
                end

            end

        end

    end

    return closest

end

-------------------------------------------------

while _G.AutoFarm do

    local posPart = getATM()

    if posPart then

        atSafeSpot = false

        local atmModel = posPart.Parent
        targetATM = posPart
        
        local standCFrame = posPart.CFrame * CFrame.new(0,2,-2)

        hrp.CFrame = standCFrame
        hrp.CFrame = CFrame.lookAt(hrp.Position, posPart.Position)

        local camPos = posPart.CFrame * CFrame.new(0,3,-6)

        camera.CFrame = CFrame.lookAt(
            camPos.Position,
            posPart.Position
        )

        task.wait(0.25)

        -- refresh proximity
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -0.1)

        local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt",true)

if prompt then

    local success = false

    for i = 1,3 do -- retry สูงสุด 3 ครั้ง

        if not prompt.Enabled then
            task.wait(0.2)
        end 
        
        prompt:InputHoldBegin()

        local start = tick()

        while tick() - start < prompt.HoldDuration + 0.25 do
            task.wait(0.05)

            local atm = atmModel:FindFirstChild("ATM")
            if atm and atm:FindFirstChild("BrokenSurfaceAppearance") then
                skipATM[posPart] = nil
                success = true
                break
            end
        end

        prompt:InputHoldEnd()

        if success then
            task.wait(0.2)
            break
        end

        task.wait(0.4) -- รอก่อน retry
    end

    if not success then
        skipATM[posPart] = true
    end 

end

    else

        if not atSafeSpot then
            hrp.CFrame = waitCFrame
            atSafeSpot = true
        end

        task.wait(0.5)

    end

end