-- ============================================================
-- NAZARKUS RPG v8.1 — Combined Player + Vehicle Spammer
-- ============================================================

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

local rvEv = game.ReplicatedStorage.RocketSystem.Events
local fxEv = rvEv.RocketReloadedFX
local fireEv = rvEv.FireRocketReplicated
local hitEv = rvEv.RocketHit
local rCnt = 0
local rocketModel = game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"]

local rSettings = {
    expShake = {fadeInTime=0.05, magnitude=3, rotInfluence=Vector3.new(0.4,0,0.4),
        fadeOutTime=0.5, posInfluence=Vector3.new(1,1,0), roughness=3},
    gravity=Vector3.new(0,-20,0), HelicopterDamage=450, FireRate=15, VehicleDamage=350,
    ExpName="RPG", RocketAmount=1, ExpRadius=12, BoatDamage=300, TankDamage=300,
    Acceleration=8, ShieldDamage=170, Distance=4000, PlaneDamage=500,
    GunshipDamage=170, velocity=200, ExplosionDamage=120,
}

local gradTime = 0
local curGrad = Color3.fromRGB(100, 120, 200)
local syncBtns = {}

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    Bg    = Color3.fromRGB(8,10,18),
    Sec   = Color3.fromRGB(12,15,28),
    Ter   = Color3.fromRGB(20,24,40),
    Card  = Color3.fromRGB(14,17,32),
    Sel   = Color3.fromRGB(28,45,75),
    Ok    = Color3.fromRGB(40,100,75),
    Bad   = Color3.fromRGB(120,40,50),
    Txt   = Color3.fromRGB(230,232,245),
    Dim   = Color3.fromRGB(130,135,165),
    Mute  = Color3.fromRGB(80,85,110),
    Brd   = Color3.fromRGB(45,52,85),
    Chk   = Color3.fromRGB(45,115,95),
    Glow  = Color3.fromRGB(100,80,220),
    WL    = Color3.fromRGB(60,90,160),
    WLA   = Color3.fromRGB(80,130,220),
    Shd   = Color3.fromRGB(180,160,50),
    Air   = Color3.fromRGB(60,90,160),
    Gnd   = Color3.fromRGB(160,120,50),
    Own   = Color3.fromRGB(180,140,220),
    Bas   = Color3.fromRGB(100,180,140),
    NoO   = Color3.fromRGB(80,90,110),
    TAct  = Color3.fromRGB(45,115,95),
    TIn   = Color3.fromRGB(25,28,45),
}

-- ============================================================
-- VEHICLE CONFIG
-- ============================================================
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
    Helicopter = Color3.fromRGB(70,130,200),
    Plane      = Color3.fromRGB(100,160,220),
    Gunship    = Color3.fromRGB(200,80,80),
    Boat       = Color3.fromRGB(60,150,130),
    Tank       = Color3.fromRGB(160,140,60),
    Hovercraft = Color3.fromRGB(130,100,180),
}
local vShort = {
    Helicopter="HELI", Plane="PLANE", Gunship="GNSHP",
    Boat="BOAT", Tank="TANK", Hovercraft="HOVER",
}

-- ============================================================
-- STATE
-- ============================================================
local selP, wlP, plrEl = {}, {}, {}
local selV, vehInst, vehEl = {}, {}, {}
local pSpamOn, pThreads = false, {}
local vSpamOn, vThreads = false, {}

-- ============================================================
-- HELPERS
-- ============================================================
local function l3(a, b, t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

local function cr(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = p
    return c
end

local function sk(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Brd
    s.Thickness = th or 1.5
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function shd(p)
    local s = Instance.new("ImageLabel")
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://6014261993"
    s.ImageColor3 = Color3.new(0,0,0)
    s.ImageTransparency = 0.2
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49,49,450,450)
    s.Size = UDim2.new(1,80,1,80)
    s.Position = UDim2.new(0,-40,0,-40)
    s.ZIndex = p.ZIndex - 1
    s.Parent = p
end

local function glw(p, col)
    local g = Instance.new("Frame")
    g.Size = UDim2.new(1,0,1,0)
    g.BackgroundTransparency = 1
    g.ZIndex = p.ZIndex
    g.Parent = p
    local gs = Instance.new("UIStroke")
    gs.Color = col or C.Glow
    gs.Thickness = 1.5
    gs.Transparency = 0.6
    gs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    gs.Parent = g
    cr(g, 20)
    return g, gs
end

local function hfx(btn, base)
    local d = {button = btn, baseColor = base, isHovered = false}
    table.insert(syncBtns, d)
    btn.MouseEnter:Connect(function()
        d.isHovered = true
        TS:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        d.isHovered = false
        TS:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = base, BackgroundTransparency = 0}):Play()
    end)
    return d
end

-- ============================================================
-- SHIELD CHECK
-- ============================================================
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
                if (child:IsA("BasePart") or child:IsA("MeshPart")) and child.Transparency < 1 then
                    return true
                elseif child:IsA("Model") then
                    return true
                end
            end
        end
    end

    local rp = ch:FindFirstChild("HumanoidRootPart")
    if rp then
        for _, child in pairs(rp:GetChildren()) do
            local n = child.Name:lower()
            for _, k in pairs(kw) do
                if n:find(k) then return true end
            end
        end
    end

    return false
end

-- ============================================================
-- SHIELD BREAKER (ремоты из первого скрипта)
-- ============================================================
local function breakShield(player)
    if not player then return end

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
                    targetTycoon = tycoon
                    break
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

        for attempt = 1, 50 do
            if not shieldFolder or not shieldFolder.Parent then break end

            local parts = {}
            for _, part in ipairs(shieldFolder:GetChildren()) do
                if part:IsA("BasePart") and part.Parent then
                    table.insert(parts, part)
                end
            end
            if #parts == 0 then break end

            for _, part in ipairs(parts) do
                if part and part.Parent then
                    local position = part.Position
                    pcall(function()
                        hitEv:FireServer({
                            Normal = Vector3.new(0, 1, 0),
                            HitPart = part,
                            Position = position,
                            Label = plr.Name .. "ShieldBreak" .. rCnt,
                            Vehicle = weapon,
                            Player = plr,
                            Weapon = weapon,
                        })
                    end)
                    rCnt = rCnt + 1
                end
            end

            task.wait()
        end
    end)
end

-- ============================================================
-- VEHICLE SCANNING
-- ============================================================
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
                if p.Team then data.base = p.Team.Name end
            else
                data.displayName = data.username
            end
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
                            or mdl:FindFirstChild("Main")
                            or mdl:FindFirstChild("RootPart")
                            or mdl:FindFirstChild("Head")
                            or mdl.PrimaryPart
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

-- ============================================================
-- ATTACK FUNCTIONS
-- ============================================================
local function fireRocket(targetPos, hitPart)
    if not tool or not tool.Parent then
        tool = findRPG()
        if not tool then return false end
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
            Label = plr.Name .. "Rocket" .. rCnt, Vehicle = tool, Player = plr, Weapon = tool,
        })
    end)
    rCnt = rCnt + 1
    return true
end

local function attackPlayer(player)
    if not player or not player.Character then return end
    if wlP[player] or isShielded(player) then return end
    local w = player.Character:FindFirstChild("HumanoidRootPart")
    if not w then return end
    fireRocket(w.Position, w)
end

local function attackVehicle(td)
    if not td or not td.Model or not td.Model.Parent then return false end
    local h = td.HRP
    if not h or not h.Parent then return false end
    local pos = h.Position
    local off = {Boat = 3, Tank = 1.5, Hovercraft = 2, Plane = 1}
    if off[td.Type] then pos = pos + Vector3.new(0, off[td.Type], 0) end
    return fireRocket(pos, h)
