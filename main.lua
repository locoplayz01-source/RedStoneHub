if _G.RedstoneHubLoaded then
    if not (getgenv and getgenv().ForceReload) then return end
    getgenv().ForceReload = false
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

local Config = {
    AutoLeviathanFull = false,
    SilentAim = true,
    SelectWeapon = "Sword",
    AutoBuso = true,
    AutoKen = false,
    AutoV3 = false,
    AutoV4 = false,
    FastAttack = false,
    AutoFastMode = false,
    DisableVFX = false,
    WhiteScreen = false,
    BoostFPS = false,
    PotatoMode = false,
    Theme = "Default",
    Effects = true,
    HorizontalTabs = true,
    BoatSpeed = 250,
    BoatHeight = 150,
    TweenSpeed = 300
}

local Theme = {
    Default = { Base = Color3.fromRGB(15, 2, 5), Panel = Color3.fromRGB(30, 5, 10), PanelLite = Color3.fromRGB(45, 10, 15), Accent = Color3.fromRGB(255, 30, 80), Text = Color3.fromRGB(255, 240, 245), Muted = Color3.fromRGB(180, 130, 150), Stroke = Color3.fromRGB(255, 60, 100) },
    AnimeOne = { Base = Color3.fromRGB(20, 10, 25), Panel = Color3.fromRGB(35, 15, 40), PanelLite = Color3.fromRGB(50, 20, 55), Accent = Color3.fromRGB(200, 80, 255), Text = Color3.fromRGB(255, 230, 255), Muted = Color3.fromRGB(150, 100, 180), Stroke = Color3.fromRGB(200, 80, 255) },
    AnimeTwo = { Base = Color3.fromRGB(5, 10, 20), Panel = Color3.fromRGB(10, 20, 35), PanelLite = Color3.fromRGB(15, 30, 50), Accent = Color3.fromRGB(0, 180, 255), Text = Color3.fromRGB(220, 240, 255), Muted = Color3.fromRGB(100, 140, 180), Stroke = Color3.fromRGB(0, 180, 255) },
    AnimeThree = { Base = Color3.fromRGB(10, 20, 10), Panel = Color3.fromRGB(20, 35, 20), PanelLite = Color3.fromRGB(30, 50, 30), Accent = Color3.fromRGB(50, 220, 100), Text = Color3.fromRGB(230, 255, 230), Muted = Color3.fromRGB(100, 180, 120), Stroke = Color3.fromRGB(50, 220, 100) },
    AnimeFour = { Base = Color3.fromRGB(20, 15, 10), Panel = Color3.fromRGB(35, 25, 20), PanelLite = Color3.fromRGB(50, 35, 30), Accent = Color3.fromRGB(255, 180, 50), Text = Color3.fromRGB(255, 240, 220), Muted = Color3.fromRGB(180, 150, 100), Stroke = Color3.fromRGB(255, 180, 50) },
    CustomOne = { Base = Color3.fromRGB(15, 0, 0), Panel = Color3.fromRGB(30, 0, 0), PanelLite = Color3.fromRGB(45, 5, 5), Accent = Color3.fromRGB(255, 0, 0), Text = Color3.fromRGB(255, 220, 220), Muted = Color3.fromRGB(180, 100, 100), Stroke = Color3.fromRGB(255, 0, 0), BGImage = "rbxassetid://YOUR_FIRST_IMAGE_ID" },
    CustomTwo = { Base = Color3.fromRGB(10, 10, 10), Panel = Color3.fromRGB(20, 20, 20), PanelLite = Color3.fromRGB(30, 30, 30), Accent = Color3.fromRGB(180, 180, 180), Text = Color3.fromRGB(240, 240, 240), Muted = Color3.fromRGB(120, 120, 120), Stroke = Color3.fromRGB(180, 180, 180), BGImage = "rbxassetid://YOUR_SECOND_IMAGE_ID" },
    CustomThree = { Base = Color3.fromRGB(20, 15, 18), Panel = Color3.fromRGB(35, 25, 30), PanelLite = Color3.fromRGB(50, 35, 40), Accent = Color3.fromRGB(255, 105, 180), Text = Color3.fromRGB(255, 230, 240), Muted = Color3.fromRGB(180, 130, 150), Stroke = Color3.fromRGB(255, 105, 180), BGImage = "rbxassetid://YOUR_THIRD_IMAGE_ID" }
}

