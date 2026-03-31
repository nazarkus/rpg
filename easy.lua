for _,n in ipairs({"RPGSpammerGUI","RPGVehicleGUI","NazarkusRPG"}) do
    local old = game.CoreGui:FindFirstChild(n)
    if old then old:Destroy() end
end

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function findRPG()
    local t = char:FindFirstChild("RPG")
    if not t then
        local bp = plr:FindFirstChild("Backpack")
        if bp then t = bp:FindFirstChild("RPG") end
    end
    return t
end
local tool = findRPG()

local rvEv, fxEv, fireEv, hitEv, rocketModel
local rpgReady = false

pcall(function()
    rvEv = game.ReplicatedStorage.RocketSystem.Events
    fxEv = rvEv.RocketReloadedFX
    fireEv = rvEv.FireRocketReplicated
    hitEv = rvEv.RocketHit
    rocketModel = game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"]
    rpgReady = true
end)

local rCnt = 0

local rSettings = {
    expShake = {fadeInTime=0.05, magnitude=3, rotInfluence=Vector3.new(0.4,0,0.4),
        fadeOutTime=0.5, posInfluence=Vector3.new(1,1,0), roughness=3},
    gravity=Vector3.new(0,-20,0), HelicopterDamage=450, FireRate=15, VehicleDamage=350,
    ExpName="RPG", RocketAmount=1, ExpRadius=12, BoatDamage=300, TankDamage=300,
    Acceleration=8, ShieldDamage=170, Distance=4000, PlaneDamage=500,
    GunshipDamage=170, velocity=200, ExplosionDamage=120,
}

local C = {
    Bg       = Color3.fromRGB(5, 5, 10),
    Panel    = Color3.fromRGB(12, 12, 20),
    Card     = Color3.fromRGB(20, 20, 34),
    CardH    = Color3.fromRGB(28, 28, 46),
    Input    = Color3.fromRGB(14, 14, 24),
    Border   = Color3.fromRGB(38, 38, 56),
    BorderL  = Color3.fromRGB(48, 48, 68),
    Accent   = Color3.fromRGB(98, 55, 210),
    AccentL  = Color3.fromRGB(130, 90, 240),
    AccentD  = Color3.fromRGB(70, 35, 160),
    Success  = Color3.fromRGB(16, 185, 129),
    SuccessD = Color3.fromRGB(10, 130, 90),
    Danger   = Color3.fromRGB(220, 50, 50),
    DangerD  = Color3.fromRGB(160, 30, 30),
    Warn     = Color3.fromRGB(230, 170, 30),
    Text     = Color3.fromRGB(225, 225, 235),
    TextSub  = Color3.fromRGB(120, 120, 150),
    TextMute = Color3.fromRGB(70, 70, 95),
    White    = Color3.fromRGB(255, 255, 255),
    Sel      = Color3.fromRGB(28, 24, 55),
    SelBrd   = Color3.fromRGB(98, 55, 210),
    WL       = Color3.fromRGB(50, 80, 140),
    WLA      = Color3.fromRGB(80, 130, 220),
    Shield   = Color3.fromRGB(230, 170, 30),
    NoTeam   = Color3.fromRGB(70, 70, 90),
}

local vFolders = {}
pcall(function()
    local gs = workspace:FindFirstChild("Game Systems")
    if gs then
        for _, n in ipairs({"Helicopter","Plane","Gunship","Boat","Tank","Hovercraft"}) do
            vFolders[n] = gs:FindFirstChild(n .. " Workspace")
        end
    end
end)

local vCol = {
    Helicopter = Color3.fromRGB(50, 100, 170),
    Plane      = Color3.fromRGB(70, 75, 160),
    Gunship    = Color3.fromRGB(160, 50, 50),
    Boat       = Color3.fromRGB(40, 120, 110),
    Tank       = Color3.fromRGB(150, 110, 40),
    Hovercraft = Color3.fromRGB(110, 70, 170),
}
local vShort = {
    Helicopter="HELI", Plane="PLANE", Gunship="GNSHP",
    Boat="BOAT", Tank="TANK", Hovercraft="HOVER",
}

local selP, wlP, plrEl = {}, {}, {}
local selV, vehInst, vehEl = {}, {}, {}
local pSpamOn, pThreads = false, {}
local vSpamOn, vThreads = false, {}

local function cr(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end

local function sk(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Border; s.Thickness = th or 1; s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local function pad(p, t, b, l, r)
    local pd = Instance.new("UIPadding"); pd.Parent = p
    pd.PaddingTop = UDim.new(0, t or 0); pd.PaddingBottom = UDim.new(0, b or 0)
    pd.PaddingLeft = UDim.new(0, l or 0); pd.PaddingRight = UDim.new(0, r or 0)
    return pd
end

local function addRowGradient(parent)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.15, Color3.fromRGB(240, 240, 245)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 205)),
    })
    g.Rotation = 90
    g.Parent = parent
    return g
end

local function getPlayerBase(player)
    if not player then return nil end
    if player.Team then return player.Team.Name end
    local result = nil
    pcall(function()
        local tycoonsRoot = workspace:FindFirstChild("Tycoon")
        if tycoonsRoot then
            local tycoons = tycoonsRoot:FindFirstChild("Tycoons")
            if tycoons then
                for _, tycoon in ipairs(tycoons:GetChildren()) do
                    for _, v in ipairs(tycoon:GetDescendants()) do
                        if v:IsA("ObjectValue") and v.Name == "Owner" and v.Value == player then
                            result = tycoon.Name
                        end
                    end
                    if result then break end
                end
            end
        end
    end)
    if result then return result end
    for _, attr in ipairs({"Base","Team","Faction","Side"}) do
        local val = nil
        pcall(function() val = player:GetAttribute(attr) end)
        if val and type(val) == "string" and val ~= "" then return val end
    end
    return nil
end

local function getBaseColor(baseName)
    if not baseName then return C.NoTeam end
    local lower = baseName:lower()
    if lower:find("alpha") or lower:find("red") or lower:find("crimson") then
        return Color3.fromRGB(200, 80, 80)
    elseif lower:find("bravo") or lower:find("blue") or lower:find("phantom") then
        return Color3.fromRGB(80, 120, 200)
    elseif lower:find("charlie") or lower:find("green") then
        return Color3.fromRGB(80, 180, 120)
    elseif lower:find("delta") or lower:find("yellow") then
        return Color3.fromRGB(200, 170, 60)
    elseif lower:find("echo") or lower:find("purple") then
        return Color3.fromRGB(150, 100, 220)
    end
    return Color3.fromRGB(100, 130, 160)
end

local function playerHasRPG(player)
    if not player then return false end
    local ch = player.Character
    if ch then
        for _, child in pairs(ch:GetChildren()) do
            if child:IsA("Tool") and child.Name == "RPG" then return true end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, child in pairs(bp:GetChildren()) do
            if child:IsA("Tool") and child.Name == "RPG" then return true end
        end
    end
    return false
end

local function getDistanceTo(player)
    if not player or not player.Character then return nil end
    local tHrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not tHrp or not hrp or not hrp.Parent then return nil end
    return math.floor((hrp.Position - tHrp.Position).Magnitude)