end

-- ============================================================
-- GUI BASE
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "NazarkusRPG"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 580)
main.Position = UDim2.new(0.5, -200, 0.5, -290)
main.BackgroundColor3 = C.Bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = gui
cr(main, 20)
shd(main)

local outerG, outerGS = glw(main, C.Glow)

-- ============================================================
-- ANIMATED BACKGROUND
-- ============================================================
local bgc = Instance.new("Frame")
bgc.Size = UDim2.new(1,0,1,0)
bgc.BackgroundTransparency = 1
bgc.ClipsDescendants = true
bgc.ZIndex = 0
bgc.Parent = main
cr(bgc, 20)

local bf1 = Instance.new("Frame")
bf1.Size = UDim2.new(2.5,0,2.5,0)
bf1.Position = UDim2.new(-0.75,0,-0.75,0)
bf1.BackgroundColor3 = Color3.new(1,1,1)
bf1.BackgroundTransparency = 0.65
bf1.BorderSizePixel = 0
bf1.ZIndex = 0
bf1.Parent = bgc

local ug1 = Instance.new("UIGradient")
ug1.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100,60,180)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(60,110,200)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80,160,200)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150,90,200)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200,80,150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100,60,180)),
})
ug1.Parent = bf1

local bf2 = Instance.new("Frame")
bf2.Size = UDim2.new(2.5,0,2.5,0)
bf2.Position = UDim2.new(-0.75,0,-0.75,0)
bf2.BackgroundColor3 = Color3.new(1,1,1)
bf2.BackgroundTransparency = 0.7
bf2.BorderSizePixel = 0
bf2.ZIndex = 0
bf2.Parent = bgc

local ug2 = Instance.new("UIGradient")
ug2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200,100,160)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(100,180,200)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(160,120,200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90,150,200)),
})
ug2.Rotation = 60
ug2.Parent = bf2

local bf3 = Instance.new("Frame")
bf3.Size = UDim2.new(1.2,0,0.7,0)
bf3.Position = UDim2.new(-0.1,0,-0.1,0)
bf3.BackgroundColor3 = Color3.fromRGB(120,140,200)
bf3.BackgroundTransparency = 0.55
bf3.BorderSizePixel = 0
bf3.ZIndex = 0
bf3.Parent = bgc
cr(bf3, 20)

local ug3 = Instance.new("UIGradient")
ug3.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(0.3,0.4),
    NumberSequenceKeypoint.new(0.7,0.8), NumberSequenceKeypoint.new(1,1),
})
ug3.Rotation = 90
ug3.Parent = bf3

local dots = {}
for i = 1, 6 do
    local d = Instance.new("Frame")
    d.Size = UDim2.new(0, math.random(25,60), 0, math.random(25,60))
    d.Position = UDim2.new(math.random()*0.8, 0, math.random()*0.8, 0)
    d.BackgroundColor3 = Color3.fromRGB(150,130,200)
    d.BackgroundTransparency = 0.75
    d.BorderSizePixel = 0
    d.ZIndex = 0
    d.Parent = bgc
    cr(d, 50)
    table.insert(dots, {f=d, sx=(math.random()-0.5)*0.25, sy=(math.random()-0.5)*0.25, ph=math.random()*math.pi*2})
end

local animConn = RS.RenderStepped:Connect(function(dt)
    gradTime = gradTime + dt * 1.8
    ug1.Rotation = gradTime * 25
    ug1.Offset = Vector2.new(math.sin(gradTime*0.9)*0.35, math.cos(gradTime*0.7)*0.35)
    ug2.Rotation = -gradTime * 18 + 60
    ug2.Offset = Vector2.new(math.cos(gradTime*0.8)*0.4, math.sin(gradTime*1.1)*0.4)
    ug3.Offset = Vector2.new(math.sin(gradTime*1.5)*0.25, 0)
    bf3.BackgroundTransparency = 0.5 + math.sin(gradTime)*0.15

    local hue = (gradTime * 0.06) % 1
    bf3.BackgroundColor3 = Color3.fromHSV(hue*0.35+0.55, 0.55, 0.85)
    curGrad = Color3.fromHSV(hue*0.35+0.55, 0.65, 0.95)
    outerGS.Color = Color3.fromHSV((hue*0.35+0.6)%1, 0.45, 0.9)
    outerGS.Transparency = 0.55 + math.sin(gradTime*2.5)*0.15

    for _, p in ipairs(dots) do
        local x = 0.5 + math.sin(gradTime*p.sx+p.ph)*0.45
        local y = 0.5 + math.cos(gradTime*p.sy+p.ph)*0.45
        p.f.Position = UDim2.new(x, -p.f.Size.X.Offset/2, y, -p.f.Size.Y.Offset/2)
        p.f.BackgroundTransparency = 0.7 + math.sin(gradTime*2+p.ph)*0.2
        p.f.BackgroundColor3 = Color3.fromHSV((hue+p.ph/10)%1*0.3+0.55, 0.4, 0.85)
    end

    for _, d in ipairs(syncBtns) do
        if d.isHovered and d.button and d.button.Parent then
            d.button.BackgroundColor3 = l3(d.baseColor, curGrad, 0.55)
        end
    end
end)

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 2
titleBar.Parent = main

local _dr, _di, _ds, _dp
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _dr = true; _ds = i.Position; _dp = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then _dr = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(i)
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

local iBg = Instance.new("Frame")
iBg.Size = UDim2.new(0,38,0,38)
iBg.Position = UDim2.new(0,14,0,10)
iBg.BackgroundColor3 = C.Ter
iBg.BackgroundTransparency = 0.2
iBg.ZIndex = 2
iBg.Parent = titleBar
cr(iBg, 12)

local iLbl = Instance.new("TextLabel")
iLbl.Text = "🚀"
iLbl.Size = UDim2.new(1,0,1,0)
iLbl.BackgroundTransparency = 1
iLbl.TextSize = 20
iLbl.Font = Enum.Font.SourceSans
iLbl.ZIndex = 3
iLbl.Parent = iBg

local tLbl = Instance.new("TextLabel")
tLbl.Text = "NAZARKUS RPG"
tLbl.Size = UDim2.new(1,-130,0,24)
tLbl.Position = UDim2.new(0,60,0,10)
tLbl.BackgroundTransparency = 1
tLbl.TextColor3 = C.Txt
tLbl.Font = Enum.Font.GothamBlack
tLbl.TextSize = 18
tLbl.TextXAlignment = Enum.TextXAlignment.Left
tLbl.ZIndex = 2
tLbl.Parent = titleBar

local vBg = Instance.new("Frame")
vBg.Size = UDim2.new(0,45,0,18)
vBg.Position = UDim2.new(0,60,0,35)
vBg.BackgroundColor3 = C.Chk
vBg.BackgroundTransparency = 0.2
vBg.ZIndex = 2
vBg.Parent = titleBar
cr(vBg, 9)

local vLbl = Instance.new("TextLabel")
vLbl.Text = "v8.1"
vLbl.Size = UDim2.new(1,0,1,0)
vLbl.BackgroundTransparency = 1
vLbl.TextColor3 = C.Txt
vLbl.Font = Enum.Font.GothamBold
vLbl.TextSize = 10
vLbl.ZIndex = 3
vLbl.Parent = vBg