local CurrentTheme = Theme[Config.Theme] or Theme.Default

local Character = LocalPlayer.Character
local HD = Character and Character:FindFirstChild("Humanoid")
local HRP = Character and Character:FindFirstChild("HumanoidRootPart")

local CurrentTween, Tweening, TpActive = nil, false, false
local HoldCFrame, LiveHoldFn = nil, nil
local NoclipOn, LastNoclipApply = false, 0
local AttackModel, AttackStandFn, FightTarget = nil, nil, nil
local SkillCoolDown = false
local StatusText = "Waiting..."

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
    
    local _, _, humS = GetCharacterParts()
    if humS and (humS.Sit or humS.SeatPart ~= nil) then
        StandUpFromSeat(humS.SeatPart, humS, myHRP)
        task.wait(0.2)
    end

    local part = GetTweenPart()
    part.CFrame = myHRP.CFrame
    NoClip(true)
    
    local tweenSpeed = Config.TweenSpeed
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

local function Haki_Auto()
    if not Config.AutoBuso then return end
    if Character and HRP then
        if not Character:FindFirstChild("HasBuso") then pcall(function() CommF:InvokeServer("Buso") end) end
    end
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

local function Attack_Auto()
    if not Character or not HRP or not HD then return end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local WT = tool:GetAttribute("WeaponType")
    if WT ~= "Melee" and WT ~= "Sword" then return end
    
    local Net = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Net")
    if not Net then return end
    local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
    local RegisterHit = Net:FindFirstChild("RE/RegisterHit")
    if not RegisterAttack or not RegisterHit then return end

    local hitList = {}
    for _, folder in pairs({workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Characters")}) do
        if folder then
            for _, model in pairs(folder:GetChildren()) do
                if model ~= Character then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    local hum = model:FindFirstChild("Humanoid")
                    if root and hum and hum.Health > 0 and (root.Position - HRP.Position).Magnitude <= 60 then
                        for _, part in pairs(model:GetChildren()) do
                            if part:IsA("BasePart") then table.insert(hitList, {model, part}) end
                        end
                    end
                end
            end
        end
    end
    
    if #hitList > 0 then
        pcall(function()
            RegisterAttack:FireServer()
            local head = hitList[1][1]:FindFirstChild("Head")
            if head then
                RegisterHit:FireServer(head, hitList, {}, tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15))
            end
        end)
    end
end

local function CoolDown_Auto()
    if SkillCoolDown or not Config.AutoLeviathanFull then return end
    SkillCoolDown = true
    pcall(function()
        local skillsUI = LocalPlayer.PlayerGui.Main.Skills
        for _, weapon in pairs(skillsUI:GetChildren()) do
            for _, v in pairs(weapon:GetChildren()) do
                if table.find({"Z", "X", "C", "V", "F"}, v.Name) then
                    local cooldown = v:FindFirstChild("Cooldown")
                    if cooldown and cooldown.Size == UDim2.new(0, 0, 1, -1) then
                        VirtualInputManager:SendKeyEvent(true, v.Name:upper(), false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, v.Name:upper(), false, game)
                    end
                end
            end
        end
    end)
    SkillCoolDown = false
end

local function Leviathan_Find()
    local SeaBeasts = workspace:FindFirstChild("SeaBeasts")
    if not SeaBeasts then return nil, nil end
    for _, model in pairs(SeaBeasts:GetChildren()) do
        if model.Name == "Leviathan Segment" or model.Name == "Leviathan" then
            local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
            if root then return model, root end
        end
    end
    return nil, nil
end

local function FightLeviathan()
    task.spawn(function()
        while Config.AutoLeviathanFull do
            task.wait(0.1)
            local model, root = Leviathan_Find()
            if model and root then
                StatusText = "Attacking: " .. model.Name
                _tp(root.Position + Vector3.new(0, 75, 0))
                if not (Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Sit) then
                    Equip_Auto(Config.SelectWeapon)
                    pcall(CoolDown_Auto)
                    if Config.FastAttack then pcall(Attack_Auto) end
                end
                Haki_Auto()
            else
                StatusText = "Searching for Leviathan..."
                task.wait(1)
            end
        end
    end)
end

local function UpdateCharacter()
    Character = LocalPlayer.Character
    HD = Character and Character:FindFirstChild("Humanoid")
    HRP = Character and Character:FindFirstChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    UpdateCharacter()
    Haki_Auto()
end)

