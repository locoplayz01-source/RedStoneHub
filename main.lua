if _G.RedstoneHubLoaded then
    local env = (getgenv and getgenv()) or _G
    if not env.ForceReload then return end
    env.ForceReload = false
end
_G.RedstoneHubLoaded = true

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local CommF = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("CommF_")

_G.Mode = _G.Mode or "Capitán"
_G.AutoLeviathanFull = false
_G.StopTween = false
_G.SilentAim = _G.SilentAim ~= false
_G.SelectWeapon = _G.SelectWeapon or "Sword"
_G.SkillMelee = _G.SkillMelee or {"Z", "X", "C"}
_G.SkillSword = _G.SkillSword or {"Z", "X"}
_G.SkillFruit = _G.SkillFruit or {"X"}
_G.SkillGun = _G.SkillGun or {"Z", "X"}
_G.AutoBuso = _G.AutoBuso ~= false
_G.FastAttack = _G.FastAttack or false
_G.DragonGunFarm = _G.DragonGunFarm or false
_G.DragonGunLeviathan = _G.DragonGunLeviathan or false
_G.FPSBoost = _G.FPSBoost or false
_G.AutoV3 = _G.AutoV3 or false
_G.AutoV4 = _G.AutoV4 or false
_G.BoatHeight = _G.BoatHeight or 150
_G.BoatSpeed = _G.BoatSpeed or 250
_G.PlayerTweenSpeed = _G.PlayerTweenSpeed or 275
_G.ReturnMode = _G.ReturnMode or "Boat"
_G.LeviathanDestination = _G.LeviathanDestination or "Tiki"
_G.AutoCraftScrolls = _G.AutoCraftScrolls or false
_G.AutoStoreFruits = _G.AutoStoreFruits or false
_G.HuntFightEvents = _G.HuntFightEvents or false
_G.SoloSeaFarm = _G.SoloSeaFarm or false
_G.RespawnRebuy = _G.RespawnRebuy or false
_G.CruiseReturn = _G.CruiseReturn or true
_G.WebhookURL = _G.WebhookURL or ""
_G.WebhookUsername = _G.WebhookUsername or "Redstone Hub"
_G.AutoWebhook = _G.AutoWebhook or false
_G.WebhookInterval = _G.WebhookInterval or 60

local Character = LocalPlayer.Character
local HD = Character and Character:FindFirstChild("Humanoid")
local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
local CurrentTween = nil
local LastAttackTime = 0
local SkillCoolDown = false
local AttackSeedCache, AttackSeedAt = nil, 0
local AttackNet, AttackRegisterAttack, AttackRegisterHit, AttackSeedRemote = nil, nil, nil, nil
local AttackObfuscatedRemote, AttackObfuscatedId = nil, nil
local FightTarget = nil
local AttackModel = nil
local AttackStandFn = nil
local StatusText = "Not Started"

local function SetStatus(s) StatusText = s end

local function GetCharacterParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local NoclipOn = false
local LastNoclipApply = 0

local function NoClip(v)
    if not Character or not HRP or not HD or HD.Health <= 0 then return end
    if v then
        if NoclipOn and os.clock() - LastNoclipApply < 0.5 then return end
        NoclipOn = true
        LastNoclipApply = os.clock()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    else
        NoclipOn = false
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

local Tweening = false
local TWEEN_PART_NAME = "RedstoneTweenPart"
local HoldCFrame = nil
local LiveHoldFn = nil
local TpActive = false

local function GetTweenPart()
    local part = workspace:FindFirstChild(TWEEN_PART_NAME)
    if part and part:IsA("BasePart") then return part end
    part = Instance.new("Part")
    part.Name = TWEEN_PART_NAME
    part.Size = Vector3.new(1, 1, 1)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Massless = true
    part.Transparency = 1
    part.Parent = workspace
    return part
end

local function StandUpFromSeat(seat, hum, hrp)
    local char = LocalPlayer.Character
    if not hum then return false end
    if seat then
        pcall(function()
            local Weld = seat:FindFirstChild("SeatWeld")
            local p1 = Weld and Weld.Part1
            if Weld and ((not p1) or (p1:IsA("BasePart") and char and p1:IsDescendantOf(char))) then Weld:Destroy() end
        end)
        pcall(function()
            for _, d in ipairs(seat:GetDescendants()) do
                if d:IsA("Weld") or d:IsA("WeldConstraint") then
                    local p0, p1 = d.Part0, d.Part1
                    if char and ((p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char))) then d:Destroy() end
                end
            end
        end)
        local SeatRoot = seat.Parent
        if SeatRoot and SeatRoot ~= workspace then
            pcall(function()
                for _, d in ipairs(SeatRoot:GetDescendants()) do
                    if d:IsA("Weld") or d:IsA("WeldConstraint") then
                        local p0, p1 = d.Part0, d.Part1
                        if char and ((p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char))) then d:Destroy() end
                    end
                end
            end)
        end
    end
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Weld") or d:IsA("WeldConstraint") then
                local p0, p1 = d.Part0, d.Part1
                local IsSeatWeld = d.Name == "SeatWeld" or (p0 ~= nil and p0:IsA("Seat")) or (p1 ~= nil and p1:IsA("Seat"))
                if IsSeatWeld then pcall(function() d:Destroy() end) end
            end
        end
    end
    pcall(function()
        hum.Sit = false
        hum.PlatformStand = false
        hum.Jump = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
    if hrp then
        pcall(function()
            hrp.Anchored = false
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 25, 0)
        end)
    end
    return true
end

local function _tp(targetPos, abortCheck)
    local startChar = LocalPlayer.Character
    local myHRP = select(2, GetCharacterParts())
    if not myHRP or _G.StopTween then return false end
    local targetCFrame, liveTarget
    if typeof(targetPos) == "function" then
        targetCFrame = targetPos()
        if not targetCFrame then return false end
        liveTarget = targetPos
    elseif typeof(targetPos) == "Vector3" then targetCFrame = CFrame.new(targetPos)
    elseif typeof(targetPos) == "CFrame" then targetCFrame = targetPos
    elseif typeof(targetPos) == "Instance" and targetPos:IsA("BasePart") then targetCFrame = targetPos.CFrame
    else return false end
    if targetCFrame.Position.Y < 0 then return false end
    HoldCFrame = nil
    LiveHoldFn = nil
    local _, _, humS = GetCharacterParts()
    if humS and (humS.Sit or humS.SeatPart ~= nil) then
        StandUpFromSeat(humS.SeatPart, humS, myHRP)
        task.wait(0.2)
    end
    local part = GetTweenPart()
    part.CFrame = myHRP.CFrame
    NoClip(true)
    local tweenSpeed = _G.PlayerTweenSpeed or 140
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    local tween = nil
    if not liveTarget then
        local distance = (targetCFrame.Position - myHRP.Position).Magnitude
        local duration = math.max(distance / tweenSpeed, 0.05)
        tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = targetCFrame })
        CurrentTween = tween
    end
    Tweening = true
    TpActive = true
    local aborted = false
    local arrived = false
    local seatedStop = false
    local nextAbortAt = 0
    local connection
    connection = RunService.Stepped:Connect(function(_, deltaTime)
        local dt = deltaTime or (1 / 60)
        local curChar = LocalPlayer.Character
        local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")
        local curHRP = select(2, GetCharacterParts())
        if not curHRP or curChar ~= startChar or not curHum or curHum.Health <= 0 then
            aborted = true
            if tween then tween:Cancel() end
        else
            if not seatedStop and curHum.SeatPart ~= nil then
                seatedStop = true
                arrived = true
                if tween then tween:Cancel() end
            end
            if not seatedStop then
                if liveTarget then
                    local tgt = liveTarget()
                    if tgt and tgt.Position.Y < 0 then
                        aborted = true
                        if tween then tween:Cancel() end
                    elseif tgt then
                        local cur = part.Position
                        local delta = tgt.Position - cur
                        local dist = delta.Magnitude
                        if dist <= 5 then arrived = true
                        else part.CFrame = CFrame.new(cur + delta.Unit * math.min(dist, tweenSpeed * dt)) * (part.CFrame - part.CFrame.Position) end
                    end
                end
                if not aborted then
                    curHRP.CFrame = part.CFrame
                    curHRP.AssemblyLinearVelocity = Vector3.zero
                    for _, p in ipairs(curChar:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end
        if abortCheck and not aborted then
            local now = tick()
            if now >= nextAbortAt then
                nextAbortAt = now + 0.1
                local ok, stop = pcall(abortCheck)
                if ok and stop then
                    aborted = true
                    if tween then tween:Cancel() end
                end
            end
        end
    end)
    pcall(function()
        if liveTarget then
            local timeout = tick() + math.max(8, (targetCFrame.Position - myHRP.Position).Magnitude / tweenSpeed + 8)
            repeat task.wait() until arrived or aborted or tick() > timeout
        elseif tween then
            tween:Play()
            repeat task.wait() until seatedStop or aborted or tween.PlaybackState ~= Enum.PlaybackState.Playing
        end
    end)
    pcall(function() connection:Disconnect() end)
    if tween and CurrentTween == tween then CurrentTween = nil end
    Tweening = false
    TpActive = false
    if not aborted and not seatedStop then
        if liveTarget then
            LiveHoldFn = liveTarget
            HoldCFrame = nil
        else
            LiveHoldFn = nil
            HoldCFrame = targetCFrame
        end
    end
    return not aborted
end

RunService.Heartbeat:Connect(function(dt)
    if _G.StopTween then return end
    local _, hrp, hum = GetCharacterParts()
    if not hrp or (hum and hum.SeatPart ~= nil) or TpActive then return end
    if CurrentTween and CurrentTween.PlaybackState == Enum.PlaybackState.Playing then return end
    local goal = nil
    if AttackModel then
        if not AttackModel.Parent then
            AttackModel, AttackStandFn = nil, nil
        else
            local ok, cf = pcall(AttackStandFn)
            if ok and cf then
                if cf.Position.Y < 0 then AttackModel, AttackStandFn = nil, nil
                else goal = cf end
            end
        end
    end
    if not goal and LiveHoldFn then
        local ok, cf = pcall(LiveHoldFn)
        if ok and cf and cf.Position.Y >= 0 then goal = cf end
    end
    if not goal then goal = HoldCFrame end
    if not goal or goal.Position.Y < 0 then return end
    if not LiveHoldFn then HoldCFrame = goal end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local dist = (goal.Position - hrp.Position).Magnitude
    if dist <= 3 then hrp.CFrame = goal
    else
        local step = math.min(dist, (_G.PlayerTweenSpeed or 140) * (dt or (1 / 60)))
        hrp.CFrame = hrp.CFrame:Lerp(goal, step / dist)
    end
end)

local function StopTweenAll()
    _G.StopTween = true
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    Tweening = false
    TpActive = false
    NoClip(false)
    HoldCFrame = nil
    LiveHoldFn = nil
    task.defer(function()
        task.wait(0.1)
        _G.StopTween = false
    end)
end

local function CheckItem(Item, Mode)
    if not Character or not HRP or not HD then return nil end
    if Mode == "Find" then
        for _, v in ipairs(Character:GetChildren()) do
            if string.find(v.Name, Item, 1, true) then return v end
        end
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if string.find(v.Name, Item, 1, true) then return v end
        end
    else
        return Character:FindFirstChild(Item) or LocalPlayer.Backpack:FindFirstChild(Item)
    end
end

function CheckSkill(Weapon, Key)
    local ok, result = pcall(function()
        local Item = CheckItem(Weapon)
        if not Item then return false end
        local Weapon2 = Item.ToolTip
        local Skills = nil
        if Weapon2 == "Melee" then Skills = _G.SkillMelee
        elseif Weapon2 == "Sword" then Skills = _G.SkillSword
        elseif Weapon2 == "Blox Fruit" then Skills = _G.SkillFruit
        elseif Weapon2 == "Gun" then Skills = _G.SkillGun end
        if not Skills then return false end
        for _, v in ipairs(Skills) do
            if v == Key then return true end
        end
        return false
    end)
    return ok and result
end

local function Equip_Auto(Tool)
    if not Character or not HRP or not HD then return end
    if HD.Health > 0 and LocalPlayer:FindFirstChild("Backpack") then
        if Tool == "Melee" or Tool == "Sword" or Tool == "Gun" or Tool == "Blox Fruit" then
            for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                if v.ToolTip == Tool then HD:EquipTool(v) break end
            end
        else
            for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                if v.Name == Tool then HD:EquipTool(v) break end
            end
        end
    end
end

function HasDragonstormEquipped()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local tool = hum and hum:FindFirstChildOfClass("Tool")
    return tool ~= nil and tool.Name == "Dragonstorm"
end

local function Skill_Auto(Key)
    local code = Enum.KeyCode[tostring(Key):upper()]
    if not code then return end
    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        task.wait(0.3)
    end)
    pcall(function() VirtualInputManager:SendKeyEvent(false, code, false, game) end)
    if not ok then error(err) end