local btnC = Instance.new("Frame")
btnC.Size = UDim2.new(0,70,0,34)
btnC.Position = UDim2.new(1,-84,0,12)
btnC.BackgroundColor3 = C.Sec
btnC.BackgroundTransparency = 0.2
btnC.ZIndex = 2
btnC.Parent = titleBar
cr(btnC, 10)

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "×"
closeBtn.Size = UDim2.new(0,30,0,28)
closeBtn.Position = UDim2.new(1,-33,0.5,-14)
closeBtn.BackgroundColor3 = C.Bad
closeBtn.BackgroundTransparency = 0.3
closeBtn.TextColor3 = C.Txt
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.ZIndex = 3
closeBtn.Parent = btnC
cr(closeBtn, 8)
hfx(closeBtn, C.Bad)

local minBtn = Instance.new("TextButton")
minBtn.Text = "−"
minBtn.Size = UDim2.new(0,30,0,28)
minBtn.Position = UDim2.new(0,3,0.5,-14)
minBtn.BackgroundColor3 = C.Ter
minBtn.BackgroundTransparency = 0.2
minBtn.TextColor3 = C.Txt
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.ZIndex = 3
minBtn.Parent = btnC
cr(minBtn, 8)
hfx(minBtn, C.Ter)

-- ============================================================
-- TAB BAR
-- ============================================================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1,-28,0,30)
tabBar.Position = UDim2.new(0,14,0,57)
tabBar.BackgroundColor3 = C.Card
tabBar.BackgroundTransparency = 0.15
tabBar.ZIndex = 2
tabBar.Parent = main
cr(tabBar, 10)
sk(tabBar, C.Brd, 1, 0.4)

local tabP = Instance.new("TextButton")
tabP.Text = "👤 Players"
tabP.Size = UDim2.new(0.5,-2,1,-4)
tabP.Position = UDim2.new(0,2,0,2)
tabP.BackgroundColor3 = C.TAct
tabP.TextColor3 = C.Txt
tabP.Font = Enum.Font.GothamBold
tabP.TextSize = 12
tabP.ZIndex = 3
tabP.Parent = tabBar
cr(tabP, 8)

local tabV = Instance.new("TextButton")
tabV.Text = "🚁 Vehicles"
tabV.Size = UDim2.new(0.5,-2,1,-4)
tabV.Position = UDim2.new(0.5,0,0,2)
tabV.BackgroundColor3 = C.TIn
tabV.TextColor3 = C.Dim
tabV.Font = Enum.Font.GothamBold
tabV.TextSize = 12
tabV.ZIndex = 3
tabV.Parent = tabBar
cr(tabV, 8)

local pContent = Instance.new("Frame")
pContent.Size = UDim2.new(1,-28,1,-100)
pContent.Position = UDim2.new(0,14,0,93)
pContent.BackgroundTransparency = 1
pContent.ZIndex = 2
pContent.Visible = true
pContent.Parent = main

local vContent = Instance.new("Frame")
vContent.Size = UDim2.new(1,-28,1,-100)
vContent.Position = UDim2.new(0,14,0,93)
vContent.BackgroundTransparency = 1
vContent.ZIndex = 2
vContent.Visible = false
vContent.Parent = main

local function switchTab(tab)
    if tab == "players" then
        pContent.Visible = true
        vContent.Visible = false
        TS:Create(tabP, TweenInfo.new(0.15), {BackgroundColor3 = C.TAct}):Play()
        tabP.TextColor3 = C.Txt
        TS:Create(tabV, TweenInfo.new(0.15), {BackgroundColor3 = C.TIn}):Play()
        tabV.TextColor3 = C.Dim
    else
        pContent.Visible = false
        vContent.Visible = true
        TS:Create(tabV, TweenInfo.new(0.15), {BackgroundColor3 = C.TAct}):Play()
        tabV.TextColor3 = C.Txt
        TS:Create(tabP, TweenInfo.new(0.15), {BackgroundColor3 = C.TIn}):Play()
        tabP.TextColor3 = C.Dim
    end
end

tabP.MouseButton1Click:Connect(function() switchTab("players") end)
tabV.MouseButton1Click:Connect(function() switchTab("vehicles") end)

-- ============================================================
-- PLAYERS TAB
-- ============================================================

local pListSec = Instance.new("Frame")
pListSec.Size = UDim2.new(1,0,0,250)
pListSec.BackgroundColor3 = C.Card
pListSec.BackgroundTransparency = 0.15
pListSec.BorderSizePixel = 0
pListSec.ZIndex = 2
pListSec.Parent = pContent
cr(pListSec, 14)
sk(pListSec, C.Brd, 1, 0.4)

local pHdr = Instance.new("Frame")
pHdr.Size = UDim2.new(1,0,0,36)
pHdr.BackgroundTransparency = 1
pHdr.ZIndex = 3
pHdr.Parent = pListSec

local pHdrLbl = Instance.new("TextLabel")
pHdrLbl.Text = "🎯 TARGETS"
pHdrLbl.Size = UDim2.new(0.5,0,1,0)
pHdrLbl.Position = UDim2.new(0,14,0,0)
pHdrLbl.BackgroundTransparency = 1
pHdrLbl.TextColor3 = C.Dim
pHdrLbl.Font = Enum.Font.GothamBold
pHdrLbl.TextSize = 11
pHdrLbl.TextXAlignment = Enum.TextXAlignment.Left
pHdrLbl.ZIndex = 3
pHdrLbl.Parent = pHdr

local onlineLbl = Instance.new("TextLabel")
onlineLbl.Size = UDim2.new(0.5,-14,1,0)
onlineLbl.Position = UDim2.new(0.5,0,0,0)
onlineLbl.BackgroundTransparency = 1
onlineLbl.TextColor3 = C.Mute
onlineLbl.Font = Enum.Font.GothamMedium
onlineLbl.TextSize = 10
onlineLbl.TextXAlignment = Enum.TextXAlignment.Right
onlineLbl.ZIndex = 3
onlineLbl.Parent = pHdr

local pScroll = Instance.new("ScrollingFrame")
pScroll.Size = UDim2.new(1,-16,1,-44)
pScroll.Position = UDim2.new(0,8,0,38)
pScroll.BackgroundTransparency = 1
pScroll.ScrollBarThickness = 3
pScroll.ScrollBarImageColor3 = C.Glow
pScroll.ScrollBarImageTransparency = 0.3
pScroll.BorderSizePixel = 0
pScroll.CanvasSize = UDim2.new(0,0,0,0)
pScroll.ZIndex = 3
pScroll.Parent = pListSec

local pLay = Instance.new("UIListLayout")
pLay.Padding = UDim.new(0,6)
pLay.Parent = pScroll

local pPad = Instance.new("UIPadding")
pPad.PaddingTop = UDim.new(0,2)
pPad.PaddingBottom = UDim.new(0,2)
pPad.PaddingLeft = UDim.new(0,2)
pPad.PaddingRight = UDim.new(0,2)
pPad.Parent = pScroll

local pStatBar = Instance.new("Frame")
pStatBar.Size = UDim2.new(1,0,0,32)
pStatBar.Position = UDim2.new(0,0,0,258)
pStatBar.BackgroundColor3 = C.Card
pStatBar.BackgroundTransparency = 0.15
pStatBar.ZIndex = 2
pStatBar.Parent = pContent
cr(pStatBar, 10)
sk(pStatBar, C.Brd, 1, 0.4)

local pStatLbl = Instance.new("TextLabel")
pStatLbl.Size = UDim2.new(1,0,1,0)
pStatLbl.BackgroundTransparency = 1
pStatLbl.TextColor3 = C.Dim
pStatLbl.Font = Enum.Font.GothamMedium
pStatLbl.TextSize = 12
pStatLbl.ZIndex = 3
pStatLbl.Parent = pStatBar