end

local function getDistanceToVeh(part)
    if not part or not part.Parent or not hrp or not hrp.Parent then return nil end
    return math.floor((hrp.Position - part.Position).Magnitude)
end

local function isShielded(player)
    if not player or not player.Character then return false end
    local ch = player.Character
    if ch:FindFirstChildOfClass("ForceField") then return true end
    for _, attr in ipairs({"Shielded","Shield","IsShielded","HasShield","Invincible","Invulnerable"}) do
        if ch:GetAttribute(attr) == true then return true end
    end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, attr in ipairs({"Shielded","Shield","IsShielded","Invincible"}) do
            if hum:GetAttribute(attr) == true then return true end
        end
    end
    for _, child in pairs(ch:GetDescendants()) do
        if child:IsA("BoolValue") or child:IsA("StringValue") or child:IsA("IntValue") then
            local n = child.Name:lower()
            if n == "shield" or n == "shielded" or n == "isshielded" or n == "hasshield"
                or n == "invincible" or n == "invulnerable" or n == "barrier" then
                if child:IsA("BoolValue") and child.Value then return true end
                if child:IsA("IntValue") and child.Value > 0 then return true end
                if child:IsA("StringValue") and child.Value ~= "" then return true end
            end
        end
    end
    local kw = {"shield","barrier","bubble","forcefield","dome","protect"}
    for _, child in pairs(ch:GetChildren()) do
        local n = child.Name:lower()
        for _, k in pairs(kw) do
            if n:find(k) then
                if (child:IsA("BasePart") or child:IsA("MeshPart")) and child.Transparency < 1 then return true
                elseif child:IsA("Model") then return true end
            end
        end
    end
    local rp = ch:FindFirstChild("HumanoidRootPart")
    if rp then
        for _, child in pairs(rp:GetChildren()) do
            local n = child.Name:lower()
            for _, k in pairs(kw) do if n:find(k) then return true end end
        end
    end
    return false
end

local shieldBreakCooldown = {}
local function breakShield(player)
    if not player or not rpgReady then return end
    if shieldBreakCooldown[player] and tick() - shieldBreakCooldown[player] < 2 then return end
    shieldBreakCooldown[player] = tick()
    task.spawn(function()
        local weapon = findRPG()
        if not weapon then return end
        local tycoonsRoot = workspace:FindFirstChild("Tycoon")
        if not tycoonsRoot then return end
        local tycoons = tycoonsRoot:FindFirstChild("Tycoons")
        if not tycoons then return end
        local targetTycoon = nil
        for _, tycoon in ipairs(tycoons:GetChildren()) do
            for _, v in ipairs(tycoon:GetDescendants()) do
                if v:IsA("ObjectValue") and v.Name == "Owner" and v.Value == player then
                    targetTycoon = tycoon; break
                end
            end
            if targetTycoon then break end
        end
        if not targetTycoon then return end
        local purchased = targetTycoon:FindFirstChild("PurchasedObjects")
        if not purchased then return end
        local baseShield = purchased:FindFirstChild("Base Shield")
        if not baseShield then return end
        local shieldFolder = baseShield:FindFirstChild("Shield")
        if not shieldFolder then return end
        for _ = 1, 15 do
            if not shieldFolder or not shieldFolder.Parent then break end
            local parts = {}
            for _, part in ipairs(shieldFolder:GetChildren()) do
                if part:IsA("BasePart") and part.Parent then table.insert(parts, part) end
            end
            if #parts == 0 then break end
            local hitCount = 0
            for _, part in ipairs(parts) do
                if hitCount >= 3 then break end
                if part and part.Parent then
                    pcall(function()
                        hitEv:FireServer({
                            Normal = Vector3.new(0,1,0), HitPart = part, Position = part.Position,
                            Label = plr.Name.."SB"..rCnt, Vehicle = weapon, Player = plr, Weapon = weapon,
                        })
                    end)
                    rCnt += 1; hitCount += 1
                end
            end
            task.wait(0.15)
        end
    end)
end

local function getOwnerData(model)
    local data = {username = nil, displayName = nil, base = nil}
    pcall(function()
        for _, attr in ipairs({"Owner","Pilot","KillOwner"}) do
            if not data.username then
                local v = model:GetAttribute(attr)
                if v and type(v) == "string" and v ~= "" then data.username = v end
            end
        end
        if data.username then
            local p = Players:FindFirstChild(data.username)
            if p then
                data.displayName = p.DisplayName
                data.base = getPlayerBase(p)
            else data.displayName = data.username end
        end
    end)
    return data
end

local function scanVehicles()
    vehInst = {}
    for typ, folder in pairs(vFolders) do
        if folder then
            pcall(function()
                for _, mdl in ipairs(folder:GetChildren()) do
                    if mdl:IsA("Model") then
                        local part = mdl:FindFirstChild("HumanoidRootPart")
                            or mdl:FindFirstChild("Main") or mdl:FindFirstChild("RootPart")
                            or mdl:FindFirstChild("Head") or mdl.PrimaryPart
                        if part then
                            local od = getOwnerData(mdl)
                            table.insert(vehInst, {
                                Name = mdl.Name, Type = typ, Model = mdl, HRP = part,
                                Username = od.username, DisplayName = od.displayName, Base = od.base,
                            })
                        end
                    end
                end
            end)
        end
    end
    return #vehInst
end

local function fireRocket(targetPos, hitPart)
    if not rpgReady then return false end
    if not tool or not tool.Parent then
        tool = findRPG(); if not tool then return false end
    end
    if not hrp or not hrp.Parent then
        char = plr.Character
        if not char then return false end
        hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
    end
    local dir = (targetPos - hrp.Position).Unit
    pcall(function() fxEv:FireServer(tool, false) end)
    pcall(function()
        fireEv:FireServer({
            Direction = dir, Settings = rSettings, Origin = hrp.Position,
            PlrFired = plr, Vehicle = tool, RocketModel = rocketModel, Weapon = tool,
        })
    end)
    pcall(function()
        hitEv:FireServer({
            Normal = Vector3.new(0,1,0), HitPart = hitPart, Position = targetPos,
            Label = plr.Name.."R"..rCnt, Vehicle = tool, Player = plr, Weapon = tool,
        })
    end)
    rCnt += 1; return true
end

local function attackPlayer(player)
    if not player or not player.Character then return end
    if player == plr then return end
    if wlP[player] or isShielded(player) then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return end
    local w = player.Character:FindFirstChild("HumanoidRootPart")
    if not w then return end
    fireRocket(w.Position, w)
end

local function attackVehicle(td)
    if not td or not td.Model or not td.Model.Parent then return false end
    local h = td.HRP; if not h or not h.Parent then return false end
    local pos = h.Position
    local off = {Boat=3, Tank=1.5, Hovercraft=2, Plane=1}
    if off[td.Type] then pos = pos + Vector3.new(0, off[td.Type], 0) end
    return fireRocket(pos, h)
end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "NazarkusRPG"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 450)
main.Position = UDim2.new(0.5, -260, 0.5, -225)
main.BackgroundColor3 = C.Bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = gui
cr(main, 10)
sk(main, C.Border, 1, 0.3)