end

local function Haki_Auto()
    if not _G.AutoBuso then return end
    if Character and HRP then
        if not Character:FindFirstChild("HasBuso") then pcall(function() CommF:InvokeServer("Buso") end) end
    end
end

local function Attack_Clone(inst)
    if typeof(cloneref) == "function" then return cloneref(inst) end
    return inst
end

local function Attack_CaptureRemote(R)
    if R and R:IsA("RemoteEvent") and R:GetAttribute("Id") then
        AttackObfuscatedRemote = R
        AttackObfuscatedId = R:GetAttribute("Id")
    end
end

do
    local folders = {"Util", "Common", "Remotes", "Assets", "FX"}
    for _, name in ipairs(folders) do
        local folder = RS:FindFirstChild(name)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do Attack_CaptureRemote(child) end
            folder.ChildAdded:Connect(function(child) Attack_CaptureRemote(child) end)
        end
    end
end

local function Attack_EnsureRemotes()
    if not AttackNet then
        local modules = RS:FindFirstChild("Modules")
        AttackNet = modules and modules:FindFirstChild("Net")
    end
    if not AttackNet then return false end
    if not AttackRegisterAttack then AttackRegisterAttack = AttackNet:FindFirstChild("RE/RegisterAttack") or AttackNet:FindFirstChild("RegisterAttack") end
    if not AttackRegisterHit then AttackRegisterHit = AttackNet:FindFirstChild("RE/RegisterHit") or AttackNet:FindFirstChild("RegisterHit") end
    if not AttackSeedRemote then AttackSeedRemote = AttackNet:FindFirstChild("seed") end
    return AttackRegisterAttack ~= nil and AttackRegisterHit ~= nil
end

local AttackHitCache, AttackHitOrigin, AttackHitAt