local function updPStat()
    local c = 0; for _ in pairs(selP) do c = c+1 end
    local w = 0; for _ in pairs(wlP) do w = w+1 end
    if c == 0 and w == 0 then
        pStatLbl.Text = "✨ No targets selected"; pStatLbl.TextColor3 = C.Dim
    elseif c == 0 then
        pStatLbl.Text = "🛡️ "..w.." whitelisted"; pStatLbl.TextColor3 = C.WLA
    else
        local extra = w > 0 and (" | 🛡️ "..w.." safe") or ""
        pStatLbl.Text = "✅ "..c.." target"..(c>1 and "s" or "")..extra; pStatLbl.TextColor3 = C.Chk
    end
end

local function updOnline()
    onlineLbl.Text = "👥 "..(#Players:GetPlayers()-1).." online"
end

-- Create player element
local function createPlrEl(player)
    if player == plr or plrEl[player] then return end

    local row = Instance.new("Frame")
    row.Name = player.Name
    row.Size = UDim2.new(1,-4,0,44)
    row.BackgroundColor3 = C.Sec
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.ZIndex = 4
    row.Parent = pScroll
    cr(row, 10)

    local cb = Instance.new("Frame")
    cb.Name = "CB"
    cb.Size = UDim2.new(0,22,0,22)
    cb.Position = UDim2.new(0,10,0.5,-11)
    cb.BackgroundColor3 = C.Ter
    cb.BorderSizePixel = 0
    cb.ZIndex = 5
    cb.Parent = row
    cr(cb, 7)
    sk(cb, C.Brd, 1.5, 0.2)

    local cm = Instance.new("TextLabel")
    cm.Text = ""
    cm.Size = UDim2.new(1,0,1,0)
    cm.BackgroundTransparency = 1
    cm.TextColor3 = C.Txt
    cm.Font = Enum.Font.GothamBold
    cm.TextSize = 14
    cm.ZIndex = 6
    cm.Parent = cb

    local wlBtn = Instance.new("TextButton")
    wlBtn.Name = "WL"
    wlBtn.Text = "🛡️"
    wlBtn.Size = UDim2.new(0,26,0,26)
    wlBtn.Position = UDim2.new(1,-38,0.5,-13)
    wlBtn.BackgroundColor3 = C.Ter
    wlBtn.BackgroundTransparency = 0.3
    wlBtn.TextSize = 14
    wlBtn.Font = Enum.Font.SourceSans
    wlBtn.TextColor3 = C.Mute
    wlBtn.ZIndex = 8
    wlBtn.Parent = row
    cr(wlBtn, 8)

    -- ⚡ SHIELD BREAK BUTTON
    local shIcon = Instance.new("TextButton")
    shIcon.Name = "ShieldIcon"
    shIcon.Text = "⚡"
    shIcon.Size = UDim2.new(0,26,0,26)
    shIcon.Position = UDim2.new(1,-68,0.5,-13)
    shIcon.BackgroundColor3 = C.Shd
    shIcon.BackgroundTransparency = 0.4
    shIcon.TextColor3 = C.Shd
    shIcon.Font = Enum.Font.SourceSans
    shIcon.TextSize = 16
    shIcon.ZIndex = 8
    shIcon.Visible = false
    shIcon.AutoButtonColor = false
    shIcon.Parent = row
    cr(shIcon, 8)

    shIcon.MouseEnter:Connect(function()
        TS:Create(shIcon, TweenInfo.new(0.15), {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(220, 190, 50),
        }):Play()
    end)
    shIcon.MouseLeave:Connect(function()
        TS:Create(shIcon, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.4,
            BackgroundColor3 = C.Shd,
        }):Play()
    end)

    shIcon.MouseButton1Click:Connect(function()
        TS:Create(shIcon, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        task.delay(0.3, function()
            if shIcon and shIcon.Parent then
                TS:Create(shIcon, TweenInfo.new(0.2), {BackgroundColor3 = C.Shd}):Play()
            end
        end)
        breakShield(player)
    end)

    local avH = Instance.new("Frame")
    avH.Size = UDim2.new(0,30,0,30)
    avH.Position = UDim2.new(0,38,0.5,-15)
    avH.BackgroundColor3 = C.Ter
    avH.ZIndex = 5
    avH.Parent = row
    cr(avH, 15)
    sk(avH, C.Brd, 1, 0.4)

    local av = Instance.new("ImageLabel")
    av.Size = UDim2.new(1,-2,1,-2)
    av.Position = UDim2.new(0,1,0,1)
    av.BackgroundTransparency = 1
    av.ZIndex = 6
    av.Parent = avH
    cr(av, 14)

    task.spawn(function()
        local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if ok and av and av.Parent then av.Image = img end
    end)

    local nc = Instance.new("Frame")
    nc.Size = UDim2.new(1,-120,1,0)
    nc.Position = UDim2.new(0,76,0,0)
    nc.BackgroundTransparency = 1
    nc.ZIndex = 5
    nc.Parent = row

    local nl = Instance.new("TextLabel")
    nl.Text = player.DisplayName
    nl.Size = UDim2.new(1,0,0.55,0)
    nl.Position = UDim2.new(0,0,0,4)
    nl.BackgroundTransparency = 1
    nl.TextColor3 = C.Txt
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd
    nl.ZIndex = 6
    nl.Parent = nc

    local ul = Instance.new("TextLabel")
    ul.Text = "@" .. player.Name
    ul.Size = UDim2.new(1,0,0.45,0)
    ul.Position = UDim2.new(0,0,0.5,2)
    ul.BackgroundTransparency = 1
    ul.TextColor3 = C.Mute
    ul.Font = Enum.Font.Gotham
    ul.TextSize = 10
    ul.TextXAlignment = Enum.TextXAlignment.Left
    ul.TextTruncate = Enum.TextTruncate.AtEnd
    ul.ZIndex = 6
    ul.Parent = nc

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,-40,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 7
    clickBtn.Parent = row

    local rd = {button = row, baseColor = C.Sec, isHovered = false}
    table.insert(syncBtns, rd)

    local function vis()
        local isWL = wlP[player]
        local isSel = selP[player]

        if isWL then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.WL, BackgroundTransparency=0.15}):Play()
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3=C.WLA, BackgroundTransparency=0}):Play()
            wlBtn.TextColor3 = C.Txt; rd.baseColor = C.WL
            if isSel then selP[player] = nil end
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3=C.Ter}):Play()
            cb:FindFirstChildOfClass("UIStroke").Color = C.Brd
            cb:FindFirstChildOfClass("UIStroke").Transparency = 0.2
            cm.Text = ""; nl.TextColor3 = C.WLA
        elseif isSel then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.Sel, BackgroundTransparency=0.1}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3=C.Chk}):Play()
            cb:FindFirstChildOfClass("UIStroke").Color = C.Chk
            cb:FindFirstChildOfClass("UIStroke").Transparency = 0
            cm.Text = "✓"; rd.baseColor = C.Sel
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3=C.Ter, BackgroundTransparency=0.3}):Play()
            wlBtn.TextColor3 = C.Mute; nl.TextColor3 = C.Txt
        else
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.Sec, BackgroundTransparency=0.2}):Play()
            TS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3=C.Ter}):Play()
            cb:FindFirstChildOfClass("UIStroke").Color = C.Brd
            cb:FindFirstChildOfClass("UIStroke").Transparency = 0.2
            cm.Text = ""; rd.baseColor = C.Sec
            TS:Create(wlBtn, TweenInfo.new(0.15), {BackgroundColor3=C.Ter, BackgroundTransparency=0.3}):Play()
            wlBtn.TextColor3 = C.Mute; nl.TextColor3 = C.Txt
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

    clickBtn.MouseEnter:Connect(function() rd.isHovered = true end)
    clickBtn.MouseLeave:Connect(function() rd.isHovered = false; vis() end)

    plrEl[player] = row

    if isShielded(player) then shIcon.Visible = true end

    task.defer(function()
        pScroll.CanvasSize = UDim2.new(0,0,0, pLay.AbsoluteContentSize.Y+10)
    end)