local function ApplyVFX(state)
    if state then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
        end
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 0
        for _, v in pairs(lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then v.Enabled = false end
        end
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RedstoneUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game:GetService("CoreGui")

local function Create(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local MainFrame = Create("Frame", {
    Size = UDim2.new(0, 680, 0, 440),
    Position = UDim2.new(0.5, -340, 0.5, -220),
    BackgroundColor3 = CurrentTheme.Base,
    BorderSizePixel = 0,
}, ScreenGui)

Create("UICorner", {CornerRadius = UDim.new(0, 12)}, MainFrame)

local Stroke = Create("UIStroke", {
    Thickness = 1.5,
    Color = CurrentTheme.Stroke,
    Transparency = 0.3,
}, MainFrame)

local Gradient = Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CurrentTheme.Base),
        ColorSequenceKeypoint.new(1, CurrentTheme.Panel),
    }),
    Rotation = 45,
}, MainFrame)

local TopBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
}, MainFrame)

local Logo = Create("Frame", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 15, 0.5, -15),
    BackgroundColor3 = CurrentTheme.Accent,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, Logo)
Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "R",
    TextColor3 = CurrentTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
}, Logo)

local Title = Create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 16),
    Position = UDim2.new(0, 55, 0, 10),
    BackgroundTransparency = 1,
    Text = "REDSTONE HUB",
    TextColor3 = CurrentTheme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local SubTitle = Create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 14),
    Position = UDim2.new(0, 55, 0, 26),
    BackgroundTransparency = 1,
    Text = "Made by He",
    TextColor3 = CurrentTheme.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local LayoutBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -90, 0.5, -15),
    BackgroundColor3 = CurrentTheme.PanelLite,
    Text = "↔",
    TextColor3 = CurrentTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 6)}, LayoutBtn)

local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -50, 0.5, -15),
    BackgroundColor3 = CurrentTheme.PanelLite,
    Text = "X",
    TextColor3 = CurrentTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 6)}, CloseBtn)

local TabContainer = Create("Frame", {
    Size = UDim2.new(1, -30, 0, 35),
    Position = UDim2.new(0, 15, 0, 55),
    BackgroundColor3 = CurrentTheme.Panel,
    BackgroundTransparency = 0.5,
}, MainFrame)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, TabContainer)
Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center}, TabContainer)

local ContentContainer = Create("Frame", {
    Size = UDim2.new(1, -30, 1, -105),
    Position = UDim2.new(0, 15, 0, 95),
    BackgroundTransparency = 1,
}, MainFrame)

local Pages = {}
local CurrentPage = nil
local TabButtons = {}

local function SwitchLayout()
    Config.HorizontalTabs = not Config.HorizontalTabs
    if Config.HorizontalTabs then
        MainFrame.Size = UDim2.new(0, 680, 0, 440)
        TabContainer.Size = UDim2.new(1, -30, 0, 35)
        TabContainer.Position = UDim2.new(0, 15, 0, 55)
        TabContainer.UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        ContentContainer.Size = UDim2.new(1, -30, 1, -105)
        ContentContainer.Position = UDim2.new(0, 15, 0, 95)
        LayoutBtn.Text = "↔"
    else
        MainFrame.Size = UDim2.new(0, 500, 0, 550)
        TabContainer.Size = UDim2.new(0, 100, 1, -90)
        TabContainer.Position = UDim2.new(0, 10, 0, 55)
        TabContainer.UIListLayout.FillDirection = Enum.FillDirection.Vertical
        ContentContainer.Size = UDim2.new(1, -130, 1, -65)
        ContentContainer.Position = UDim2.new(0, 120, 0, 55)
        LayoutBtn.Text = "↕"
    end
    MainFrame.Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X/2, 0.5, -MainFrame.AbsoluteSize.Y/2)
end

LayoutBtn.MouseButton1Click:Connect(SwitchLayout)