local function Attack_BuildHitList(character, origin)
    local now = os.clock()
    if AttackHitCache and AttackHitOrigin and (now - AttackHitAt) < 0.1 and (origin - AttackHitOrigin).Magnitude < 40 then return AttackHitCache end
    local hitList = AttackHitCache or {}
    table.clear(hitList)
    local folders = {workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Characters")}
    for _, folder in ipairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model ~= character then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    local hum = model:FindFirstChild("Humanoid")
                    if root and hum and hum.Health > 0 and (root.Position - origin).Magnitude <= 60 then
                        for _, part in ipairs(model:GetChildren()) do
                            if part:IsA("BasePart") then hitList[#hitList + 1] = {model, part} end
                        end
                    end
                end
            end
        end
    end
    AttackHitCache, AttackHitOrigin, AttackHitAt = hitList, origin, now
    return hitList
end

local function Attack_GetSeed()
    local now = os.clock()
    if AttackSeedCache and (now - AttackSeedAt) < 1 then return AttackSeedCache end
    if AttackSeedRemote then
        local ok, seed = pcall(function() return AttackSeedRemote:InvokeServer() end)
        if ok and seed then AttackSeedCache = seed AttackSeedAt = now return seed end
    end
    return AttackSeedCache or 1
end

local function Attack_Auto()
    if not Character or not HRP or not HD then return end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local WT = tool:GetAttribute("WeaponType")
    if WT ~= "Melee" and WT ~= "Sword" then return end
    if not Attack_EnsureRemotes() then return end
    local hitList = Attack_BuildHitList(Character, HRP.Position)
    if #hitList == 0 then return end
    pcall(function()
        local okNet, netApi = pcall(function() return require(AttackNet) end)
        if okNet and netApi and netApi.RemoteEvent then pcall(netApi.RemoteEvent, netApi, "RegisterHit", true) end
        AttackRegisterAttack:FireServer()
        local primaryModel = hitList[1][1]
        local head = primaryModel and primaryModel:FindFirstChild("Head")
        if not head then return end
        AttackRegisterHit:FireServer(head, hitList, {}, tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
        if AttackObfuscatedRemote and AttackObfuscatedId then
            local key = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
            local encName = string.gsub("RE/RegisterHit", ".", function(c) return string.char(bit32.bxor(string.byte(c), key)) end)
            local encId = bit32.bxor(AttackObfuscatedId + 909090, Attack_GetSeed() * 2)
            Attack_Clone(AttackObfuscatedRemote):FireServer(encName, encId, head, hitList)
        end
    end)
end

local function TargetPos(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        local primary = inst.PrimaryPart
        if primary then return primary.Position end
        local part = inst:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    local ok, center = pcall(function() return inst:GetBoundingBox() end)
    if ok and center then return center.Position end
    return nil
end

local HeartPosCache = { inst = nil, part = nil }
local function GetHeartPos(Heart)
    if not Heart then return nil end
    if HeartPosCache.inst ~= Heart then
        HeartPosCache.inst = Heart
        HeartPosCache.part = nil
    end
    local part = HeartPosCache.part
    if not part or not part.Parent then
        if Heart:IsA("BasePart") then part = Heart
        elseif Heart:IsA("Model") then part = Heart.PrimaryPart or Heart:FindFirstChildWhichIsA("BasePart") or Heart:FindFirstChildWhichIsA("BasePart", true) end
        HeartPosCache.part = part
    end
    if part and part.Parent then return part.Position end
    return nil
end

local function IsFrozenHeartHarpooned()
    local mapFolder = game:GetService("Workspace"):FindFirstChild("Map")
    if mapFolder then
        local frozenHeart = mapFolder:FindFirstChild("FrozenHeart")
        if frozenHeart then
            local inside = frozenHeart:FindFirstChild("Inside")
            if inside then return inside:GetAttribute("Harpooned") or false end
        end
    end
    return false
end

local function Leviathan_CommF()
    local CommF2 = CommF
    if not CommF2 then
        local remotes = RS:FindFirstChild("Remotes")
        CommF2 = remotes and remotes:FindFirstChild("CommF_")
    end
    return CommF2
end

local BribeCache = nil
local BribeCacheAt = 0
local function GetBribeStatus()
    if BribeCache and os.clock() - BribeCacheAt < 2 then return BribeCache end
    local CommF2 = Leviathan_CommF()
    if not CommF2 then return nil end
    local ok, result = pcall(function() return CommF2:InvokeServer("InfoLeviathan", "1") end)
    if ok then
        local n = tonumber(result)
        if n then BribeCache = n BribeCacheAt = os.clock() return n end
        BribeCache = 5 BribeCacheAt = os.clock() return 5
    end
    return nil
end

local function DoBribe()
    local CommF2 = Leviathan_CommF()
    if not CommF2 then return nil end
    local ok, result = pcall(function() return CommF2:InvokeServer("InfoLeviathan", "2") end)
    if ok then return result end
    return nil
end

local function BribeUntilDone()
    local S0 = GetBribeStatus()
    if S0 == 5 or S0 == -1 or S0 == nil then return end
    for i = 1, 4 do
        SetStatus("Bribing Spy (" .. i .. "/4)")
        DoBribe()
        task.wait(0.5)
        local S = GetBribeStatus()
        if S == 5 or S == -1 or S == nil then break end
    end
end

local BoatDealerCF = CFrame.new(-16917.1523, 8.59936905, 511.799042)
local BoatFindRange = 5000
local CruiseWP_A = CFrame.new(-44541.7617, 30.0003204, -1244.8584)
local CruiseWP_B = CFrame.new(-90000, 30.0003204, -1244.8584)
local CruiseWP_Far = CFrame.new(-9000000000, 30.0003204, -1244.8584)
local SailArriveDist = 40

local function IsBeastHunterBoat(boat)
    if not boat then return false end
    if _G.SoloSeaFarm then return boat.Name == (_G.SoloSeaBoat or "Beast Hunter") end
    return boat.Name == "Beast Hunter"
end

local function BoatOwnerMatch(boat, player)
    local Owner = boat and boat:FindFirstChild("Owner")
    if not Owner or not player then return false end
    if Owner.Value == player then return true end
    if typeof(Owner.Value) == "string" and Owner.Value == player.Name then return true end
    if tostring(Owner.Value) == player.Name then return true end
    return false
end

_G.RJR_AbandonedBoats = _G.RJR_AbandonedBoats or setmetatable({}, { __mode = "k" })

local function GetOwnBoat(includeDead)
    local boats = workspace:FindFirstChild("Boats")
    if not boats then return nil end
    local _, hrp = GetCharacterParts()
    local myPos = hrp and hrp.Position
    if not myPos then return nil end
    for _, boat in ipairs(boats:GetChildren()) do
        local owner = boat:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer or tostring(owner.Value) == LocalPlayer.Name)
        and (not _G.SoloSeaFarm or boat.Name == (_G.SoloSeaBoat or "Beast Hunter")) then
            if not _G.RJR_AbandonedBoats[boat] then
                local seat = boat:FindFirstChild("VehicleSeat") or boat.PrimaryPart or boat:FindFirstChildWhichIsA("BasePart", true)
                if seat and (seat.Position - myPos).Magnitude <= BoatFindRange then return boat end
            end
        end
    end
    return nil
end

local function GetCaptainBoat()
    local boats = workspace:FindFirstChild("Boats")
    if not boats then return nil end
    local captain = Players:FindFirstChild(_G.FollowTarget)
    if not captain then return nil end
    local _, hrp = GetCharacterParts()
    local myPos = hrp and hrp.Position
    if not myPos then return nil end
    for _, boat in ipairs(boats:GetChildren()) do
        local owner = boat:FindFirstChild("Owner")
        if owner and (owner.Value == captain or tostring(owner.Value) == captain.Name) and not _G.RJR_AbandonedBoats[boat] then
            local seat = boat:FindFirstChild("VehicleSeat") or boat.PrimaryPart or boat:FindFirstChildWhichIsA("BasePart", true)
            if seat and (seat.Position - myPos).Magnitude <= BoatFindRange then return boat end
        end
    end
    return nil
end

local function KeepFacing()
    local _, hrpNow = GetCharacterParts()
    if hrpNow then return hrpNow.CFrame - hrpNow.CFrame.Position end
    return CFrame.new()
end

local function LiveSeatCF(seat)
    return function()
        if not seat or not seat.Parent then return nil end
        return seat.CFrame
    end
end

local function LiveHeartCF(height)
    return function()
        local Map = workspace:FindFirstChild("Map")
        local Heart = Map and Map:FindFirstChild("FrozenHeart")
        local hp = Heart and GetHeartPos(Heart)
        if not hp then return nil end
        return (CFrame.new(hp) * CFrame.new(0, height or 35, 0)) * KeepFacing()
    end
end

local function LiveGateCF(height)
    return function()
        local Map = workspace:FindFirstChild("Map")
        local Gate = Map and Map:FindFirstChild("LeviathanGate")
        local Watcher = Gate and Gate:FindFirstChild("FrozenWatcherPart")
        local wp = Watcher and TargetPos(Watcher)
        if not wp then return nil end
        return (CFrame.new(wp) * CFrame.new(0, height or 5, 0)) * KeepFacing()
    end
end

local function Unseat()
    HoldCFrame = nil
    LiveHoldFn = nil
    AttackModel = nil
    AttackStandFn = nil
    FightTarget = nil
    for _ = 1, 3 do
        local _, hrp, hum = GetCharacterParts()
        if not hum or (not hum.Sit and hum.SeatPart == nil) then return true end
        StandUpFromSeat(hum.SeatPart, hum, hrp)
        local UnseatStart = os.clock()
        while os.clock() - UnseatStart < 2 do
            local _, _, hum2 = GetCharacterParts()
            if hum2 and (hum2.Sit or hum2.SeatPart ~= nil) then
                pcall(function()
                    hum2.Sit = false
                    hum2.PlatformStand = false
                    hum2.Jump = true
                    hum2:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
                task.wait(0.2)
            else
                return true
            end
        end
    end
    return false
end

local function BoardSeat(seat, timeout)
    timeout = timeout or 15
    if not seat or not seat.Parent then return false end
    local start = os.clock()
    local Deadline = start + timeout
    while _G.AutoLeviathanFull and os.clock() < Deadline do
        if not seat or not seat.Parent then return false end
        local _, hrp, hum = GetCharacterParts()
        if hum and hum.SeatPart == seat then
            HoldCFrame = nil
            return true
        end
        if hum and (hum.Sit or hum.SeatPart ~= nil) then
            Unseat()
            task.wait(0.3)
        end
        if hrp then
            if (hrp.Position - seat.Position).Magnitude <= BoatFindRange then
                _tp(LiveSeatCF(seat), function()
                    if (not _G.AutoLeviathanFull) or (not seat or not seat.Parent) then return true end
                    local _, _, humNow = GetCharacterParts()
                    return humNow ~= nil and humNow.SeatPart ~= nil
                end)
            else
                return false
            end
        end
        task.wait(0.2)
    end
    local _, _, hum = GetCharacterParts()
    return hum and hum.SeatPart == seat
end

local function ForceUnseat(Seconds)
    local Deadline = os.clock() + (Seconds or 10)
    while _G.AutoLeviathanFull and os.clock() < Deadline do
        local _, _, hum = GetCharacterParts()
        if not hum or (not hum.Sit and hum.SeatPart == nil) then return true end
        Unseat()
        task.wait(0.3)
    end
    local _, _, hum = GetCharacterParts()
    return hum == nil or (not hum.Sit and hum.SeatPart == nil)
end

local function BoardSeatRetry(seat, timeout, attempts)
    attempts = attempts or 3
    for _ = 1, attempts do
        if not seat or not seat.Parent then return false end
        if BoardSeat(seat, timeout) then return true end
        Unseat()
        task.wait(0.5)
    end
    return false
end

local function BuyOwnBoat(Message)
    SetStatus(Message or "Boat gone, buying new one")
    local _, _, humB = GetCharacterParts()
    if humB and (humB.Sit or humB.SeatPart ~= nil) then Unseat() end
    local start = os.clock()
    local Arrived = false
    while _G.AutoLeviathanFull and os.clock() - start < 90 do
        local _, hrp = GetCharacterParts()
        if hrp and (hrp.Position - BoatDealerCF.Position).Magnitude <= 20 then
            Arrived = true
            break
        end
        _tp(function() return BoatDealerCF end, function() return not _G.AutoLeviathanFull end)
        task.wait(0.5)
    end
    if not Arrived then return false end
    local CommF2 = Leviathan_CommF()
    if CommF2 then pcall(function() CommF2:InvokeServer("BuyBoat", (_G.SoloSeaFarm and _G.SoloSeaBoat) or "Beast Hunter") end) end
    task.wait(1)
    return true
end

local function RebuyBoatAndBoard()
    BuyOwnBoat()
    local SpawnStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - SpawnStart < 30 do
        local b3 = GetOwnBoat()
        local s3 = b3 and b3:FindFirstChild("VehicleSeat")
        if b3 and s3 and BoardSeatRetry(s3) then
            SetStatus("New boat bought")
            return b3, s3
        end
        task.wait(0.5)
    end
    return nil, nil
end

local LastSailAt = 0
local CruiseCheckPos = nil
local CruiseCheckAt = 0
local CruiseStalls = 0
local CruiseToB = true

local function SailBoatStream(seat, speed)
    speed = speed or _G.BoatSpeed or 150
    if not seat or not seat.Parent then return false end
    LastSailAt = os.clock()
    local _, hrp = GetCharacterParts()
    if not hrp then return false end
    local dt = RunService.Heartbeat:Wait() or (1 / 60)
    if (seat.Position or hrp.Position).Y < 0 then
        SetStatus("Boat sank, rebuying")
        Unseat()
        return false
    end
    local pos = hrp.Position
    local target = _G.CruiseReturn and (CruiseToB and CruiseWP_B or CruiseWP_A) or CruiseWP_Far
    local zone = target.Position
    local flat = Vector3.new(zone.X - pos.X, 0, zone.Z - pos.Z)
    local dist = flat.Magnitude
    if _G.CruiseReturn and dist <= SailArriveDist then
        CruiseToB = not CruiseToB
        target = CruiseToB and CruiseWP_B or CruiseWP_A
        zone = target.Position
        flat = Vector3.new(zone.X - pos.X, 0, zone.Z - pos.Z)
        dist = flat.Magnitude
    end
    if os.clock() - CruiseCheckAt >= 15 then
        if CruiseCheckPos and Vector3.new(pos.X - CruiseCheckPos.X, 0, pos.Z - CruiseCheckPos.Z).Magnitude < 200 then
            CruiseStalls = CruiseStalls + 1
            if CruiseStalls >= 2 then
                CruiseStalls = 0
                CruiseCheckPos = nil
                CruiseCheckAt = os.clock()
                SetStatus("Cruise stalled, restarting")
                Unseat()
                task.wait(0.3)
                if seat.Parent then BoardSeatRetry(seat, 10) end
            else
                SetStatus("Cruise stuck, re-seating")
                Unseat()
                task.wait(0.3)
                if seat.Parent then BoardSeatRetry(seat, 10) end
                CruiseCheckPos = nil
            end
        else
            CruiseStalls = 0
            CruiseCheckPos = pos
        end
        CruiseCheckAt = os.clock()
    end
    local dir = flat.Unit
    local step = math.min(dist, speed * dt)
    local np = pos + dir * step
    local lockY = _G.BoatHeight or 150
    pcall(function()
        hrp.CFrame = CFrame.lookAt(Vector3.new(np.X, lockY, np.Z), Vector3.new(np.X, lockY, np.Z - 1), Vector3.new(0, 1, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
    return true
end

local function SailBoatTurn(seat, targetPos, speed, FixedY)
    speed = speed or _G.BoatSpeed or 250
    local pos = seat.Position
    local flat = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
    if flat.Magnitude < 0.5 then return end
    LastSailAt = os.clock()
    local dt = RunService.Heartbeat:Wait() or 1 / 60
    local yaw = math.atan2(flat.X, flat.Z) + math.pi
    local move = flat.Unit * speed * dt
    local newPos = seat.Position + move
    seat.CFrame = CFrame.new(newPos.X, FixedY or seat.Position.Y, newPos.Z) * CFrame.Angles(0, yaw, 0)
end

local SeaAPI = {}
do
    local Sea_MobStillAlive
    local SEA_EVENT_OPTIONS = {"Shark", "Piranha", "Fish Crew Member", "Terrorshark", "Sea Beast", "Ghost Ship", "Pirate Brigade Ship", "Pirate Grand Brigade Ship", "Pirate Basic Ship"}
    local SEA_EVENT_OPTIONS_BY_MOB = {
        ["Shark"] = "Shark", ["Piranha"] = "Piranha", ["Fish Crew Member"] = "Fish Crew Member", ["Terrorshark"] = "Terrorshark",
        ["SeaBeast1"] = "Sea Beast", ["FishBoat"] = "Ghost Ship", ["PirateBrigade"] = "Pirate Brigade Ship",
        ["PirateGrandBrigade"] = "Pirate Grand Brigade Ship", ["PirateBasic"] = "Pirate Basic Ship"
    }

    local function Sea_NormalizeSelection(Value, FromDropdown)
        local Raw = {}
        if type(Value) == "table" then
            local HasBooleanMap = FromDropdown == true
            for Key, Flag in pairs(Value) do if type(Key) == "string" and type(Flag) == "boolean" then HasBooleanMap = true break end end
            if HasBooleanMap then
                for Key, Flag in pairs(Value) do if Flag == true and type(Key) == "string" then Raw[#Raw + 1] = Key end end
            else
                for _, Name in ipairs(Value) do if type(Name) == "string" and Name ~= "" then Raw[#Raw + 1] = Name end end
                for _, Flag in pairs(Value) do if type(Flag) == "string" and Flag ~= "" then Raw[#Raw + 1] = Flag end end
            end
        elseif type(Value) == "string" and Value ~= "" then Raw[1] = Value end
        local Seen, Out = {}, {}
        for _, Name in ipairs(Raw) do
            if not Seen[Name] and table.find(SEA_EVENT_OPTIONS, Name) then Seen[Name] = true Out[#Out + 1] = Name end
        end
        return Out
    end

    local function Sea_SelectionSet()
        local Clean = Sea_NormalizeSelection(_G.HuntSelectEvents)
        if #Clean == 0 then return nil end
        local Set = {}
        for _, Name in ipairs(Clean) do Set[Name] = true end
        return Set
    end

    local function Sea_SelectionAllows(MobName)
        local Option = SEA_EVENT_OPTIONS_BY_MOB[MobName]
        if not Option then return true end
        local Set = Sea_SelectionSet()
        return Set == nil or Set[Option] == true
    end

    local function Sea_Mob(MaxDistance, Exclude, Origin)
        MaxDistance = MaxDistance or 4000
        local Ref = Origin or HRP
        if not Origin and not _G.SoloSeaFarm then
            local boat = (_G.Mode == "Capitán") and GetOwnBoat() or GetCaptainBoat()
            local seat = boat and boat:FindFirstChild("VehicleSeat")
            Ref = seat or Ref
        end
        local Enemies = workspace:FindFirstChild("Enemies")
        local SeaBeasts = workspace:FindFirstChild("SeaBeasts")
        local MobList = {
            {Name = "Terrorshark", ConfigName = "Terrorshark", Folder = Enemies, Skill = false},
            {Name = "Piranha", ConfigName = "Piranha", Folder = Enemies, Skill = false},
            {Name = "Shark", ConfigName = "Shark", Folder = Enemies, Skill = false},
            {Name = "Fish Crew Member", ConfigName = "Fish Crew Member", Folder = Enemies, Skill = false},
            {Name = "FishBoat", ConfigName = "Ghost Ship", Folder = Enemies, Skill = true},
            {Name = "PirateBrigade", ConfigName = "Pirate Brigade Ship", Folder = Enemies, Skill = true},
            {Name = "PirateGrandBrigade", ConfigName = "Pirate Grand Brigade Ship", Folder = Enemies, Skill = true},
            {Name = "PirateBasic", ConfigName = "Pirate Basic Ship", Folder = Enemies, Skill = true},
            {Name = "SeaBeast1", ConfigName = "Sea Beast", Folder = SeaBeasts, Skill = true},
        }
        local SelectedSet = Sea_SelectionSet()
        local Best, BestRoot, BestSkill, BestDist = nil, nil, false, MaxDistance
        for _, Data in ipairs(MobList) do
            local IsSelected = SelectedSet and SelectedSet[Data.ConfigName] == true
            local AllowTarget = IsSelected or SelectedSet == nil
            if AllowTarget and Data.Folder then
                for _, Mob in ipairs(Data.Folder:GetChildren()) do
                    if Mob.Name == Data.Name and not (Exclude and Exclude[Mob]) then
                        local Alive = Sea_MobStillAlive(Mob)
                        local Root = Mob:FindFirstChild("HumanoidRootPart") or Mob:FindFirstChild("RootPart") or Mob.PrimaryPart or Mob:FindFirstChild("Head") or Mob:FindFirstChildWhichIsA("BasePart", true)
                        if Alive and Root and Root.Position and Ref then
                            local Dist = (Root.Position - Ref.Position).Magnitude
                            if Dist < BestDist then Best, BestRoot, BestSkill, BestDist = Mob, Root, Data.Skill == true, Dist end
                        end
                    end
                end
            end
        end
        return Best, BestRoot, BestSkill
    end

    Sea_MobStillAlive = function(Mob)
        if not Mob or not Mob.Parent then return false end
        local Health = Mob:FindFirstChild("Health")
        if Health and Health:IsA("ValueBase") and Health.Value <= 0 then return false end
        local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
        if Humanoid and Humanoid.Health <= 0 then return false end
        return (Health ~= nil and Health:IsA("ValueBase")) or (Humanoid ~= nil)
    end

    local FaceTargetCF = (function()
        local Cached = { model = nil, part = nil, at = 0 }
        return function(standPos, model)
            if not model or not model.Parent or model:IsA("BasePart") then return nil end
            local now = os.clock()
            if Cached.model ~= model or now - Cached.at > 2 then
                Cached.model, Cached.at, Cached.part = model, now, nil
                local best, bestDist = nil, nil
                local stack, visited = { model }, 0
                while #stack > 0 and visited < 150 do
                    local node = table.remove(stack)
                    for _, child in ipairs(node:GetChildren()) do
                        visited = visited + 1
                        if child:IsA("BasePart") then
                            local flat = Vector3.new(child.Position.X - standPos.X, 0, child.Position.Z - standPos.Z)
                            local d = flat.Magnitude
                            if d > 1 and (bestDist == nil or d < bestDist) then best, bestDist = child, d end
                        elseif child:IsA("Model") then stack[#stack + 1] = child end
                    end
                end
                Cached.part = best
            end
            local part = Cached.part
            if not part or not part.Parent then return nil end
            local flat = Vector3.new(part.Position.X - standPos.X, 0, part.Position.Z - standPos.Z)
            if flat.Magnitude < 1 then return nil end
            return CFrame.lookAt(standPos, standPos + flat.Unit)
        end
    end)()

    local function Sea_Stand(Mob, Root)
        if not Root then return nil end
        local standPos
        if Mob.Parent and Mob.Parent.Name == "SeaBeasts" then standPos = Vector3.new(Root.Position.X, 120, Root.Position.Z)
        else standPos = Root.Position + Vector3.new(0, 40, 0) end
        return FaceTargetCF(standPos, Mob) or CFrame.new(standPos)
    end

    local function Sea_EventRoot(Mob)
        if not Mob then return nil end
        return Mob:FindFirstChild("HumanoidRootPart") or Mob:FindFirstChild("RootPart") or Mob.PrimaryPart or Mob:FindFirstChild("Head") or Mob:FindFirstChildWhichIsA("BasePart", true)
    end

    local ShootGunEvent, Validator2
    local shootFunc, idx, dragonReady = nil, {}, false
    local LIMB_PARTS = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "HumanoidRootPart"}
    local VALID_SEA_ENEMIES = {"Terrorshark", "Shark", "Piranha", "Fish Crew Member", "Haunted Crew Member", "FishBoat", "PirateBrigade", "PirateGrandBrigade"}

    local function getRandomLimb(character)
        if not character then return nil end
        local available = {}
        for _, name in ipairs(LIMB_PARTS) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then available[#available + 1] = part end
        end
        if #available == 0 then return character:FindFirstChild("HumanoidRootPart") end
        return available[math.random(1, #available)]
    end

    local function initDragon()
        if dragonReady then return end
        local success = pcall(function()
            local cc = require(RS:WaitForChild("Controllers"):WaitForChild("CombatController"))
            for _, v in ipairs(debug.getupvalues(cc.Attack)) do
                if type(v) == "function" then
                    for i, uv in ipairs(debug.getupvalues(v)) do
                        if uv == 727595 then
                            shootFunc = v
                            idx = { u25 = i - 3, u21 = i - 2, u24 = i - 1, u20 = i, u22 = i + 1, u23 = i + 2, u26 = i + 3 }
                            break
                        end
                    end
                    if shootFunc then break end
                end
            end
        end)
        if success and shootFunc then dragonReady = true end
    end

    local function fireShot(pos, hit)
        if not shootFunc or not Validator2 or not ShootGunEvent then return end
        local u20 = debug.getupvalue(shootFunc, idx.u20)
        local u21 = debug.getupvalue(shootFunc, idx.u21)
        local u22 = debug.getupvalue(shootFunc, idx.u22)
        local u23 = debug.getupvalue(shootFunc, idx.u23)
        local u24 = debug.getupvalue(shootFunc, idx.u24)
        local u25 = debug.getupvalue(shootFunc, idx.u25)
        local u26 = debug.getupvalue(shootFunc, idx.u26)
        local u79 = u25 * u21
        local u80 = (u24 * u21 + u25 * u20) % u22
        u80 = (u80 * u22 + u79) % u23
        u24 = math.floor(u80 / u22)
        u25 = u80 - u24 * u22
        u26 = u26 + 1
        debug.setupvalue(shootFunc, idx.u24, u24)
        debug.setupvalue(shootFunc, idx.u25, u25)
        debug.setupvalue(shootFunc, idx.u26, u26)
        Validator2:FireServer(math.floor(u80 / u23 * 16777215), u26)
        ShootGunEvent:FireServer(pos, { hit })
    end

    local SeaBoatModelsCache, SeaBoatModelsAt
    local function getAllPlayerBoatModels()
        local now = os.clock()
        if SeaBoatModelsCache and (now - SeaBoatModelsAt) < 0.5 then return SeaBoatModelsCache end
        local models = {}
        local boats = workspace:FindFirstChild("Boats")
        if boats then
            for _, v in ipairs(boats:GetChildren()) do
                local owner = v:FindFirstChild("Owner")
                if owner and owner.Value and tostring(owner.Value) ~= "" then models[v.Name] = true end
            end
        end
        SeaBoatModelsCache, SeaBoatModelsAt = models, now
        return models
    end

    local AttackRange = 450
    local SeaTargetCache, SeaTargetAt
    local function getClosestSeaTarget()
        local now = os.clock()
        if SeaTargetCache and (now - SeaTargetAt) < 0.2 then return SeaTargetCache end
        local char = LocalPlayer.Character
        if not char then return nil end
        local myHRP = char:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local best, bestDist = nil, AttackRange
        local playerBoats = getAllPlayerBoatModels()
        local seaBeasts = workspace:FindFirstChild("SeaBeasts")
        if seaBeasts then
            for _, e in ipairs(seaBeasts:GetChildren()) do
                local hrp = e:FindFirstChild("HumanoidRootPart")
                local hp = e:FindFirstChild("Health")
                if hrp and hp and hp:IsA("ValueBase") and hp.Value > 0 then
                    local segment = e:FindFirstChild("Leviathan Segment")
                    if segment then
                        local dist = (segment.Position - myHRP.Position).Magnitude
                        if dist < bestDist then bestDist = dist best = segment end
                    end
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < bestDist then bestDist = dist best = getRandomLimb(e) or hrp end
                end
            end
        end
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, e in ipairs(enemies:GetChildren()) do
                if table.find(VALID_SEA_ENEMIES, e.Name) and not playerBoats[e.Name] and Sea_SelectionAllows(e.Name) then
                    local engine = e:FindFirstChild("Engine")
                    local isBoat = engine and e:FindFirstChild("VehicleSeat")
                    if isBoat then
                        local hp = e:FindFirstChild("Health")
                        if hp and hp:IsA("ValueBase") and hp.Value > 0 then
                            local dist = (engine.Position - myHRP.Position).Magnitude
                            if dist < bestDist then bestDist = dist best = engine end
                        end
                    else
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        local hum = e:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist < bestDist then bestDist = dist best = getRandomLimb(e) or hrp end
                        end
                    end
                end
            end
        end
        SeaTargetCache, SeaTargetAt = best, now
        return best
    end

    local function StartDragonAttack()
        task.spawn(function()
            while not dragonReady do initDragon() task.wait(1) end
            while _G.DragonGunFarm do
                pcall(function()
                    if not ShootGunEvent then
                        local modules = RS:FindFirstChild("Modules")
                        local net = modules and modules:FindFirstChild("Net")
                        ShootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
                    end
                    if not Validator2 then
                        local remotes = RS:FindFirstChild("Remotes")
                        Validator2 = remotes and remotes:FindFirstChild("Validator2")
                    end
                    if not ShootGunEvent or not Validator2 then return end
                    local target = getClosestSeaTarget()
                    if not target then return end
                    local char = LocalPlayer.Character
                    if not char then return end
                    local tool = char:FindFirstChildOfClass("Tool")
                    if not tool or tool.Name ~= "Dragonstorm" then
                        if not (Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Sit) then Equip_Auto("Dragonstorm") end
                        return
                    end
                    fireShot(target.Position, target)
                end)
                task.wait()
            end
        end)
    end

    local function FightSeaEvent(Mob, Root, Skill, ShouldBreak)
        local start = os.clock()
        local function CurrentStand()
            local r = Sea_EventRoot(Mob)
            if not r then return nil end
            return Sea_Stand(Mob, r)
        end
        while _G.AutoLeviathanFull and os.clock() - start < 600 do
            if ShouldBreak and ShouldBreak() then break end
            if not Character or not HRP or not HD or HD.Health <= 0 then break end
            if not Mob or not Mob.Parent or not Sea_MobStillAlive(Mob) then
                if Mob then SetStatus("Sea event defeated: " .. Mob.Name) end
                break
            end
            SetStatus("Farming: " .. Mob.Name)
            AttackModel = Mob
            AttackStandFn = CurrentStand
            local _, _, humSE = GetCharacterParts()
            if humSE and (humSE.Sit or humSE.SeatPart ~= nil) then ForceUnseat(5) end
            local Stand = CurrentStand()
            if Stand then
                local _, hrpNow = GetCharacterParts()
                if hrpNow and (Stand.Position - hrpNow.Position).Magnitude > 10 then
                    _tp(CurrentStand, function() return (not _G.AutoLeviathanFull) or (not Mob or not Mob.Parent) or (not Sea_MobStillAlive(Mob)) or (ShouldBreak and ShouldBreak()) end)
                end
                if not Sea_MobStillAlive(Mob) then
                    SetStatus("Sea event defeated: " .. Mob.Name)
                    break
                end
                FightTarget = { CF = Stand, At = os.clock() }
            end
            if not (Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Sit) then
                if _G.DragonGunFarm then Equip_Auto("Dragonstorm")
                elseif Stand and HRP then
                    local Distance = (Stand.Position - HRP.Position).Magnitude
                    local RootNow = Sea_EventRoot(Mob)
                    local MobUp = (RootNow and RootNow.Position and RootNow.Position.Y or 0) >= -600
                    if Skill and Distance <= 80 and MobUp then pcall(CoolDown_Auto) else Equip_Auto(_G.SelectWeapon or "Sword") end
                end
            end
            Haki_Auto()
            task.wait(0.05)
        end
        AttackModel = nil
        AttackStandFn = nil
        FightTarget = nil
        task.wait(0.3)
    end

    local function Leviathan_IsDead(model)
        local Hum = model:FindFirstChildOfClass("Humanoid")
        if Hum and Hum.Health <= 0 then return true end
        local Health = model:FindFirstChild("Health")
        if Health and (Health:IsA("NumberValue") or Health:IsA("IntValue")) and Health.Value <= 0 then return true end
        return false
    end

    local function Leviathan_GetHP(model)
        if not model then return nil end
        local Hum = model:FindFirstChildOfClass("Humanoid")
        if Hum then return Hum.Health end
        local Health = model:FindFirstChild("Health")
        if Health and (Health:IsA("NumberValue") or Health:IsA("IntValue")) then return Health.Value end
        return nil
    end

    local function Leviathan_RootPart(model)
        if not model then return nil end
        return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    end

    local LeviathanFindCache
    local LeviathanFindCacheAt = 0
    local function Leviathan_Find()
        local now = os.clock()
        if LeviathanFindCache and (now - LeviathanFindCacheAt) < 0.25 then return LeviathanFindCache[1], LeviathanFindCache[2] end
        local SeaBeasts = workspace:FindFirstChild("SeaBeasts")
        if not SeaBeasts then LeviathanFindCache, LeviathanFindCacheAt = nil, now return nil, nil end
        local foundModel, foundPart = nil, nil
        for _, model in ipairs(SeaBeasts:GetChildren()) do
            if model.Name == "Leviathan Segment" and not Leviathan_IsDead(model) then
                local part = Leviathan_RootPart(model)
                if part then foundModel, foundPart = model, part break end
            end
        end
        if not foundModel then
            local leviathan = SeaBeasts:FindFirstChild("Leviathan")
            if leviathan then
                local part = Leviathan_RootPart(leviathan)
                if part and not Leviathan_IsDead(leviathan) then foundModel, foundPart = leviathan, part end
            end
        end
        LeviathanFindCache, LeviathanFindCacheAt = {foundModel, foundPart}, now
        return foundModel, foundPart
    end

    local function Leviathan_SegmentsExist() return Leviathan_Find() ~= nil end

    local function Leviathan_Stand(model, part)
        local Root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart or model:FindFirstChild("Head") or part
        if not Root then return nil end
        local standPos = Vector3.new(Root.Position.X, Root.Position.Y + 75, Root.Position.Z)
        return FaceTargetCF(standPos, model) or CFrame.new(standPos)
    end

    local LeviathanWaitDone = false
    local LeviathanPartsAt = nil

    task.spawn(function()
        local LastSeenAt = os.clock()
        while true do
            task.wait(0.5)
            if Leviathan_Find() then
                LastSeenAt = os.clock()
                if not LeviathanPartsAt then LeviathanPartsAt = LastSeenAt end
            elseif os.clock() - LastSeenAt > 15 then
                LeviathanWaitDone = false
                LeviathanPartsAt = nil
            end
        end
    end)

    local function FightLeviathan(ShouldBreak, WaitSec)
        local model, part = Leviathan_Find()
        if not model then return false end
        if not LeviathanWaitDone then
            WaitSec = WaitSec or 10
            local Since = LeviathanPartsAt or os.clock()
            local Aborted = false
            while _G.AutoLeviathanFull and os.clock() - Since < WaitSec do
                if ShouldBreak and ShouldBreak() then Aborted = true break end
                SetStatus("Leviathan spawned: attacking in " .. string.format("%.1f", WaitSec - (os.clock() - Since)) .. "s")
                task.wait(0.2)
            end
            LeviathanWaitDone = not Aborted
        end
        local Killed = false
        local start = os.clock()
        local LastFind = 0
        local MissingSince = nil
        local MissingGrace = 15
        while _G.AutoLeviathanFull and os.clock() - start < 900 do
            if ShouldBreak and ShouldBreak() then break end
            if not Character or not HRP or not HD or HD.Health <= 0 then break end
            local HeartMap = workspace:FindFirstChild("Map")
            if HeartMap and HeartMap:FindFirstChild("FrozenHeart") then
                Killed = true
                SetStatus("Heart detected: hooking")
                break
            end
            local _, _, humNow = GetCharacterParts()
            if humNow and (humNow.Sit or humNow.SeatPart ~= nil) then
                SetStatus("Getting off seat to fight")
                if not ForceUnseat(20) then SetStatus("Failed to unseat: skipping fight") break end
            end
            if os.clock() - LastFind >= 0.4 then
                LastFind = os.clock()
                model, part = Leviathan_Find()
                if model then
                    MissingSince = nil
                    if Leviathan_IsDead(model) then Killed = true break end
                else
                    MissingSince = MissingSince or os.clock()
                    if os.clock() - MissingSince >= MissingGrace then Killed = true break end
                end
            end
            if not model then
                SetStatus("Leviathan not found, waiting")
                AttackModel = nil
                AttackStandFn = nil
                FightTarget = nil
                task.wait(0.2)
            else
                local MyHP = HD and HD.Health
                if MyHP and MyHP < 3000 then
                    SetStatus("Low HP: flying up")
                    local _, hrp = GetCharacterParts()
                    local FleeY = hrp and (hrp.Position.Y + 1050) or nil
                    local EscStart = os.clock()
                    while _G.AutoLeviathanFull and os.clock() - EscStart < 600 do
                        if ShouldBreak and ShouldBreak() then break end
                        if not Character or not HRP or not HD or HD.Health <= 0 then break end
                        model, part = Leviathan_Find()
                        if not model then break end
                        local H = HD and HD.Health
                        if H and H >= 5000 then SetStatus("HP restored, attacking") break end
                        local _, hrp2 = GetCharacterParts()
                        local _, _, hum2 = GetCharacterParts()
                        if hum2 and (hum2.Sit or hum2.SeatPart ~= nil) then StandUpFromSeat(hum2.SeatPart, hum2, hrp2) end
                        if hrp2 and FleeY then hrp2.CFrame = CFrame.new(hrp2.Position.X, FleeY, hrp2.Position.Z) end
                        task.wait(0.2)
                    end
                    task.wait(0.5)
                end
                if model then
                    local _, _, humPre = GetCharacterParts()
                    if humPre and (humPre.Sit or humPre.SeatPart ~= nil) then SetStatus("Getting off seat") ForceUnseat(5) end
                    local HPNow = Leviathan_GetHP(model)
                    SetStatus("Attacking Leviathan: " .. model.Name .. (HPNow and (" - HP " .. string.format("%.0f", HPNow)) or ""))
                    local function CurrentStand()
                        if not model.Parent or Leviathan_IsDead(model) then return nil end
                        local _, p = Leviathan_Find()
                        return Leviathan_Stand(model, p or part)
                    end
                    AttackModel = model
                    AttackStandFn = CurrentStand
                    local Stand = CurrentStand()
                    if Stand then
                        local _, hrpNow = GetCharacterParts()
                        if not hrpNow or (Stand.Position - hrpNow.Position).Magnitude > 10 then
                            _tp(CurrentStand, function() return (not _G.AutoLeviathanFull) or (not model or not model.Parent) or (ShouldBreak and ShouldBreak()) end)
                        end
                        FightTarget = { CF = Stand, At = os.clock() }
                    end
                    if _G.DragonGunLeviathan and CheckItem("Dragonstorm") then
                        initDragon()
                        if not HasDragonstormEquipped() then Equip_Auto("Dragonstorm") end
                        local target = getClosestSeaTarget()
                        if target then fireShot(target.Position, target) end
                    else
                        local Distance = Stand and (Stand.Position - HRP.Position).Magnitude or 0
                        if Distance <= 80 then pcall(CoolDown_Auto) else Equip_Auto(_G.SelectWeapon or "Sword") end
                    end
                    Haki_Auto()
                end
            end
            task.wait(0.05)
        end
        AttackModel = nil
        AttackStandFn = nil
        FightTarget = nil
        return Killed
    end

    SeaAPI.Sea_Mob = Sea_Mob
    SeaAPI.Sea_MobStillAlive = Sea_MobStillAlive
    SeaAPI.Sea_Stand = Sea_Stand
    SeaAPI.StartDragonAttack = StartDragonAttack
    SeaAPI.InitDragon = initDragon
    SeaAPI.FightSeaEvent = FightSeaEvent
    SeaAPI.Leviathan_IsDead = Leviathan_IsDead
    SeaAPI.Leviathan_GetHP = Leviathan_GetHP
    SeaAPI.Leviathan_Find = Leviathan_Find
    SeaAPI.Leviathan_SegmentsExist = Leviathan_SegmentsExist
    SeaAPI.Leviathan_Stand = Leviathan_Stand
    SeaAPI.FightLeviathan = FightLeviathan
    SeaAPI.SeaEventOptions = SEA_EVENT_OPTIONS
    SeaAPI.NormalizeSelection = Sea_NormalizeSelection
end

_G.RJR_Resetting = false
_G.RJR_LeviathanPresent = function()
    local MapL = workspace:FindFirstChild("Map")
    if not MapL then return SeaAPI.Leviathan_SegmentsExist() end
    if MapL:FindFirstChild("LeviathanGate") or MapL:FindFirstChild("FrozenHeart") then return true end
    return SeaAPI.Leviathan_SegmentsExist()
end

_G.RJR_ResetCharacterAtTiki = function(reason)
    if _G.RJR_Resetting then return end
    if _G.RJR_LeviathanPresent() then return end
    _G.RJR_Resetting = true
    local WaitStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - WaitStart < 120 do
        local M = select(1, SeaAPI.Sea_Mob(1200))
        if not M then break end
        task.wait(1)
    end
    if _G.RJR_LeviathanPresent() then _G.RJR_Resetting = false return end
    SetStatus("Resetting to Tiki")
    pcall(Unseat)
    pcall(function()
        local CommF2 = Leviathan_CommF()
        if CommF2 then CommF2:InvokeServer("SetLastSpawnPoint", "Tiki") end
    end)
    local _, _, hum = GetCharacterParts()
    if hum and hum.Health > 0 then pcall(function() hum.Health = 0 end) end
    local Deadline = os.clock() + 20
    while os.clock() < Deadline do
        local _, h, hm = GetCharacterParts()
        if h and hm and hm.Health > 0 then break end
        task.wait(0.2)
    end
    _G.RJR_Resetting = false
end

local function ComputeHarpoonPitch(FromPos, ToPos)
    local dx = ToPos.X - FromPos.X
    local dy = ToPos.Y - FromPos.Y
    local dz = ToPos.Z - FromPos.Z
    local Horizontal = math.sqrt(dx * dx + dz * dz)
    return math.atan2(dy, Horizontal)
end

local function HarpoonHeart()
    local boat = GetOwnBoat()
    if not boat then return false end
    local DriverSeat = boat:FindFirstChild("VehicleSeat")
    if not DriverSeat then return false end
    local Map = workspace:FindFirstChild("Map")
    local Heart = Map and Map:FindFirstChild("FrozenHeart")
    local HeartPos = GetHeartPos(Heart)
    if not HeartPos then return false end
    if IsFrozenHeartHarpooned() then return true end
    local Harpoon = boat:FindFirstChild("Harpoon")
    local HarpoonSeat = Harpoon and Harpoon:FindFirstChild("Seat")
    if not HarpoonSeat then return false end
    local BoatStartY = DriverSeat.Position.Y
    local function AimYaw(flat) return math.atan2(flat.X, flat.Z) + math.pi end
    local CommF2 = Leviathan_CommF()
    local Fires = 0
    while _G.AutoLeviathanFull and Fires < 10 do
        local Map2 = workspace:FindFirstChild("Map")
        local CurrentHeart = Map2 and Map2:FindFirstChild("FrozenHeart")
        local CurrentHeartPos = GetHeartPos(CurrentHeart)
        if not CurrentHeart or not CurrentHeartPos then break end
        if IsFrozenHeartHarpooned() then break end
        if not BoardSeatRetry(DriverSeat) then break end
        local ApproachStart = os.clock()
        while _G.AutoLeviathanFull and os.clock() - ApproachStart < 60 do
            if not DriverSeat or not DriverSeat.Parent then break end
            local HeartNow = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("FrozenHeart")
            local HeartPosNow = HeartNow and GetHeartPos(HeartNow)
            if not HeartPosNow then break end
            local pos = DriverSeat.Position
            local TargetPoint = Vector3.new(HeartPosNow.X + 300, BoatStartY, HeartPosNow.Z)
            local flat = Vector3.new(TargetPoint.X - pos.X, 0, TargetPoint.Z - pos.Z)
            local dist = flat.Magnitude
            if dist < 10 then break end
            SailBoatTurn(DriverSeat, TargetPoint, _G.BoatSpeed, BoatStartY)
            if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then break end
        end
        if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then break end
        local AdjustStart = os.clock()
        while _G.AutoLeviathanFull and os.clock() - AdjustStart < 15 do
            if not DriverSeat or not DriverSeat.Parent then break end
            if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then break end
            local HeartNow = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("FrozenHeart")
            local HeartPosNow = HeartNow and GetHeartPos(HeartNow)
            if not HeartPosNow then break end
            local pos = DriverSeat.Position
            local flat = Vector3.new(HeartPosNow.X - pos.X, 0, HeartPosNow.Z - pos.Z)
            if flat.Magnitude < 0.5 then break end
            DriverSeat.CFrame = CFrame.new(pos.X, BoatStartY, pos.Z) * CFrame.Angles(0, AimYaw(flat), 0)
            local dir = flat.Unit
            local look = DriverSeat.CFrame.LookVector
            local dot = math.clamp(look.X * dir.X + look.Z * dir.Z, -1, 1)
            if math.acos(dot) <= 0.02 then break end
            task.wait()
        end
        if not Unseat() then break end
        task.wait(0.3)
        if not BoardSeatRetry(HarpoonSeat) then break end
        local YKeepStart = os.clock()
        while _G.AutoLeviathanFull and os.clock() - YKeepStart < 3 do
            if DriverSeat and DriverSeat.Parent then
                local pos = DriverSeat.Position
                if math.abs(pos.Y - BoatStartY) > 5 then
                    DriverSeat.CFrame = CFrame.new(pos.X, BoatStartY, pos.Z) * (DriverSeat.CFrame - DriverSeat.CFrame.Position)
                end
            end
            task.wait(0.2)
        end
        local FireOrigin = Harpoon:FindFirstChild("Muzzle") or Harpoon:FindFirstChild("Tip") or Harpoon.PrimaryPart or HarpoonSeat
        local HeartAtFire = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("FrozenHeart")
        local HeartPosAtFire = HeartAtFire and GetHeartPos(HeartAtFire)
        local Pitch = (FireOrigin and HeartPosAtFire) and (ComputeHarpoonPitch(FireOrigin.Position, HeartPosAtFire) + math.rad(3)) or 0.7853981633974483
        if CommF2 then pcall(function() CommF2:InvokeServer("FireHarpoon", Pitch, 0, Harpoon, workspace:GetServerTimeNow()) end) end
        Fires = Fires + 1
        local GrabbedNow = false
        local PostWaitStart = os.clock()
        while _G.AutoLeviathanFull and os.clock() - PostWaitStart < 10 do
            if DriverSeat and DriverSeat.Parent then
                local pos2 = DriverSeat.Position
                if math.abs(pos2.Y - BoatStartY) > 5 then DriverSeat.CFrame = CFrame.new(pos2.X, BoatStartY, pos2.Z) * (DriverSeat.CFrame - DriverSeat.CFrame.Position) end
            end
            local Map3 = workspace:FindFirstChild("Map")
            local Heart3 = Map3 and Map3:FindFirstChild("FrozenHeart")
            local HeartPos3 = Heart3 and GetHeartPos(Heart3)
            if not Heart3 or not HeartPos3 then break end
            if IsFrozenHeartHarpooned() then GrabbedNow = true break end
            task.wait(0.5)
        end
        if GrabbedNow then break end
        if not Unseat() then end
        task.wait(0.3)
    end
    Unseat()
    local MapFinal = workspace:FindFirstChild("Map")
    local HeartFinal = MapFinal and MapFinal:FindFirstChild("FrozenHeart")
    local HeartPosFinal = HeartFinal and GetHeartPos(HeartFinal)
    if HeartPosFinal and IsFrozenHeartHarpooned() then return true end
    return false
end

local function OpenLeviathanGate()
    local Map = workspace:FindFirstChild("Map")
    local Gate = Map and Map:FindFirstChild("LeviathanGate")
    local Watcher = Gate and Gate:FindFirstChild("FrozenWatcherPart")
    if not Watcher then return false end
    local WatcherPos = TargetPos(Watcher)
    if not WatcherPos then return false end
    _tp(LiveGateCF(5), function() return (not _G.AutoLeviathanFull) or SeaAPI.Leviathan_SegmentsExist() end)
    local ArriveStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - ArriveStart < 60 do
        if SeaAPI.Leviathan_SegmentsExist() then return true end
        local _, hrpA = GetCharacterParts()
        if hrpA and (hrpA.Position - WatcherPos).Magnitude < 150 then break end
        task.wait(0.5)
    end
    local CommF2 = Leviathan_CommF()
    local start = os.clock()
    local Fires = 0
    local LastInvoke = 0
    while _G.AutoLeviathanFull and os.clock() - start < 300 do
        if SeaAPI.Leviathan_SegmentsExist() then return true end
        if CommF2 and os.clock() - LastInvoke >= 10 then
            LastInvoke = os.clock()
            Fires = Fires + 1
            pcall(function() CommF2:InvokeServer("OpenLeviathanGate") end)
        end
        task.wait(1)
    end
    return SeaAPI.Leviathan_SegmentsExist()
end

local TikiWaypointCF = CFrame.new(-2044.52, 27.82, -701.59)
local TikiReturnCF = CFrame.new(-16206.9014, 7.75799561, 404.552002)

local function ComputeSteerAngle(seat, targetPos)
    local cframe = seat.CFrame
    local look = (cframe.LookVector * Vector3.new(1, 0, 1)).Unit
    local toTarget = ((targetPos - cframe.Position) * Vector3.new(1, 0, 1)).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(toTarget), -1, 1)))
    if look:Cross(toTarget).Y < 0 then angle = -angle end
    return angle
end

local function TurnBoatTowards(seat, targetPos)
    local pos = seat.Position
    seat.CFrame = CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
end

local function TurnBoatPrimTowards(prim, targetPos)
    local pos = prim.Position
    prim.CFrame = CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
end

local function SailToCF(seat, TargetCF, Speed, HeartCheck)
    Speed = Speed or _G.BoatSpeed or 250
    local TargetPos = TargetCF.Position
    local boat = (seat and seat.Parent and seat.Parent:IsA("Model")) and seat.Parent or nil
    local prim = boat and boat.PrimaryPart or nil
    local OrigMaxSpeed = seat.MaxSpeed
    local OrigTurnSpeed = seat.TurnSpeed
    local start = os.clock()
    local LastCheckPos = seat.Position
    local LastCheckAt = os.clock()
    local LastHeartCheckAt = 0
    local Arrived = false
    local SailStalls = 0
    while _G.AutoLeviathanFull and os.clock() - start < 900 do
        LastSailAt = os.clock()
        if not seat or not seat.Parent then break end
        if HeartCheck and os.clock() - LastHeartCheckAt >= 1 then
            LastHeartCheckAt = os.clock()
            if not HeartCheck(seat) then break end
        end
        if os.clock() - LastCheckAt >= 30 then
            local Moved = (seat.Position - LastCheckPos).Magnitude
            if Moved < 200 then
                SailStalls = SailStalls + 1
                if SailStalls >= 2 then
                    SailStalls = 0
                    LastCheckPos = seat.Position
                    LastCheckAt = os.clock()
                    break
                end
                if not Unseat() then
                    LastCheckPos = seat.Position
                    LastCheckAt = os.clock()
                else
                    task.wait(0.5)
                    if not BoardSeatRetry(seat) then break end
                    LastCheckPos = seat.Position
                    LastCheckAt = os.clock()
                end
            else
                SailStalls = 0
                LastCheckPos = seat.Position
                LastCheckAt = os.clock()
            end
        end
        local pos = seat.Position
        local flat = Vector3.new(TargetPos.X - pos.X, 0, TargetPos.Z - pos.Z)
        local distance = flat.Magnitude
        if distance <= 40 then
            Arrived = true
            pcall(function() seat.Throttle = 0 seat.ThrottleFloat = 0 end)
            if prim then pcall(function() prim.ThrottleFloat = 0 prim.Throttle = 0 end) end
            break
        end
        pcall(function() seat.MaxSpeed = Speed seat.TurnSpeed = Speed end)
        local steerAngle = ComputeSteerAngle(seat, TargetPos)
        if math.abs(steerAngle) <= 5 then
            pcall(function() seat.Throttle = 1 seat.ThrottleFloat = 1 end)
            if prim then pcall(function() prim.ThrottleFloat = 1 prim.Throttle = 1 end) end
        else
            pcall(function() TurnBoatTowards(seat, TargetPos) end)
            if prim then pcall(function() TurnBoatPrimTowards(prim, TargetPos) end) end
            pcall(function() seat.Throttle = 0 seat.ThrottleFloat = 0 end)
            if prim then pcall(function() prim.ThrottleFloat = 0 prim.Throttle = 0 end) end
        end
        task.wait()
    end
    pcall(function()
        seat.Throttle = 0
        seat.ThrottleFloat = 0
        seat.MaxSpeed = OrigMaxSpeed
        seat.TurnSpeed = OrigTurnSpeed
    end)
    if prim then pcall(function() prim.ThrottleFloat = 0 prim.Throttle = 0 end) end
    return Arrived
end

local function ReturnTiki(Speed)
    Speed = Speed or 200
    local boat = GetOwnBoat()
    if not boat then return false end
    local DriverSeat = boat:FindFirstChild("VehicleSeat")
    if not DriverSeat then return false end
    if not BoardSeatRetry(DriverSeat) then return false end
    SetStatus("Returning to Tiki")
    local function HeartCloseCheck(seat)
        local Map = workspace:FindFirstChild("Map")
        local Heart = Map and Map:FindFirstChild("FrozenHeart")
        local HeartPos = Heart and GetHeartPos(Heart)
        if not HeartPos then return false end
        local Dist = (HeartPos - seat.Position).Magnitude
        if Dist > 3000 then return false end
        return true
    end
    local TotalStart = os.clock()
    local Returned = false
    while _G.AutoLeviathanFull and os.clock() - TotalStart < 1800 do
        local Map = workspace:FindFirstChild("Map")
        local Heart = Map and Map:FindFirstChild("FrozenHeart")
        if not Heart then break end
        local HeartPos = Heart and GetHeartPos(Heart)
        if not HeartPos then break end
        if not DriverSeat or not DriverSeat.Parent then
            local b2 = GetOwnBoat()
            if not b2 then break end
            DriverSeat = b2:FindFirstChild("VehicleSeat")
            if not DriverSeat or not BoardSeatRetry(DriverSeat) then break end
        end
        local WentToHeart = false
        local BoatPos = DriverSeat.Position
        local Dist3D = (HeartPos - BoatPos).Magnitude
        if Dist3D > 3000 then
            SailToCF(DriverSeat, CFrame.new(HeartPos.X, BoatPos.Y, HeartPos.Z), Speed)
            local HoldStart = os.clock()
            while _G.AutoLeviathanFull and os.clock() - HoldStart < 1.5 do task.wait(0.2) end
            WentToHeart = true
        end
        if not WentToHeart then
            local R1 = SailToCF(DriverSeat, TikiWaypointCF, Speed, HeartCloseCheck)
            if R1 then
                local R2 = SailToCF(DriverSeat, TikiReturnCF, Speed, HeartCloseCheck)
                pcall(function() DriverSeat.CFrame = TikiReturnCF end)
                if R2 then Returned = true break end
            end
        end
    end
    return Returned
end

local function NearestPlayerDistance(boat)
    local _, hrp = GetCharacterParts()
    if not hrp then return math.huge end
    local Min = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local OnThisBoat = hum and hum.SeatPart ~= nil and boat ~= nil and hum.SeatPart:IsDescendantOf(boat)
                if not OnThisBoat then
                    local d = (root.Position - hrp.Position).Magnitude
                    if d < Min then Min = d end
                end
            end
        end
    end
    return Min
end

local function CountTeammatesOnBoat(boat)
    if not boat or not boat.Parent then return 0 end
    local Count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if seat and seat.Parent and seat:IsDescendantOf(boat) and hum.Sit then Count = Count + 1 end
        end
    end
    return Count
end

local function WaitForTeammates(boat, DriverSeat, ShouldStop, FightEvents, NoRebuy, MaxWait, FarImmediate)
    if FightEvents == nil then FightEvents = true end
    local FarStart = nil
    local WaitStart = os.clock()
    local LastHopOffAt = os.clock()
    local LastCrewCount = -1
    while _G.AutoLeviathanFull do
        if _G.SoloSeaFarm then return boat, DriverSeat, false end
        if MaxWait and os.clock() - WaitStart >= MaxWait then return boat, DriverSeat, false end
        if ShouldStop and ShouldStop() then return boat, DriverSeat, true end
        if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then
            if not BoardSeatRetry(DriverSeat) then
                local b2 = GetOwnBoat()
                if not b2 then return boat, DriverSeat, false end
                local s2 = b2:FindFirstChild("VehicleSeat")
                if not s2 then return boat, DriverSeat, false end
                boat, DriverSeat = b2, s2
            end
        end
        if not boat or not boat.Parent then return boat, DriverSeat, false end
        if CountTeammatesOnBoat(boat) >= 4 then return boat, DriverSeat, false end
        if not NoRebuy then
            local ND = NearestPlayerDistance(boat)
            local RebuyCd = os.clock() - LastRebuyAt
            if FarImmediate then
                if ND > 10000 and RebuyCd >= 60 then
                    local b3, s3 = RebuyBoatAndBoard()
                    if b3 and s3 then boat, DriverSeat = b3, s3 end
                end
            elseif ND > 12000 then
                if RebuyCd >= 60 then
                    FarStart = FarStart or os.clock()
                    if os.clock() - FarStart >= 30 then
                        FarStart = nil
                        local b3, s3 = RebuyBoatAndBoard()
                        if b3 and s3 then boat, DriverSeat = b3, s3 end
                    end
                else
                    FarStart = nil
                end
            else
                FarStart = nil
            end
        else
            FarStart = nil
        end
        local Mob, Root, Skill = SeaAPI.Sea_Mob()
        if FightEvents and Mob and Root then
            if not Unseat() then end
            local Stuck = {}
            while _G.AutoLeviathanFull do
                if ShouldStop and ShouldStop() then break end
                if CountTeammatesOnBoat(boat) >= 4 then break end
                local M, R, S = SeaAPI.Sea_Mob(SeaAPI.SearchRange, Stuck)
                if not M or not R then break end
                SeaAPI.FightSeaEvent(M, R, S)
                if SeaAPI.Sea_MobStillAlive(M) then Stuck[M] = true end
                task.wait(0.5)
            end
            if DriverSeat and DriverSeat.Parent then BoardSeatRetry(DriverSeat) end
        else
            local CrewNow = CountTeammatesOnBoat(boat)
            if CrewNow ~= LastCrewCount then
                LastCrewCount = CrewNow
                LastHopOffAt = os.clock()
            end
            if os.clock() - LastHopOffAt >= 30 then
                LastHopOffAt = os.clock()
                if Unseat() then
                    task.wait(0.4)
                    if DriverSeat and DriverSeat.Parent then BoardSeatRetry(DriverSeat, 5, 2) end
                end
            end
            task.wait(1)
        end
    end
    return boat, DriverSeat, false
end

local function CaptainFarmPhase()
    local boat = GetOwnBoat()
    if not boat then
        BuyOwnBoat()
        local SpawnStart = os.clock()
        while _G.AutoLeviathanFull and not _G.RJR_Resetting and os.clock() - SpawnStart < 20 do
            boat = GetOwnBoat()
            if boat then break end
            task.wait(0.5)
        end
    end
    if not boat then return end
    local DriverSeat = boat:FindFirstChild("VehicleSeat")
    if not DriverSeat then return end
    if not BoardSeatRetry(DriverSeat) then return end
    if _G.SoloSeaFarm then SetStatus("Solo farm: skipping teammates")
    else boat, DriverSeat = WaitForTeammates(boat, DriverSeat, nil, true, false, nil, true) end
    local FarmDone = false
    local FarmStart = os.clock()
    if not _G.SoloSeaFarm then
        task.spawn(function()
            while _G.AutoLeviathanFull and not FarmDone do
                task.wait(2)
                local S = GetBribeStatus()
                if S == nil or S ~= -1 then FarmDone = true end
            end
        end)
    end
    local LastTeamCheck = 0
    local LastMobCheck = 0
    local LastSlowCheck = 0
    local Fought = {}
    local Mob, Root, Skill = nil, nil, false
    while _G.AutoLeviathanFull and not FarmDone do
        if os.clock() - LastSlowCheck >= 0.4 then
            LastSlowCheck = os.clock()
            local MapX = workspace:FindFirstChild("Map")
            if SeaAPI.Leviathan_SegmentsExist() or (MapX and MapX:FindFirstChild("LeviathanGate")) then break end
            local b2 = GetOwnBoat()
            local s2 = b2 and b2:FindFirstChild("VehicleSeat")
            if b2 and s2 then
                boat = b2
                DriverSeat = s2
            elseif _G.AutoLeviathanFull then
                local _, _, humR = GetCharacterParts()
                if humR and humR.Health > 0 then
                    local b3, s3 = RebuyBoatAndBoard()
                    if b3 and s3 then boat, DriverSeat = b3, s3 end
                end
            end
        end
        if os.clock() - LastTeamCheck >= 1 then
            LastTeamCheck = os.clock()
            if not _G.SoloSeaFarm and CountTeammatesOnBoat(boat) < 4 then
                local b3, s3, Stopped = WaitForTeammates(boat, DriverSeat, function() return FarmDone end, true, false, nil, true)
                boat, DriverSeat = b3, s3
                if Stopped then break end
                task.wait(0.5)
            else
                local b2 = GetOwnBoat()
                local s2 = b2 and b2:FindFirstChild("VehicleSeat")
                if b2 and s2 then boat, DriverSeat = b2, s2 end
            end
        end
        if os.clock() - LastMobCheck >= 0.2 then
            LastMobCheck = os.clock()
            Mob, Root, Skill = SeaAPI.Sea_Mob(4000, Fought)
        end
        if Mob and Root then
            if not Unseat() then end
            while _G.AutoLeviathanFull and not FarmDone do
                local M, R, S = SeaAPI.Sea_Mob(4000, Fought)
                if not M or not R then break end
                SeaAPI.FightSeaEvent(M, R, S)
                if SeaAPI.Sea_MobStillAlive(M) then Fought[M] = true end
                task.wait(0.5)
            end
            if DriverSeat and DriverSeat.Parent then BoardSeatRetry(DriverSeat) end
            LastTeamCheck = 0
            LastMobCheck = 0
        else
            if not DriverSeat or not DriverSeat.Parent then task.wait(0.2)
            elseif not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then BoardSeat(DriverSeat, 3)
            else
                local staying = SailBoatStream(DriverSeat, _G.BoatSpeed)
                if staying == false then
                    local b3, s3 = RebuyBoatAndBoard()
                    if b3 and s3 then boat, DriverSeat = b3, s3 end
                end
            end
        end
    end
end

local function HeartFinishPhase()
    if _G.AutoLeviathanFull and not GetOwnBoat() then
        BuyOwnBoat()
        local BoatWaitStart = os.clock()
        while _G.AutoLeviathanFull and not _G.RJR_Resetting and os.clock() - BoatWaitStart < 30 do
            if GetOwnBoat() then break end
            task.wait(0.5)
        end
    end
    local Grabbed = HarpoonHeart()
    if not Grabbed then return end
    local PreSyncStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - PreSyncStart < 2 do task.wait(0.25) end
    local boat = GetOwnBoat()
    local DriverSeat = boat and boat:FindFirstChild("VehicleSeat")
    if DriverSeat and not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then BoardSeatRetry(DriverSeat) end
    local PostBoardStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - PostBoardStart < 2 do task.wait(0.25) end
    local Returned = ReturnTiki(300)
    local HeartLockDone = false
    if Returned then
        task.spawn(function()
            while _G.AutoLeviathanFull and not HeartLockDone do
                pcall(function()
                    local bL = GetOwnBoat()
                    local sL = bL and bL:FindFirstChild("VehicleSeat")
                    if sL and (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == sL) then
                        local _, hrpL = GetCharacterParts()
                        if hrpL then hrpL.CFrame = CFrame.new(TikiReturnCF.Position.X, hrpL.Position.Y, TikiReturnCF.Position.Z) * (hrpL.CFrame - hrpL.CFrame.Position) end
                        sL.ThrottleFloat = 1
                        sL.SteerFloat = 0
                    end
                end)
                task.wait(0.2)
            end
        end)
    end
    local WaitStart = os.clock()
    local LastHeartScan = 0
    while _G.AutoLeviathanFull and os.clock() - WaitStart < 1800 do
        local Map = workspace:FindFirstChild("Map")
        local Heart = Map and Map:FindFirstChild("FrozenHeart")
        local HeartGone = not Heart
        if Heart and Heart:IsA("BasePart") then HeartGone = Heart.Transparency >= 1
        elseif Heart then
            local primary = Heart:IsA("Model") and Heart.PrimaryPart
            local PrimaryGone = primary == nil or primary.Transparency >= 1
            if PrimaryGone and os.clock() - LastHeartScan >= 5 then
                LastHeartScan = os.clock()
                local AnyVisible = false
                for _, p in ipairs(Heart:GetDescendants()) do
                    if p:IsA("BasePart") and p.Transparency < 1 then AnyVisible = true break end
                end
                HeartGone = not AnyVisible
            end
        end
        if HeartGone then HeartLockDone = true break end
        task.wait(2)
    end
    HeartLockDone = true
    if not _G.AutoLeviathanFull then return end
    if not Unseat() then end
    local OldBoat = GetOwnBoat()
    BuyOwnBoat()
    local SpawnStart = os.clock()
    while _G.AutoLeviathanFull and not _G.RJR_Resetting and os.clock() - SpawnStart < 20 do
        local b3 = GetOwnBoat()
        if b3 and b3 ~= OldBoat then break end
        task.wait(0.5)
    end
end

local HuntStart = nil
local function CaptainHuntPhase()
    if HuntStart == nil then HuntStart = os.clock() end
    local HuntSuccess = false
    local MapEarly = workspace:FindFirstChild("Map")
    if SeaAPI.Leviathan_SegmentsExist() or (MapEarly and MapEarly:FindFirstChild("LeviathanGate")) then HuntSuccess = true end
    local boat = nil
    local DriverSeat = nil
    if not HuntSuccess then
        boat = GetOwnBoat()
        if not boat then
            BuyOwnBoat()
            local SpawnStart = os.clock()
            while _G.AutoLeviathanFull and not _G.RJR_Resetting and os.clock() - SpawnStart < 20 do
                boat = GetOwnBoat()
                if boat then break end
                task.wait(0.5)
            end
        end
        if not boat then return end
        DriverSeat = boat:FindFirstChild("VehicleSeat")
        if not DriverSeat then return end
        if not BoardSeatRetry(DriverSeat) then return end
        NoClip(true)
    end
    local LastHuntCheck = 0
    local LastTeamCheck2 = 0
    local LastMobCheck = 0
    while _G.AutoLeviathanFull and not HuntSuccess do
        if not boat or not boat.Parent or _G.RJR_AbandonedBoats[boat] then return end
        if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart == DriverSeat) then
            if not BoardSeatRetry(DriverSeat, 5, 2) then return end
        end
        if os.clock() - LastHuntCheck >= 0.2 then
            LastHuntCheck = os.clock()
            local Map = workspace:FindFirstChild("Map")
            if SeaAPI.Leviathan_SegmentsExist() or (Map and Map:FindFirstChild("LeviathanGate")) then HuntSuccess = true break end
        end
        if os.clock() - LastTeamCheck2 >= 1 then
            LastTeamCheck2 = os.clock()
            if not _G.SoloSeaFarm and CountTeammatesOnBoat(boat) < 4 then
                local b3, s3 = WaitForTeammates(boat, DriverSeat, nil, _G.HuntFightEvents)
                boat, DriverSeat = b3, s3
                if not boat or not DriverSeat or not boat.Parent then return end
                task.wait(0.5)
            end
        end
        if _G.HuntFightEvents and os.clock() - LastMobCheck >= 0.5 then
            LastMobCheck = os.clock()
            local Mob, Root, Skill = SeaAPI.Sea_Mob(4000)
            if Mob and Root then
                if not Unseat() then end
                local Stuck = {}
                while _G.AutoLeviathanFull do
                    local MapX = workspace:FindFirstChild("Map")
                    if SeaAPI.Leviathan_SegmentsExist() or (MapX and MapX:FindFirstChild("LeviathanGate")) then break end
                    local M, R, S = SeaAPI.Sea_Mob(4000, Stuck)
                    if not M or not R then break end
                    SeaAPI.FightSeaEvent(M, R, S, function()
                        local MapX2 = workspace:FindFirstChild("Map")
                        return SeaAPI.Leviathan_SegmentsExist() or (MapX2 and MapX2:FindFirstChild("LeviathanGate"))
                    end)
                    if SeaAPI.Sea_MobStillAlive(M) then Stuck[M] = true end
                    task.wait(0.5)
                end
                if DriverSeat and DriverSeat.Parent then BoardSeatRetry(DriverSeat) end
                LastTeamCheck2 = 0
            end
        end
        local staying = SailBoatStream(DriverSeat, _G.BoatSpeed)
        if staying == false then
            local b3, s3 = RebuyBoatAndBoard()
            if b3 and s3 then boat, DriverSeat = b3, s3 end
        end
    end
    if not HuntSuccess then return end
    HuntStart = nil
    if not Unseat() then return end
    OpenLeviathanGate()
    local Killed = SeaAPI.FightLeviathan(nil, 8)
    if not Killed then return end
    if _G.AutoLeviathanFull and not GetOwnBoat() then
        BuyOwnBoat()
        local BoatWaitStart = os.clock()
        while _G.AutoLeviathanFull and not _G.RJR_Resetting and os.clock() - BoatWaitStart < 30 do
            if GetOwnBoat() then break end
            task.wait(0.5)
        end
    end
    local HeartStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - HeartStart < 900 do
        local Map = workspace:FindFirstChild("Map")
        if Map and Map:FindFirstChild("FrozenHeart") then break end
        task.wait(1)
    end
    local PostHeartStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - PostHeartStart < 5 do task.wait(0.5) end
    HeartFinishPhase()
end

local CaptainRunning = false
local function StartCaptain()
    if CaptainRunning then return end
    CaptainRunning = true
    task.spawn(function()
        while _G.AutoLeviathanFull and _G.Mode == "Capitán" do
            local ok, err = pcall(function()
                local Map = workspace:FindFirstChild("Map")
                local Heart = Map and Map:FindFirstChild("FrozenHeart")
                if Heart and not _G.SoloSeaFarm then
                    HeartFinishPhase()
                    return
                end
                if not _G.SoloSeaFarm then
                    local S = GetBribeStatus()
                    if S == nil then task.wait(2) return end
                    if S ~= -1 and S ~= 5 then BribeUntilDone() S = GetBribeStatus() end
                    if SeaAPI.Leviathan_SegmentsExist() or (Map and Map:FindFirstChild("LeviathanGate")) then
                        CaptainHuntPhase()
                        return
                    end
                    if S == 5 then CaptainHuntPhase()
                    else CaptainFarmPhase() end
                else
                    CaptainFarmPhase()
                end
            end)
            task.wait(1)
        end
        CaptainRunning = false
    end)
end

local FollowerRunning = false
local LastLeviathanSeen = 0
local FollowSeatsFull = false

local function IsOnCaptainBoat(boat)
    local _, _, hum = GetCharacterParts()
    if not hum or not hum.SeatPart then return false end
    return hum.SeatPart:IsDescendantOf(boat)
end

local function IsCaptainOnBoat(boat)
    local captain = Players:FindFirstChild(_G.FollowTarget)
    local char = captain and captain.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local DriverSeat = boat and boat:FindFirstChild("VehicleSeat")
    return hum ~= nil and DriverSeat ~= nil and hum.SeatPart == DriverSeat
end

local function GetCaptainHRP()
    local captain = Players:FindFirstChild(_G.FollowTarget)
    local char = captain and captain.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function LiveCaptainTopCF(height)
    return function()
        local capHrp = GetCaptainHRP()
        if not capHrp then return nil end
        return CFrame.new(capHrp.Position + Vector3.new(0, height or 35, 0)) * KeepFacing()
    end
end

local function FollowerBoardSeat(boat)
    local cannons = {}
    if boat then
        for _, child in ipairs(boat:GetChildren()) do
            if child.Name == "Cannon" then table.insert(cannons, child) end
        end
    end
    local _, hrp0 = GetCharacterParts()
    local firstSeat = boat and (boat:FindFirstChild("VehicleSeat") or cannons[1])
    if hrp0 and firstSeat and (hrp0.Position - firstSeat.Position).Magnitude > 2500 then
        if (hrp0.Position - firstSeat.Position).Magnitude > BoatFindRange then return false end
        local FlyStart = os.clock()
        while _G.AutoLeviathanFull and os.clock() - FlyStart < 30 do
            local _, hrp1 = GetCharacterParts()
            if not hrp1 or not firstSeat or not firstSeat.Parent then break end
            if (hrp1.Position - firstSeat.Position).Magnitude <= 500 then break end
            _tp(function() return firstSeat.Parent and firstSeat.CFrame or nil end, function()
                local _, h = GetCharacterParts()
                return (not firstSeat.Parent) or (not h) or (firstSeat.Position - h.Position).Magnitude <= 500
            end)
            task.wait(0.1)
        end
    end
    local tried = {}
    local BoardStart = os.clock()
    while _G.AutoLeviathanFull and os.clock() - BoardStart < 25 do
        local seat = nil
        for _, cannon in ipairs(cannons) do
            local s = cannon:FindFirstChild("Seat")
            if s and not tried[s] then
                local isOccupied = false
                local Weld = s:FindFirstChild("SeatWeld")
                if Weld and Weld.Part1 and Weld.Part1:IsA("BasePart") and Weld.Part1:IsDescendantOf(workspace) then
                    local ownerChar = Weld.Part1:FindFirstAncestorWhichIsA("Model")
                    local hum = ownerChar and ownerChar:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then isOccupied = true end
                end
                if not isOccupied then seat = s break end
            end
        end
        if not seat then FollowSeatsFull = true return false end
        if BoardSeat(seat, 0.5) then
            FollowSeatsFull = false
            return true
        end
        tried[seat] = true
    end
    return false
end

local function FollowerHeartWait()
    if CurrentTween then pcall(function() CurrentTween:Cancel() CurrentTween = nil end) end
    Tweening = false
    Unseat()
    local StartAt = os.clock()
    local LastTPPos = nil
    while _G.AutoLeviathanFull and _G.Mode == "Seguidor" do
        local Map = workspace:FindFirstChild("Map")
        local Heart = Map and Map:FindFirstChild("FrozenHeart")
        if not Heart then return end
        local hp = GetHeartPos(Heart)
        if hp and (LastTPPos == nil or (hp - LastTPPos).Magnitude > 20) then
            LastTPPos = hp
            _tp(LiveHeartCF(35), function() return not _G.AutoLeviathanFull end)
        end
        task.wait(1)
    end
end

local function StartFollower()
    if FollowerRunning then return end
    FollowerRunning = true
    local function CaptainBackOnBoat()
        local boat = GetCaptainBoat()
        return IsCaptainOnBoat(boat)
    end
    task.spawn(function()
        local GateTweening = false
        while _G.AutoLeviathanFull and _G.Mode == "Seguidor" do
            local ok, err = pcall(function()
                local boat = GetCaptainBoat()
                local CaptainOn = boat ~= nil and IsCaptainOnBoat(boat)
                local Map = workspace:FindFirstChild("Map")
                local Heart = Map and Map:FindFirstChild("FrozenHeart")
                local HeartPos = Heart and GetHeartPos(Heart)
                local HeartGrabbed = HeartPos ~= nil and IsFrozenHeartHarpooned()
                if Heart then FollowerHeartWait() return end
                if HeartGrabbed then
                    if boat then
                        if not IsOnCaptainBoat(boat) then FollowerBoardSeat(boat) end
                    else
                        if GetCaptainHRP() then _tp(LiveCaptainTopCF(35), function() return not _G.AutoLeviathanFull end) end
                    end
                    return
                end
                local LV = SeaAPI.Leviathan_Find()
                if LV then
                    if GateTweening then
                        GateTweening = false
                        if CurrentTween then pcall(function() CurrentTween:Cancel() CurrentTween = nil end) end
                        Tweening = false
                    end
                    if boat and IsOnCaptainBoat(boat) then Unseat() end
                    LastLeviathanSeen = os.clock()
                    SeaAPI.FightLeviathan(CaptainBackOnBoat, 10)
                    return
                end
                if boat and CaptainOn then
                    if not IsOnCaptainBoat(boat) then FollowerBoardSeat(boat) end
                else
                    if boat and IsOnCaptainBoat(boat) then Unseat() end
                    local MapG = workspace:FindFirstChild("Map")
                    local Gate = MapG and MapG:FindFirstChild("LeviathanGate")
                    local Watcher = Gate and Gate:FindFirstChild("FrozenWatcherPart")
                    if Watcher and SeaAPI.Leviathan_SegmentsExist() then
                        if GateTweening then
                            GateTweening = false
                            if CurrentTween then pcall(function() CurrentTween:Cancel() CurrentTween = nil end) end
                            Tweening = false
                        end
                    elseif Watcher and os.clock() - LastLeviathanSeen >= 120 then
                        GateTweening = true
                        local WatcherPos = TargetPos(Watcher)
                        if WatcherPos then
                            _tp(LiveGateCF(5), function() return (not _G.AutoLeviathanFull) or SeaAPI.Leviathan_SegmentsExist() end)
                            GateTweening = false
                        end
                    elseif Heart then
                        local HeartPos2 = GetHeartPos(Heart)
                        if HeartPos2 then _tp(LiveHeartCF(35), function() return not _G.AutoLeviathanFull end) end
                    elseif os.clock() - LastLeviathanSeen < 120 then
                        local capHrp = GetCaptainHRP()
                        if capHrp then _tp(LiveCaptainTopCF(35), function() return not _G.AutoLeviathanFull end) end
                    else
                        local Mob, Root, Skill = nil, nil, false
                        if _G.HuntFightEvents then Mob, Root, Skill = SeaAPI.Sea_Mob(4000) end
                        if Mob and Root then SeaAPI.FightSeaEvent(Mob, Root, Skill, CaptainBackOnBoat)
                        else
                            if not (GetCharacterParts() and select(3, GetCharacterParts()).SeatPart) then
                                if GetCaptainHRP() then _tp(LiveCaptainTopCF(35), function() return not _G.AutoLeviathanFull end) end
                            end
                        end
                    end
                end
            end)
            task.wait(0.2)
        end
        FollowerRunning = false
    end)
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Redstone Hub",
    SubTitle = "Auto Leviathan",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.G,
})

local ImageGui = Instance.new("ScreenGui")
ImageGui.Name = "RedstoneImage"
ImageGui.ResetOnSpawn = false
ImageGui.IgnoreGuiInset = true
ImageGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ImageGui.DisplayOrder = 999
ImageGui.Parent = game:GetService("CoreGui")

local Image = Instance.new("ImageLabel")
Image.Name = "GlitchEye"
Image.Parent = ImageGui
Image.BackgroundTransparency = 1
Image.Image = "rbxassetid://1234567890"
Image.Size = UDim2.new(0, 250, 0, 250)
Image.Position = UDim2.new(1, -260, 1, -260)
Image.AnchorPoint = Vector2.new(0, 0)
Image.ImageTransparency = 0.5
Image.ZIndex = 1

local Tabs = {
    Status = Window:AddTab({ Title = "Status", Icon = "info" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Perf = Window:AddTab({ Title = "Perf", Icon = "zap" }),
    Config = Window:AddTab({ Title = "Config", Icon = "settings" }),
}

local ModeSection = Tabs.Status:AddSection("Mode")
local PlayerDropdown
local PlayerListOptions = {}

local function RefreshPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    table.sort(list)
    if #list == 0 then list = { "--" } end
    PlayerListOptions = list
    if PlayerDropdown then pcall(function() PlayerDropdown:SetValues(list) end) end
end

ModeSection:AddDropdown("mode.select", {
    Title = "Select Mode",
    Values = { "Captain", "Follower" },
    Default = "Captain",
    Multi = false,
    Callback = function(Value) _G.Mode = (Value == "Captain") and "Capitán" or "Seguidor" end,
})

PlayerDropdown = ModeSection:AddDropdown("follow.player", {
    Title = "Follow Player",
    Values = PlayerListOptions,
    Default = nil,
    Multi = false,
    Callback = function(Value) _G.FollowTarget = Value end,
})

ModeSection:AddButton({ Title = "Refresh Players", Callback = function() RefreshPlayerList() end })

local MainSection = Tabs.Status:AddSection("Main Controls")

MainSection:AddToggle("auto.full", {
    Title = "Auto Leviathan Full",
    Default = _G.AutoLeviathanFull,
    Callback = function(State)
        _G.AutoLeviathanFull = State
        if State then
            if _G.Mode == "Capitán" then StartCaptain() else StartFollower() end
        else StopTweenAll() end
    end,
})

MainSection:AddButton({
    Title = "Stop All",
    Callback = function()
        _G.AutoLeviathanFull = false
        StopTweenAll()
    end,
})

local TravelSection = Tabs.Status:AddSection("Travel")
TravelSection:AddInput("boat.speed", {
    Title = "Boat Speed",
    Default = tostring(_G.BoatSpeed),
    Numeric = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then _G.BoatSpeed = math.clamp(num, 50, 500) end
    end,
})

TravelSection:AddInput("boat.height", {
    Title = "Boat Height",
    Default = tostring(_G.BoatHeight),
    Numeric = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then _G.BoatHeight = math.clamp(num, 30, 500) end
    end,
})

local CombatSection = Tabs.Combat:AddSection("Combat Settings")
CombatSection:AddDropdown("sel.weapon", {
    Title = "Select Weapon",
    Values = { "Melee", "Sword", "Gun" },
    Default = _G.SelectWeapon,
    Multi = false,
    Callback = function(Value) _G.SelectWeapon = Value end,
})

CombatSection:AddToggle("silent.aim", {
    Title = "Silent Aim",
    Default = _G.SilentAim,
    Callback = function(State) _G.SilentAim = State end,
})

CombatSection:AddToggle("fast.attack", {
    Title = "Fast Attack",
    Default = _G.FastAttack,
    Callback = function(State) _G.FastAttack = State end,
})

CombatSection:AddToggle("dragon.leviathan", {
    Title = "Dragonstorm vs Leviathan",
    Default = _G.DragonGunLeviathan,
    Callback = function(State)
        _G.DragonGunLeviathan = State
        if State then SeaAPI.InitDragon() end
    end,
})

local PerfSection = Tabs.Perf:AddSection("Performance")
PerfSection:AddToggle("fps.boost", {
    Title = "FPS Boost",
    Default = _G.FPSBoost,
    Callback = function(State)
        _G.FPSBoost = State
        if State then
            pcall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                for _, item in ipairs(lighting:GetDescendants()) do
                    if item:IsA("BlurEffect") or item:IsA("SunRaysEffect") or item:IsA("ColorCorrectionEffect") or item:IsA("BloomEffect") or item:IsA("DepthOfFieldEffect") then item.Enabled = false end
                end
                local terrain = workspace.Terrain
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 0
                end
            end)
        end
    end,
})

local ThemeSection = Tabs.Config:AddSection("UI Themes")
ThemeSection:AddDropdown("theme.select", {
    Title = "Select Theme",
    Values = { "Dark", "Light", "Aqua", "Rose", "Gravel" },
    Default = "Dark",
    Multi = false,
    Callback = function(Value) Window:SetTheme(Value) end,
})

pcall(function()
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager.Settings.MenuKeybind = "G"
    InterfaceManager:SetFolder("RedstoneHub")
    SaveManager:SetFolder("RedstoneHub/configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:LoadAutoloadConfig()
end)

local function Update_Character()
    Character = LocalPlayer.Character
    HD = Character and (Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid"))
    HRP = Character and (Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart"))
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    Update_Character()
    task.wait(2)
    Haki_Auto()
end)

LocalPlayer.CharacterRemoving:Connect(function()
    Character = nil
    HD = nil
    HRP = nil
    NoclipOn = false
    LastNoclipApply = 0
end)

task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoLeviathanFull and _G.FastAttack then
            local _, _, hum = GetCharacterParts()
            if hum and hum.SeatPart == nil and not hum.Sit then pcall(Attack_Auto) end
        end
    end
end)

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            if _G.AutoLeviathanFull and _G.SilentAim and (tostring(self) == "RemoteEvent" or tostring(self) == "CommE") then
                local char = LocalPlayer.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                local target = AttackModel and AttackModel:FindFirstChild("HumanoidRootPart")
                if myHRP and target then
                    local args = {...}
                    for i, v in pairs(args) do
                        if typeof(v) == "Vector3" then args[i] = target.Position end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

RefreshPlayerList()
Window:SelectTab(1)
