if _G.RedstoneUltimateLoaded then
    if not (getgenv and getgenv().ForceReload) then return end
    getgenv().ForceReload = false
end
_G.RedstoneUltimateLoaded = true

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CommF = RS:FindFirstChild("Remotes") and RS:FindFirstChild("CommF_")

local ConfigFolder = "RedstoneUltimate"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local Character = LocalPlayer.Character
local HD = Character and Character:FindFirstChild("Humanoid")
local HRP = Character and Character:FindFirstChild("HumanoidRootPart")

local Tweening, TpActive, CurrentTween = false, false, nil
local HoldCFrame, LiveHoldFn = nil, nil
local NoclipOn, LastNoclipApply = false, 0
local AttackModel, AttackStandFn, FightTarget = nil, nil, nil
local SkillCoolDown = false

local function GetCharacterParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function NoClip(v)
    local char, hrp, hum = GetCharacterParts()
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    if v then
        if NoclipOn and os.clock() - LastNoclipApply < 0.5 then return end
        NoclipOn = true
        LastNoclipApply = os.clock()
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    else
        NoclipOn = false
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

local function GetTweenPart()
    local part = workspace:FindFirstChild("RedstoneTweenPart")
    if part and part:IsA("BasePart") then return part end
    part = Instance.new("Part")
    part.Name = "RedstoneTweenPart"
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

