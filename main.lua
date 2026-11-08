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
    PotatoMode = false,
    Theme = "RedBlack",
    AccentColor = Color3.fromRGB(255, 30, 80)
}

local Themes = {
    RedBlack = { Base = Color3.fromRGB(10, 2, 4), Panel = Color3.fromRGB(25, 5, 10), Glass = Color3.fromRGB(40, 10, 15), Text = Color3.fromRGB(255, 235, 240), Muted = Color3.fromRGB(180, 100, 120) },
    GreyBlack = { Base = Color3.fromRGB(10, 10, 12), Panel = Color3.fromRGB(20, 20, 25), Glass = Color3.fromRGB(35, 35, 40), Text = Color3.fromRGB(240, 240, 240), Muted = Color3.fromRGB(140, 140, 140) },
    PinkGrey = { Base = Color3.fromRGB(15, 10, 15), Panel = Color3.fromRGB(30, 20, 30), Glass = Color3.fromRGB(45, 30, 45), Text = Color3.fromRGB(255, 220, 240), Muted = Color3.fromRGB(200, 130, 170) }
}

local ActiveTheme = Themes[Config.Theme]

local Character = LocalPlayer.Character
local HD = Character and Character:FindFirstChild("Humanoid")
local HRP = Character and Character:FindFirstChild("HumanoidRootPart")

local CurrentTween, Tweening, TpActive = nil, false, false
local NoclipOn, LastNoclipApply = false, 0
local AttackModel = nil
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

local function Haki_Auto()
    if not Config.AutoBuso then return end
    if Character and HRP then
        if not Character:FindFirstChild("HasBuso") then pcall(function() CommF:InvokeServer("Buso") end) end
    end
end

local function Equip_Auto(Tool)
    if not Character or not HRP or not HD then return end
    if HD.Health > 0 and LocalPlayer:FindFirstChild("Backpack") then
        for i, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v.ToolTip == Tool or v.Name == Tool then HD:EquipTool(v) break end
        end
    end
end

local function Attack_Auto()
    if not Character or not HRP or not HD then return end
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
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
                AttackModel = model
                _tp(root.Position + Vector3.new(0, 75, 0))
                if not (Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Sit) then
                    Equip_Auto(Config.SelectWeapon)
                    if Config.FastAttack then pcall(Attack_Auto) end
                end
                Haki_Auto()
            else
                StatusText = "Searching..."
                task.wait(1)
            end
        end
    end)
end

if game.CoreGui:FindFirstChild("RedstoneUI") then game.CoreGui.RedstoneUI:Destroy() end

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
    Size = UDim2.new(0, 600, 0, 380),
    Position = UDim2.new(0.5, -300, 0.5, -190),
    BackgroundColor3 = ActiveTheme.Base,
    BorderSizePixel = 0,
}, ScreenGui)
Create("UICorner", {CornerRadius = UDim.new(0, 16)}, MainFrame)

local MainStroke = Create("UIStroke", {
    Thickness = 1.5,
    Color = Config.AccentColor,
    Transparency = 0.2,
}, MainFrame)

local TopBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = ActiveTheme.Panel,
    BackgroundTransparency = 0.5,
}, MainFrame)
Create("UICorner", {CornerRadius = UDim.new(0, 16)}, TopBar)

local Logo = Create("Frame", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 15, 0.5, -15),
    BackgroundColor3 = Config.AccentColor,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, Logo)
Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "R",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
}, Logo)

local Title = Create("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 55, 0, 0),
    BackgroundTransparency = 1,
    Text = "REDSTONE HUB",
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local MinimizeBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -75, 0.5, -15),
    BackgroundColor3 = ActiveTheme.Glass,
    Text = "-",
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, MinimizeBtn)

local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0.5, -15),
    BackgroundColor3 = ActiveTheme.Glass,
    Text = "X",
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
}, TopBar)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, CloseBtn)

local TabContainer = Create("Frame", {
    Size = UDim2.new(1, -30, 0, 35),
    Position = UDim2.new(0, 15, 0, 60),
    BackgroundTransparency = 1,
}, MainFrame)
Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center}, TabContainer)

local ContentContainer = Create("Frame", {
    Size = UDim2.new(1, -30, 1, -110),
    Position = UDim2.new(0, 15, 0, 100),
    BackgroundTransparency = 1,
}, MainFrame)

local Pages = {}
local CurrentPage = nil
local TabButtons = {}