-- ============================================================
-- SIDEBAR
-- ============================================================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, 0)
sidebar.BackgroundColor3 = C.Panel
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 3
sidebar.Parent = main
cr(sidebar, 10)

local sideClip = Instance.new("Frame")
sideClip.Size = UDim2.new(0, 20, 1, 0)
sideClip.Position = UDim2.new(1, -10, 0, 0)
sideClip.BackgroundColor3 = C.Panel
sideClip.BorderSizePixel = 0
sideClip.ZIndex = 3
sideClip.Parent = sidebar

local sideBorder = Instance.new("Frame")
sideBorder.Size = UDim2.new(0, 1, 1, -20)
sideBorder.Position = UDim2.new(1, 0, 0, 10)
sideBorder.BackgroundColor3 = C.Border
sideBorder.BackgroundTransparency = 0.3
sideBorder.BorderSizePixel = 0
sideBorder.ZIndex = 4
sideBorder.Parent = sidebar

local titleLbl = Instance.new("TextLabel")
titleLbl.Text = "NAZARKUS"
titleLbl.Size = UDim2.new(1, 0, 0, 30)
titleLbl.Position = UDim2.new(0, 0, 0, 22)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = C.White
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 16
titleLbl.ZIndex = 5
titleLbl.Parent = sidebar

local rpgDot = Instance.new("Frame")
rpgDot.Size = UDim2.new(0, 8, 0, 8)
rpgDot.Position = UDim2.new(0.5, -22, 0, 54)
rpgDot.BackgroundColor3 = rpgReady and C.Success or C.Danger
rpgDot.BorderSizePixel = 0
rpgDot.ZIndex = 5
rpgDot.Parent = sidebar
cr(rpgDot, 4)

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.Text = "RPG"
subtitleLbl.Size = UDim2.new(1, 0, 0, 16)
subtitleLbl.Position = UDim2.new(0, 0, 0, 49)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.TextColor3 = C.Accent
subtitleLbl.Font = Enum.Font.GothamBold
subtitleLbl.TextSize = 11
subtitleLbl.ZIndex = 5
subtitleLbl.Parent = sidebar

-- Nav buttons
local navBtns = {}
local currentTab = "players"

local function createNavBtn(text, id, yPos)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = id == "players" and C.Card or C.Panel
    btn.BackgroundTransparency = id == "players" and 0 or 1
    btn.TextColor3 = id == "players" and C.White or C.TextSub
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Parent = sidebar
    cr(btn, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 22)
    indicator.Position = UDim2.new(0, 0, 0.5, -11)
    indicator.BackgroundColor3 = C.Accent
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 6
    indicator.Visible = id == "players"
    indicator.Parent = btn
    cr(indicator, 2)

    navBtns[id] = {btn = btn, indicator = indicator}

    btn.MouseEnter:Connect(function()
        if currentTab ~= id then
            TS:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0, BackgroundColor3 = C.CardH}):Play()
            btn.TextColor3 = C.Text
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= id then
            TS:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            btn.TextColor3 = C.TextSub
        end
    end)

    return btn
end

local navPlayers = createNavBtn("PLAYERS", "players", 90)
local navVehicles = createNavBtn("VEHICLES", "vehicles", 130)

local sideInfo = Instance.new("TextLabel")
sideInfo.Size = UDim2.new(1, -20, 0, 40)
sideInfo.Position = UDim2.new(0, 10, 1, -80)
sideInfo.BackgroundTransparency = 1
sideInfo.TextColor3 = C.TextMute
sideInfo.Font = Enum.Font.Gotham
sideInfo.TextSize = 10
sideInfo.TextWrapped = true
sideInfo.TextYAlignment = Enum.TextYAlignment.Bottom
sideInfo.ZIndex = 5
sideInfo.Parent = sidebar

local myBaseLbl = Instance.new("TextLabel")
myBaseLbl.Size = UDim2.new(1, -20, 0, 14)
myBaseLbl.Position = UDim2.new(0, 10, 1, -36)
myBaseLbl.BackgroundTransparency = 1
myBaseLbl.Font = Enum.Font.GothamBold
myBaseLbl.TextSize = 10
myBaseLbl.TextWrapped = true
myBaseLbl.ZIndex = 5
myBaseLbl.Parent = sidebar

local function updateMyBase()
    local base = getPlayerBase(plr)
    if base then
        myBaseLbl.Text = base
        myBaseLbl.TextColor3 = getBaseColor(base)
    else
        myBaseLbl.Text = "No base"
        myBaseLbl.TextColor3 = C.TextMute
    end
end

-- ============================================================
-- CONTENT AREA
-- ============================================================
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -130, 1, 0)
contentArea.Position = UDim2.new(0, 130, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.ZIndex = 2
contentArea.Parent = main

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "×"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -36, 0, 10)
closeBtn.BackgroundColor3 = C.Danger
closeBtn.BackgroundTransparency = 0.15
closeBtn.TextColor3 = C.White
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 8
closeBtn.Parent = contentArea
cr(closeBtn, 13)

closeBtn.MouseEnter:Connect(function()
    TS:Create(closeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TS:Create(closeBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.15, BackgroundColor3 = C.Danger}):Play()
end)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local pContent = Instance.new("Frame")
pContent.Size = UDim2.new(1, -24, 1, -16)
pContent.Position = UDim2.new(0, 12, 0, 8)
pContent.BackgroundTransparency = 1
pContent.ZIndex = 3
pContent.Visible = true
pContent.Parent = contentArea

local vContent = Instance.new("Frame")
vContent.Size = UDim2.new(1, -24, 1, -16)
vContent.Position = UDim2.new(0, 12, 0, 8)
vContent.BackgroundTransparency = 1
vContent.ZIndex = 3
vContent.Visible = false
vContent.Parent = contentArea

local function switchTab(tab)
    currentTab = tab
    for id, data in pairs(navBtns) do
        if id == tab then
            TS:Create(data.btn, TweenInfo.new(0.2), {BackgroundColor3 = C.Card, BackgroundTransparency = 0}):Play()
            data.btn.TextColor3 = C.White
            data.indicator.Visible = true
        else
            TS:Create(data.btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            data.btn.TextColor3 = C.TextSub
            data.indicator.Visible = false
        end
    end
    pContent.Visible = tab == "players"
    vContent.Visible = tab == "vehicles"
end

navPlayers.MouseButton1Click:Connect(function() switchTab("players") end)
navVehicles.MouseButton1Click:Connect(function() switchTab("vehicles") end)

-- Drag
local titleDrag = Instance.new("Frame")
titleDrag.Size = UDim2.new(1, -40, 0, 50)
titleDrag.BackgroundTransparency = 1
titleDrag.ZIndex = 7
titleDrag.Parent = contentArea

local _dr, _di, _ds, _dp
titleDrag.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _dr = true; _ds = i.Position; _dp = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then _dr = false end
        end)
    end
end)
titleDrag.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then _di = i end
end)
UIS.InputChanged:Connect(function(i)
    if i == _di and _dr then
        local d = i.Position - _ds
        TS:Create(main, TweenInfo.new(0.06), {
            Position = UDim2.new(_dp.X.Scale, _dp.X.Offset+d.X, _dp.Y.Scale, _dp.Y.Offset+d.Y)
        }):Play()
    end
end)

