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

-- CONFIG
local detectDistance = 35
local detectDistSq = detectDistance * detectDistance

local waitCFrame = CFrame.new(
-885.639526,243.493607,-1564.73035,
0.944067478,0.232263952,-0.23407279,
4.33200587e-09,0.709844172,0.704358757,
0.329752356,-0.664962173,0.670140803
)

local safeSpots = {
    CFrame.new(-594,378,-918),
    CFrame.new(-564,415,639),
    CFrame.new(-1038,1014,3287),
    CFrame.new(-2174,1437,3818),
    CFrame.new(-1549,579,4837),
    CFrame.new(193,926,3577)
}

local targetATM, atSafeSpot = nil, false
local skipATM, atmList = {}, {}

-------------------------------------------------
-- UTILS
-------------------------------------------------

local function randOffset(xz, y1, y2)
    return Vector3.new(
        math.random(-xz,xz),
        math.random(y1,y2),
        math.random(-xz,xz)
    )
end

local function freeze(state)
    hrp.Anchored = state
    if state then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-------------------------------------------------
-- CAMERA
-------------------------------------------------

RunService.RenderStepped:Connect(function()
    if _G.AutoFarm and targetATM and not atSafeSpot and not hrp.Anchored then
        local cf = targetATM.CFrame
        local camPos = cf * CFrame.new(0,3,-6)
        camera.CFrame = CFrame.lookAt(camPos.Position, cf.Position)
    end
end)

-------------------------------------------------
-- ATM CACHE
-------------------------------------------------

local function addATM(model)
    local pos = model:FindFirstChild("Position") or model:FindFirstChild("Position", true)
    if pos then atmList[#atmList+1] = pos end
end

for _,v in ipairs(spawner:GetDescendants()) do
    if v.Name == "CriminalATM" then addATM(v) end
end

spawner.DescendantAdded:Connect(function(v)
    if v.Name == "CriminalATM" then
        task.defer(addATM, v)
    end
end)

-------------------------------------------------
-- DANGER (optimized)
-------------------------------------------------

local function isDanger()
    local myPos = hrp.Position

    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Team and p.Team.Name == "Security" then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = r.Position - myPos
                if (d.X*d.X + d.Y*d.Y + d.Z*d.Z) < detectDistSq then
                    return true
                end
            end
        end
    end
end

-------------------------------------------------
-- ESCAPE (fast)
-------------------------------------------------

local escaping = false

RunService.Heartbeat:Connect(function()
    if not _G.AutoFarm or escaping then return end
    if not isDanger() then return end

    escaping = true
    targetATM = nil

    freeze(true)

    hrp.CFrame = safeSpots[math.random(#safeSpots)] + randOffset(20,20,50)
    camera.CameraType = Enum.CameraType.Custom

    task.wait(0.6)
    escaping = false
end)

-------------------------------------------------
-- GET ATM (optimized loop)
-------------------------------------------------

local function getATM()
    local myPos = hrp.Position
    local closest, dist = nil, math.huge

    for i = #atmList,1,-1 do
        local pos = atmList[i]

        if not pos or not pos.Parent then
            atmList[i] = atmList[#atmList]
            atmList[#atmList] = nil
        else
            local atm = pos.Parent:FindFirstChild("ATM")
            if atm and not atm:FindFirstChild("BrokenSurfaceAppearance") and not skipATM[pos] then
                local d = (pos.Position - myPos).Magnitude
                if d < dist then
                    dist = d
                    closest = pos
                end
            end
        end
    end

    return closest
end

-------------------------------------------------
-- MAIN
-------------------------------------------------

while _G.AutoFarm do

    local posPart = getATM()

    if posPart then
        freeze(false)
        atSafeSpot = false
        targetATM = posPart

        local atmModel = posPart.Parent

        hrp.CFrame = posPart.CFrame * CFrame.new(0,2,-2)
        hrp.CFrame = CFrame.lookAt(hrp.Position, posPart.Position)

        task.wait(0.2)

        local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)

        if prompt then
            local success = false

            for _ = 1,1 do
                if not prompt.Enabled then task.wait(0.15) end

                prompt:InputHoldBegin()
                local start = tick()

                while tick() - start < prompt.HoldDuration + 0.2 do
                    task.wait(0.05)

                    if isDanger() then
                        prompt:InputHoldEnd()
                        break
                    end

                    local atm = atmModel:FindFirstChild("ATM")
                    if atm and atm:FindFirstChild("BrokenSurfaceAppearance") then
                        skipATM[posPart] = nil
                        success = true
                        break
                    end
                end

                prompt:InputHoldEnd()
                if success then break end

                task.wait(0.25)
            end

            if not success then
                skipATM[posPart] = true
            end
        end

    else
        if not atSafeSpot then
            freeze(true)
            camera.CameraType = Enum.CameraType.Custom
            atSafeSpot = true
        end

        hrp.CFrame = CFrame.new(waitCFrame.Position + randOffset(30,20,40))
        task.wait(0.15)
    end
end