local function UpdateTheme()
    MainFrame.BackgroundColor3 = ActiveTheme.Base
    MainStroke.Color = Config.AccentColor
    TopBar.BackgroundColor3 = ActiveTheme.Panel
    Logo.BackgroundColor3 = Config.AccentColor
    Title.TextColor3 = ActiveTheme.Text
    MinimizeBtn.BackgroundColor3 = ActiveTheme.Glass
    MinimizeBtn.TextColor3 = ActiveTheme.Text
    CloseBtn.BackgroundColor3 = ActiveTheme.Glass
    CloseBtn.TextColor3 = ActiveTheme.Text
    
    for _, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = ActiveTheme.Panel
        btn.TextColor3 = ActiveTheme.Muted
        if btn == CurrentPage.Btn then
            btn.BackgroundColor3 = Config.AccentColor
            btn.TextColor3 = Color3.new(1,1,1)
        end
    end
    
    for _, page in pairs(Pages) do
        for _, v in pairs(page:GetDescendants()) do
            if v:IsA("Frame") and v:GetAttribute("IsSection") then
                v.BackgroundColor3 = ActiveTheme.Panel
            elseif v:IsA("Frame") and v:GetAttribute("IsToggle") then
                v.BackgroundColor3 = ActiveTheme.Glass
            elseif v:IsA("TextLabel") then
                v.TextColor3 = ActiveTheme.Text
            elseif v:IsA("Frame") and v:GetAttribute("IsAccentLine") then
                v.BackgroundColor3 = Config.AccentColor
            end
        end
    end
end

local function SwitchPage(page)
    if CurrentPage then CurrentPage.Visible = false end
    for _, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = ActiveTheme.Panel
        btn.TextColor3 = ActiveTheme.Muted
    end
    page.Visible = true
    page.Btn.BackgroundColor3 = Config.AccentColor
    page.Btn.TextColor3 = Color3.new(1,1,1)
    CurrentPage = page
    
    page.Position = UDim2.new(0, 0, 0, 10)
    page.BackgroundTransparency = 1
    TweenService:Create(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
end

local function CreatePage(name)
    local page = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, ContentContainer)
    Create("UIListLayout", {Padding = UDim.new(0, 10)}, page)
    
    local tabBtn = Create("TextButton", {
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = ActiveTheme.Panel,
        Text = name,
        TextColor3 = ActiveTheme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, TabContainer)
    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, tabBtn)
    
    tabBtn.MouseButton1Click:Connect(function() SwitchPage(page) end)
    
    table.insert(TabButtons, tabBtn)
    Pages[name] = page
    page.Btn = tabBtn
    
    if not CurrentPage then SwitchPage(page) end
    return page
end

local function CreateSection(parent, title)
    local sec = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = ActiveTheme.Panel,
        BackgroundTransparency = 0.3,
    }, parent)
    sec:SetAttribute("IsSection", true)
    Create("UICorner", {CornerRadius = UDim.new(0, 10)}, sec)
    Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, sec)
    Create("UIListLayout", {Padding = UDim.new(0, 8)}, sec)
    
    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
    }, sec)
    local line = Create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Config.AccentColor}, header)
    line:SetAttribute("IsAccentLine", true)
    Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = ActiveTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    return sec
end

local function CreateToggle(parent, text, default, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = ActiveTheme.Glass,
        BackgroundTransparency = 0.4,
    }, parent)
    frame:SetAttribute("IsToggle", true)
    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, frame)
    
    Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = ActiveTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    
    local toggleBtn = Create("TextButton", {
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = default and Config.AccentColor or ActiveTheme.Base,
        Text = "",
    }, frame)
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBtn)
    
    local knob = Create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = Color3.new(1,1,1),
    }, toggleBtn)
    Create("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    
    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Config.AccentColor or ActiveTheme.Base
        }):Play()
        if callback then callback(state) end
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = ActiveTheme.Glass,
        Text = text,
        TextColor3 = ActiveTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, parent)
    btn:SetAttribute("IsToggle", true)
    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local OverlayGui = Create("ScreenGui", {
    Name = "RedstoneOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = game:GetService("CoreGui")
}, game:GetService("CoreGui"))