sidebar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _dr = true; _ds = i.Position; _dp = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then _dr = false end
        end)
    end
end)
sidebar.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then _di = i end
end)

-- ============================================================
-- PLAYERS TAB
-- ============================================================
local pTitle = Instance.new("TextLabel")
pTitle.Text = "PLAYERS"
pTitle.Size = UDim2.new(0.5, 0, 0, 26)
pTitle.Position = UDim2.new(0, 4, 0, 8)
pTitle.BackgroundTransparency = 1
pTitle.TextColor3 = C.Text
pTitle.Font = Enum.Font.GothamBlack
pTitle.TextSize = 16
pTitle.TextXAlignment = Enum.TextXAlignment.Left
pTitle.ZIndex = 5
pTitle.Parent = pContent

local onlineLbl = Instance.new("TextLabel")
onlineLbl.Size = UDim2.new(0.5, -48, 0, 26)
onlineLbl.Position = UDim2.new(0.5, 0, 0, 8)
onlineLbl.BackgroundTransparency = 1
onlineLbl.TextColor3 = C.TextMute
onlineLbl.Font = Enum.Font.Gotham
onlineLbl.TextSize = 11
onlineLbl.TextXAlignment = Enum.TextXAlignment.Right
onlineLbl.ZIndex = 5
onlineLbl.Parent = pContent

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 30)
searchFrame.Position = UDim2.new(0, 0, 0, 38)
searchFrame.BackgroundColor3 = C.Card
searchFrame.BorderSizePixel = 0
searchFrame.ZIndex = 4
searchFrame.Parent = pContent
cr(searchFrame, 8)
sk(searchFrame, C.Border, 1, 0.4)

local searchIcon = Instance.new("TextLabel")
searchIcon.Text = "🔍"
searchIcon.Size = UDim2.new(0, 26, 1, 0)
searchIcon.Position = UDim2.new(0, 6, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.TextColor3 = C.TextMute
searchIcon.Font = Enum.Font.SourceSans
searchIcon.TextSize = 12
searchIcon.ZIndex = 5
searchIcon.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search player..."
searchBox.Text = ""
searchBox.Size = UDim2.new(1, -38, 1, 0)
searchBox.Position = UDim2.new(0, 32, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextColor3 = C.Text
searchBox.PlaceholderColor3 = C.TextMute
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 5
searchBox.Parent = searchFrame

local searchQuery = ""
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text:lower()
    for player, el in pairs(plrEl) do
        if searchQuery == "" then
            el.Visible = true
        else
            local match = player.Name:lower():find(searchQuery) or player.DisplayName:lower():find(searchQuery)
            el.Visible = match ~= nil
        end
    end
    task.defer(function()
        local lay = pContent:FindFirstChild("PlayerScroll") and pContent.PlayerScroll:FindFirstChildOfClass("UIListLayout")
        if lay then pContent.PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8) end
    end)
end)

local pScroll = Instance.new("ScrollingFrame")
pScroll.Name = "PlayerScroll"
pScroll.Size = UDim2.new(1, 0, 0, 200)
pScroll.Position = UDim2.new(0, 0, 0, 72)
pScroll.BackgroundColor3 = C.Bg
pScroll.BackgroundTransparency = 0.3
pScroll.ScrollBarThickness = 3
pScroll.ScrollBarImageColor3 = C.Accent
pScroll.ScrollBarImageTransparency = 0.4
pScroll.BorderSizePixel = 0
pScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
pScroll.ZIndex = 4
pScroll.Parent = pContent
cr(pScroll, 8)
sk(pScroll, C.Border, 1, 0.5)

local pLay = Instance.new("UIListLayout"); pLay.Padding = UDim.new(0, 3); pLay.Parent = pScroll
pad(pScroll, 4, 4, 4, 4)

local pStatLbl = Instance.new("TextLabel")
pStatLbl.Size = UDim2.new(1, 0, 0, 26)
pStatLbl.Position = UDim2.new(0, 0, 0, 278)
pStatLbl.BackgroundColor3 = C.Card
pStatLbl.BackgroundTransparency = 0.3
pStatLbl.TextColor3 = C.TextMute
pStatLbl.Font = Enum.Font.Gotham
pStatLbl.TextSize = 11
pStatLbl.ZIndex = 4
pStatLbl.Parent = pContent
cr(pStatLbl, 6)

local function updPStat()
    local c = 0; for _ in pairs(selP) do c += 1 end
    local w = 0; for _ in pairs(wlP) do w += 1 end
    if c == 0 and w == 0 then
        pStatLbl.Text = "No targets selected"; pStatLbl.TextColor3 = C.TextMute
    elseif c == 0 then
        pStatLbl.Text = w.." whitelisted"; pStatLbl.TextColor3 = C.WLA
    else
        local extra = w > 0 and ("  ·  "..w.." safe") or ""
        pStatLbl.Text = c.." target"..(c>1 and "s" or "")..extra; pStatLbl.TextColor3 = C.Success
    end
end

local function updOnline()
    local count = #Players:GetPlayers() - 1
    onlineLbl.Text = count.." online"
    sideInfo.Text = "RPG Spammer\n"..count.." players"
end

