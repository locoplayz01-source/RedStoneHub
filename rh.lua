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
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CommF = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("CommF_")

local Config = {
    BoatOwner = "Self",
    FollowTarget = "None",
    ReturnMethod = "Go indefinitely",
    HeartDrop = "Tiki",
    IgniteLantern = false,
    AutoLeviathanFull = false,
    SoloEventsFarm = false,
    SoloEventBoat = "Beast Hunter",
    AutoRespawnTiki = false,
    ShowInfoUI = false,
    FastAttack = false,
    SilentAim = true,
    Theme = "RedBlack"
}

local Themes = {
    RedBlack = {
        Base = Color3.fromRGB(12, 4, 6),
        Panel = Color3.fromRGB(25, 8, 12),
        Glass = Color3.fromRGB(45, 15, 20),
        Text = Color3.fromRGB(255, 235, 240),
        Muted = Color3.fromRGB(180, 100, 120),
        Accent = Color3.fromRGB(255, 30, 80),
        Image = "rbxassetid://1234567890"
    },
    GreyBlack = {
        Base = Color3.fromRGB(10, 10, 12),
        Panel = Color3.fromRGB(22, 22, 26),
        Glass = Color3.fromRGB(38, 38, 42),
        Text = Color3.fromRGB(240, 240, 240),
        Muted = Color3.fromRGB(140, 140, 140),
        Accent = Color3.fromRGB(180, 180, 180),
        Image = "rbxassetid://1234567890"
    },
    PinkGrey = {
        Base = Color3.fromRGB(18, 12, 16),
        Panel = Color3.fromRGB(35, 22, 30),
        Glass = Color3.fromRGB(50, 32, 42),
        Text = Color3.fromRGB(255, 220, 240),
        Muted = Color3.fromRGB(200, 130, 170),
        Accent = Color3.fromRGB(255, 105, 180),
        Image = "rbxassetid://1234567890"
    }
}

local ActiveTheme = Themes[Config.Theme]
local Character, HD, HRP
local CurrentTween, Tweening, TpActive = nil, false, false
local StatusText = "Idle"

local function GetCharacterParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
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
    
    local part = workspace:FindFirstChild("RedstoneTweenPart")
    if not part then
        part = Instance.new("Part")
        part.Name = "RedstoneTweenPart"
        part.Size = Vector3.new(1, 1, 1)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Parent = workspace
    end
    part.CFrame = myHRP.CFrame
    
    if CurrentTween then pcall(function() CurrentTween:Cancel() end) CurrentTween = nil end
    local tween = nil
    if not liveTarget then
        local distance = (targetCFrame.Position - myHRP.Position).Magnitude
        tween = TweenService:Create(part, TweenInfo.new(math.max(distance / 300, 0.05), Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        CurrentTween = tween
    end

    Tweening = true
    TpActive = true
    local aborted, arrived = false, false
    
    local connection
    connection = RunService.Stepped:Connect(function(_, deltaTime)
        local dt = deltaTime or (1 / 60)
        local curChar, curHRP, curHum = GetCharacterParts()
        
        if not curHRP or curChar ~= startChar or not curHum or curHum.Health <= 0 then
            aborted = true if tween then tween:Cancel() end
        else
            if liveTarget then
                local tgt = liveTarget()
                if tgt and tgt.Position.Y < 0 then
                    aborted = true if tween then tween:Cancel() end
                elseif tgt then
                    local cur = part.Position
                    local delta = tgt.Position - cur
                    local dist = delta.Magnitude
                    if dist <= 5 then arrived = true
                    else part.CFrame = CFrame.new(cur + delta.Unit * math.min(dist, 300 * dt)) * (part.CFrame - part.CFrame.Position) end
                end
            end
            if not aborted then
                curHRP.CFrame = part.CFrame
                curHRP.AssemblyLinearVelocity = Vector3.zero
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
            repeat task.wait() until aborted or tween.PlaybackState ~= Enum.PlaybackState.Playing
        end
    end)
    pcall(function() connection:Disconnect() end)
    if tween and CurrentTween == tween then CurrentTween = nil end
    Tweening = false
    TpActive = false
    return not aborted
end

local function FightLeviathan()
    task.spawn(function()
        while Config.AutoLeviathanFull do
            task.wait(0.1)
            local SeaBeasts = workspace:FindFirstChild("SeaBeasts")
            local model, root = nil, nil
            if SeaBeasts then
                for _, v in pairs(SeaBeasts:GetChildren()) do
                    if v.Name == "Leviathan Segment" or v.Name == "Leviathan" then
                        root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                        if root then model = v break end
                    end
                end
            end
            
            if model and root then
                StatusText = "Attacking: " .. model.Name
                _tp(root.Position + Vector3.new(0, 75, 0))
                if not (Character and Character:FindFirstChildOfClass("Humanoid") and Character.Humanoid.Sit) then
                    local tool = Character:FindFirstChildOfClass("Tool")
                    if Config.FastAttack and tool then
                        pcall(function()
                            RS.Modules.Net["RE/RegisterAttack"]:FireServer()
                            RS.Modules.Net["RE/RegisterHit"]:FireServer(root, {{model, root}})
                        end)
                    end
                end
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
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game:GetService("CoreGui")

local function Create(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

-- Key System / Jarvis Loading Screen
local KeyGui = Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(5, 5, 5),
    BorderSizePixel = 0,
}, ScreenGui)

local JarvisText = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0.4, 0),
    BackgroundTransparency = 1,
    Text = "SYSTEM INITIALIZING...",
    TextColor3 = Color3.fromRGB(255, 30, 80),
    Font = Enum.Font.Code,
    TextSize = 24,
}, KeyGui)