end

local function removePlrEl(player)
    selP[player] = nil
    wlP[player] = nil
    if plrEl[player] then
        for i, d in ipairs(syncBtns) do
            if d.button == plrEl[player] then table.remove(syncBtns, i); break end
        end
        plrEl[player]:Destroy()
        plrEl[player] = nil
    end
    updPStat(); updOnline()
    task.defer(function()
        pScroll.CanvasSize = UDim2.new(0,0,0, pLay.AbsoluteContentSize.Y+10)
    end)
end

-- Player action buttons
local pBtns = Instance.new("Frame")
pBtns.Size = UDim2.new(1,0,0,38)
pBtns.Position = UDim2.new(0,0,0,298)
pBtns.BackgroundTransparency = 1
pBtns.ZIndex = 2
pBtns.Parent = pContent

local pSelAll = Instance.new("TextButton")
pSelAll.Text = "Select All"
pSelAll.Size = UDim2.new(0.315,0,1,0)
pSelAll.BackgroundColor3 = C.Ter
pSelAll.BackgroundTransparency = 0.1
pSelAll.TextColor3 = C.Txt
pSelAll.Font = Enum.Font.GothamBold
pSelAll.TextSize = 11
pSelAll.ZIndex = 2
pSelAll.Parent = pBtns
cr(pSelAll, 10); sk(pSelAll, C.Brd, 1, 0.4); hfx(pSelAll, C.Ter)

pSelAll.MouseButton1Click:Connect(function()
    for p, el in pairs(plrEl) do
        if not wlP[p] then
            selP[p] = true
            local cb2 = el:FindFirstChild("CB")
            if cb2 then
                TS:Create(el, TweenInfo.new(0.12), {BackgroundColor3=C.Sel, BackgroundTransparency=0.1}):Play()
                TS:Create(cb2, TweenInfo.new(0.12), {BackgroundColor3=C.Chk}):Play()
                local s = cb2:FindFirstChildOfClass("UIStroke")
                if s then s.Color = C.Chk; s.Transparency = 0 end
                local t = cb2:FindFirstChildOfClass("TextLabel")
                if t then t.Text = "✓" end
            end
            for _, d in ipairs(syncBtns) do
                if d.button == el then d.baseColor = C.Sel; break end
            end
        end
    end
    updPStat()
end)

local pClear = Instance.new("TextButton")
pClear.Text = "Clear All"
pClear.Size = UDim2.new(0.315,0,1,0)
pClear.Position = UDim2.new(0.34,0,0,0)
pClear.BackgroundColor3 = C.Ter
pClear.BackgroundTransparency = 0.1
pClear.TextColor3 = C.Txt
pClear.Font = Enum.Font.GothamBold
pClear.TextSize = 11
pClear.ZIndex = 2
pClear.Parent = pBtns
cr(pClear, 10); sk(pClear, C.Brd, 1, 0.4); hfx(pClear, C.Ter)

pClear.MouseButton1Click:Connect(function()
    for p, el in pairs(plrEl) do
        selP[p] = nil
        local cb2 = el:FindFirstChild("CB")
        if cb2 then
            TS:Create(el, TweenInfo.new(0.12), {BackgroundColor3=C.Sec, BackgroundTransparency=0.2}):Play()
            TS:Create(cb2, TweenInfo.new(0.12), {BackgroundColor3=C.Ter}):Play()
            local s = cb2:FindFirstChildOfClass("UIStroke")
            if s then s.Color = C.Brd; s.Transparency = 0.2 end
            local t = cb2:FindFirstChildOfClass("TextLabel")
            if t then t.Text = "" end
        end
        for _, d in ipairs(syncBtns) do
            if d.button == el and not wlP[p] then d.baseColor = C.Sec; break end
        end
    end
    updPStat()
end)

local pClearWL = Instance.new("TextButton")
pClearWL.Text = "🛡️ Clear WL"
pClearWL.Size = UDim2.new(0.315,0,1,0)
pClearWL.Position = UDim2.new(0.685,0,0,0)
pClearWL.BackgroundColor3 = C.WL
pClearWL.BackgroundTransparency = 0.2
pClearWL.TextColor3 = C.Txt
pClearWL.Font = Enum.Font.GothamBold
pClearWL.TextSize = 11
pClearWL.ZIndex = 2
pClearWL.Parent = pBtns
cr(pClearWL, 10); sk(pClearWL, C.Brd, 1, 0.4); hfx(pClearWL, C.WL)

pClearWL.MouseButton1Click:Connect(function()
    for p, el in pairs(plrEl) do
        wlP[p] = nil
        local wl = el:FindFirstChild("WL")
        if wl then
            TS:Create(wl, TweenInfo.new(0.12), {BackgroundColor3=C.Ter, BackgroundTransparency=0.3}):Play()
            wl.TextColor3 = C.Mute
        end
        if not selP[p] then
            TS:Create(el, TweenInfo.new(0.12), {BackgroundColor3=C.Sec, BackgroundTransparency=0.2}):Play()
            for _, d in ipairs(syncBtns) do
                if d.button == el then d.baseColor = C.Sec; break end
            end
        end
    end
    updPStat()
end)

-- Player START/STOP
local pToggle = Instance.new("TextButton")
pToggle.Text = "⚡️ START PLAYERS"
pToggle.Size = UDim2.new(1,0,0,52)
pToggle.Position = UDim2.new(0,0,0,344)
pToggle.BackgroundColor3 = C.Bad
pToggle.BackgroundTransparency = 0.05
pToggle.TextColor3 = C.Txt
pToggle.Font = Enum.Font.GothamBlack
pToggle.TextSize = 15
pToggle.ZIndex = 2
pToggle.Parent = pContent
cr(pToggle, 14)

local pTStroke = sk(pToggle, C.Bad, 2, 0.2)

local pTGlow = Instance.new("Frame")
pTGlow.Size = UDim2.new(1,4,1,4)
pTGlow.Position = UDim2.new(0,-2,0,-2)
pTGlow.BackgroundTransparency = 1
pTGlow.ZIndex = 1
pTGlow.Parent = pToggle

local pTGS = Instance.new("UIStroke")
pTGS.Color = C.Bad; pTGS.Thickness = 3; pTGS.Transparency = 0.6
pTGS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; pTGS.Parent = pTGlow
cr(pTGlow, 16)

local pInfo = Instance.new("TextLabel")
pInfo.Text = "🛡️ Shield detection active | ⚡ = click to break shield"
pInfo.Size = UDim2.new(1,0,0,22)
pInfo.Position = UDim2.new(0,0,0,402)
pInfo.BackgroundTransparency = 1
pInfo.TextColor3 = C.Mute
pInfo.Font = Enum.Font.Gotham
pInfo.TextSize = 10
pInfo.ZIndex = 2
pInfo.Parent = pContent