-- ============================================================
-- PLAYER ROW (volumetric)
-- ============================================================
local function createPlrEl(player)
    if player == plr or plrEl[player] then return end

    local row = Instance.new("Frame")
    row.Name = player.Name
    row.Size = UDim2.new(1, -4, 0, 50)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel = 0
    row.ZIndex = 5
    row.Parent = pScroll
    cr(row, 8)
    local rowStroke = sk(row, C.Border, 1, 0.35)
    addRowGradient(row)

    -- Checkbox
    local cb = Instance.new("Frame")
    cb.Size = UDim2.new(0, 18, 0, 18)
    cb.Position = UDim2.new(0, 8, 0.5, -9)
    cb.BackgroundColor3 = C.Input
    cb.BorderSizePixel = 0; cb.ZIndex = 6
    cb.Parent = row; cr(cb, 5)
    local cbStroke = sk(cb, C.Border, 1, 0)

    local cm = Instance.new("TextLabel")
    cm.Text = ""; cm.Size = UDim2.new(1,0,1,0); cm.BackgroundTransparency = 1
    cm.TextColor3 = C.White; cm.Font = Enum.Font.GothamBold; cm.TextSize = 12
    cm.ZIndex = 7; cm.Parent = cb

    -- Avatar
    local avFrame = Instance.new("Frame")
    avFrame.Size = UDim2.new(0, 32, 0, 32)
    avFrame.Position = UDim2.new(0, 32, 0.5, -16)
    avFrame.BackgroundColor3 = C.Input
    avFrame.ZIndex = 6; avFrame.Parent = row; cr(avFrame, 16)
    sk(avFrame, C.Border, 1, 0.6)

    local av = Instance.new("ImageLabel")
    av.Size = UDim2.new(1, -2, 1, -2)
    av.Position = UDim2.new(0, 1, 0, 1)
    av.BackgroundTransparency = 1; av.ZIndex = 7
    av.Parent = avFrame; cr(av, 15)

    task.spawn(function()
        local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if ok and av and av.Parent then av.Image = img end
    end)

    -- Name
    local nl = Instance.new("TextLabel")
    nl.Text = player.DisplayName
    nl.Size = UDim2.new(0, 100, 0, 16)
    nl.Position = UDim2.new(0, 70, 0, 7)
    nl.BackgroundTransparency = 1; nl.TextColor3 = C.Text
    nl.Font = Enum.Font.GothamBold; nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd
    nl.ZIndex = 7; nl.Parent = row

    -- Info line
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Name = "InfoLbl"
    infoLbl.Size = UDim2.new(0, 180, 0, 12)
    infoLbl.Position = UDim2.new(0, 70, 0, 27)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 10
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
    infoLbl.ZIndex = 7; infoLbl.RichText = true
    infoLbl.Parent = row

    local function updateInfo()
        if not player or not player.Parent then return end
        local parts = {}
        table.insert(parts, '<font color="#50506A">@'..player.Name..'</font>')
        local base = getPlayerBase(player)
        if base then
            local bCol = getBaseColor(base)
            local bHex = string.format("#%02X%02X%02X", math.floor(bCol.R*255), math.floor(bCol.G*255), math.floor(bCol.B*255))
            table.insert(parts, '<font color="'..bHex..'">'..base..'</font>')
        end
        local dist = getDistanceTo(player)
        if dist then table.insert(parts, '<font color="#50506A">'..dist..'m</font>') end
        if playerHasRPG(player) then table.insert(parts, '<font color="#6237D2">RPG</font>') end
        infoLbl.Text = table.concat(parts, '  ')
    end
    updateInfo()

    -- Shield break button
    local shBtn = Instance.new("TextButton")
    shBtn.Name = "ShieldIcon"
    shBtn.Text = "⚡"
    shBtn.Size = UDim2.new(0, 22, 0, 22)
    shBtn.Position = UDim2.new(1, -52, 0.5, -11)
    shBtn.BackgroundColor3 = C.Shield
    shBtn.BackgroundTransparency = 0.7
    shBtn.TextColor3 = C.Shield
    shBtn.Font = Enum.Font.SourceSans
    shBtn.TextSize = 13
    shBtn.AutoButtonColor = false
    shBtn.BorderSizePixel = 0; shBtn.ZIndex = 8
    shBtn.Visible = false; shBtn.Parent = row
    cr(shBtn, 5)

    shBtn.MouseEnter:Connect(function()
        TS:Create(shBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        shBtn.TextColor3 = C.Bg
    end)
    shBtn.MouseLeave:Connect(function()
        TS:Create(shBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.7}):Play()
        shBtn.TextColor3 = C.Shield
    end)
    shBtn.MouseButton1Click:Connect(function()
        TS:Create(shBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.Danger}):Play()
        task.delay(0.5, function()
            if shBtn and shBtn.Parent then
                TS:Create(shBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.Shield}):Play()
            end
        end)
        breakShield(player)
    end)

    -- WL button
    local wlBtn = Instance.new("TextButton")
    wlBtn.Name = "WL"
    wlBtn.Text = "🛡"
    wlBtn.Size = UDim2.new(0, 22, 0, 22)
    wlBtn.Position = UDim2.new(1, -26, 0.5, -11)
    wlBtn.BackgroundColor3 = C.Input
    wlBtn.TextColor3 = C.TextMute
    wlBtn.Font = Enum.Font.SourceSans
    wlBtn.TextSize = 13
    wlBtn.AutoButtonColor = false
    wlBtn.BorderSizePixel = 0; wlBtn.ZIndex = 8
    wlBtn.Parent = row; cr(wlBtn, 5)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, -58, 1, 0)
    clickBtn.BackgroundTransparency = 1; clickBtn.Text = ""
    clickBtn.ZIndex = 8; clickBtn.Parent = row

    local function vis()
        local isWL = wlP[player]
        local isSel = selP[player]
        if isWL then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 28, 50)}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.WL, Transparency = 0.2}):Play()
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.WL}):Play()
            wlBtn.TextColor3 = C.White
            if isSel then selP[player] = nil end
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = C.Input}):Play()
            cbStroke.Color = C.Border; cm.Text = ""
            nl.TextColor3 = C.WLA
        elseif isSel then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.Sel}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.SelBrd, Transparency = 0.15}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
            cbStroke.Color = C.Accent; cm.Text = "✓"
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.Input}):Play()
            wlBtn.TextColor3 = C.TextMute; nl.TextColor3 = C.Text
        else
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.Card}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.Border, Transparency = 0.35}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = C.Input}):Play()
            cbStroke.Color = C.Border; cm.Text = ""
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.Input}):Play()
            wlBtn.TextColor3 = C.TextMute; nl.TextColor3 = C.Text
        end
    end

    clickBtn.MouseButton1Click:Connect(function()
        if wlP[player] then return end
        selP[player] = not selP[player] or nil
        vis(); updPStat()
    end)

    wlBtn.MouseButton1Click:Connect(function()
        wlP[player] = not wlP[player] or nil
        vis(); updPStat()
    end)

    clickBtn.MouseEnter:Connect(function()
        if not selP[player] and not wlP[player] then
            TS:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C.CardH}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.1), {Transparency = 0.15}):Play()
        end
    end)
    clickBtn.MouseLeave:Connect(function() vis() end)

    plrEl[player] = row

    if not row:FindFirstChild("_updateFunc") then
        local bv = Instance.new("BindableEvent")
        bv.Name = "_updateFunc"
        bv.Parent = row
        bv.Event:Connect(updateInfo)
    end

    if isShielded(player) then shBtn.Visible = true end

    task.defer(function()
        pScroll.CanvasSize = UDim2.new(0, 0, 0, pLay.AbsoluteContentSize.Y + 8)
    end)
end

local function removePlrEl(player)
    selP[player] = nil; wlP[player] = nil
    if plrEl[player] then plrEl[player]:Destroy(); plrEl[player] = nil end
    updPStat(); updOnline()
    task.defer(function()
        pScroll.CanvasSize = UDim2.new(0, 0, 0, pLay.AbsoluteContentSize.Y + 8)
    end)
end

-- Action buttons
local pBtnFrame = Instance.new("Frame")
pBtnFrame.Size = UDim2.new(1, 0, 0, 30)
pBtnFrame.Position = UDim2.new(0, 0, 0, 310)
pBtnFrame.BackgroundTransparency = 1
pBtnFrame.ZIndex = 4
pBtnFrame.Parent = pContent

local function makeSmallBtn(text, xPos, xSize, parent, col)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(xSize, -4, 1, 0)
    btn.Position = UDim2.new(xPos, 2, 0, 0)
    btn.BackgroundColor3 = col or C.Card
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Parent = parent
    cr(btn, 6)
    sk(btn, C.Border, 1, 0.5)
    local base = col or C.Card
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.CardH}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = base}):Play()
    end)
    return btn
end