local function CreatePage(name)
    local page = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, ContentContainer)
    
    local tabBtn = Create("TextButton", {
        Size = UDim2.new(0, 85, 1, -10),
        BackgroundColor3 = CurrentTheme.Base,
        BackgroundTransparency = 0.5,
        Text = name,
        TextColor3 = CurrentTheme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, TabContainer)
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}, tabBtn)
    
    tabBtn.MouseButton1Click:Connect(function()
        if CurrentPage then CurrentPage.Visible = false end
        for _, btn in pairs(TabButtons) do
            btn.BackgroundTransparency = 0.5
            btn.TextColor3 = CurrentTheme.Muted
        end
        page.Visible = true
        tabBtn.BackgroundTransparency = 0
        tabBtn.TextColor3 = CurrentTheme.Accent
        CurrentPage = page
    end)
    
    table.insert(TabButtons, tabBtn)
    Pages[name] = page
    
    if not CurrentPage then
        page.Visible = true
        tabBtn.BackgroundTransparency = 0
        tabBtn.TextColor3 = CurrentTheme.Accent
        CurrentPage = page
    end
    return page
end

local function CreateSection(parent, title)
    local sec = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = CurrentTheme.Panel,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 0, 0, #parent:GetChildren() * 10),
    }, parent)
    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, sec)
    Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, sec)
    Create("UIListLayout", {Padding = UDim.new(0, 8)}, sec)
    
    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
    }, sec)
    Create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = CurrentTheme.Accent}, header)
    Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    return sec
end

local function CreateToggle(parent, text, default, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = CurrentTheme.PanelLite,
        BackgroundTransparency = 0.5,
    }, parent)
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    
    Create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    
    local toggleBtn = Create("TextButton", {
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = default and CurrentTheme.Accent or CurrentTheme.Panel,
        Text = "",
    }, frame)
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBtn)
    
    local knob = Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = CurrentTheme.Text,
    }, toggleBtn)
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    
    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Panel
        }):Play()
        if callback then callback(state) end
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = CurrentTheme.PanelLite,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, parent)
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local LeviPage = CreatePage("Leviathan")
local MainSec = CreateSection(LeviPage, "Leviathan Full")
CreateToggle(MainSec, "Auto Leviathan Full", false, function(state)
    Config.AutoLeviathanFull = state
    if state then FightLeviathan() end
end)
CreateButton(MainSec, "Teleport to Tiki", function() _tp(CFrame.new(-16204, 9, 479)) end)

local CombatPage = CreatePage("Combat")
local CombatSec = CreateSection(CombatPage, "Attacks")
CreateToggle(CombatSec, "Fast Attack", false, function(state) Config.FastAttack = state end)
CreateToggle(CombatSec, "Silent Aim", true, function(state) Config.SilentAim = state end)

local PerfPage = CreatePage("Performance")
local PerfSec = CreateSection(PerfPage, "Optimization")
CreateToggle(PerfSec, "FPS Boost (White Screen)", false, function(state)
    Config.WhiteScreen = state
    if state then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), Parent = ScreenGui})
    else
        game:GetService("RunService"):Set3dRenderingEnabled(true)
        for _, v in pairs(ScreenGui:GetChildren()) do
            if v:IsA("Frame") and v.BackgroundColor3 == Color3.new(1,1,1) then v:Destroy() end
        end
    end
end)

local MiscPage = CreatePage("Misc")
local MiscSec = CreateSection(MiscPage, "Ken and Race")
CreateToggle(MiscSec, "Auto Buso", true, function(state) Config.AutoBuso = state end)
CreateToggle(MiscSec, "Auto Ken", false, function(state) Config.AutoKen = state end)
CreateToggle(MiscSec, "Auto V3", false, function(state) Config.AutoV3 = state end)
CreateToggle(MiscSec, "Auto V4", false, function(state) Config.AutoV4 = state end)

local MiscPerfSec = CreateSection(MiscPage, "Performance")
CreateToggle(MiscPerfSec, "Auto Fast Mode", false, function(state) Config.AutoFastMode = state end)
CreateToggle(MiscPerfSec, "Disable VFX", false, function(state) Config.DisableVFX = state ApplyVFX(state) end)
CreateToggle(MiscPerfSec, "White Screen", false, function(state)
    Config.WhiteScreen = state
    if state then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), Parent = ScreenGui})
    else
        game:GetService("RunService"):Set3dRenderingEnabled(true)
        for _, v in pairs(ScreenGui:GetChildren()) do
            if v:IsA("Frame") and v.BackgroundColor3 == Color3.new(1,1,1) then v:Destroy() end
        end
    end