local KeyBox = Create("TextBox", {
    Size = UDim2.new(0, 200, 0, 40),
    Position = UDim2.new(0.5, -100, 0.5, 20),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    Text = "",
    PlaceholderText = "Enter Key",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Code,
    TextSize = 14,
}, KeyGui)
Create("UICorner", {CornerRadius = UDim.new(0, 6)}, KeyBox)

local SubmitBtn = Create("TextButton", {
    Size = UDim2.new(0, 200, 0, 40),
    Position = UDim2.new(0.5, -100, 0.5, 70),
    BackgroundColor3 = Color3.fromRGB(255, 30, 80),
    Text = "AUTHENTICATE",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Code,
    TextSize = 14,
}, KeyGui)
Create("UICorner", {CornerRadius = UDim.new(0, 6)}, SubmitBtn)

task.spawn(function()
    local dots = 0
    while KeyGui.Parent do
        task.wait(0.5)
        dots = (dots + 1) % 4
        JarvisText.Text = "SYSTEM INITIALIZING" .. string.rep(".", dots)
    end
end)

SubmitBtn.MouseButton1Click:Connect(function()
    if KeyBox.Text == "loco" then
        KeyGui:Destroy()
        -- Build Main UI
        local MainFrame = Create("Frame", {
            Size = UDim2.new(0, 580, 0, 420),
            Position = UDim2.new(0.5, -290, 0.5, -210),
            BackgroundColor3 = ActiveTheme.Base,
            BorderSizePixel = 0,
        }, ScreenGui)
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, MainFrame)
        Create("UIStroke", {Thickness = 1.5, Color = ActiveTheme.Accent, Transparency = 0.2}, MainFrame)

        local TopBar = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundColor3 = ActiveTheme.Panel,
            BackgroundTransparency = 0.3,
        }, MainFrame)
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, TopBar)

        local Title = Create("TextLabel", {
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = "RedstoneHub",
            TextColor3 = ActiveTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, TopBar)

        local MinBtn = Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -70, 0.5, -14),
            BackgroundColor3 = ActiveTheme.Glass,
            Text = "-",
            TextColor3 = ActiveTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
        }, TopBar)
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}, MinBtn)

        local CloseBtn = Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -35, 0.5, -14),
            BackgroundColor3 = ActiveTheme.Glass,
            Text = "X",
            TextColor3 = ActiveTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
        }, TopBar)
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}, CloseBtn)

        local TabContainer = Create("Frame", {
            Size = UDim2.new(1, -20, 0, 35),
            Position = UDim2.new(0, 10, 0, 55),
            BackgroundTransparency = 1,
        }, MainFrame)
        Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, TabContainer)

        local ContentContainer = Create("Frame", {
            Size = UDim2.new(1, -20, 1, -100),
            Position = UDim2.new(0, 10, 0, 95),
            BackgroundTransparency = 1,
        }, MainFrame)

        local Pages = {}
        local CurrentPage = nil
        local TabButtons = {}

        local function SwitchPage(page)
            if CurrentPage then CurrentPage.Visible = false end
            for _, btn in pairs(TabButtons) do
                btn.BackgroundColor3 = ActiveTheme.Panel
                btn.TextColor3 = ActiveTheme.Muted
            end
            page.Visible = true
            page.Btn.BackgroundColor3 = ActiveTheme.Accent
            page.Btn.TextColor3 = ActiveTheme.Text
            CurrentPage = page
        end

        local function CreatePage(name)
            local page = Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Visible = false,
            }, ContentContainer)
            Create("UIListLayout", {Padding = UDim.new(0, 10)}, page)
            
            local tabBtn = Create("TextButton", {
                Size = UDim2.new(0, 90, 1, 0),
                BackgroundColor3 = ActiveTheme.Panel,
                Text = name,
                TextColor3 = ActiveTheme.Muted,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
            }, TabContainer)
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}, tabBtn)
            
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
                BackgroundTransparency = 0.2,
            }, parent)
            Create("UICorner", {CornerRadius = UDim.new(0, 8)}, sec)
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, sec)
            Create("UIListLayout", {Padding = UDim.new(0, 6)}, sec)
            
            local header = Create("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1}, sec)
            Create("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = ActiveTheme.Accent}, header)
            Create("TextLabel", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = string.upper(title),
                TextColor3 = ActiveTheme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
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
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
            Create("TextLabel", {
                Size = UDim2.new(1, -50, 1, 0),
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
                BackgroundColor3 = default and ActiveTheme.Accent or ActiveTheme.Base,
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
                TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = state and ActiveTheme.Accent or ActiveTheme.Base}):Play()
                if callback then callback(state) end
            end)
            return frame
        end

        local function CreateDropdown(parent, text, options, default, callback)
            local frame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = ActiveTheme.Glass,
                BackgroundTransparency = 0.4,
            }, parent)
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
            Create("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = ActiveTheme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, frame)
            local btn = Create("TextButton", {
                Size = UDim2.new(0, 80, 1, -8),
                Position = UDim2.new(1, -85, 0, 4),
                BackgroundColor3 = ActiveTheme.Base,
                Text = default .. " ▼",
                TextColor3 = ActiveTheme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
            }, frame)
            Create("UICorner", {CornerRadius = UDim.new(0, 4)}, btn)
            
            local dropFrame = Create("Frame", {
                Size = UDim2.new(0, 80, 0, #options * 20),
                Position = UDim2.new(1, -85, 1, 2),
                BackgroundColor3 = ActiveTheme.Panel,
                Visible = false,
                ZIndex = 10,
            }, frame)
            Create("UICorner", {CornerRadius = UDim.new(0, 4)}, dropFrame)
            Create("UIListLayout", {}, dropFrame)
            
            for _, opt in ipairs(options) do
                local optBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundColor3 = ActiveTheme.Panel,
                    Text = opt,
                    TextColor3 = ActiveTheme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    ZIndex = 11,
                }, dropFrame)
                optBtn.MouseButton1Click:Connect(function()
                    btn.Text = opt .. " ▼"
                    dropFrame.Visible = false
                    if callback then callback(opt) end
                end)
            end
            
            btn.MouseButton1Click:Connect(function()
                dropFrame.Visible = not dropFrame.Visible
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
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        local OverlayGui = Create("ScreenGui", {Name = "RedstoneOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = game:GetService("CoreGui")}, game:GetService("CoreGui"))
        local OverlayFrame = Create("Frame", {
            Size = UDim2.new(0, 240, 0, 60),
            Position = UDim2.new(0.5, -120, 0, 15),
            BackgroundColor3 = ActiveTheme.Base,
            BackgroundTransparency = 0.2,
            Visible = false,
        }, OverlayGui)
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}, OverlayFrame)
        Create("UIStroke", {Color = ActiveTheme.Accent, Thickness = 1}, OverlayFrame)
        local StatusLabel = Create("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = StatusText,
            TextColor3 = ActiveTheme.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, OverlayFrame)

        local LeviPage = CreatePage("Leviathan")

        local SetupSec = CreateSection(LeviPage, "Setup")
        CreateDropdown(SetupSec, "Boat Owner", {"Self", "Friend"}, "Self", function(v) Config.BoatOwner = v end)
        local playerNames = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(playerNames, p.Name) end end
        if #playerNames == 0 then table.insert(playerNames, "None") end
        CreateDropdown(SetupSec, "Follow Player", playerNames, playerNames[1], function(v) Config.FollowTarget = v end)
        CreateButton(SetupSec, "Refresh Player List", function()
            local newNames = {}
            for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(newNames, p.Name) end end
            if #newNames == 0 then table.insert(newNames, "None") end
            Config.FollowTarget = newNames[1]
        end)
        CreateDropdown(SetupSec, "Return Method", {"Go indefinitely", "Return after 10km", "Return if set accounts disconnected"}, "Go indefinitely", function(v) Config.ReturnMethod = v end)

        local MainSec = CreateSection(LeviPage, "Main")
        CreateDropdown(MainSec, "Leviathan Heart Drop", {"Tiki", "Hydra"}, "Tiki", function(v) Config.HeartDrop = v end)
        CreateToggle(MainSec, "Ignite Hydra Lantern", false, function(v) Config.IgniteLantern = v end)
        CreateToggle(MainSec, "Auto Leviathan Full", false, function(v)
            Config.AutoLeviathanFull = v
            OverlayFrame.Visible = v
            if v then FightLeviathan() end
        end)
        
        local soloEventsToggle = CreateToggle(MainSec, "Solo Events Farm", false, function(v)
            Config.SoloEventsFarm = v
        end)
        local soloEventDropdown = CreateDropdown(MainSec, "Solo Event Farm Boat", {"Beast Hunter", "Pirate Brigade", "Grand Brigade"}, "Beast Hunter", function(v) Config.SoloEventBoat = v end)
        soloEventDropdown.Visible = false

        soloEventsToggle:GetDescendantOfClass("TextButton").MouseButton1Click:Connect(function()
            task.wait(0.1)
            soloEventDropdown.Visible = Config.SoloEventsFarm
        end)

        CreateToggle(MainSec, "Auto Respawn Tiki", false, function(v) Config.AutoRespawnTiki = v end)
        CreateButton(MainSec, "Show Info UI", function()
            Config.ShowInfoUI = not Config.ShowInfoUI
            OverlayFrame.Visible = Config.ShowInfoUI
        end)

        local ConfigPage = CreatePage("Config")
        local ThemeSec = CreateSection(ConfigPage, "Themes")
        local themeNames = {"RedBlack", "GreyBlack", "PinkGrey"}
        local themeIndex = 1
        local themeBtn = CreateButton(ThemeSec, "Theme: " .. Config.Theme, function()
            themeIndex = themeIndex % #themeNames + 1
            Config.Theme = themeNames[themeIndex]
            ActiveTheme = Themes[Config.Theme]
            themeBtn.Text = "Theme: " .. Config.Theme
            
            MainFrame.BackgroundColor3 = ActiveTheme.Base
            TopBar.BackgroundColor3 = ActiveTheme.Panel
            Title.TextColor3 = ActiveTheme.Text
            MinBtn.BackgroundColor3 = ActiveTheme.Glass
            CloseBtn.BackgroundColor3 = ActiveTheme.Glass
            
            for _, btn in pairs(TabButtons) do
                btn.BackgroundColor3 = ActiveTheme.Panel
                btn.TextColor3 = ActiveTheme.Muted
            end
            if CurrentPage then
                CurrentPage.Btn.BackgroundColor3 = ActiveTheme.Accent
                CurrentPage.Btn.TextColor3 = ActiveTheme.Text
            end
            
            OverlayFrame.BackgroundColor3 = ActiveTheme.Base
            StatusLabel.TextColor3 = ActiveTheme.Accent
            
            for _, page in pairs(Pages) do
                for _, v in pairs(page:GetDescendants()) do
                    if v:IsA("Frame") and v.BackgroundColor3 == Color3.fromRGB(255, 30, 80) then
                        v.BackgroundColor3 = ActiveTheme.Accent
                    end
                end
            end
        end)

        task.spawn(function()
            while task.wait(1) do
                if StatusLabel then StatusLabel.Text = StatusText end
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
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        CloseBtn.MouseButton1Click:Connect(function()
            ScreenGui.Enabled = false
        end)

        local lastTap = 0
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local now = tick()
                if now - lastTap < 0.3 then
                    if MainFrame.Size == UDim2.new(0, 580, 0, 420) then
                        MainFrame.Size = UDim2.new(0, 45, 0, 45)
                        TopBar.Size = UDim2.new(1, 0, 1, 0)
                        Title.Position = UDim2.new(0.5, -40, 0.5, -10)
                        Title.Text = "RH"
                        Title.TextXAlignment = Enum.TextXAlignment.Center
                        MinBtn.Visible = false
                        CloseBtn.Visible = false
                        TabContainer.Visible = false
                        ContentContainer.Visible = false
                    else
                        MainFrame.Size = UDim2.new(0, 580, 0, 420)
                        TopBar.Size = UDim2.new(1, 0, 0, 45)
                        Title.Position = UDim2.new(0, 20, 0, 0)
                        Title.Text = "RedstoneHub"
                        Title.TextXAlignment = Enum.TextXAlignment.Left
                        MinBtn.Visible = true
                        CloseBtn.Visible = true
                        TabContainer.Visible = true
                        ContentContainer.Visible = true
                    end
                end
                lastTap = now
            end
        end)

        MinBtn.MouseButton1Click:Connect(function()
            MainFrame.Size = UDim2.new(0, 45, 0, 45)
            TopBar.Size = UDim2.new(1, 0, 1, 0)
            Title.Position = UDim2.new(0.5, -40, 0.5, -10)
            Title.Text = "RH"
            Title.TextXAlignment = Enum.TextXAlignment.Center
            MinBtn.Visible = false
            CloseBtn.Visible = false
            TabContainer.Visible = false
            ContentContainer.Visible = false
        end)
    else
        KeyBox.Text = ""
        KeyBox.PlaceholderText = "Invalid Key"
        KeyBox.PlaceholderColor3 = Color3.fromRGB(255, 50, 50)
    end
end)