local pSelAll = makeSmallBtn("Select All", 0, 0.33, pBtnFrame)
local pClear = makeSmallBtn("Clear All", 0.33, 0.34, pBtnFrame)
local pClearWL = makeSmallBtn("Clear WL", 0.67, 0.33, pBtnFrame, Color3.fromRGB(25, 35, 60))

pSelAll.MouseButton1Click:Connect(function()
    for p in pairs(plrEl) do
        if not wlP[p] then selP[p] = true end
    end
    for p, el in pairs(plrEl) do
        if selP[p] then
            TS:Create(el, TweenInfo.new(0.1), {BackgroundColor3 = C.Sel}):Play()
            local rs = el:FindFirstChildOfClass("UIStroke")
            if rs then TS:Create(rs, TweenInfo.new(0.1), {Color = C.SelBrd, Transparency = 0.15}):Play() end
            for _, child in pairs(el:GetChildren()) do
                if child:IsA("Frame") and child.Size == UDim2.new(0, 18, 0, 18) then
                    TS:Create(child, TweenInfo.new(0.1), {BackgroundColor3 = C.Accent}):Play()
                    local cbs = child:FindFirstChildOfClass("UIStroke")
                    if cbs then cbs.Color = C.Accent end
                    local txt = child:FindFirstChildOfClass("TextLabel")
                    if txt then txt.Text = "✓" end
                end
            end
        end
    end
    updPStat()
end)

pClear.MouseButton1Click:Connect(function()
    for p in pairs(selP) do selP[p] = nil end
    for p, el in pairs(plrEl) do
        if not wlP[p] then
            TS:Create(el, TweenInfo.new(0.1), {BackgroundColor3 = C.Card}):Play()
            local rs = el:FindFirstChildOfClass("UIStroke")
            if rs then TS:Create(rs, TweenInfo.new(0.1), {Color = C.Border, Transparency = 0.35}):Play() end
            for _, child in pairs(el:GetChildren()) do
                if child:IsA("Frame") and child.Size == UDim2.new(0, 18, 0, 18) then
                    TS:Create(child, TweenInfo.new(0.1), {BackgroundColor3 = C.Input}):Play()
                    local cbs = child:FindFirstChildOfClass("UIStroke")
                    if cbs then cbs.Color = C.Border end
                    local txt = child:FindFirstChildOfClass("TextLabel")
                    if txt then txt.Text = "" end
                end
            end
        end
    end
    updPStat()
end)

pClearWL.MouseButton1Click:Connect(function()
    for p in pairs(wlP) do wlP[p] = nil end
    for p, el in pairs(plrEl) do
        if not selP[p] then
            TS:Create(el, TweenInfo.new(0.1), {BackgroundColor3 = C.Card}):Play()
        end
        local wl = el:FindFirstChild("WL")
        if wl then
            TS:Create(wl, TweenInfo.new(0.1), {BackgroundColor3 = C.Input}):Play()
            wl.TextColor3 = C.TextMute
        end
    end
    updPStat()
end)

local pToggle = Instance.new("TextButton")
pToggle.Text = "⚡  START PLAYERS"
pToggle.Size = UDim2.new(1, 0, 0, 44)
pToggle.Position = UDim2.new(0, 0, 0, 346)
pToggle.BackgroundColor3 = C.AccentD
pToggle.TextColor3 = C.White
pToggle.Font = Enum.Font.GothamBlack
pToggle.TextSize = 14
pToggle.AutoButtonColor = false
pToggle.BorderSizePixel = 0
pToggle.ZIndex = 5
pToggle.Parent = pContent
cr(pToggle, 8)

local pGrad = Instance.new("UIGradient")
pGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 35, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 25, 55)),
})
pGrad.Rotation = 90
pGrad.Parent = pToggle

pToggle.MouseEnter:Connect(function()
    TS:Create(pToggle, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
end)
pToggle.MouseLeave:Connect(function()
    TS:Create(pToggle, TweenInfo.new(0.2), {BackgroundColor3 = C.AccentD}):Play()
end)

pToggle.MouseButton1Click:Connect(function()
    pSpamOn = not pSpamOn
    if pSpamOn then
        local n = 0; for _ in pairs(selP) do n += 1 end
        if n == 0 then
            pStatLbl.Text = "Select targets first!"; pStatLbl.TextColor3 = C.Danger
            pSpamOn = false; return
        end
        if not rpgReady then
            pStatLbl.Text = "RPG system not found!"; pStatLbl.TextColor3 = C.Danger
            pSpamOn = false; return
        end
        pToggle.Text = "⏹  STOP PLAYERS"
        pGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 110, 75)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 75, 55)),
        })
        pStatLbl.Text = "Active — "..n.." target"..(n>1 and "s" or "")
        pStatLbl.TextColor3 = C.Success

        pThreads["main"] = task.spawn(function()
            while pSpamOn do
                for p in pairs(selP) do
                    if p and p.Parent and p.Character and not wlP[p] and not isShielded(p) then
                        for i = 1, 3 do task.spawn(attackPlayer, p) end
                    end
                end
                task.wait(0.05)
            end
        end)
        for i = 1, 3 do
            pThreads["t"..i] = task.spawn(function()
                while pSpamOn do
                    for p in pairs(selP) do
                        if p and p.Parent and p.Character and not wlP[p] and not isShielded(p) then
                            task.spawn(attackPlayer, p)
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    else
        pToggle.Text = "⚡  START PLAYERS"
        pGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 35, 170)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 25, 55)),
        })
        pStatLbl.Text = "Stopped"; pStatLbl.TextColor3 = C.TextMute
        for _, th in pairs(pThreads) do pcall(task.cancel, th) end
        pThreads = {}
    end
end)

-- ============================================================
-- VEHICLES TAB
-- ============================================================
local vTitle = Instance.new("TextLabel")
vTitle.Text = "VEHICLES"
vTitle.Size = UDim2.new(0.5, 0, 0, 26)
vTitle.Position = UDim2.new(0, 4, 0, 8)
vTitle.BackgroundTransparency = 1
vTitle.TextColor3 = C.Text
vTitle.Font = Enum.Font.GothamBlack
vTitle.TextSize = 16
vTitle.TextXAlignment = Enum.TextXAlignment.Left
vTitle.ZIndex = 5
vTitle.Parent = vContent

local vCntLbl = Instance.new("TextLabel")
vCntLbl.Size = UDim2.new(0.5, -48, 0, 26)
vCntLbl.Position = UDim2.new(0.5, 0, 0, 8)
vCntLbl.BackgroundTransparency = 1
vCntLbl.TextColor3 = C.TextMute
vCntLbl.Font = Enum.Font.Gotham
vCntLbl.TextSize = 11
vCntLbl.TextXAlignment = Enum.TextXAlignment.Right
vCntLbl.ZIndex = 5
vCntLbl.Parent = vContent

local vScroll = Instance.new("ScrollingFrame")
vScroll.Size = UDim2.new(1, 0, 0, 250)
vScroll.Position = UDim2.new(0, 0, 0, 38)
vScroll.BackgroundColor3 = C.Bg
vScroll.BackgroundTransparency = 0.3
vScroll.ScrollBarThickness = 3
vScroll.ScrollBarImageColor3 = C.Accent
vScroll.ScrollBarImageTransparency = 0.4
vScroll.BorderSizePixel = 0
vScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
vScroll.ZIndex = 4
vScroll.Parent = vContent
cr(vScroll, 8)
sk(vScroll, C.Border, 1, 0.5)