local function _tp(targetPos, abortCheck, allowNavigationOwner)
    if _G.StopTween then return false end
    local startChar = LocalPlayer.Character
    local myHRP = select(2, GetCharacterParts())
    if not myHRP then return false end
    
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
    
    local tweenSpeed = 300
    if CurrentTween then pcall(function() CurrentTween:Cancel() end) CurrentTween = nil end

    local tween = nil
    if not liveTarget then
        local distance = (targetCFrame.Position - myHRP.Position).Magnitude
        local duration = math.max(distance / tweenSpeed, 0.05)
        tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        CurrentTween = tween
    end

    Tweening = true
    TpActive = true
    local aborted, arrived, seatedStop = false, false, false
    
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
            local ok, stop = pcall(abortCheck)
            if ok and stop then aborted = true if tween then tween:Cancel() end end
        end
    end)

    pcall(function()
        if liveTarget then
            local timeout = tick() + 15
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
    return not aborted
end

local function StopTweenAll()
    _G.StopTween = true
    if CurrentTween then pcall(function() CurrentTween:Cancel() end) CurrentTween = nil end
    Tweening, TpActive = false, false
    NoClip(false)
    HoldCFrame, LiveHoldFn = nil, nil
    task.defer(function() task.wait(0.1) _G.StopTween = false end)
end

local function Unseat()
    HoldCFrame, LiveHoldFn = nil, nil
    for _ = 1, 3 do
        local _, hrp, hum = GetCharacterParts()
        if not hum or (not hum.Sit and hum.SeatPart == nil) then return true end
        StandUpFromSeat(hum.SeatPart, hum, hrp)
        task.wait(0.2)
    end
    return false
end

local function BoardSeat(seat, timeout)
    timeout = timeout or 15
    if not seat or not seat.Parent then return false end
    local Deadline = os.clock() + timeout
    while os.clock() < Deadline do
        local _, hrp, hum = GetCharacterParts()
        if hum and hum.SeatPart == seat then return true end
        if hum and (hum.Sit or hum.SeatPart ~= nil) then Unseat() task.wait(0.3) end
        if hrp then
            _tp(seat.CFrame, function()
                local _, _, humNow = GetCharacterParts()
                return humNow ~= nil and humNow.SeatPart ~= nil
            end)
        end
        task.wait(0.2)
    end
    return false
end

local SeaAPI = {}
do
    local function Sea_MobStillAlive(Mob)
        if not Mob or not Mob.Parent then return false end
        local Health = Mob:FindFirstChild("Health")
        if Health and Health:IsA("ValueBase") and Health.Value <= 0 then return false end
        local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
        if Humanoid and Humanoid.Health <= 0 then return false end
        return true
    end

    local function Sea_EventRoot(Mob)
        if not Mob then return nil end
        return Mob:FindFirstChild("HumanoidRootPart") or Mob:FindFirstChild("RootPart") or Mob.PrimaryPart or Mob:FindFirstChildWhichIsA("BasePart", true)
    end

    local function Sea_Mob(MaxDistance)
        MaxDistance = MaxDistance or 4000
        local _, hrp = GetCharacterParts()
        if not hrp then return nil end
        local MobList = {
            {Name = "Terrorshark", Folder = workspace:FindFirstChild("Enemies")},
            {Name = "Piranha", Folder = workspace:FindFirstChild("Enemies")},
            {Name = "Shark", Folder = workspace:FindFirstChild("Enemies")},
            {Name = "FishBoat", Folder = workspace:FindFirstChild("Enemies")},
            {Name = "PirateBrigade", Folder = workspace:FindFirstChild("Enemies")},
            {Name = "SeaBeast1", Folder = workspace:FindFirstChild("SeaBeasts")},
        }
        local Best, BestRoot, BestDist = nil, nil, MaxDistance
        for _, Data in ipairs(MobList) do
            if Data.Folder then
                for _, Mob in ipairs(Data.Folder:GetChildren()) do
                    if Mob.Name == Data.Name and Sea_MobStillAlive(Mob) then
                        local Root = Sea_EventRoot(Mob)
                        if Root then
                            local Dist = (Root.Position - hrp.Position).Magnitude
                            if Dist < BestDist then Best, BestRoot, BestDist = Mob, Root, Dist end
                        end
                    end
                end
            end
        end
        return Best, BestRoot
    end

    local function Leviathan_Find()
        local SeaBeasts = workspace:FindFirstChild("SeaBeasts")
        if not SeaBeasts then return nil, nil end
        for _, model in ipairs(SeaBeasts:GetChildren()) do
            if model.Name == "Leviathan Segment" and Sea_MobStillAlive(model) then
                return model, Sea_EventRoot(model)
            end
        end
        local lev = SeaBeasts:FindFirstChild("Leviathan")
        if lev and Sea_MobStillAlive(lev) then return lev, Sea_EventRoot(lev) end
        return nil, nil
    end

    local function FightSeaEvent(Mob, Root)
        local start = os.clock()
        while _G.AutoSeaEvent and os.clock() - start < 600 do
            if not Mob or not Mob.Parent or not Sea_MobStillAlive(Mob) then break end
            local _, hrp = GetCharacterParts()
            if not hrp then break end
            local targetPos = Root.Position + Vector3.new(0, 30, 0)
            _tp(targetPos)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if LocalPlayer.Backpack:FindFirstChild("Dragonstorm") then
                    hum:EquipTool(LocalPlayer.Backpack.Dragonstorm)
                else
                    hum:EquipTool(LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool"))
                end
            end
            local args = {[1] = "RegisterAttack"}
            pcall(function() RS.Modules.Net["RE/RegisterAttack"]:FireServer() end)
            pcall(function() RS.Modules.Net["RE/RegisterHit"]:FireServer(Root, {{Mob, Root}}) end)
            task.wait(0.1)
        end
    end

    SeaAPI.Sea_Mob = Sea_Mob
    SeaAPI.Leviathan_Find = Leviathan_Find
    SeaAPI.FightSeaEvent = FightSeaEvent
end

local function DoAutoFarm()
    task.spawn(function()
        while _G.AutoFarm do
            task.wait(0.1)
            if not LocalPlayer.Character then break end
            local _, hrp = GetCharacterParts()
            if not hrp then break end
            
            if _G.FarmMode == "Level" then
                local mob = SeaAPI.Sea_Mob(1000)
                if mob then
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if root then
                        _tp(root.Position + Vector3.new(0, 30, 0))
                        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")) end
                        pcall(function() RS.Modules.Net["RE/RegisterAttack"]:FireServer() end)
                        pcall(function() RS.Modules.Net["RE/RegisterHit"]:FireServer(root, {{mob, root}}) end)
                    end
                end
            elseif _G.FarmMode == "Fruit" then
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("Tool") and string.find(v.Name, "Fruit") then
                        if v:FindFirstChild("Handle") then
                            _tp(v.Handle.CFrame)
                            task.wait(1)
                        end
                    end
                end
            end
        end
    end)
end

local function GetSeaName()
    local placeId = game.PlaceId
    if placeId == 2753915549 or placeId == 4442272183 then return "First Sea" end
    if placeId == 4442272183 or placeId == 79091703265657 then return "Second Sea" end
    if placeId == 7449423635 or placeId == 100117331123089 then return "Third Sea" end
    return "Unknown"
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Themes = {
    ["Midnight"] = { Accent = Color3.fromRGB(150, 60, 255), Base = Color3.fromRGB(20, 20, 25), Text = Color3.fromRGB(240, 240, 245) },
    ["Rose Gold"] = { Accent = Color3.fromRGB(255, 150, 180), Base = Color3.fromRGB(40, 25, 30), Text = Color3.fromRGB(255, 240, 245) },
    ["Ocean"] = { Accent = Color3.fromRGB(0, 180, 255), Base = Color3.fromRGB(15, 25, 35), Text = Color3.fromRGB(230, 245, 255) },
    ["Emerald"] = { Accent = Color3.fromRGB(50, 220, 120), Base = Color3.fromRGB(20, 30, 25), Text = Color3.fromRGB(235, 255, 240) },
    ["Crimson"] = { Accent = Color3.fromRGB(255, 60, 60), Base = Color3.fromRGB(30, 15, 15), Text = Color3.fromRGB(255, 235, 235) },
    ["Amethyst"] = { Accent = Color3.fromRGB(180, 80, 255), Base = Color3.fromRGB(25, 15, 35), Text = Color3.fromRGB(245, 235, 255) },
    ["Sunset"] = { Accent = Color3.fromRGB(255, 120, 50), Base = Color3.fromRGB(35, 20, 15), Text = Color3.fromRGB(255, 240, 230) },
    ["Matrix"] = { Accent = Color3.fromRGB(0, 255, 0), Base = Color3.fromRGB(10, 10, 10), Text = Color3.fromRGB(200, 255, 200) },
    ["Ghost"] = { Accent = Color3.fromRGB(200, 200, 200), Base = Color3.fromRGB(30, 30, 30), Text = Color3.fromRGB(255, 255, 255) }
}

local Window = Fluent:CreateWindow({
    Title = "Redstone Ultimate",
    SubTitle = "All-in-One Hub",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.G,
})

local ActiveTheme = "Midnight"
local function ApplyTheme(name)
    ActiveTheme = name
    local T = Themes[name]
    if not T then return end
    if Window.Root then
        Window.Root.BackgroundColor3 = T.Base
        for _, obj in ipairs(Window.Root:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                obj.TextColor3 = T.Text
            elseif obj:IsA("Frame") and obj.Name ~= "Bar" then
                if obj.BackgroundColor3 ~= Color3.new(1,1,1) then
                    obj.BackgroundColor3 = T.Base:Lerp(Color3.new(0,0,0), 0.2)
                end
            elseif obj:IsA("UIStroke") then
                obj.Color = T.Accent
            end
        end
    end
end

local lastTitleTap = 0
local lastScreenTap = 0
local IsHidden = false

local function SetupDoubleTap()
    if Window.Root and Window.Root:FindFirstChild("Title") then
        Window.Root.Title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if tick() - lastTitleTap < 0.4 then
                    Window.Root.Visible = false
                    IsHidden = true
                end
                lastTitleTap = tick()
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if IsHidden and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if tick() - lastScreenTap < 0.4 then
            Window.Root.Visible = true
            IsHidden = false
        end
        lastScreenTap = tick()
    end
end)

task.spawn(function()
    task.wait(1)
    SetupDoubleTap()
    ApplyTheme("Midnight")
end)

local Tabs = {
    AutoLevi = Window:AddTab({ Title = "Auto Levi", Icon = "anchor" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "crosshair" }),
    SeaEvents = Window:AddTab({ Title = "Sea Events", Icon = "waves" }),
    FPSBoost = Window:AddTab({ Title = "FPS Boost", Icon = "zap" }),
    Config = Window:AddTab({ Title = "Config", Icon = "settings" }),
}

local LeviTab = Tabs.AutoLevi
local farmTab = Tabs.AutoFarm
local seaTab = Tabs.SeaEvents
local fpsTab = Tabs.FPSBoost
local confTab = Tabs.Config

local statsSec = LeviTab:AddSection("Player Stats")
local statLabel = statsSec:AddParagraph({
    Title = "Loading Stats...",
    Content = "Please wait."
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local name = LocalPlayer.Name
            local lvl = LocalPlayer.Data and LocalPlayer.Data.Level and LocalPlayer.Data.Level.Value or "?"
            local sea = GetSeaName()
            local race = LocalPlayer.Data and LocalPlayer.Data.Race and LocalPlayer.Data.Race.Value or "?"
            statLabel:SetTitle("User: " .. name .. " | Sea: " .. sea)
            statLabel:SetDesc("Level: " .. tostring(lvl) .. " | Race: " .. race)
        end)
    end
end)

local leviMain = LeviTab:AddSection("Leviathan Control")
local autoLeviToggle = leviMain:AddToggle("autoLevi", {
    Title = "Auto Leviathan Full",
    Default = false,
    Callback = function(State)
        _G.AutoLeviathanFull = State
        if State then
            task.spawn(function()
                while _G.AutoLeviathanFull do
                    task.wait(1)
                    local mob, root = SeaAPI.Leviathan_Find()
                    if mob and root then
                        _tp(root.Position + Vector3.new(0, 50, 0))
                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")) end
                        pcall(function() RS.Modules.Net["RE/RegisterAttack"]:FireServer() end)
                        pcall(function() RS.Modules.Net["RE/RegisterHit"]:FireServer(root, {{mob, root}}) end)
                    else
                        _tp(CFrame.new(-16204, 9, 479))
                        task.wait(2)
                    end
                end
            end)
        end
    end,
})

leviMain:AddButton({
    Title = "Teleport to Tiki",
    Callback = function() _tp(CFrame.new(-16204, 9, 479)) end
})

local leviImgSec = LeviTab:AddSection("Boss Preview")
leviImgSec:AddParagraph({
    Title = "Leviathan",
    Content = "rbxassetid://1234567890 (Replace with your image)"
})

local farmSec = farmTab:AddSection("Farming Options")
farmSec:AddDropdown("farmMode", {
    Title = "Farm Mode",
    Values = {"Level", "Fruit", "Item"},
    Default = "Level",
    Multi = false,
    Callback = function(v) _G.FarmMode = v end,
})

farmSec:AddToggle("autoFarm", {
    Title = "Enable Auto Farm",
    Default = false,
    Callback = function(State)
        _G.AutoFarm = State
        if State then DoAutoFarm() end
    end,
})

local seaSec = seaTab:AddSection("Sea Events")
seaSec:AddToggle("autoSea", {
    Title = "Auto Sea Event (Beast Farm)",
    Default = false,
    Callback = function(State)
        _G.AutoSeaEvent = State
        if State then
            task.spawn(function()
                while _G.AutoSeaEvent do
                    task.wait(1)
                    local mob, root = SeaAPI.Sea_Mob(4000)
                    if mob and root then
                        SeaAPI.FightSeaEvent(mob, root)
                    else
                        _tp(CFrame.new(-16204, 9, 479))
                        task.wait(2)
                    end
                end
            end)
        end
    end,
})

local fpsSec = fpsTab:AddSection("FPS / Lag Optimization")
local whiteScreenActive = false

local function SetWhiteScreen(enabled)
    whiteScreenActive = enabled
    if enabled then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        local gui = Instance.new("ScreenGui", game.CoreGui)
        gui.Name = "WhiteScreenOverlay"
        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.new(1,1,1)
        _G.WhiteScreenGui = gui
    else
        game:GetService("RunService"):Set3dRenderingEnabled(true)
        if _G.WhiteScreenGui then _G.WhiteScreenGui:Destroy() end
    end
end

fpsSec:AddToggle("whiteScreen", {
    Title = "White Screen Mode",
    Default = false,
    Callback = function(State)
        SetWhiteScreen(State)
    end,
})

fpsSec:AddToggle("flagOpt", {
    Title = "Flag-Based Optimization",
    Default = false,
    Callback = function(State)
        if State then
            pcall(function() setfflag("RenderFidelity", "0") end)
            pcall(function() setfflag("DisablePostFx", "True") end)
            pcall(function() game:GetService("Lighting").GlobalShadows = false end)
            pcall(function() game:GetService("Lighting").FogEnd = 0 end)
        else
            pcall(function() setfflag("RenderFidelity", "Auto") end)
            pcall(function() setfflag("DisablePostFx", "False") end)
            pcall(function() game:GetService("Lighting").GlobalShadows = true end)
        end
    end,
})

local confSec = confTab:AddSection("Configuration")
confSec:AddDropdown("themeSelect", {
    Title = "Theme",
    Values = {"Midnight", "Rose Gold", "Ocean", "Emerald", "Crimson", "Amethyst", "Sunset", "Matrix", "Ghost"},
    Default = "Midnight",
    Multi = false,
    Callback = function(v) ApplyTheme(v) end,
})

local webhookUrl = ""
confSec:AddInput("webhook", {
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v) webhookUrl = v end,
})

confSec:AddToggle("webhookSend", {
    Title = "Send Levi Kills to Webhook",
    Default = false,
    Callback = function(State) _G.WebhookSend = State end,
})

pcall(function()
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager.Settings.MenuKeybind = "G"
    InterfaceManager:SetFolder("RedstoneUltimate")
    SaveManager:SetFolder("RedstoneUltimate/configs")
    InterfaceManager:BuildInterfaceSection(confTab)
    SaveManager:BuildConfigSection(confTab)
    SaveManager:LoadAutoloadConfig()
end)

Window:SelectTab(1)

SendNotify = function(title, content)
    pcall(function()
        Fluent:Notify({ Title = title, Content = content, Duration = 3 })
    end)
end

SendNotify("Redstone Ultimate", "Loaded successfully. Press G to toggle.")