local OverlayFrame = Create("Frame", {
    Size = UDim2.new(0, 260, 0, 70),
    Position = UDim2.new(0.5, -130, 0, 15),
    BackgroundColor3 = ActiveTheme.Base,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Visible = false,
}, OverlayGui)
Create("UICorner", {CornerRadius = UDim.new(0, 10)}, OverlayFrame)
Create("UIStroke", {Color = Config.AccentColor, Thickness = 1}, OverlayFrame)

Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 16),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Text = "LEVIATHAN STATUS",
    TextColor3 = ActiveTheme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

local StatusLabel = Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 20),
    BackgroundTransparency = 1,
    Text = StatusText,
    TextColor3 = Config.AccentColor,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 14),
    Position = UDim2.new(0, 10, 0, 42),
    BackgroundTransparency = 1,
    Text = "Players: " .. #Players:GetPlayers(),
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

local PingLabel = Create("TextLabel", {
    Size = UDim2.new(0, 100, 0, 14),
    Position = UDim2.new(0, 90, 0, 42),
    BackgroundTransparency = 1,
    Text = "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms",
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, OverlayFrame)

local LeviPage = CreatePage("Leviathan")
local MainSec = CreateSection(LeviPage, "Main")
CreateToggle(MainSec, "Auto Leviathan", false, function(state)
    Config.AutoLeviathanFull = state
    OverlayFrame.Visible = state
    if state then FightLeviathan() end
end)
CreateButton(MainSec, "Teleport to Tiki", function() _tp(CFrame.new(-16204, 9, 479)) end)

local CombatPage = CreatePage("Combat")
local CombatSec = CreateSection(CombatPage, "Combat Settings")
CreateToggle(CombatSec, "Fast Attack", false, function(state) Config.FastAttack = state end)
CreateToggle(CombatSec, "Silent Aim", true, function(state) Config.SilentAim = state end)

local MiscPage = CreatePage("Misc")
local MiscSec = CreateSection(MiscPage, "Haki & Race")
CreateToggle(MiscSec, "Auto Buso", true, function(state) Config.AutoBuso = state end)
CreateToggle(MiscSec, "Auto Ken", false, function(state) Config.AutoKen = state end)
CreateToggle(MiscSec, "Auto V3", false, function(state) Config.AutoV3 = state end)
CreateToggle(MiscSec, "Auto V4", false, function(state) Config.AutoV4 = state end)

local MiscPerfSec = CreateSection(MiscPage, "Performance")
CreateToggle(MiscPerfSec, "Disable VFX", false, function(state)
    if state then
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end
end)
CreateToggle(MiscPerfSec, "White Screen", false, function(state)
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

local ThemePage = CreatePage("Theme")
local ThemeSec = CreateSection(ThemePage, "Themes")
local themeNames = {"RedBlack", "GreyBlack", "PinkGrey"}
local themeIndex = 1
local themeBtn = CreateButton(ThemeSec, "Theme: " .. Config.Theme, function()
    themeIndex = themeIndex % #themeNames + 1
    Config.Theme = themeNames[themeIndex]
    ActiveTheme = Themes[Config.Theme]
    themeBtn.Text = "Theme: " .. Config.Theme
    UpdateTheme()
end)

local ColorSec = CreateSection(ThemePage, "Custom Accent")
local ColorInput = Create("TextBox", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = ActiveTheme.Glass,
    Text = "255, 30, 80",
    TextColor3 = ActiveTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    PlaceholderText = "R, G, B",
}, ColorSec)
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, ColorInput)
CreateButton(ColorSec, "Apply Color", function()
    local r, g, b = string.match(ColorInput.Text, "(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        Config.AccentColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        UpdateTheme()
    end
end)

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
    ScreenGui.Enabled = false
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    if MainFrame.Size == UDim2.new(0, 600, 0, 380) then
        MainFrame.Size = UDim2.new(0, 40, 0, 40)
        TopBar.Size = UDim2.new(1, 0, 1, 0)
        Logo.Position = UDim2.new(0.5, -15, 0.5, -15)
        Title.Visible = false
        MinimizeBtn.Visible = false
        CloseBtn.Position = UDim2.new(1, -25, 0, 5)
        TabContainer.Visible = false
        ContentContainer.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 600, 0, 380)
        TopBar.Size = UDim2.new(1, 0, 0, 50)
        Logo.Position = UDim2.new(0, 15, 0.5, -15)
        Title.Visible = true
        MinimizeBtn.Visible = true
        CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
        TabContainer.Visible = true
        ContentContainer.Visible = true
    end
end)