pToggle.MouseButton1Click:Connect(function()
    pSpamOn = not pSpamOn
    if pSpamOn then
        local n = 0; for _ in pairs(selP) do n = n+1 end
        if n == 0 then
            pStatLbl.Text = "❌ Select targets first!"; pStatLbl.TextColor3 = C.Bad
            pSpamOn = false; return
        end
        pToggle.Text = "⏹️ STOP PLAYERS"
        TS:Create(pToggle, TweenInfo.new(0.25), {BackgroundColor3=C.Ok}):Play()
        TS:Create(pTStroke, TweenInfo.new(0.25), {Color=C.Ok}):Play()
        TS:Create(pTGS, TweenInfo.new(0.25), {Color=C.Ok, Transparency=0.4}):Play()
        pStatLbl.Text = "🔥 Active — "..n.." target"..(n>1 and "s" or "")
        pStatLbl.TextColor3 = C.Ok

        pThreads["main"] = task.spawn(function()
            while pSpamOn do
                for p in pairs(selP) do
                    if p and p.Character and not wlP[p] and not isShielded(p) then
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
                        if p and p.Character and not wlP[p] and not isShielded(p) then
                            task.spawn(attackPlayer, p)
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    else
        pToggle.Text = "⚡️ START PLAYERS"
        TS:Create(pToggle, TweenInfo.new(0.25), {BackgroundColor3=C.Bad}):Play()
        TS:Create(pTStroke, TweenInfo.new(0.25), {Color=C.Bad}):Play()
        TS:Create(pTGS, TweenInfo.new(0.25), {Color=C.Bad, Transparency=0.6}):Play()
        pStatLbl.Text = "💤 Stopped"; pStatLbl.TextColor3 = C.Dim
        for _, th in pairs(pThreads) do pcall(task.cancel, th) end
        pThreads = {}
    end
end)

-- ============================================================
-- VEHICLES TAB
-- ============================================================

local vListSec = Instance.new("Frame")
vListSec.Size = UDim2.new(1,0,0,260)
vListSec.BackgroundColor3 = C.Card
vListSec.BackgroundTransparency = 0.15
vListSec.BorderSizePixel = 0
vListSec.ZIndex = 2
vListSec.Parent = vContent
cr(vListSec, 14); sk(vListSec, C.Brd, 1, 0.4)

local vHdr = Instance.new("Frame")
vHdr.Size = UDim2.new(1,0,0,36)
vHdr.BackgroundTransparency = 1
vHdr.ZIndex = 3
vHdr.Parent = vListSec

local vHdrLbl = Instance.new("TextLabel")
vHdrLbl.Text = "🚁 VEHICLES"
vHdrLbl.Size = UDim2.new(0.5,0,1,0)
vHdrLbl.Position = UDim2.new(0,14,0,0)
vHdrLbl.BackgroundTransparency = 1
vHdrLbl.TextColor3 = C.Dim
vHdrLbl.Font = Enum.Font.GothamBold
vHdrLbl.TextSize = 11
vHdrLbl.TextXAlignment = Enum.TextXAlignment.Left
vHdrLbl.ZIndex = 3
vHdrLbl.Parent = vHdr

local vCntLbl = Instance.new("TextLabel")
vCntLbl.Size = UDim2.new(0.5,-14,1,0)
vCntLbl.Position = UDim2.new(0.5,0,0,0)
vCntLbl.BackgroundTransparency = 1
vCntLbl.TextColor3 = C.Mute
vCntLbl.Font = Enum.Font.GothamMedium
vCntLbl.TextSize = 10
vCntLbl.TextXAlignment = Enum.TextXAlignment.Right
vCntLbl.ZIndex = 3
vCntLbl.Parent = vHdr

local vScroll = Instance.new("ScrollingFrame")
vScroll.Size = UDim2.new(1,-16,1,-44)
vScroll.Position = UDim2.new(0,8,0,38)
vScroll.BackgroundTransparency = 1
vScroll.ScrollBarThickness = 3
vScroll.ScrollBarImageColor3 = C.Glow
vScroll.ScrollBarImageTransparency = 0.3
vScroll.BorderSizePixel = 0
vScroll.CanvasSize = UDim2.new(0,0,0,0)
vScroll.ZIndex = 3
vScroll.Parent = vListSec

local vLay = Instance.new("UIListLayout"); vLay.Padding = UDim.new(0,6); vLay.Parent = vScroll
local vPad = Instance.new("UIPadding")
vPad.PaddingTop = UDim.new(0,2); vPad.PaddingBottom = UDim.new(0,2)
vPad.PaddingLeft = UDim.new(0,2); vPad.PaddingRight = UDim.new(0,2)
vPad.Parent = vScroll

local vStatBar = Instance.new("Frame")
vStatBar.Size = UDim2.new(1,0,0,32)
vStatBar.Position = UDim2.new(0,0,0,268)
vStatBar.BackgroundColor3 = C.Card
vStatBar.BackgroundTransparency = 0.15
vStatBar.ZIndex = 2
vStatBar.Parent = vContent
cr(vStatBar, 10); sk(vStatBar, C.Brd, 1, 0.4)

local vStatLbl = Instance.new("TextLabel")
vStatLbl.Size = UDim2.new(1,0,1,0)
vStatLbl.BackgroundTransparency = 1
vStatLbl.TextColor3 = C.Dim
vStatLbl.Font = Enum.Font.GothamMedium
vStatLbl.TextSize = 12
vStatLbl.ZIndex = 3
vStatLbl.Parent = vStatBar

local function updVStat()
    local n = 0; for _ in pairs(selV) do n = n+1 end
    if n == 0 then
        vStatLbl.Text = "No targets selected"; vStatLbl.TextColor3 = C.Dim
    else
        vStatLbl.Text = n.." target"..(n>1 and "s" or "").." selected"; vStatLbl.TextColor3 = C.Chk
    end
end

local ownHex = string.format("#%02X%02X%02X", math.floor(C.Own.R*255), math.floor(C.Own.G*255), math.floor(C.Own.B*255))
local basHex = string.format("#%02X%02X%02X", math.floor(C.Bas.R*255), math.floor(C.Bas.G*255), math.floor(C.Bas.B*255))
local nooHex = string.format("#%02X%02X%02X", math.floor(C.NoO.R*255), math.floor(C.NoO.G*255), math.floor(C.NoO.B*255))

local function makeVehRow(tgt)
    local mdl = tgt.Model

    local row = Instance.new("Frame")
    row.Name = tgt.Name
    row.Size = UDim2.new(1,-4,0,48)
    row.BackgroundColor3 = C.Sec
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.ZIndex = 4
    row.Parent = vScroll
    cr(row, 10)

    local cb2 = Instance.new("Frame")
    cb2.Name = "CB"
    cb2.Size = UDim2.new(0,22,0,22)
    cb2.Position = UDim2.new(0,10,0.5,-11)
    cb2.BackgroundColor3 = C.Ter
    cb2.BorderSizePixel = 0
    cb2.ZIndex = 5
    cb2.Parent = row
    cr(cb2, 7); sk(cb2, C.Brd, 1.5, 0.2)

    local cm2 = Instance.new("TextLabel")
    cm2.Text = ""
    cm2.Size = UDim2.new(1,0,1,0)
    cm2.BackgroundTransparency = 1
    cm2.TextColor3 = C.Txt
    cm2.Font = Enum.Font.GothamBold
    cm2.TextSize = 14
    cm2.ZIndex = 6
    cm2.Parent = cb2

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,38,0,30)
    badge.Position = UDim2.new(0,38,0.5,-15)
    badge.BackgroundColor3 = vCol[tgt.Type] or C.Ter
    badge.BackgroundTransparency = 0.3
    badge.ZIndex = 5
    badge.Parent = row
    cr(badge, 8)

    local bTxt = Instance.new("TextLabel")
    bTxt.Text = vShort[tgt.Type] or "??"
    bTxt.Size = UDim2.new(1,0,1,0)
    bTxt.BackgroundTransparency = 1
    bTxt.TextColor3 = C.Txt
    bTxt.TextSize = 8
    bTxt.Font = Enum.Font.GothamBlack
    bTxt.ZIndex = 6
    bTxt.Parent = badge

    local nc2 = Instance.new("Frame")
    nc2.Size = UDim2.new(1,-86,1,0)
    nc2.Position = UDim2.new(0,82,0,0)
    nc2.BackgroundTransparency = 1
    nc2.ZIndex = 5
    nc2.Parent = row

    local nl2 = Instance.new("TextLabel")
    nl2.Text = tgt.Name
    nl2.Size = UDim2.new(1,0,0,16)
    nl2.Position = UDim2.new(0,0,0,5)
    nl2.BackgroundTransparency = 1
    nl2.TextColor3 = C.Txt
    nl2.Font = Enum.Font.GothamBold
    nl2.TextSize = 13
    nl2.TextXAlignment = Enum.TextXAlignment.Left
    nl2.TextTruncate = Enum.TextTruncate.AtEnd
    nl2.ZIndex = 6
    nl2.Parent = nc2

    local ol = Instance.new("TextLabel")
    ol.Size = UDim2.new(1,0,0,14)
    ol.Position = UDim2.new(0,0,0,24)
    ol.BackgroundTransparency = 1
    ol.Font = Enum.Font.Gotham
    ol.TextSize = 10
    ol.TextXAlignment = Enum.TextXAlignment.Left
    ol.TextTruncate = Enum.TextTruncate.AtEnd
    ol.ZIndex = 6
    ol.RichText = true
    ol.Parent = nc2

    if tgt.DisplayName and tgt.DisplayName ~= "" then
        local t = '<font color="'..ownHex..'">'..tgt.DisplayName..'</font>'
        if tgt.Base and tgt.Base ~= "" then
            t = t .. '   <font color="'..basHex..'">'..tgt.Base..'</font>'
        end
        ol.Text = t
    else
        ol.Text = '<font color="'..nooHex..'">No owner</font>'
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = row

    local rd = {button = row, baseColor = C.Sec, isHovered = false}
    table.insert(syncBtns, rd)

    local function vis()
        local s = selV[mdl] ~= nil
        if s then
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.Sel, BackgroundTransparency=0.1}):Play()
            TS:Create(cb2, TweenInfo.new(0.15), {BackgroundColor3=C.Chk}):Play()
            cb2:FindFirstChildOfClass("UIStroke").Color = C.Chk
            cb2:FindFirstChildOfClass("UIStroke").Transparency = 0
            cm2.Text = "✓"; rd.baseColor = C.Sel
        else
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.Sec, BackgroundTransparency=0.2}):Play()
            TS:Create(cb2, TweenInfo.new(0.15), {BackgroundColor3=C.Ter}):Play()
            cb2:FindFirstChildOfClass("UIStroke").Color = C.Brd
            cb2:FindFirstChildOfClass("UIStroke").Transparency = 0.2
            cm2.Text = ""; rd.baseColor = C.Sec
        end
    end

    btn.MouseButton1Click:Connect(function()
        if selV[mdl] then selV[mdl] = nil
        else selV[mdl] = {Model=mdl, HRP=tgt.HRP, Type=tgt.Type, Name=tgt.Name} end
        vis(); updVStat()
    end)

    btn.MouseEnter:Connect(function() rd.isHovered = true end)
    btn.MouseLeave:Connect(function() rd.isHovered = false; vis() end)

    vehEl[mdl] = {row=row, rd=rd, vis=vis, tgt=tgt}