local vLay = Instance.new("UIListLayout"); vLay.Padding = UDim.new(0, 3); vLay.Parent = vScroll
pad(vScroll, 4, 4, 4, 4)

local vStatLbl = Instance.new("TextLabel")
vStatLbl.Size = UDim2.new(1, 0, 0, 26)
vStatLbl.Position = UDim2.new(0, 0, 0, 294)
vStatLbl.BackgroundColor3 = C.Card
vStatLbl.BackgroundTransparency = 0.3
vStatLbl.TextColor3 = C.TextMute
vStatLbl.Font = Enum.Font.Gotham
vStatLbl.TextSize = 11
vStatLbl.ZIndex = 4
vStatLbl.Parent = vContent
cr(vStatLbl, 6)

local function updVStat()
    local n = 0; for _ in pairs(selV) do n += 1 end
    if n == 0 then
        vStatLbl.Text = "No targets selected"; vStatLbl.TextColor3 = C.TextMute
    else
        vStatLbl.Text = n.." target"..(n>1 and "s" or "").." selected"; vStatLbl.TextColor3 = C.Success
    end
end

local function makeVehRow(tgt)
    local mdl = tgt.Model

    local row = Instance.new("Frame")
    row.Name = tgt.Name
    row.Size = UDim2.new(1, -4, 0, 50)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel = 0; row.ZIndex = 5
    row.Parent = vScroll; cr(row, 8)
    local rowStroke = sk(row, C.Border, 1, 0.35)
    addRowGradient(row)

    local cb = Instance.new("Frame")
    cb.Size = UDim2.new(0, 18, 0, 18)
    cb.Position = UDim2.new(0, 8, 0.5, -9)
    cb.BackgroundColor3 = C.Input
    cb.BorderSizePixel = 0; cb.ZIndex = 6
    cb.Parent = row; cr(cb, 5)
    local cbStroke = sk(cb, C.Border, 1, 0)

    local cm = Instance.new("TextLabel")
    cm.Text = ""; cm.Size = UDim2.new(1,0,1,0); cm.BackgroundTransparency = 1
    cm.TextColor3 = C.White; cm.Font = Enum.Font.GothamBold; cm.TextSize = 12
    cm.ZIndex = 7; cm.Parent = cb

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 40, 0, 20)
    badge.Position = UDim2.new(0, 32, 0.5, -10)
    badge.BackgroundColor3 = vCol[tgt.Type] or C.Card
    badge.BackgroundTransparency = 0.5
    badge.ZIndex = 6; badge.Parent = row; cr(badge, 5)

    local bTxt = Instance.new("TextLabel")
    bTxt.Text = vShort[tgt.Type] or "??"
    bTxt.Size = UDim2.new(1,0,1,0); bTxt.BackgroundTransparency = 1
    bTxt.TextColor3 = C.Text; bTxt.TextSize = 9; bTxt.Font = Enum.Font.GothamBlack
    bTxt.ZIndex = 7; bTxt.Parent = badge

    local nl = Instance.new("TextLabel")
    nl.Text = tgt.Name
    nl.Size = UDim2.new(0, 150, 0, 16); nl.Position = UDim2.new(0, 78, 0, 7)
    nl.BackgroundTransparency = 1; nl.TextColor3 = C.Text
    nl.Font = Enum.Font.GothamBold; nl.TextSize = 12
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd; nl.ZIndex = 7; nl.Parent = row

    local ol = Instance.new("TextLabel")
    ol.Name = "VehInfo"
    ol.Size = UDim2.new(0, 220, 0, 12); ol.Position = UDim2.new(0, 78, 0, 27)
    ol.BackgroundTransparency = 1; ol.Font = Enum.Font.Gotham; ol.TextSize = 10
    ol.TextXAlignment = Enum.TextXAlignment.Left; ol.TextTruncate = Enum.TextTruncate.AtEnd
    ol.ZIndex = 7; ol.RichText = true; ol.Parent = row

    local function updateVehInfo()
        local parts = {}
        if tgt.DisplayName and tgt.DisplayName ~= "" then
            parts[#parts+1] = '<font color="#9C84FC">'..tgt.DisplayName..'</font>'
            if tgt.Base and tgt.Base ~= "" then
                local bCol = getBaseColor(tgt.Base)
                local bHex = string.format("#%02X%02X%02X", math.floor(bCol.R*255), math.floor(bCol.G*255), math.floor(bCol.B*255))
                parts[#parts+1] = '<font color="'..bHex..'">'..tgt.Base..'</font>'
            end
        else
            parts[#parts+1] = '<font color="#50506A">No owner</font>'
        end
        local dist = getDistanceToVeh(tgt.HRP)
        if dist then parts[#parts+1] = '<font color="#50506A">'..dist..'m</font>' end
        ol.Text = table.concat(parts, '  ')
    end
    updateVehInfo()

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.ZIndex = 8; btn.Parent = row

    local function vis()
        local s = selV[mdl] ~= nil
        if s then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.Sel}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.SelBrd, Transparency = 0.15}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
            cbStroke.Color = C.Accent; cm.Text = "✓"
        else
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.Card}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.Border, Transparency = 0.35}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = C.Input}):Play()
            cbStroke.Color = C.Border; cm.Text = ""
        end
    end

    btn.MouseButton1Click:Connect(function()
        if selV[mdl] then selV[mdl] = nil
        else selV[mdl] = {Model=mdl, HRP=tgt.HRP, Type=tgt.Type, Name=tgt.Name} end
        vis(); updVStat()
    end)

    btn.MouseEnter:Connect(function()
        if not selV[mdl] then
            TS:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C.CardH}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.1), {Transparency = 0.15}):Play()
        end
    end)
    btn.MouseLeave:Connect(function() vis() end)

    vehEl[mdl] = {row=row, vis=vis, tgt=tgt, updateInfo=updateVehInfo}
end

local function refreshVeh()
    for m, e in pairs(vehEl) do e.row:Destroy() end
    vehEl = {}
    scanVehicles()
    local keep = {}
    for _, t in ipairs(vehInst) do
        if selV[t.Model] then keep[t.Model] = {Model=t.Model, HRP=t.HRP, Type=t.Type, Name=t.Name} end
    end
    selV = keep
    for _, t in ipairs(vehInst) do
        makeVehRow(t)
        if selV[t.Model] then vehEl[t.Model].vis() end
    end
    vCntLbl.Text = #vehInst.." found"
    task.defer(function()
        vScroll.CanvasSize = UDim2.new(0, 0, 0, vLay.AbsoluteContentSize.Y + 8)
    end)
    updVStat()
end

local vBtnFrame = Instance.new("Frame")
vBtnFrame.Size = UDim2.new(1, 0, 0, 30)
vBtnFrame.Position = UDim2.new(0, 0, 0, 326)
vBtnFrame.BackgroundTransparency = 1
vBtnFrame.ZIndex = 4
vBtnFrame.Parent = vContent