end)
CreateToggle(MiscPerfSec, "Boost FPS", false, function(state) Config.BoostFPS = state end)
CreateToggle(MiscPerfSec, "Potato Mode", false, function(state)
    Config.PotatoMode = state
    if state then
        Config.DisableVFX = true
        Config.WhiteScreen = true
        ApplyVFX(true)
        game:GetService("RunService"):Set3dRenderingEnabled(false)
        Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), Parent = ScreenGui})
    end
end)

local ThemePage = CreatePage("Theme")
local ThemeSec = CreateSection(ThemePage, "Theme")
local themeNames = {"Default", "AnimeOne", "AnimeTwo", "AnimeThree", "AnimeFour", "CustomOne", "CustomTwo", "CustomThree"}
local themeIndex = 1
local themeBtn = CreateButton(ThemeSec, "Current: Default", function()
    themeIndex = themeIndex % #themeNames + 1
    Config.Theme = themeNames[themeIndex]
    CurrentTheme = Theme[Config.Theme]
    themeBtn.Text = "Current: " .. Config.Theme
    MainFrame.BackgroundColor3 = CurrentTheme.Base
    Stroke.Color = CurrentTheme.Stroke
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CurrentTheme.Base),
        ColorSequenceKeypoint.new(1, CurrentTheme.Panel),
    })
    Logo.BackgroundColor3 = CurrentTheme.Accent
    Title.TextColor3 = CurrentTheme.Accent
    SubTitle.TextColor3 = CurrentTheme.Muted
    LayoutBtn.BackgroundColor3 = CurrentTheme.PanelLite
    CloseBtn.BackgroundColor3 = CurrentTheme.PanelLite
    TabContainer.BackgroundColor3 = CurrentTheme.Panel
    for _, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = CurrentTheme.Base
        btn.TextColor3 = CurrentTheme.Muted
    end
    for _, sec in pairs(ContentContainer:GetChildren()) do
        if sec:IsA("Frame") then
            for _, child in pairs(sec:GetChildren()) do
                if child:IsA("Frame") and child.BackgroundColor3 == CurrentTheme.Panel then
                    child.BackgroundColor3 = CurrentTheme.Panel
                end
            end
        end
    end
end)

local EffectsSec = CreateSection(ThemePage, "Effects")
CreateToggle(EffectsSec, "Enable Effects", true, function(state) Config.Effects = state end)

local ConfigPage = CreatePage("Config")
local CfgSec = CreateSection(ConfigPage, "Settings")
CreateButton(CfgSec, "Reload UI", function() ScreenGui:Destroy() loadstring(game:HttpGet("https://raw.githubusercontent.com/locoplayz01-source/RedStoneHub/main/main.lua"))() end)

local OverlayGui = Create("ScreenGui", {
    Name = "RedstoneOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = game:GetService("CoreGui")
}, game:GetService("CoreGui"))

local OverlayFrame = Create("Frame", {
    Size = UDim2.new(0, 320, 0, 80),
    Position = UDim2.new(0.5, -160, 0, 15),
    BackgroundColor3 = CurrentTheme.Base,
    BorderSizePixel = 0,
}, OverlayGui)
Create("UICorner", {CornerRadius = UDim.new(0, 10)}, OverlayFrame)
Create("UIStroke", {Color = CurrentTheme.Accent, Thickness = 1}, OverlayFrame)

Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 20),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Text = "Status",
    TextColor3 = CurrentTheme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

local StatusLabel = Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 20),
    BackgroundTransparency = 1,
    Text = StatusText,
    TextColor3 = CurrentTheme.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 15),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundTransparency = 1,
    Text = "Players: " .. #Players:GetPlayers(),
    TextColor3 = CurrentTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

local PingLabel = Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 15),
    Position = UDim2.new(0, 100, 0, 45),
    BackgroundTransparency = 1,
    Text = "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms",
    TextColor3 = CurrentTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

task.spawn(function()
    while task.wait(1) do
        if StatusLabel then StatusLabel.Text = StatusText end
        if PingLabel then PingLabel.Text = "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms" end
    end
end)

local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)