end

local function refreshVeh()
    for m, e in pairs(vehEl) do
        for i = #syncBtns, 1, -1 do
            if syncBtns[i].button == e.row then table.remove(syncBtns, i) end
        end
        e.row:Destroy()
    end
    vehEl = {}

    scanVehicles()

    local keep = {}
    for _, t in ipairs(vehInst) do
        if selV[t.Model] then
            keep[t.Model] = {Model=t.Model, HRP=t.HRP, Type=t.Type, Name=t.Name}
        end
    end
    selV = keep

    for _, t in ipairs(vehInst) do
        makeVehRow(t)
        if selV[t.Model] then vehEl[t.Model].vis() end
    end

    vCntLbl.Text = #vehInst .. " found"
    task.defer(function()
        vScroll.CanvasSize = UDim2.new(0,0,0, vLay.AbsoluteContentSize.Y+10)
    end)
    updVStat()
end

-- Vehicle buttons row 1
local vR1 = Instance.new("Frame")
vR1.Size = UDim2.new(1,0,0,34)
vR1.Position = UDim2.new(0,0,0,308)
vR1.BackgroundTransparency = 1
vR1.ZIndex = 2
vR1.Parent = vContent

local vSelAll = Instance.new("TextButton")
vSelAll.Text = "Select All"
vSelAll.Size = UDim2.new(0.48,0,1,0)
vSelAll.BackgroundColor3 = C.Ter
vSelAll.BackgroundTransparency = 0.1
vSelAll.TextColor3 = C.Txt
vSelAll.Font = Enum.Font.GothamBold
vSelAll.TextSize = 11
vSelAll.ZIndex = 2
vSelAll.Parent = vR1
cr(vSelAll, 10); sk(vSelAll, C.Brd, 1, 0.4); hfx(vSelAll, C.Ter)

vSelAll.MouseButton1Click:Connect(function()
    for m, e in pairs(vehEl) do
        selV[m] = {Model=m, HRP=e.tgt.HRP, Type=e.tgt.Type, Name=e.tgt.Name}
        e.vis()
    end
    updVStat()
end)

local vClearAll = Instance.new("TextButton")
vClearAll.Text = "Clear All"
vClearAll.Size = UDim2.new(0.48,0,1,0)
vClearAll.Position = UDim2.new(0.52,0,0,0)
vClearAll.BackgroundColor3 = C.Ter
vClearAll.BackgroundTransparency = 0.1
vClearAll.TextColor3 = C.Txt
vClearAll.Font = Enum.Font.GothamBold
vClearAll.TextSize = 11
vClearAll.ZIndex = 2
vClearAll.Parent = vR1
cr(vClearAll, 10); sk(vClearAll, C.Brd, 1, 0.4); hfx(vClearAll, C.Ter)

vClearAll.MouseButton1Click:Connect(function()
    selV = {}
    for _, e in pairs(vehEl) do e.vis() end
    updVStat()
end)

-- Vehicle buttons row 2
local vR2 = Instance.new("Frame")
vR2.Size = UDim2.new(1,0,0,34)
vR2.Position = UDim2.new(0,0,0,348)
vR2.BackgroundTransparency = 1
vR2.ZIndex = 2
vR2.Parent = vContent

local vAir = Instance.new("TextButton")
vAir.Text = "Air Only"
vAir.Size = UDim2.new(0.48,0,1,0)
vAir.BackgroundColor3 = C.Air
vAir.BackgroundTransparency = 0.15
vAir.TextColor3 = C.Txt
vAir.Font = Enum.Font.GothamBold
vAir.TextSize = 11
vAir.ZIndex = 2
vAir.Parent = vR2
cr(vAir, 10); sk(vAir, C.Brd, 1, 0.4); hfx(vAir, C.Air)

vAir.MouseButton1Click:Connect(function()
    selV = {}
    for m, e in pairs(vehEl) do
        local tp = e.tgt.Type
        if tp == "Helicopter" or tp == "Plane" or tp == "Gunship" then
            selV[m] = {Model=m, HRP=e.tgt.HRP, Type=tp, Name=e.tgt.Name}
        end
        e.vis()
    end
    updVStat()
end)

local vGnd = Instance.new("TextButton")
vGnd.Text = "Ground / Sea"
vGnd.Size = UDim2.new(0.48,0,1,0)
vGnd.Position = UDim2.new(0.52,0,0,0)
vGnd.BackgroundColor3 = C.Gnd
vGnd.BackgroundTransparency = 0.15
vGnd.TextColor3 = C.Txt
vGnd.Font = Enum.Font.GothamBold
vGnd.TextSize = 11
vGnd.ZIndex = 2
vGnd.Parent = vR2
cr(vGnd, 10); sk(vGnd, C.Brd, 1, 0.4); hfx(vGnd, C.Gnd)