local vSelAll = makeSmallBtn("Select All", 0, 0.5, vBtnFrame)
local vClearAll = makeSmallBtn("Clear All", 0.5, 0.5, vBtnFrame)

vSelAll.MouseButton1Click:Connect(function()
    for m, e in pairs(vehEl) do
        selV[m] = {Model=m, HRP=e.tgt.HRP, Type=e.tgt.Type, Name=e.tgt.Name}
        e.vis()
    end
    updVStat()
end)

vClearAll.MouseButton1Click:Connect(function()
    selV = {}; for _, e in pairs(vehEl) do e.vis() end; updVStat()
end)

local vToggle = Instance.new("TextButton")
vToggle.Text = "⚡  START VEHICLES"
vToggle.Size = UDim2.new(1, 0, 0, 44)
vToggle.Position = UDim2.new(0, 0, 0, 362)
vToggle.BackgroundColor3 = C.AccentD
vToggle.TextColor3 = C.White
vToggle.Font = Enum.Font.GothamBlack
vToggle.TextSize = 14
vToggle.AutoButtonColor = false
vToggle.BorderSizePixel = 0
vToggle.ZIndex = 5
vToggle.Parent = vContent
cr(vToggle, 8)

local vGrad = Instance.new("UIGradient")
vGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 35, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 25, 55)),
})
vGrad.Rotation = 90
vGrad.Parent = vToggle

vToggle.MouseEnter:Connect(function()
    TS:Create(vToggle, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
end)
vToggle.MouseLeave:Connect(function()
    TS:Create(vToggle, TweenInfo.new(0.2), {BackgroundColor3 = C.AccentD}):Play()
end)

vToggle.MouseButton1Click:Connect(function()
    vSpamOn = not vSpamOn
    if vSpamOn then
        local n = 0; for _ in pairs(selV) do n += 1 end
        if n == 0 then
            vStatLbl.Text = "Select targets first!"; vStatLbl.TextColor3 = C.Danger
            vSpamOn = false; return
        end
        if not rpgReady then
            vStatLbl.Text = "RPG system not found!"; vStatLbl.TextColor3 = C.Danger
            vSpamOn = false; return
        end
        if not tool then
            tool = findRPG()
            if not tool then
                vStatLbl.Text = "Need RPG!"; vStatLbl.TextColor3 = C.Danger
                vSpamOn = false; return
            end
        end
        vToggle.Text = "⏹  STOP VEHICLES"
        vGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 110, 75)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 75, 55)),
        })
        vStatLbl.Text = "Active — "..n.." target"..(n>1 and "s" or "")
        vStatLbl.TextColor3 = C.Success

        vThreads["main"] = task.spawn(function()
            while vSpamOn do
                for _, td in pairs(selV) do
                    if vSpamOn and td.Model and td.Model.Parent then
                        attackVehicle(td); task.wait(0.05)
                    end
                end
                task.wait(0.1)
            end
        end)
        for i = 1, 3 do
            vThreads["t"..i] = task.spawn(function()
                while vSpamOn do
                    for _, td in pairs(selV) do
                        if vSpamOn and td.Model and td.Model.Parent then
                            task.spawn(attackVehicle, td)
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    else
        vToggle.Text = "⚡  START VEHICLES"
        vGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 35, 170)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 25, 55)),
        })
        vStatLbl.Text = "Stopped"; vStatLbl.TextColor3 = C.TextMute
        for _, th in pairs(vThreads) do pcall(task.cancel, th) end
        vThreads = {}
    end
end)

-- ============================================================
-- FLOATING TOGGLE
-- ============================================================
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "Toggle"
floatBtn.Text = "RPG"
floatBtn.Size = UDim2.new(0, 42, 0, 42)
floatBtn.Position = UDim2.new(0, 12, 0.5, -21)
floatBtn.BackgroundColor3 = C.Bg
floatBtn.TextColor3 = C.AccentL
floatBtn.Font = Enum.Font.GothamBlack
floatBtn.TextSize = 10
floatBtn.AutoButtonColor = false
floatBtn.BorderSizePixel = 0
floatBtn.ZIndex = 10
floatBtn.Active = true
floatBtn.Parent = gui
cr(floatBtn, 21)
local fStroke = sk(floatBtn, C.Accent, 2, 0.3)

floatBtn.MouseEnter:Connect(function()
    TS:Create(fStroke, TweenInfo.new(0.15), {Transparency = 0, Color = C.AccentL}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TS:Create(fStroke, TweenInfo.new(0.2), {Transparency = 0.3, Color = C.Accent}):Play()
end)

local fd, fdi, fds, fsp
floatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        fd = true; fds = i.Position; fsp = floatBtn.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then fd = false end
        end)
    end
end)
floatBtn.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then fdi = i end
end)
UIS.InputChanged:Connect(function(i)
    if i == fdi and fd then
        local d = i.Position - fds
        floatBtn.Position = UDim2.new(fsp.X.Scale, fsp.X.Offset+d.X, fsp.Y.Scale, fsp.Y.Offset+d.Y)
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

-- ============================================================
-- RESPAWN
-- ============================================================
plr.CharacterAdded:Connect(function(nc)
    char = nc
    hrp = nc:WaitForChild("HumanoidRootPart")
    tool = nc:WaitForChild("RPG", 5)
    if not tool then
        local bp = plr:FindFirstChild("Backpack")
        if bp then tool = bp:FindFirstChild("RPG") end
    end
    pcall(function()
        if not rpgReady then
            rvEv = game.ReplicatedStorage.RocketSystem.Events
            fxEv = rvEv.RocketReloadedFX
            fireEv = rvEv.FireRocketReplicated
            hitEv = rvEv.RocketHit
            rocketModel = game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"]
            rpgReady = true
        end
    end)
    if rpgReady and rpgDot then rpgDot.BackgroundColor3 = C.Success end
end)

-- ============================================================
-- INIT
-- ============================================================
for _, p in pairs(Players:GetPlayers()) do createPlrEl(p) end
updOnline(); updPStat(); updateMyBase()

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5); createPlrEl(p); updOnline()
end)
Players.PlayerRemoving:Connect(function(p) removePlrEl(p) end)

task.spawn(function()
    while true do
        for p, el in pairs(plrEl) do
            if p and p.Parent and el and el.Parent then
                local si = el:FindFirstChild("ShieldIcon")
                if si then si.Visible = isShielded(p) end
                local uf = el:FindFirstChild("_updateFunc")
                if uf then pcall(function() uf:Fire() end) end
            end
        end
        for m, e in pairs(vehEl) do
            if e.updateInfo and e.row and e.row.Parent then
                pcall(e.updateInfo)
            end
        end
        updateMyBase()
        task.wait(1.5)
    end
end)

refreshVeh()
task.spawn(function()
    while true do task.wait(3); refreshVeh() end
end)

task.spawn(function()
    while true do
        if rpgDot and rpgDot.Parent then
            local hasRPG = findRPG() ~= nil
            rpgDot.BackgroundColor3 = (rpgReady and hasRPG) and C.Success or C.Danger
        end
        task.wait(2)
    end
end)
