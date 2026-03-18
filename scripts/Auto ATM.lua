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
local lastEscape = 0

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

local atSafeSpot = false
local targetATM = nil
local skipATM = {}
local atmList = {}

-------------------------------------------------
-- 🔥 FREEZE (ลอย + ล็อกตัว)
-------------------------------------------------

local function freeze(state)
    if state then
        hrp.Anchored = true
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    else
        hrp.Anchored = false
    end
end

-------------------------------------------------
-- CAMERA
-------------------------------------------------

RunService.RenderStepped:Connect(function()
    if _G.AutoFarm and targetATM and not atSafeSpot and not hrp.Anchored then
        local camPos = targetATM.CFrame * CFrame.new(0,3,-6)
        camera.CFrame = CFrame.lookAt(camPos.Position, targetATM.Position)
    end
end)

-------------------------------------------------
-- ATM CACHE
-------------------------------------------------

local function addATM(model)
    local pos = model:FindFirstChild("Position") or model:FindFirstChild("Position", true)
    if pos then
        table.insert(atmList, pos)
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
-- UTIL
-------------------------------------------------

local function isDanger()
    local myPos = hrp.Position
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Team and p.Team.Name == "Security" then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and (myPos - r.Position).Magnitude < detectDistance then
                return true
            end
        end
    end
    return false
end

local function escape()
    freeze(true)
    hrp.CFrame = safeSpots[math.random(#safeSpots)] + Vector3.new(
        math.random(-20,20),
        math.random(20,50),
        math.random(-20,20)
    )
    camera.CameraType = Enum.CameraType.Custom
    task.wait(1) -- ลอยค้างกันโดนจับ
end

local function getATM()
    for i = #atmList,1,-1 do
        if not atmList[i] or not atmList[i].Parent then
            table.remove(atmList, i)
        end
    end

    local closest, dist = nil, math.huge

    for _,pos in ipairs(atmList) do
        local atm = pos.Parent and pos.Parent:FindFirstChild("ATM")
        if atm and not atm:FindFirstChild("BrokenSurfaceAppearance") and not skipATM[pos] then
            local m = (hrp.Position - pos.Position).Magnitude
            if m < dist then
                dist = m
                closest = pos
            end
        end
    end

    return closest
end

-------------------------------------------------
-- MAIN
-------------------------------------------------

local escaping = false

RunService.Heartbeat:Connect(function()
    if not _G.AutoFarm or escaping then return end

    if isDanger() then
        escaping = true
        lastEscape = tick()

        -- 🔥 ยกเลิกทุกอย่างทันที
        targetATM = nil
        freeze(true)

        hrp.CFrame = safeSpots[math.random(#safeSpots)] + Vector3.new(0, 10, 0)
        camera.CameraType = Enum.CameraType.Custom

        task.wait(0.5) -- ลอยกันจับ

        escaping = false
    end
end)

while _G.AutoFarm do

    local posPart = getATM()

    if posPart then

        freeze(false) -- 🔥 ปลดล็อกก่อนทำงาน

        atSafeSpot = false
        targetATM = posPart

        local atmModel = posPart.Parent

        hrp.CFrame = posPart.CFrame * CFrame.new(0,2,-2)
        hrp.CFrame = CFrame.lookAt(hrp.Position, posPart.Position)

        task.wait(0.25)

        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -0.1)

        local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)

        if prompt then
            local success = false

            for i = 1,3 do

                if not prompt.Enabled then
                    task.wait(0.2)
                end

                prompt:InputHoldBegin()
                local start = tick()

                while tick() - start < prompt.HoldDuration + 0.25 do
                    task.wait(0.7)

                    -- 🚨 หนีกลาง hold
                    if isDanger() and (tick() - start < prompt.HoldDuration - 0.1) then
                        prompt:InputHoldEnd()
                        lastEscape = tick()
                        escape()
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

                if success then
                    task.wait(0.2)
                    break
                end

                task.wait(0.4)
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

        -- 🔥 ขยับตลอด กันโดนวาร์ปจับ
        local base = waitCFrame.Position

        local offset = Vector3.new(
            math.random(-30,30),
            math.random(20,40), -- ลอยสูง
            math.random(-30,30)
        )

        hrp.CFrame = CFrame.new(base + offset)

        task.wait(0.2)
    end
end