vGnd.MouseButton1Click:Connect(function()
    selV = {}
    for m, e in pairs(vehEl) do
        local tp = e.tgt.Type
        if tp == "Boat" or tp == "Tank" or tp == "Hovercraft" then
            selV[m] = {Model=m, HRP=e.tgt.HRP, Type=tp, Name=e.tgt.Name}
        end
        e.vis()
    end
    updVStat()
end)

-- Vehicle START/STOP
local vToggle = Instance.new("TextButton")
vToggle.Text = "⚡️ START VEHICLES"
vToggle.Size = UDim2.new(1,0,0,52)
vToggle.Position = UDim2.new(0,0,0,390)
vToggle.BackgroundColor3 = C.Bad
vToggle.BackgroundTransparency = 0.05
vToggle.TextColor3 = C.Txt
vToggle.Font = Enum.Font.GothamBlack
vToggle.TextSize = 15
vToggle.ZIndex = 2
vToggle.Parent = vContent
cr(vToggle, 14)

local vTStroke = sk(vToggle, C.Bad, 2, 0.2)

local vTGlow = Instance.new("Frame")
vTGlow.Size = UDim2.new(1,4,1,4)
vTGlow.Position = UDim2.new(0,-2,0,-2)
vTGlow.BackgroundTransparency = 1
vTGlow.ZIndex = 1
vTGlow.Parent = vToggle

local vTGS = Instance.new("UIStroke")
vTGS.Color = C.Bad; vTGS.Thickness = 3; vTGS.Transparency = 0.6
vTGS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; vTGS.Parent = vTGlow
cr(vTGlow, 16)

local vInfo = Instance.new("TextLabel")
vInfo.Text = "Auto-refresh 3s | DisplayName + Base"
vInfo.Size = UDim2.new(1,0,0,22)
vInfo.Position = UDim2.new(0,0,0,450)
vInfo.BackgroundTransparency = 1
vInfo.TextColor3 = C.Mute
vInfo.Font = Enum.Font.Gotham
vInfo.TextSize = 10
vInfo.ZIndex = 2
vInfo.Parent = vContent

vToggle.MouseButton1Click:Connect(function()
    vSpamOn = not vSpamOn
    if vSpamOn then
        local n = 0; for _ in pairs(selV) do n = n+1 end
        if n == 0 then
            vStatLbl.Text = "Select targets first!"; vStatLbl.TextColor3 = C.Bad
            vSpamOn = false; return
        end
        if not tool then
            tool = findRPG()
            if not tool then
                vStatLbl.Text = "Need RPG!"; vStatLbl.TextColor3 = C.Bad
                vSpamOn = false; return
            end
        end
        vToggle.Text = "⏹️ STOP VEHICLES"
        TS:Create(vToggle, TweenInfo.new(0.25), {BackgroundColor3=C.Ok}):Play()
        TS:Create(vTStroke, TweenInfo.new(0.25), {Color=C.Ok}):Play()
        TS:Create(vTGS, TweenInfo.new(0.25), {Color=C.Ok, Transparency=0.4}):Play()
        vStatLbl.Text = "Active — "..n.." target"..(n>1 and "s" or "")
        vStatLbl.TextColor3 = C.Ok

        vThreads["main"] = task.spawn(function()
            while vSpamOn do
                for _, td in pairs(selV) do
                    if vSpamOn and td.Model and td.Model.Parent then
                        attackVehicle(td)
                        task.wait(0.05)
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
        vToggle.Text = "⚡️ START VEHICLES"
        TS:Create(vToggle, TweenInfo.new(0.25), {BackgroundColor3=C.Bad}):Play()
        TS:Create(vTStroke, TweenInfo.new(0.25), {Color=C.Bad}):Play()
        TS:Create(vTGS, TweenInfo.new(0.25), {Color=C.Bad, Transparency=0.6}):Play()
        vStatLbl.Text = "Stopped"; vStatLbl.TextColor3 = C.Dim
        for _, th in pairs(vThreads) do pcall(task.cancel, th) end
        vThreads = {}
    end
end)

-- ============================================================
-- CLOSE / MINIMIZE
-- ============================================================
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

local minimized = false
local origSize = main.Size

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TS:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size=UDim2.new(0,400,0,60)}):Play()
        minBtn.Text = "+"; pContent.Visible = false; vContent.Visible = false; tabBar.Visible = false
    else
        TS:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size=origSize}):Play()
        minBtn.Text = "−"; tabBar.Visible = true
        task.wait(0.15)
        pContent.Visible = true; vContent.Visible = false
        switchTab("players")
    end
end)

-- ============================================================
-- FLOATING TOGGLE BUTTON
-- ============================================================
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "Toggle"
floatBtn.Text = "RPG"
floatBtn.Size = UDim2.new(0,50,0,50)
floatBtn.Position = UDim2.new(0,16,0.5,-25)
floatBtn.BackgroundColor3 = C.Bg
floatBtn.TextColor3 = C.Txt
floatBtn.Font = Enum.Font.GothamBlack
floatBtn.TextSize = 12
floatBtn.ZIndex = 10
floatBtn.Active = true
floatBtn.Parent = gui
cr(floatBtn, 25)
sk(floatBtn, C.Glow, 2, 0.3)

local fSh = Instance.new("ImageLabel")
fSh.BackgroundTransparency = 1
fSh.Image = "rbxassetid://6014261993"
fSh.ImageColor3 = Color3.new(0,0,0)
fSh.ImageTransparency = 0.4
fSh.ScaleType = Enum.ScaleType.Slice
fSh.SliceCenter = Rect.new(49,49,450,450)
fSh.Size = UDim2.new(1,40,1,40)
fSh.Position = UDim2.new(0,-20,0,-20)
fSh.ZIndex = 9
fSh.Parent = floatBtn

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
    if main.Visible then
        local s = floatBtn:FindFirstChildOfClass("UIStroke")
        if s then
            TS:Create(s, TweenInfo.new(0.3), {Color=C.Ok, Transparency=0}):Play()
            task.delay(0.3, function()
                if s and s.Parent then
                    TS:Create(s, TweenInfo.new(0.3), {Color=C.Glow, Transparency=0.3}):Play()
                end
            end)
        end
    end
end)

-- ============================================================
-- RESPAWN HANDLER
-- ============================================================
plr.CharacterAdded:Connect(function(nc)
    char = nc
    hrp = nc:WaitForChild("HumanoidRootPart")
    tool = nc:WaitForChild("RPG", 5)
    if not tool then
        local bp = plr:FindFirstChild("Backpack")
        if bp then tool = bp:FindFirstChild("RPG") end
    end
end)

-- ============================================================
-- INIT
-- ============================================================

for _, p in pairs(Players:GetPlayers()) do
    createPlrEl(p)
end
updOnline()
updPStat()

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    createPlrEl(p)
    updOnline()
end)

Players.PlayerRemoving:Connect(function(p)
    removePlrEl(p)
end)

-- Shield update loop
task.spawn(function()
    while true do
        for p, el in pairs(plrEl) do
            if p and p.Parent and el and el.Parent then
                local si = el:FindFirstChild("ShieldIcon")
                if si then si.Visible = isShielded(p) end
            end
        end
        task.wait(1)
    end
end)

-- Vehicle refresh loop
refreshVeh()
task.spawn(function()
    while true do
        task.wait(3)
        refreshVeh()
    end
end)
