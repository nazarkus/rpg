if _G.HubConnections then for _,c in pairs(_G.HubConnections) do pcall(function() c:Disconnect() end) end end; _G.HubConnections = {}
if _G.HubThreads then for _,t in pairs(_G.HubThreads) do pcall(task.cancel, t) end end; _G.HubThreads = {}
for _,n in ipairs({"RPGSpammerGUI","RPGVehicleGUI","NazarkusRPG"}) do
    local old = game.CoreGui:FindFirstChild(n) if old then old:Destroy() end
end
local oldEsp = game.CoreGui:FindFirstChild("VehESP_Folder") if oldEsp then oldEsp:Destroy() end

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local Mouse = plr:GetMouse()

local function findRPG()
    if char then local t = char:FindFirstChild("RPG"); if t then return t end end
    local bp = plr:FindFirstChild("Backpack"); if bp then return bp:FindFirstChild("RPG") end
    return nil
end

local tool = findRPG()
local rvEv,fxEv,fireEv,hitEv,rocketModel
local rpgReady = false
pcall(function()
    rvEv = game.ReplicatedStorage.RocketSystem.Events
    fxEv = rvEv.RocketReloadedFX; fireEv = rvEv.FireRocketReplicated
    hitEv = rvEv.RocketHit; rocketModel = game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"]
    rpgReady = true
end)

local rCnt = 0
local rSettings = {
    expShake={fadeInTime=0.05,magnitude=3,rotInfluence=Vector3.new(0.4,0,0.4),fadeOutTime=0.5,posInfluence=Vector3.new(1,1,0),roughness=3},
    gravity=Vector3.new(0,-20,0),HelicopterDamage=450,FireRate=15,VehicleDamage=350,ExpName="RPG",RocketAmount=1,ExpRadius=12,
    BoatDamage=300,TankDamage=300,Acceleration=8,ShieldDamage=170,Distance=4000,PlaneDamage=500,GunshipDamage=170,velocity=200,ExplosionDamage=120
}

local C = {}
do
    C.Bg=Color3.fromRGB(10,10,16); C.Panel=Color3.fromRGB(16,16,26); C.Card=Color3.fromRGB(22,22,38); C.CardH=Color3.fromRGB(32,32,54)
    C.Input=Color3.fromRGB(12,12,20); C.Border=Color3.fromRGB(44,44,68); C.Accent=Color3.fromRGB(115,60,255); C.AccentL=Color3.fromRGB(145,100,255)
    C.AccentD=Color3.fromRGB(80,40,190); C.Success=Color3.fromRGB(16,185,129); C.Danger=Color3.fromRGB(239,68,68); C.Warn=Color3.fromRGB(245,158,11)
    C.Text=Color3.fromRGB(225,225,235); C.TextSub=Color3.fromRGB(140,140,170); C.TextMute=Color3.fromRGB(80,80,110); C.White=Color3.fromRGB(255,255,255)
    C.Sel=Color3.fromRGB(30,24,60); C.SelBrd=Color3.fromRGB(115,60,255); C.WL=Color3.fromRGB(45,75,135); C.WLA=Color3.fromRGB(90,140,240)
    C.Shield=Color3.fromRGB(245,158,11); C.NoTeam=Color3.fromRGB(75,75,95); C.Farm=Color3.fromRGB(245,158,11); C.FarmD=Color3.fromRGB(180,110,10)
    C.Draw=Color3.fromRGB(200,160,255)
end

local function getVFolders()
    local folders = {}
    pcall(function() 
        local gs = workspace:FindFirstChild("Game Systems")
        if gs then
            for _,n in ipairs({"Helicopter","Plane","Gunship","Boat","Tank","Hovercraft","Vehicle","Submarine","Drone","RC"}) do
                local f = gs:FindFirstChild(n.." Workspace")
                if f then folders[n] = f end
            end
        else
            -- Backup: maybe they are just in workspace?
            for _,n in ipairs({"Helicopter","Plane","Gunship","Boat","Tank","Hovercraft","Vehicle","Submarine","Drone","RC"}) do
                local f = workspace:FindFirstChild(n.." Workspace")
                if f then folders[n] = f end
            end
        end 
    end)
    return folders
end
local vFolders = getVFolders()

local vCol,vShort = {},{}
do
    vCol = {Helicopter=Color3.fromRGB(50,100,170),Plane=Color3.fromRGB(70,75,160),Gunship=Color3.fromRGB(160,50,50),
        Boat=Color3.fromRGB(40,120,110),Tank=Color3.fromRGB(150,110,40),Hovercraft=Color3.fromRGB(110,70,170),
        Vehicle=Color3.fromRGB(150,150,150),Submarine=Color3.fromRGB(100,150,200),Drone=Color3.fromRGB(255,150,50),RC=Color3.fromRGB(200,100,150)}
    vShort = {Helicopter="HELI",Plane="PLANE",Gunship="GNSHP",Boat="BOAT",Tank="TANK",Hovercraft="HOVER",
        Vehicle="VEH",Submarine="SUB",Drone="DRONE",RC="RC"}
end

local selectAllPlayersActive = false
local selectAllVehiclesActive = false

local selP,wlP,plrEl = {},{},{}
local selV,vehInst,vehEl = {},{},{}
local pSpamOn,pThreads = false,{}
local vSpamOn,vThreads = false,{}
local rpgClickOn = false
local ignoreShield = false
local autoBreakShield = false
local clickHolding = false
local clickSpamThread = nil
local clickPower = 3
local antiExplosion = false

local farmActive = false
local farmThread = nil
local farmTotalDestroyed = 0
local farmCycleCount = 0
local FARM_MAX_DIST = 500
local FARM_HITS = 1
local FARM_RESCAN = 2

local espFolder = Instance.new("Folder"); espFolder.Name = "VehESP_Folder"; espFolder.Parent = game.CoreGui
local vehicleESP = {}
local ESP_CONFIG = {}
do
    ESP_CONFIG.MaxDistance=5000; ESP_CONFIG.HighlightOutlineTransp=0.3; ESP_CONFIG.HighlightFillTransp=0.7
    ESP_CONFIG.OwnerColor=Color3.fromRGB(200,160,255)
    ESP_CONFIG.Colors={Helicopter=Color3.fromRGB(70,180,255),Plane=Color3.fromRGB(100,220,255),Gunship=Color3.fromRGB(255,80,80),
        Boat=Color3.fromRGB(80,200,170),Tank=Color3.fromRGB(220,180,60),Hovercraft=Color3.fromRGB(180,130,255),
        Vehicle=Color3.fromRGB(150,150,150),Submarine=Color3.fromRGB(100,150,200),Drone=Color3.fromRGB(255,150,50),RC=Color3.fromRGB(200,100,150)}
end

local BRUSH_SIZE = 3
local DRAW_SCALE = 4
local DRAW_SPACING = 5
local DRAW_BIND = Enum.KeyCode.F5
local ERASE_MULT = 3
local MAX_UNDO = 30
local drawPoints = {}
local drawMouseDown = false
local drawEraseMode = false
local drawLastPos = nil
local drawStrokePoints = {}
local drawUndoStack = {}
local dWaitBind = false
local allSliders = {}
local pulseThreads = {}

local GUI_TOGGLE_BIND = Enum.KeyCode.RightShift

local function cr(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 6);c.Parent=p;return c end
local function sk(p,col,th,tr) local s=Instance.new("UIStroke");s.Color=col or C.Border;s.Thickness=th or 1;s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p;return s end
local function pad(p,t,b,l,r) local pd=Instance.new("UIPadding");pd.Parent=p;pd.PaddingTop=UDim.new(0,t or 0);pd.PaddingBottom=UDim.new(0,b or 0);pd.PaddingLeft=UDim.new(0,l or 0);pd.PaddingRight=UDim.new(0,r or 0);return pd end
local function addRowGradient(p) local g=Instance.new("UIGradient");g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(0.15,Color3.fromRGB(240,240,245)),ColorSequenceKeypoint.new(1,Color3.fromRGB(190,190,205))});g.Rotation=90;g.Parent=p;return g end

-- Dragging Handler
local function makeDraggable(frame, dragTrigger)
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    local dragConn
    dragTrigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            
            if dragConn then dragConn:Disconnect() end
            dragConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if dragConn then dragConn:Disconnect(); dragConn = nil end
                end
            end)
        end
    end)
    
    dragTrigger.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Premium Button Hover Effect
local function makeButtonInteractive(btn, customHoverColor, customClickColor)
    local stroke = btn:FindFirstChildOfClass("UIStroke") or sk(btn, C.Border, 1, 0.5)
    local originalColor = btn.BackgroundColor3
    local hoverColor = customHoverColor or C.CardH
    local clickColor = customClickColor or C.Accent
    
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            BackgroundColor3 = hoverColor
        }):Play()
        TS:Create(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
            Color = C.Accent,
            Transparency = 0
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            BackgroundColor3 = originalColor
        }):Play()
        TS:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            Color = C.Border,
            Transparency = 0.5
        }):Play()
    end)
    
    btn.MouseButton1Down:Connect(function()
        TS:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
            BackgroundColor3 = clickColor
        }):Play()
    end)
    
    btn.MouseButton1Up:Connect(function()
        TS:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
end

-- Checkbox Animation Handler
local function animateCheckbox(cb, cm, active)
    local stroke = cb:FindFirstChildOfClass("UIStroke")
    if active then
        TS:Create(cb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = C.Accent,
            Size = UDim2.new(0, 15, 0, 15)
        }):Play()
        if stroke then
            TS:Create(stroke, TweenInfo.new(0.2), {Color = C.Accent}):Play()
        end
        cm.Text = "✔"
        TS:Create(cm, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextTransparency = 0,
            TextSize = 10
        }):Play()
    else
        TS:Create(cb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = C.Input,
            Size = UDim2.new(0, 14, 0, 14)
        }):Play()
        if stroke then
            TS:Create(stroke, TweenInfo.new(0.15), {Color = C.Border}):Play()
        end
        TS:Create(cm, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1,
            TextSize = 0
        }):Play()
        task.delay(0.1, function() if not active then cm.Text = "" end end)
    end
end

-- Toggle Switch Indicator States
local function setToggleButtonState(btn, active, activeColor)
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    local txtColor = active and C.White or C.TextMute
    local bgCol = active and (activeColor or C.AccentD) or C.Card
    local borderCol = active and (activeColor or C.Accent) or C.Border
    
    TS:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        BackgroundColor3 = bgCol,
        TextColor3 = txtColor
    }):Play()
    if stroke then
        TS:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Color = borderCol,
            Transparency = active and 0 or 0.35
        }):Play()
    end
end

local function startPulse(btn,id)
    if pulseThreads[id] then return end
    pulseThreads[id]=task.spawn(function()
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        while pulseThreads[id] do
            TS:Create(btn,TweenInfo.new(0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.3}):Play()
            if stroke then TS:Create(stroke,TweenInfo.new(0.6,Enum.EasingStyle.Sine),{Thickness=2}):Play() end
            task.wait(0.6)
            TS:Create(btn,TweenInfo.new(0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0}):Play()
            if stroke then TS:Create(stroke,TweenInfo.new(0.6,Enum.EasingStyle.Sine),{Thickness=1}):Play() end
            task.wait(0.6)
        end
    end)
end

local function stopPulse(btn,id)
    if pulseThreads[id] then pcall(task.cancel,pulseThreads[id]);pulseThreads[id]=nil end
    btn.BackgroundTransparency=0
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Thickness = 1 end
end

local gui=Instance.new("ScreenGui");gui.Name="NazarkusRPG";gui.Parent=game.CoreGui;gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local notifContainer=Instance.new("Frame");notifContainer.Size=UDim2.new(0,260,1,0);notifContainer.Position=UDim2.new(1,-270,0,0);notifContainer.BackgroundTransparency=1;notifContainer.ZIndex=20;notifContainer.Parent=gui
local notifLayout=Instance.new("UIListLayout");notifLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom;notifLayout.Padding=UDim.new(0,6);notifLayout.SortOrder=Enum.SortOrder.LayoutOrder;notifLayout.Parent=notifContainer
pad(notifContainer,0,10,0,0)

local notifOrder=0
local function notify(text,color,duration)
    notifOrder+=1;duration=duration or 3
    local nf=Instance.new("Frame");nf.Size=UDim2.new(1,0,0,0);nf.BackgroundColor3=C.Card;nf.BorderSizePixel=0;nf.ZIndex=21;nf.ClipsDescendants=true;nf.LayoutOrder=notifOrder;nf.Parent=notifContainer;cr(nf,8);sk(nf,color or C.Accent,1,0.3)
    local accent=Instance.new("Frame");accent.Size=UDim2.new(0,4,1,0);accent.BackgroundColor3=color or C.Accent;accent.BorderSizePixel=0;accent.ZIndex=22;accent.Parent=nf;cr(accent,2)
    local lbl=Instance.new("TextLabel");lbl.Text=text;lbl.Size=UDim2.new(1,-20,1,0);lbl.Position=UDim2.new(0,12,0,0);lbl.BackgroundTransparency=1;lbl.TextColor3=C.Text;lbl.Font=Enum.Font.GothamMedium;lbl.TextSize=11;lbl.TextWrapped=true;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=22;lbl.Parent=nf
    TS:Create(nf,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,38)}):Play()
    task.delay(duration,function()
        TS:Create(nf,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1}):Play()
        task.wait(0.35);if nf and nf.Parent then nf:Destroy() end
    end)
end

local hoverPreview=Instance.new("Frame");hoverPreview.Size=UDim2.new(0,80,0,80);hoverPreview.BackgroundColor3=C.Card;hoverPreview.BorderSizePixel=0;hoverPreview.ZIndex=30;hoverPreview.Visible=false;hoverPreview.Parent=gui;cr(hoverPreview,10);sk(hoverPreview,C.Accent,2,0.2)
local hoverImg=Instance.new("ImageLabel");hoverImg.Size=UDim2.new(1,-6,1,-6);hoverImg.Position=UDim2.new(0,3,0,3);hoverImg.BackgroundTransparency=1;hoverImg.ZIndex=31;hoverImg.Parent=hoverPreview;cr(hoverImg,8)
local hoverName=Instance.new("TextLabel");hoverName.Size=UDim2.new(0,80,0,14);hoverName.Position=UDim2.new(0,0,1,2);hoverName.BackgroundTransparency=1;hoverName.TextColor3=C.White;hoverName.Font=Enum.Font.GothamBold;hoverName.TextSize=9;hoverName.ZIndex=31;hoverName.Parent=hoverPreview

local function showHoverPreview(player,rowFrame)
    if not player or not rowFrame then return end
    task.spawn(function()
        local ok,img=pcall(Players.GetUserThumbnailAsync,Players,player.UserId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size150x150)
        if ok and hoverImg then hoverImg.Image=img end
    end)
    hoverName.Text=player.DisplayName
    local pos=rowFrame.AbsolutePosition
    local yOffset = pos.Y - 10
    if yOffset < 50 then yOffset = 50 end
    hoverPreview.Position=UDim2.new(0,pos.X-85,0,yOffset)
    hoverPreview.Visible=true
end
local function hideHoverPreview() hoverPreview.Visible=false end

local function toggleAntiExplosion(enable)
    if enable then
        local ok=pcall(function()
            local rs=game:GetService("ReplicatedStorage")
            local evts=rs.RocketSystem.Events
            local function safeDestroy(parent,name) local c=parent:FindFirstChild(name);if c then c:Destroy() end end
            safeDestroy(evts,"ExplosionShake");safeDestroy(evts,"FireFlare");safeDestroy(evts,"FireRocketFX");safeDestroy(evts,"JamRocket")
            local rpgR=rs.RocketSystem.Rockets:FindFirstChild("RPG Rocket")
            if rpgR then local mp=rpgR:FindFirstChild("MainPart");if mp then
                for _,n in ipairs({"BurnSFX","SmokeTrail","TrailEnd","TrailStart","VFXAttachment","WeldConstraint"}) do safeDestroy(mp,n) end
            end end
            local javR=rs.RocketSystem.Rockets:FindFirstChild("Javelin G-Rocket")
            if javR then local mp=javR:FindFirstChild("MainPart");if mp then
                for _,n in ipairs({"BurnSFX","SmokeTrail","TrailEnd","TrailStart","VFXAttachment","Motor6D"}) do safeDestroy(mp,n) end
            end end
            safeDestroy(rs.RocketSystem,"FireBox")
            local assets=rs:FindFirstChild("Assets");if assets then safeDestroy(assets,"Explosion")
                local oe=assets:FindFirstChild("ObstacleEffects");if oe then safeDestroy(oe,"VFX") end end
            local remotes=rs:FindFirstChild("Remotes");if remotes then safeDestroy(remotes,"ExplosionEffectLocal");safeDestroy(remotes,"ExplosionEffect") end
            safeDestroy(rs.RocketSystem,"FlareModel");safeDestroy(rs,"SendAFK")
            local sp=game:GetService("StarterPlayer");local sps=sp:FindFirstChild("StarterPlayerScripts");if sps then safeDestroy(sps,"BulletHitFX") end
            local res=rs:FindFirstChild("Resources");if res then safeDestroy(res,"CameraShaker") end
        end)
        return ok
    end
    return false
end

local function createSlider(parent,label,min,max,default,yPos,callback)
    local frame=Instance.new("Frame");frame.Size=UDim2.new(1,0,0,20);frame.Position=UDim2.new(0,0,0,yPos);frame.BackgroundColor3=Color3.fromRGB(15,15,25);frame.BorderSizePixel=0;frame.ZIndex=4;frame.Parent=parent;cr(frame,5)
    local stroke = sk(frame,C.Border,1,0.7)
    
    local lbl=Instance.new("TextLabel");lbl.Text=label..": <font color=\"#733CFF\"><b>"..default.."</b></font>";lbl.Size=UDim2.new(0,80,1,0);lbl.Position=UDim2.new(0,6,0,0);lbl.BackgroundTransparency=1;lbl.TextColor3=C.TextSub;lbl.Font=Enum.Font.GothamMedium;lbl.TextSize=9;lbl.RichText=true;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=5;lbl.Parent=frame
    
    local track=Instance.new("Frame");track.Size=UDim2.new(1,-94,0,4);track.Position=UDim2.new(0,86,0.5,-2);track.BackgroundColor3=Color3.fromRGB(30,30,46);track.BorderSizePixel=0;track.ZIndex=5;track.Parent=frame;cr(track,2)
    local pct=math.clamp((default-min)/(max-min),0,1)
    local fill=Instance.new("Frame");fill.Size=UDim2.new(pct,0,1,0);fill.BackgroundColor3=C.Accent;fill.BorderSizePixel=0;fill.ZIndex=5;fill.Parent=track;cr(fill,2)
    
    local knob=Instance.new("Frame");knob.Size=UDim2.new(0,10,0,10);knob.Position=UDim2.new(pct,-5,0.5,-5);knob.BackgroundColor3=C.White;knob.BorderSizePixel=0;knob.ZIndex=6;knob.Parent=track;cr(knob,5)
    local knobStroke = sk(knob, C.Accent, 1.5, 0)
    
    local s={sliding=false,track=track,fill=fill,knob=knob,lbl=lbl,label=label,min=min,max=max,callback=callback}
    
    frame.MouseEnter:Connect(function()
        TS:Create(stroke, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0.3}):Play()
        TS:Create(knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(knob.Position.X.Scale, -6, 0.5, -6)}):Play()
    end)
    frame.MouseLeave:Connect(function()
        TS:Create(stroke, TweenInfo.new(0.15), {Color = C.Border, Transparency = 0.7}):Play()
        TS:Create(knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(knob.Position.X.Scale, -5, 0.5, -5)}):Play()
    end)
    
    track.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then s.sliding=true end end)
    knob.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then s.sliding=true end end)
    table.insert(allSliders,s)
    return frame
end

RS.Heartbeat:Connect(function()
    for _,s in ipairs(allSliders) do
        if s.sliding then
            local mx=UIS:GetMouseLocation().X
            local rel=math.clamp((mx-s.track.AbsolutePosition.X)/s.track.AbsoluteSize.X,0,1)
            local val=math.floor(s.min+(s.max-s.min)*rel+0.5)
            val=math.clamp(val,s.min,s.max)
            s.fill.Size=UDim2.new(rel,0,1,0)
            local sz = s.knob.Size.X.Offset
            s.knob.Position=UDim2.new(rel,-sz/2,0.5,-sz/2)
            s.lbl.Text=s.label..": <font color=\"#733CFF\"><b>"..val.."</b></font>";s.callback(val)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        for _,s in ipairs(allSliders) do s.sliding=false end
    end
end)

local function getPlayerBase(player)
    if not player then return nil end;if player.Team then return player.Team.Name end
    local result=nil;pcall(function() local tr=workspace:FindFirstChild("Tycoon");if tr then local ty=tr:FindFirstChild("Tycoons");if ty then for _,t in ipairs(ty:GetChildren()) do for _,v in ipairs(t:GetDescendants()) do if v:IsA("ObjectValue") and v.Name=="Owner" and v.Value==player then result=t.Name end end;if result then break end end end end end)
    if result then return result end;for _,attr in ipairs({"Base","Team","Faction","Side"}) do local val;pcall(function() val=player:GetAttribute(attr) end);if val and type(val)=="string" and val~="" then return val end end;return nil
end

local function getBaseColor(bn) if not bn then return C.NoTeam end;local l=bn:lower();if l:find("alpha") or l:find("red") then return Color3.fromRGB(200,80,80) elseif l:find("bravo") or l:find("blue") then return Color3.fromRGB(80,120,200) elseif l:find("charlie") or l:find("green") then return Color3.fromRGB(80,180,120) elseif l:find("delta") or l:find("yellow") then return Color3.fromRGB(200,170,60) elseif l:find("echo") or l:find("purple") then return Color3.fromRGB(150,100,220) end;return Color3.fromRGB(100,130,160) end
local function playerHasRPG(p) if not p then return false end;local ch=p.Character;if ch then for _,c in pairs(ch:GetChildren()) do if c:IsA("Tool") and c.Name=="RPG" then return true end end end;local bp=p:FindFirstChild("Backpack");if bp then for _,c in pairs(bp:GetChildren()) do if c:IsA("Tool") and c.Name=="RPG" then return true end end end;return false end
local function getDistanceTo(p) if not p or not p.Character then return nil end;local t=p.Character:FindFirstChild("HumanoidRootPart");if not t or not hrp or not hrp.Parent then return nil end;return math.floor((hrp.Position-t.Position).Magnitude) end
local function getDistanceToVeh(part) if not part or not part.Parent or not hrp or not hrp.Parent then return nil end;return math.floor((hrp.Position-part.Position).Magnitude) end

local function getVehicleHealth(model)
    if not model or not model.Parent then return nil, nil end
    local health, maxHealth = nil, nil
    local hv = model:FindFirstChild("Health")
    local mhv = model:FindFirstChild("MaxHealth")
    if hv and hv:IsA("ValueBase") then health = hv.Value elseif type(hv)=="number" then health = hv end
    if mhv and mhv:IsA("ValueBase") then maxHealth = mhv.Value elseif type(mhv)=="number" then maxHealth = mhv end
    if not health then health = model:GetAttribute("Health") end
    if not maxHealth then maxHealth = model:GetAttribute("MaxHealth") end
    if not health or not maxHealth then 
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then health = hum.Health; maxHealth = hum.MaxHealth end
    end
    return health, maxHealth
end

local function isShielded(p)
    if not p or not p.Character then return false end
    local ch=p.Character
    if ch:FindFirstChildOfClass("ForceField") then return true end
    for _,a in ipairs({"Shielded","Shield","IsShielded","HasShield","Invincible","Invulnerable"}) do if ch:GetAttribute(a)==true then return true end end
    local hum=ch:FindFirstChildOfClass("Humanoid")
    if hum then for _,a in ipairs({"Shielded","Shield","IsShielded","Invincible"}) do if hum:GetAttribute(a)==true then return true end end end
    for _,child in pairs(ch:GetDescendants()) do
        if child:IsA("BoolValue") or child:IsA("StringValue") or child:IsA("IntValue") then
            local n=child.Name:lower()
            if n=="shield" or n=="shielded" or n=="isshielded" or n=="hasshield" or n=="invincible" or n=="invulnerable" or n=="barrier" then
                if child:IsA("BoolValue") and child.Value then return true end
                if child:IsA("IntValue") and child.Value>0 then return true end
                if child:IsA("StringValue") and child.Value~="" then return true end
            end
        end
    end
    local kw={"shield","barrier","bubble","forcefield","dome","protect"}
    for _,child in pairs(ch:GetChildren()) do local n=child.Name:lower();for _,k in pairs(kw) do if n:find(k) then if(child:IsA("BasePart") or child:IsA("MeshPart")) and child.Transparency<1 then return true elseif child:IsA("Model") then return true end end end end
    local rp=ch:FindFirstChild("HumanoidRootPart");if rp then for _,child in pairs(rp:GetChildren()) do local n=child.Name:lower();for _,k in pairs(kw) do if n:find(k) then return true end end end end
    return false
end

local shieldBreakCooldown={}
local function breakShield(player)
    if not player or not rpgReady then return end;if shieldBreakCooldown[player] and tick()-shieldBreakCooldown[player]<2 then return end;shieldBreakCooldown[player]=tick()
    task.spawn(function() local weapon=findRPG();if not weapon then return end;local tr=workspace:FindFirstChild("Tycoon");if not tr then return end;local ty=tr:FindFirstChild("Tycoons");if not ty then return end
        local tt=nil;for _,t in ipairs(ty:GetChildren()) do for _,v in ipairs(t:GetDescendants()) do if v:IsA("ObjectValue") and v.Name=="Owner" and v.Value==player then tt=t;break end end;if tt then break end end
        if not tt then return end;local pu=tt:FindFirstChild("PurchasedObjects");if not pu then return end;local bs=pu:FindFirstChild("Base Shield");if not bs then return end;local sf=bs:FindFirstChild("Shield");if not sf then return end
        for _=1,15 do if not sf or not sf.Parent then break end;local parts={};for _,part in ipairs(sf:GetChildren()) do if part:IsA("BasePart") and part.Parent then table.insert(parts,part) end end;if #parts==0 then break end
            local hc=0;for _,part in ipairs(parts) do if hc>=3 then break end;if part and part.Parent then pcall(function() hitEv:FireServer({Normal=Vector3.new(0,1,0),HitPart=part,Position=part.Position,Label=plr.Name.."SB"..rCnt,Vehicle=weapon,Player=plr,Weapon=weapon}) end);rCnt+=1;hc+=1 end end;task.wait(0.15) end end)
end

local function destroyAllShields()
    if not rpgReady then return 0 end
    local weapon=findRPG();if not weapon then return 0 end
    local tr=workspace:FindFirstChild("Tycoon");if not tr then return 0 end
    local ty=tr:FindFirstChild("Tycoons");if not ty then return 0 end
    local count=0
    for _,t in ipairs(ty:GetChildren()) do
        local pu=t:FindFirstChild("PurchasedObjects");if not pu then continue end
        local bs=pu:FindFirstChild("Base Shield");if not bs then continue end
        local sf=bs:FindFirstChild("Shield");if not sf then continue end
        local isMyBase=false
        for _,v in ipairs(t:GetDescendants()) do if v:IsA("ObjectValue") and v.Name=="Owner" and v.Value==plr then isMyBase=true;break end end
        if isMyBase then continue end
        count+=1
        task.spawn(function()
            for _=1,20 do if not sf or not sf.Parent then break end
                local parts={};for _,part in ipairs(sf:GetChildren()) do if part:IsA("BasePart") and part.Parent then table.insert(parts,part) end end
                if #parts==0 then break end
                for _,part in ipairs(parts) do if part and part.Parent then pcall(function() hitEv:FireServer({Normal=Vector3.new(0,1,0),HitPart=part,Position=part.Position,Label=plr.Name.."DS"..rCnt,Vehicle=weapon,Player=plr,Weapon=weapon}) end);rCnt+=1 end end
                task.wait(0.1)
            end
        end)
    end
    return count
end

local function getOwnerData(model) local data={username=nil,displayName=nil,base=nil};pcall(function() for _,attr in ipairs({"Owner","Pilot","KillOwner"}) do if not data.username then local v=model:GetAttribute(attr);if v and type(v)=="string" and v~="" then data.username=v end end end;if data.username then local p=Players:FindFirstChild(data.username);if p then data.displayName=p.DisplayName;data.base=getPlayerBase(p) else data.displayName=data.username end end end);return data end

local function scanVehicles()
    vehInst={}
    vFolders = getVFolders() -- ALWAYS UPDATE FOLDERS
    for typ,folder in pairs(vFolders) do
        if folder then pcall(function()
            for _,mdl in ipairs(folder:GetChildren()) do
                if mdl:IsA("Model") then
                    -- Проверка владельца: своя техника полностью игнорируется (не подсвечивается и не добавляется в список)
                    local od=getOwnerData(mdl)
                    if od and od.username == plr.Name then continue end

                    -- Проверка ХП: если у техники 0 или меньше ХП, то полностью её скипаем
                    local health, maxHealth = getVehicleHealth(mdl)
                    if health and health <= 0 then continue end
                    
                    local part=mdl:FindFirstChild("HumanoidRootPart") or mdl:FindFirstChild("Main") or mdl:FindFirstChild("RootPart") or mdl:FindFirstChild("Head") or mdl.PrimaryPart
                    if not part then for _,c in ipairs(mdl:GetChildren()) do if c:IsA("BasePart") then part=c;break end end end
                    if part then table.insert(vehInst,{Name=mdl.Name,Type=typ,Model=mdl,HRP=part,Username=od.username,DisplayName=od.displayName,Base=od.base}) end
                end
            end
        end) end
    end
    return #vehInst
end

local function fireRocket(targetPos,hitPart)
    if not rpgReady then return false end;if not tool or not tool.Parent then tool=findRPG();if not tool then return false end end
    if not hrp or not hrp.Parent then char=plr.Character;if not char then return false end;hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return false end end
    local dir=(targetPos-hrp.Position).Unit
    if fxEv then fxEv:FireServer(tool,false) end
    if fireEv then fireEv:FireServer({Direction=dir,Settings=rSettings,Origin=hrp.Position,PlrFired=plr,Vehicle=tool,RocketModel=rocketModel,Weapon=tool}) end
    if hitEv then hitEv:FireServer({Normal=Vector3.new(0,1,0),HitPart=hitPart,Position=targetPos,Label=plr.Name.."R"..rCnt,Vehicle=tool,Player=plr,Weapon=tool}) end
    rCnt+=1;return true
end

local function fireRocketMulti(targetPos,hitPart,count) for i=1,count do fireRocket(targetPos,hitPart) end end

local function attackPlayer(player)
    if not player or not player.Character or player==plr then return end;if wlP[player] then return end
    if not ignoreShield and isShielded(player) then if autoBreakShield then breakShield(player) end;return end
    local hum=player.Character:FindFirstChildOfClass("Humanoid");if hum and hum.Health<=0 then return end
    local w=player.Character:FindFirstChild("HumanoidRootPart");if not w then return end;fireRocketMulti(w.Position,w,clickPower)
end

local function attackVehicle(td)
    if not td or not td.Model or not td.Model.Parent then return false end
    local h=td.HRP;if not h or not h.Parent then return false end
    local health, maxHealth = getVehicleHealth(td.Model)
    if health and health<=0 then return false end
    local pos=h.Position;local off={Boat=3,Tank=1.5,Hovercraft=2,Plane=1};if off[td.Type] then pos=pos+Vector3.new(0,off[td.Type],0) end
    
    -- Orbital Strike!
    if not rpgReady or not hrp then return false end
    for i=1, 3 do
        local rOffset = Vector3.new(math.random(-15,15), 0, math.random(-15,15))
        local strikePos = pos + rOffset
        local origin = strikePos + Vector3.new(0, 500, 0)
        local dir = (strikePos - origin).Unit
        if fxEv then fxEv:FireServer(tool, false) end
        if fireEv then fireEv:FireServer({Direction=dir,Settings=rSettings,Origin=origin,PlrFired=plr,Vehicle=tool,RocketModel=rocketModel,Weapon=tool}) end
        if hitEv then hitEv:FireServer({Normal=Vector3.new(0,1,0),HitPart=h,Position=strikePos,Label=plr.Name.."R"..rCnt,Vehicle=tool,Player=plr,Weapon=tool}) end
        rCnt += 1
    end
    return true
end

local function isPartOfMyCharacter(target) if not char or not target then return false end;local current=target;while current and current~=workspace do if current==char then return true end;current=current.Parent end;return false end

local function fireAtMouse()
    if not rpgReady then return end;tool=findRPG();if not tool then return end;char=plr.Character;if not char then return end;hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
    local target=Mouse.Target;if not target then return end;if isPartOfMyCharacter(target) then return end
    local current=target;while current and current~=workspace do if current:FindFirstChildOfClass("Humanoid") then if current~=char then local tHrp=current:FindFirstChild("HumanoidRootPart");if tHrp then fireRocketMulti(tHrp.Position,tHrp,clickPower) end end;return end;current=current.Parent end
    fireRocketMulti(Mouse.Hit.Position,target,clickPower)
end

local function fireAtDraw(pos)
    if not rpgReady then return end;local t=findRPG();if not t then return end;if not hrp or not hrp.Parent then char=plr.Character;if not char then return end;hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end end
    local dir=(pos-hrp.Position).Unit
    pcall(function() fxEv:FireServer(t,false) end)
    pcall(function() fireEv:FireServer({Direction=dir,Settings=rSettings,Origin=hrp.Position,PlrFired=plr,Vehicle=t,RocketModel=rocketModel,Weapon=t}) end)
    pcall(function() hitEv:FireServer({Normal=Vector3.new(0,1,0),HitPart=workspace.Terrain,Position=pos,Label=plr.Name.."D"..rCnt,Vehicle=t,Player=plr,Weapon=t}) end)
    rCnt+=1
end

local function scanAlive()
    local results={};local ma;pcall(function() ma=workspace["Map Assets"] end);if not ma then return results end
    local function ds(parent) for _,child in ipairs(parent:GetChildren()) do if child:IsA("Model") then local hp=child:FindFirstChild("ObstacleHitPoint")
        if hp and hp:IsA("BasePart") and hp.Size~=Vector3.new(0,0,0) then if hrp and hrp.Parent then local dist=(hrp.Position-hp.Position).Magnitude;if dist<=FARM_MAX_DIST then table.insert(results,{Model=child,HitPoint=hp,Dist=dist}) end end end;ds(child)
    elseif child:IsA("Folder") or child:IsA("Configuration") then ds(child) end end end
    ds(ma);table.sort(results,function(a,b) return a.Dist<b.Dist end);return results
end

local function getHealthColor(pct) if pct>0.6 then return Color3.fromRGB(80,220,100) elseif pct>0.3 then return Color3.fromRGB(255,200,50) else return Color3.fromRGB(255,70,70) end end

local function createVehESP(mdl,part,vType)
    local color=ESP_CONFIG.Colors[vType] or Color3.new(1,1,1)
    local ex=mdl:FindFirstChild("VehESP_HL");if ex then ex:Destroy() end
    local hl=Instance.new("Highlight");hl.Name="VehESP_HL";hl.Adornee=mdl;hl.OutlineColor=color;hl.FillColor=color;hl.OutlineTransparency=ESP_CONFIG.HighlightOutlineTransp;hl.FillTransparency=ESP_CONFIG.HighlightFillTransp;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Parent=mdl
    local bb=Instance.new("BillboardGui");bb.Name="VehESP_BB";bb.Size=UDim2.new(0,200,0,90);bb.StudsOffset=Vector3.new(0,6,0);bb.AlwaysOnTop=true;bb.MaxDistance=ESP_CONFIG.MaxDistance;bb.ResetOnSpawn=false;bb.Adornee=part;bb.Parent=espFolder
    local cont=Instance.new("Frame");cont.Size=UDim2.new(1,0,1,0);cont.BackgroundTransparency=1;cont.Parent=bb
    local lay=Instance.new("UIListLayout");lay.HorizontalAlignment=Enum.HorizontalAlignment.Center;lay.VerticalAlignment=Enum.VerticalAlignment.Center;lay.SortOrder=Enum.SortOrder.LayoutOrder;lay.Padding=UDim.new(0,2);lay.Parent=cont
    local nameLbl=Instance.new("TextLabel");nameLbl.Text=mdl.Name;nameLbl.Size=UDim2.new(1,0,0,16);nameLbl.BackgroundTransparency=1;nameLbl.Font=Enum.Font.GothamBold;nameLbl.TextSize=14;nameLbl.TextColor3=color;nameLbl.TextStrokeTransparency=0;nameLbl.TextStrokeColor3=Color3.new(0,0,0);nameLbl.LayoutOrder=1;nameLbl.Parent=cont
    local hpBg=Instance.new("Frame");hpBg.Size=UDim2.new(0,80,0,6);hpBg.BackgroundColor3=Color3.fromRGB(30,30,30);hpBg.BorderSizePixel=0;hpBg.LayoutOrder=2;hpBg.Parent=cont;Instance.new("UICorner",hpBg).CornerRadius=UDim.new(0,3)
    local hpFill=Instance.new("Frame");hpFill.Size=UDim2.new(1,0,1,0);hpFill.BackgroundColor3=Color3.fromRGB(80,220,100);hpFill.BorderSizePixel=0;hpFill.Parent=hpBg;Instance.new("UICorner",hpFill).CornerRadius=UDim.new(0,3)
    local hpText=Instance.new("TextLabel");hpText.Text="";hpText.Size=UDim2.new(1,0,0,12);hpText.BackgroundTransparency=1;hpText.Font=Enum.Font.GothamMedium;hpText.TextSize=11;hpText.TextColor3=Color3.new(1,1,1);hpText.TextStrokeTransparency=0;hpText.TextStrokeColor3=Color3.new(0,0,0);hpText.LayoutOrder=3;hpText.Parent=cont
    local ownerLbl=Instance.new("TextLabel");ownerLbl.Text="";ownerLbl.Size=UDim2.new(1,0,0,12);ownerLbl.BackgroundTransparency=1;ownerLbl.Font=Enum.Font.Gotham;ownerLbl.TextSize=11;ownerLbl.TextColor3=ESP_CONFIG.OwnerColor;ownerLbl.TextStrokeTransparency=0;ownerLbl.TextStrokeColor3=Color3.new(0,0,0);ownerLbl.LayoutOrder=4;ownerLbl.Parent=cont
    local distLbl=Instance.new("TextLabel");distLbl.Text="";distLbl.Size=UDim2.new(1,0,0,12);distLbl.BackgroundTransparency=1;distLbl.Font=Enum.Font.Gotham;distLbl.TextSize=10;distLbl.TextColor3=Color3.fromRGB(180,180,180);distLbl.TextStrokeTransparency=0;distLbl.TextStrokeColor3=Color3.new(0,0,0);distLbl.LayoutOrder=5;distLbl.Parent=cont
    return {bb=bb,hl=hl,nameLbl=nameLbl,hpBg=hpBg,hpFill=hpFill,hpText=hpText,ownerLbl=ownerLbl,distLbl=distLbl,model=mdl,part=part,vType=vType}
end

local function destroyVehESP(esp) if not esp then return end;pcall(function() if esp.bb then esp.bb:Destroy() end end);pcall(function() if esp.hl and esp.hl.Parent then esp.hl:Destroy() end end) end

local function updateVehESP(esp)
    if not esp or not esp.bb or not esp.model or not esp.model.Parent or not esp.part or not esp.part.Parent then return false end
    
    -- Если у техники 0 хп во время обновления ESP, сообщаем, что она не валидна
    local health, maxHealth = getVehicleHealth(esp.model)
    if health and health <= 0 then return false end

    local dist=hrp and hrp.Parent and(hrp.Position-esp.part.Position).Magnitude or math.huge
    if dist>ESP_CONFIG.MaxDistance then esp.bb.Enabled=false;return true end;esp.bb.Enabled=true;esp.bb.Adornee=esp.part
    esp.distLbl.Text=string.format("[%dm]",math.floor(dist))
    do
        if health and maxHealth and maxHealth>0 then 
            local pct=math.clamp(health/maxHealth,0,1);
            esp.hpBg.Visible=true;
            esp.hpFill.Size=UDim2.new(math.max(pct,0.01),0,1,0);
            esp.hpFill.BackgroundColor3=getHealthColor(pct);
            -- Показываем здоровье в процентах вместо единиц
            esp.hpText.Text=string.format("%d%%",math.floor(pct*100));
            esp.hpText.TextColor3=getHealthColor(pct) 
        else 
            esp.hpBg.Visible=false;
            esp.hpText.Text="" 
        end
    end
    do local displayName,base
        pcall(function() local o=esp.model:GetAttribute("Owner") or esp.model:GetAttribute("Pilot") or esp.model:GetAttribute("KillOwner");if o and type(o)=="string" and o~="" then local p=Players:FindFirstChild(o);if p then displayName=p.DisplayName;if p.Team then base=p.Team.Name end else displayName=o end end end)
        if displayName then local str=displayName;if base then str=str.." ["..base.."]" end;esp.ownerLbl.Text=str else esp.ownerLbl.Text="" end
    end
    return true
end

local main=Instance.new("Frame");main.Size=UDim2.new(0,0,0,0);main.Position=UDim2.new(0.5,0,0.5,0);main.AnchorPoint=Vector2.new(0.5,0.5);main.BackgroundColor3=C.Bg;main.BackgroundTransparency=1;main.BorderSizePixel=0;main.ClipsDescendants=true;main.Active=true;main.Parent=gui;cr(main,10);sk(main,C.Border,1,0.3)

TS:Create(main,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,520,0,480),BackgroundTransparency=0}):Play()

local sidebar, navBtns, currentTab, contentArea
local pContent, vContent, fContent, dContent
local rpgDot, myBaseLbl, sideInfo

-- Toggle Main Frame Smoothly
local function toggleGUI()
    if main.Visible then
        TS:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        main.Visible = false
    else
        main.Visible = true
        main.Size = UDim2.new(0, 0, 0, 0)
        main.BackgroundTransparency = 1
        TS:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 520, 0, 480),
            BackgroundTransparency = 0
        }):Play()
    end
end

do
    sidebar=Instance.new("Frame");sidebar.Size=UDim2.new(0,130,1,0);sidebar.BackgroundColor3=C.Panel;sidebar.BorderSizePixel=0;sidebar.ZIndex=3;sidebar.Parent=main;cr(sidebar,10)
    local sideClipF=Instance.new("Frame");sideClipF.Size=UDim2.new(0,20,1,0);sideClipF.Position=UDim2.new(1,-10,0,0);sideClipF.BackgroundColor3=C.Panel;sideClipF.BorderSizePixel=0;sideClipF.ZIndex=3;sideClipF.Parent=sidebar
    local sideBorder=Instance.new("Frame");sideBorder.Size=UDim2.new(0,1,1,-20);sideBorder.Position=UDim2.new(1,0,0,10);sideBorder.BackgroundColor3=C.Border;sideBorder.BackgroundTransparency=0.3;sideBorder.BorderSizePixel=0;sideBorder.ZIndex=4;sideBorder.Parent=sidebar

    local titleLbl=Instance.new("TextLabel");titleLbl.Text="NAZARKUS";titleLbl.Size=UDim2.new(1,0,0,30);titleLbl.Position=UDim2.new(0,0,0,18);titleLbl.BackgroundTransparency=1;titleLbl.TextColor3=C.White;titleLbl.Font=Enum.Font.GothamBlack;titleLbl.TextSize=16;titleLbl.ZIndex=5;titleLbl.Parent=sidebar
    rpgDot=Instance.new("Frame");rpgDot.Size=UDim2.new(0,8,0,8);rpgDot.Position=UDim2.new(0.5,-22,0,50);rpgDot.BackgroundColor3=rpgReady and C.Success or C.Danger;rpgDot.BorderSizePixel=0;rpgDot.ZIndex=5;rpgDot.Parent=sidebar;cr(rpgDot,4)
    local subtitleLbl=Instance.new("TextLabel");subtitleLbl.Text="RPG";subtitleLbl.Size=UDim2.new(1,0,0,16);subtitleLbl.Position=UDim2.new(0,0,0,45);subtitleLbl.BackgroundTransparency=1;subtitleLbl.TextColor3=C.Accent;subtitleLbl.Font=Enum.Font.GothamBold;subtitleLbl.TextSize=11;subtitleLbl.ZIndex=5;subtitleLbl.Parent=sidebar

    navBtns={};currentTab="players"
    local function createNavBtn(text,id,yPos)
        local btn=Instance.new("TextButton");btn.Text=text;btn.Size=UDim2.new(1,-20,0,28);btn.Position=UDim2.new(0,10,0,yPos);btn.BackgroundColor3=id=="players" and C.Card or C.Panel;btn.BackgroundTransparency=id=="players" and 0 or 1;btn.TextColor3=id=="players" and C.White or C.TextSub;btn.Font=Enum.Font.GothamBold;btn.TextSize=11;btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.ZIndex=5;btn.Parent=sidebar;cr(btn,6)
        local ind=Instance.new("Frame");ind.Size=id=="players" and UDim2.new(0,3,0,16) or UDim2.new(0,3,0,0);ind.Position=UDim2.new(0,0,0.5,-8);ind.BackgroundColor3=C.Accent;ind.BorderSizePixel=0;ind.ZIndex=6;ind.BackgroundTransparency=id=="players" and 0 or 1;ind.Parent=btn;cr(ind,2)
        navBtns[id]={btn=btn,indicator=ind}
        btn.MouseEnter:Connect(function() if currentTab~=id then TS:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0,BackgroundColor3=C.CardH}):Play();btn.TextColor3=C.Text end end)
        btn.MouseLeave:Connect(function() if currentTab~=id then TS:Create(btn,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play();btn.TextColor3=C.TextSub end end)
        return btn
    end

    local navPlayers=createNavBtn("PLAYERS","players",72)
    local navVehicles=createNavBtn("VEHICLES","vehicles",104)
    local navFarm=createNavBtn("FARM","farm",136)
    local navDraw=createNavBtn("DRAW","draw",168)

    local avatarFrame=Instance.new("Frame");avatarFrame.Size=UDim2.new(0,70,0,70);avatarFrame.Position=UDim2.new(0.5,-35,1,-160);avatarFrame.BackgroundColor3=C.Input;avatarFrame.BorderSizePixel=0;avatarFrame.ZIndex=5;avatarFrame.Parent=sidebar;cr(avatarFrame,35)
    sk(avatarFrame,C.Accent,2,0.3)
    local avatarImg=Instance.new("ImageLabel");avatarImg.Size=UDim2.new(1,-4,1,-4);avatarImg.Position=UDim2.new(0,2,0,2);avatarImg.BackgroundTransparency=1;avatarImg.ZIndex=6;avatarImg.Parent=avatarFrame;cr(avatarImg,33)
    task.spawn(function() local ok,img=pcall(Players.GetUserThumbnailAsync,Players,plr.UserId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size150x150);if ok and avatarImg and avatarImg.Parent then avatarImg.Image=img end end)
    local myNameLbl=Instance.new("TextLabel");myNameLbl.Size=UDim2.new(1,-10,0,14);myNameLbl.Position=UDim2.new(0,5,1,-84);myNameLbl.BackgroundTransparency=1;myNameLbl.Text=plr.DisplayName;myNameLbl.TextColor3=C.White;myNameLbl.Font=Enum.Font.GothamBold;myNameLbl.TextSize=10;myNameLbl.TextTruncate=Enum.TextTruncate.AtEnd;myNameLbl.ZIndex=5;myNameLbl.Parent=sidebar

    sideInfo=Instance.new("TextLabel");sideInfo.Size=UDim2.new(1,-20,0,30);sideInfo.Position=UDim2.new(0,10,1,-70);sideInfo.BackgroundTransparency=1;sideInfo.TextColor3=C.TextMute;sideInfo.Font=Enum.Font.Gotham;sideInfo.TextSize=9;sideInfo.TextWrapped=true;sideInfo.TextYAlignment=Enum.TextYAlignment.Bottom;sideInfo.ZIndex=5;sideInfo.Parent=sidebar
    myBaseLbl=Instance.new("TextLabel");myBaseLbl.Size=UDim2.new(1,-20,0,14);myBaseLbl.Position=UDim2.new(0,10,1,-36);myBaseLbl.BackgroundTransparency=1;myBaseLbl.Font=Enum.Font.GothamBold;myBaseLbl.TextSize=9;myBaseLbl.TextWrapped=true;myBaseLbl.ZIndex=5;myBaseLbl.Parent=sidebar

    contentArea=Instance.new("Frame");contentArea.Size=UDim2.new(1,-130,1,0);contentArea.Position=UDim2.new(0,130,0,0);contentArea.BackgroundTransparency=1;contentArea.ZIndex=2;contentArea.Parent=main
    local closeBtn=Instance.new("TextButton");closeBtn.Text="x";closeBtn.Size=UDim2.new(0,24,0,24);closeBtn.Position=UDim2.new(1,-34,0,10);closeBtn.BackgroundColor3=C.Danger;closeBtn.BackgroundTransparency=0.2;closeBtn.TextColor3=C.White;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=14;closeBtn.AutoButtonColor=false;closeBtn.BorderSizePixel=0;closeBtn.ZIndex=8;closeBtn.Parent=contentArea;cr(closeBtn,12)
    makeButtonInteractive(closeBtn, Color3.fromRGB(240, 70, 70))
    closeBtn.MouseButton1Click:Connect(toggleGUI)

    pContent=Instance.new("Frame");pContent.Size=UDim2.new(1,-24,1,-16);pContent.Position=UDim2.new(0,12,0,8);pContent.BackgroundTransparency=1;pContent.ZIndex=3;pContent.Visible=true;pContent.Parent=contentArea
    vContent=Instance.new("Frame");vContent.Size=UDim2.new(1,-24,1,-16);vContent.Position=UDim2.new(0,12,0,8);vContent.BackgroundTransparency=1;vContent.ZIndex=3;vContent.Visible=false;vContent.Parent=contentArea
    fContent=Instance.new("Frame");fContent.Size=UDim2.new(1,-24,1,-16);fContent.Position=UDim2.new(0,12,0,8);fContent.BackgroundTransparency=1;fContent.ZIndex=3;fContent.Visible=false;fContent.Parent=contentArea
    dContent=Instance.new("Frame");dContent.Size=UDim2.new(1,-24,1,-16);dContent.Position=UDim2.new(0,12,0,8);dContent.BackgroundTransparency=1;dContent.ZIndex=3;dContent.Visible=false;dContent.Parent=contentArea

    local function switchTab(tab) currentTab=tab
        for id,data in pairs(navBtns) do if id==tab then TS:Create(data.btn,TweenInfo.new(0.2),{BackgroundColor3=C.Card,BackgroundTransparency=0}):Play();data.btn.TextColor3=C.White;TS:Create(data.indicator,TweenInfo.new(0.2),{Size=UDim2.new(0,3,0,16),BackgroundTransparency=0}):Play()
        else TS:Create(data.btn,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play();data.btn.TextColor3=C.TextSub;TS:Create(data.indicator,TweenInfo.new(0.2),{Size=UDim2.new(0,3,0,0),BackgroundTransparency=1}):Play() end end
        pContent.Visible=tab=="players";vContent.Visible=tab=="vehicles";fContent.Visible=tab=="farm";dContent.Visible=tab=="draw"
    end
    navPlayers.MouseButton1Click:Connect(function() switchTab("players") end)
    navVehicles.MouseButton1Click:Connect(function() switchTab("vehicles") end)
    navFarm.MouseButton1Click:Connect(function() switchTab("farm") end)
    navDraw.MouseButton1Click:Connect(function() switchTab("draw") end)

    local titleDrag=Instance.new("Frame");titleDrag.Size=UDim2.new(1,-40,0,50);titleDrag.BackgroundTransparency=1;titleDrag.ZIndex=7;titleDrag.Parent=contentArea
    makeDraggable(main, titleDrag)
    makeDraggable(main, sidebar)
end

local function updateMyBase() local base=getPlayerBase(plr);if base then myBaseLbl.Text=base;myBaseLbl.TextColor3=getBaseColor(base) else myBaseLbl.Text="No base";myBaseLbl.TextColor3=C.TextMute end end

local pScroll, pLay, pStatLbl, onlineLbl, pToggle, pGrad
local updPStat, updOnline, createPlrEl, removePlrEl

do
    local pt=Instance.new("TextLabel");pt.Text="PLAYERS";pt.Size=UDim2.new(0.5,0,0,24);pt.Position=UDim2.new(0,4,0,6);pt.BackgroundTransparency=1;pt.TextColor3=C.Text;pt.Font=Enum.Font.GothamBlack;pt.TextSize=15;pt.TextXAlignment=Enum.TextXAlignment.Left;pt.ZIndex=5;pt.Parent=pContent
    onlineLbl=Instance.new("TextLabel");onlineLbl.Size=UDim2.new(0.5,-48,0,24);onlineLbl.Position=UDim2.new(0.5,0,0,6);onlineLbl.BackgroundTransparency=1;onlineLbl.TextColor3=C.TextMute;onlineLbl.Font=Enum.Font.Gotham;onlineLbl.TextSize=10;onlineLbl.TextXAlignment=Enum.TextXAlignment.Right;onlineLbl.ZIndex=5;onlineLbl.Parent=pContent

    local searchFrame=Instance.new("Frame");searchFrame.Size=UDim2.new(1,0,0,24);searchFrame.Position=UDim2.new(0,0,0,30);searchFrame.BackgroundColor3=C.Card;searchFrame.BorderSizePixel=0;searchFrame.ZIndex=4;searchFrame.Parent=pContent;cr(searchFrame,6)
    local searchStroke = sk(searchFrame, C.Border, 1, 0.4)
    local searchIcon=Instance.new("TextLabel");searchIcon.Text="🔍";searchIcon.Size=UDim2.new(0,20,1,0);searchIcon.Position=UDim2.new(0,4,0,0);searchIcon.BackgroundTransparency=1;searchIcon.TextColor3=C.TextMute;searchIcon.Font=Enum.Font.Gotham;searchIcon.TextSize=11;searchIcon.ZIndex=5;searchIcon.Parent=searchFrame
    local searchBox=Instance.new("TextBox");searchBox.PlaceholderText="Search...";searchBox.Text="";searchBox.Size=UDim2.new(1,-28,1,0);searchBox.Position=UDim2.new(0,24,0,0);searchBox.BackgroundTransparency=1;searchBox.TextColor3=C.Text;searchBox.PlaceholderColor3=C.TextMute;searchBox.Font=Enum.Font.Gotham;searchBox.TextSize=10;searchBox.TextXAlignment=Enum.TextXAlignment.Left;searchBox.ClearTextOnFocus=false;searchBox.ZIndex=5;searchBox.Parent=searchFrame
    
    searchBox.Focused:Connect(function()
        TS:Create(searchStroke, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0}):Play()
    end)
    searchBox.FocusLost:Connect(function()
        TS:Create(searchStroke, TweenInfo.new(0.2), {Color = C.Border, Transparency = 0.4}):Play()
    end)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() local q=searchBox.Text:lower();for player,el in pairs(plrEl) do el.Visible=q=="" or player.Name:lower():find(q) or player.DisplayName:lower():find(q) end end)

    local optFrame=Instance.new("Frame");optFrame.Size=UDim2.new(1,0,0,22);optFrame.Position=UDim2.new(0,0,0,56);optFrame.BackgroundTransparency=1;optFrame.ZIndex=4;optFrame.Parent=pContent
    local function makeToggleBtn(text,xPos,xSize,parent)
        local btn=Instance.new("TextButton");btn.Text=text;btn.Size=UDim2.new(xSize,-2,1,0);btn.Position=UDim2.new(xPos,1,0,0);btn.BackgroundColor3=C.Card;btn.TextColor3=C.TextMute;btn.Font=Enum.Font.GothamBold;btn.TextSize=7;btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.ZIndex=5;btn.Parent=parent;cr(btn,4);sk(btn,C.Border,1,0.35)
        return btn
    end

    local rpgClickBtn=makeToggleBtn("RPG CLICK",0,0.2,optFrame)
    local ignoreShieldBtn=makeToggleBtn("IGN SHIELD",0.2,0.2,optFrame)
    local autoBreakBtn=makeToggleBtn("AUTO BREAK",0.4,0.2,optFrame)
    local destroyShieldsBtn=makeToggleBtn("DESTROY ALL",0.6,0.2,optFrame)
    local antiExpBtn=makeToggleBtn("ANTI BOOM",0.8,0.2,optFrame)
    destroyShieldsBtn.BackgroundColor3=Color3.fromRGB(45,30,15);destroyShieldsBtn.TextColor3=C.Shield
    antiExpBtn.BackgroundColor3=Color3.fromRGB(15,35,20);antiExpBtn.TextColor3=C.Success

    rpgClickBtn.MouseButton1Click:Connect(function() rpgClickOn=not rpgClickOn;setToggleButtonState(rpgClickBtn, rpgClickOn);notify(rpgClickOn and "RPG Click ON" or "RPG Click OFF",rpgClickOn and C.Success or C.TextMute,2) end)
    ignoreShieldBtn.MouseButton1Click:Connect(function() ignoreShield=not ignoreShield;setToggleButtonState(ignoreShieldBtn, ignoreShield) end)
    autoBreakBtn.MouseButton1Click:Connect(function() autoBreakShield=not autoBreakShield;setToggleButtonState(autoBreakBtn, autoBreakShield) end)
    destroyShieldsBtn.MouseButton1Click:Connect(function()
        if not rpgReady then notify("No RPG system!",C.Danger,2);return end
        destroyShieldsBtn.TextColor3=C.White;destroyShieldsBtn.BackgroundColor3=C.Shield
        local cnt=destroyAllShields()
        if cnt>0 then notify("Destroying "..cnt.." shields...",C.Shield,3) else notify("No shields found",C.TextMute,2) end
        task.delay(1,function() destroyShieldsBtn.TextColor3=C.Shield;destroyShieldsBtn.BackgroundColor3=Color3.fromRGB(45,30,15) end)
    end)
    antiExpBtn.MouseButton1Click:Connect(function()
        if antiExplosion then notify("Already active",C.TextMute,2);return end
        local ok=toggleAntiExplosion(true)
        if ok then antiExplosion=true;setToggleButtonState(antiExpBtn, true, C.Success);notify("Anti-Explosion enabled!",C.Success,3)
        else notify("Failed to enable",C.Danger,2) end
    end)

    createSlider(pContent,"Power",1,5,clickPower,80,function(v) clickPower=v end)

    UIS.InputBegan:Connect(function(input,gp) if gp then return end;if not rpgClickOn then return end;if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        fireAtMouse();clickHolding=true
        if clickSpamThread then pcall(task.cancel,clickSpamThread);clickSpamThread=nil end
        clickSpamThread=task.spawn(function() task.wait(0.15);while clickHolding and rpgClickOn do fireAtMouse();task.wait() end end)
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then clickHolding=false;if clickSpamThread then pcall(task.cancel,clickSpamThread);clickSpamThread=nil end end end)

    pScroll=Instance.new("ScrollingFrame");pScroll.Name="PlayerScroll";pScroll.Size=UDim2.new(1,0,0,155);pScroll.Position=UDim2.new(0,0,0,100);pScroll.BackgroundColor3=C.Bg;pScroll.BackgroundTransparency=0.3;pScroll.ScrollBarThickness=4;pScroll.ScrollBarImageColor3=C.Accent;pScroll.ScrollBarImageTransparency=0.2;pScroll.BorderSizePixel=0;pScroll.CanvasSize=UDim2.new(0,0,0,0);pScroll.ZIndex=4;pScroll.Parent=pContent;cr(pScroll,8);sk(pScroll,C.Border,1,0.5)
    pLay=Instance.new("UIListLayout");pLay.Padding=UDim.new(0,3);pLay.Parent=pScroll;pad(pScroll,4,4,4,4)

    pStatLbl=Instance.new("TextLabel");pStatLbl.Size=UDim2.new(1,0,0,18);pStatLbl.Position=UDim2.new(0,0,0,259);pStatLbl.BackgroundColor3=C.Card;pStatLbl.BackgroundTransparency=0.3;pStatLbl.TextColor3=C.TextMute;pStatLbl.Font=Enum.Font.Gotham;pStatLbl.TextSize=10;pStatLbl.ZIndex=4;pStatLbl.Parent=pContent;cr(pStatLbl,6);sk(pStatLbl,C.Border,1,0.5)

    updPStat = function() local c,w=0,0;for _ in pairs(selP) do c+=1 end;for _ in pairs(wlP) do w+=1 end;if c==0 and w==0 then pStatLbl.Text="No targets";pStatLbl.TextColor3=C.TextMute elseif c==0 then pStatLbl.Text=w.." whitelisted";pStatLbl.TextColor3=C.WLA else pStatLbl.Text=c.." target"..(c>1 and "s" or "")..(w>0 and(" | "..w.." safe") or "");pStatLbl.TextColor3=C.Success end end
    updOnline = function() local count=#Players:GetPlayers()-1;onlineLbl.Text=count.." online";sideInfo.Text="RPG Hub\n"..count.." players" end

    createPlrEl = function(player)
        if player==plr or plrEl[player] then return end
        
        -- Если включен автоматический выбор всех, добавляем игрока в цели (если он не в вайтлисте)
        if selectAllPlayersActive and not wlP[player] then
            selP[player] = true
        end

        local row=Instance.new("Frame");row.Name=player.Name;row.Size=UDim2.new(1,-4,0,40);row.BackgroundColor3=C.Card;row.BorderSizePixel=0;row.ZIndex=5;row.Parent=pScroll;cr(row,7);local rowStroke=sk(row,C.Border,1,0.35);addRowGradient(row)
        
        local cb=Instance.new("Frame");cb.Size=UDim2.new(0,14,0,14);cb.Position=UDim2.new(0,6,0.5,-7);cb.BackgroundColor3=C.Input;cb.BorderSizePixel=0;cb.ZIndex=6;cb.Parent=row;cr(cb,4);local cbStroke=sk(cb,C.Border,1,0)
        local cm=Instance.new("TextLabel");cm.Text="";cm.Size=UDim2.new(1,0,1,0);cm.BackgroundTransparency=1;cm.TextColor3=C.White;cm.Font=Enum.Font.GothamBold;cm.TextSize=10;cm.ZIndex=7;cm.Parent=cb
        
        local avFrame=Instance.new("Frame");avFrame.Size=UDim2.new(0,26,0,26);avFrame.Position=UDim2.new(0,26,0.5,-13);avFrame.BackgroundColor3=C.Input;avFrame.ZIndex=6;avFrame.Parent=row;cr(avFrame,13)
        local av=Instance.new("ImageLabel");av.Size=UDim2.new(1,-2,1,-2);av.Position=UDim2.new(0,1,0,1);av.BackgroundTransparency=1;av.ZIndex=7;av.Parent=avFrame;cr(av,12)
        task.spawn(function() local ok,img=pcall(Players.GetUserThumbnailAsync,Players,player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48);if ok and av and av.Parent then av.Image=img end end)
        
        local nl=Instance.new("TextLabel");nl.Text=player.DisplayName;nl.Size=UDim2.new(0,80,0,13);nl.Position=UDim2.new(0,58,0,4);nl.BackgroundTransparency=1;nl.TextColor3=C.Text;nl.Font=Enum.Font.GothamBold;nl.TextSize=10;nl.TextXAlignment=Enum.TextXAlignment.Left;nl.TextTruncate=Enum.TextTruncate.AtEnd;nl.ZIndex=7;nl.Parent=row
        local infoLbl=Instance.new("TextLabel");infoLbl.Name="InfoLbl";infoLbl.Size=UDim2.new(0,140,0,10);infoLbl.Position=UDim2.new(0,58,0,19);infoLbl.BackgroundTransparency=1;infoLbl.Font=Enum.Font.Gotham;infoLbl.TextSize=8;infoLbl.TextXAlignment=Enum.TextXAlignment.Left;infoLbl.ZIndex=7;infoLbl.RichText=true;infoLbl.Parent=row
        
        local function updateInfo() if not player or not player.Parent then return end;local p={};table.insert(p,'<font color="#50506A">@'..player.Name..'</font>');local base=getPlayerBase(player);if base then local bc=getBaseColor(base);table.insert(p,'<font color="'..string.format("#%02X%02X%02X",math.floor(bc.R*255),math.floor(bc.G*255),math.floor(bc.B*255))..'">'..base..'</font>') end;local dist=getDistanceTo(player);if dist then table.insert(p,'<font color="#50506A">'..dist..'m</font>') end;if playerHasRPG(player) then table.insert(p,'<font color="#6237D2">RPG</font>') end;infoLbl.Text=table.concat(p,'  ') end;updateInfo()
        
        local shBtn=Instance.new("TextButton");shBtn.Name="ShieldIcon";shBtn.Text="⚡";shBtn.Size=UDim2.new(0,18,0,18);shBtn.Position=UDim2.new(1,-42,0.5,-9);shBtn.BackgroundColor3=C.Shield;shBtn.BackgroundTransparency=0.7;shBtn.TextColor3=C.Shield;shBtn.Font=Enum.Font.GothamBold;shBtn.TextSize=11;shBtn.AutoButtonColor=false;shBtn.BorderSizePixel=0;shBtn.ZIndex=8;shBtn.Visible=false;shBtn.Parent=row;cr(shBtn,5);shBtn.MouseButton1Click:Connect(function() breakShield(player);notify("Breaking "..player.DisplayName.."'s shield",C.Shield,2) end)
        local wlBtn=Instance.new("TextButton");wlBtn.Name="WL";wlBtn.Text="🛡️";wlBtn.Size=UDim2.new(0,18,0,18);wlBtn.Position=UDim2.new(1,-20,0.5,-9);wlBtn.BackgroundColor3=C.Input;wlBtn.TextColor3=C.TextMute;wlBtn.Font=Enum.Font.GothamBold;wlBtn.TextSize=11;wlBtn.AutoButtonColor=false;wlBtn.BorderSizePixel=0;wlBtn.ZIndex=8;wlBtn.Parent=row;cr(wlBtn,5)
        local clickBtn=Instance.new("TextButton");clickBtn.Size=UDim2.new(1,-46,1,0);clickBtn.BackgroundTransparency=1;clickBtn.Text="";clickBtn.ZIndex=8;clickBtn.Parent=row
        
        row.MouseEnter:Connect(function()
            showHoverPreview(player,row)
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.CardH}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            hideHoverPreview()
            local actCol = wlP[player] and Color3.fromRGB(20,28,50) or (selP[player] and C.Sel or C.Card)
            local strCol = wlP[player] and C.WL or (selP[player] and C.SelBrd or C.Border)
            TS:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = actCol}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.2), {Color = strCol, Transparency = 0.4}):Play()
        end)
        
        local function vis() if wlP[player] then row.BackgroundColor3=Color3.fromRGB(20,28,50);rowStroke.Color=C.WL;wlBtn.BackgroundColor3=C.WL;wlBtn.TextColor3=C.White;animateCheckbox(cb, cm, false);nl.TextColor3=C.WLA
        elseif selP[player] then row.BackgroundColor3=C.Sel;rowStroke.Color=C.SelBrd;wlBtn.BackgroundColor3=C.Input;wlBtn.TextColor3=C.TextMute;animateCheckbox(cb, cm, true);nl.TextColor3=C.Text
        else row.BackgroundColor3=C.Card;rowStroke.Color=C.Border;wlBtn.BackgroundColor3=C.Input;wlBtn.TextColor3=C.TextMute;animateCheckbox(cb, cm, false);nl.TextColor3=C.Text end end
        
        -- Вызываем vis() изначально, чтобы применилось выделение, если игрок добавился под автоматическим Select All
        vis()
        
        clickBtn.MouseButton1Click:Connect(function() if wlP[player] then return end;selP[player]=not selP[player] or nil;vis();updPStat() end)
        wlBtn.MouseButton1Click:Connect(function() wlP[player]=not wlP[player] or nil;vis();updPStat() end)
        plrEl[player]=row;local bv=Instance.new("BindableEvent");bv.Name="_updateFunc";bv.Parent=row;bv.Event:Connect(updateInfo);if isShielded(player) then shBtn.Visible=true end
        task.defer(function() pScroll.CanvasSize=UDim2.new(0,0,0,pLay.AbsoluteContentSize.Y+8) end)
    end
    removePlrEl = function(player) selP[player]=nil;wlP[player]=nil;if plrEl[player] then plrEl[player]:Destroy();plrEl[player]=nil end;updPStat();updOnline() end

    local pBtnFrame=Instance.new("Frame");pBtnFrame.Size=UDim2.new(1,0,0,22);pBtnFrame.Position=UDim2.new(0,0,0,280);pBtnFrame.BackgroundTransparency=1;pBtnFrame.ZIndex=4;pBtnFrame.Parent=pContent
    local function makeSmallBtn(text,xPos,xSize,parent) local btn=Instance.new("TextButton");btn.Text=text;btn.Size=UDim2.new(xSize,-3,1,0);btn.Position=UDim2.new(xPos,1,0,0);btn.BackgroundColor3=C.Card;btn.TextColor3=C.Text;btn.Font=Enum.Font.GothamBold;btn.TextSize=9;btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.ZIndex=5;btn.Parent=parent;cr(btn,5);sk(btn,C.Border,1,0.5);return btn end
    local pSelAll=makeSmallBtn("Select All",0,0.33,pBtnFrame);local pClear=makeSmallBtn("Clear All",0.33,0.34,pBtnFrame);local pClearWL=makeSmallBtn("Clear WL",0.67,0.33,pBtnFrame)
    makeButtonInteractive(pSelAll); makeButtonInteractive(pClear); makeButtonInteractive(pClearWL)
    
    pSelAll.MouseButton1Click:Connect(function()
        selectAllPlayersActive = not selectAllPlayersActive
        if selectAllPlayersActive then
            pSelAll.BackgroundColor3 = C.AccentD
            pSelAll.TextColor3 = C.White
            -- Выделяем всех текущих игроков
            for p in pairs(plrEl) do 
                if not wlP[p] then 
                    selP[p]=true 
                end 
            end
            for p in pairs(plrEl) do 
                if selP[p] then 
                    local el=plrEl[p]
                    el.BackgroundColor3=C.Sel
                    local rStr=el:FindFirstChildOfClass("UIStroke")
                    if rStr then rStr.Color=C.SelBrd end
                    local cb=el:FindFirstChildOfClass("Frame")
                    if cb then 
                        local cm=cb:FindFirstChildOfClass("TextLabel")
                        if cm then animateCheckbox(cb,cm,true) end 
                    end 
                end 
            end
            notify("Auto-Select Players ENABLED", C.Success, 2)
        else
            pSelAll.BackgroundColor3 = C.Card
            pSelAll.TextColor3 = C.Text
            notify("Auto-Select Players DISABLED", C.TextMute, 2)
        end
        updPStat()
    end)
    
    pClear.MouseButton1Click:Connect(function()
        -- Выключаем автовыбор, если нажали очистку
        if selectAllPlayersActive then
            selectAllPlayersActive = false
            pSelAll.BackgroundColor3 = C.Card
            pSelAll.TextColor3 = C.Text
        end
        for p in pairs(selP) do selP[p]=nil end
        for p,el in pairs(plrEl) do if not wlP[p] then el.BackgroundColor3=C.Card;local rStr=el:FindFirstChildOfClass("UIStroke");if rStr then rStr.Color=C.Border end;local cb=el:FindFirstChildOfClass("Frame");if cb then local cm=cb:FindFirstChildOfClass("TextLabel");if cm then animateCheckbox(cb,cm,false) end end end end;updPStat()
    end)
    pClearWL.MouseButton1Click:Connect(function() for p in pairs(wlP) do wlP[p]=nil end;for _,el in pairs(plrEl) do local wl=el:FindFirstChild("WL");if wl then wl.BackgroundColor3=C.Input;wl.TextColor3=C.TextMute end;local rStr=el:FindFirstChildOfClass("UIStroke");if rStr then rStr.Color=C.Border end end;updPStat() end)

    pToggle=Instance.new("TextButton");pToggle.Text="START PLAYERS";pToggle.Size=UDim2.new(1,0,0,34);pToggle.Position=UDim2.new(0,0,0,306);pToggle.BackgroundColor3=C.AccentD;pToggle.TextColor3=C.White;pToggle.Font=Enum.Font.GothamBlack;pToggle.TextSize=12;pToggle.AutoButtonColor=false;pToggle.BorderSizePixel=0;pToggle.ZIndex=5;pToggle.Parent=pContent;cr(pToggle,8);sk(pToggle,C.Accent,1,0.2)
    pGrad=Instance.new("UIGradient");pGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,35,170)),ColorSequenceKeypoint.new(1,Color3.fromRGB(160,25,55))});pGrad.Rotation=90;pGrad.Parent=pToggle

    pToggle.MouseButton1Click:Connect(function() pSpamOn=not pSpamOn
        if pSpamOn then local n=0;for _ in pairs(selP) do n+=1 end;if n==0 then pStatLbl.Text="Select targets!";pStatLbl.TextColor3=C.Danger;pSpamOn=false;return end;if not rpgReady then pStatLbl.Text="No RPG!";pStatLbl.TextColor3=C.Danger;pSpamOn=false;return end
            pToggle.Text="STOP PLAYERS";pGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(10,110,75)),ColorSequenceKeypoint.new(1,Color3.fromRGB(15,75,55))});pStatLbl.Text="Active — "..n;pStatLbl.TextColor3=C.Success
            startPulse(pToggle,"pToggle");notify("Player spam started — "..n.." targets",C.Success,3)
            pThreads["main"]=task.spawn(function() while pSpamOn do for p in pairs(selP) do if p and p.Parent and p.Character then if wlP[p] then continue end;if not ignoreShield and isShielded(p) then if autoBreakShield then breakShield(p) end;continue end;attackPlayer(p) end end;task.wait(0.05) end end)
            
        else pToggle.Text="START PLAYERS";pGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,35,170)),ColorSequenceKeypoint.new(1,Color3.fromRGB(160,25,55))});pStatLbl.Text="Stopped";pStatLbl.TextColor3=C.TextMute
            stopPulse(pToggle,"pToggle");notify("Player spam stopped",C.TextMute,2)
            for _,th in pairs(pThreads) do pcall(task.cancel,th) end;pThreads={} end end)
end

local vScroll, vLay, vStatLbl, vCntLbl, vToggle, vGrad
local updVStat, makeVehRow, refreshVeh

do
    local vt=Instance.new("TextLabel");vt.Text="VEHICLES";vt.Size=UDim2.new(0.5,0,0,24);vt.Position=UDim2.new(0,4,0,6);vt.BackgroundTransparency=1;vt.TextColor3=C.Text;vt.Font=Enum.Font.GothamBlack;vt.TextSize=15;vt.TextXAlignment=Enum.TextXAlignment.Left;vt.ZIndex=5;vt.Parent=vContent
    vCntLbl=Instance.new("TextLabel");vCntLbl.Size=UDim2.new(0.5,-48,0,24);vCntLbl.Position=UDim2.new(0.5,0,0,6);vCntLbl.BackgroundTransparency=1;vCntLbl.TextColor3=C.TextMute;vCntLbl.Font=Enum.Font.Gotham;vCntLbl.TextSize=10;vCntLbl.TextXAlignment=Enum.TextXAlignment.Right;vCntLbl.ZIndex=5;vCntLbl.Parent=vContent
    vScroll=Instance.new("ScrollingFrame");vScroll.Size=UDim2.new(1,0,0,260);vScroll.Position=UDim2.new(0,0,0,34);vScroll.BackgroundColor3=C.Bg;vScroll.BackgroundTransparency=0.3;vScroll.ScrollBarThickness=4;vScroll.ScrollBarImageColor3=C.Accent;vScroll.ScrollBarImageTransparency=0.2;vScroll.BorderSizePixel=0;vScroll.CanvasSize=UDim2.new(0,0,0,0);vScroll.ZIndex=4;vScroll.Parent=vContent;cr(vScroll,8);sk(vScroll,C.Border,1,0.5)
    vLay=Instance.new("UIListLayout");vLay.Padding=UDim.new(0,3);vLay.Parent=vScroll;pad(vScroll,4,4,4,4)
    vStatLbl=Instance.new("TextLabel");vStatLbl.Size=UDim2.new(1,0,0,18);vStatLbl.Position=UDim2.new(0,0,0,300);vStatLbl.BackgroundColor3=C.Card;vStatLbl.BackgroundTransparency=0.3;vStatLbl.TextColor3=C.TextMute;vStatLbl.Font=Enum.Font.Gotham;vStatLbl.TextSize=10;vStatLbl.ZIndex=4;vStatLbl.Parent=vContent;cr(vStatLbl,6);sk(vStatLbl,C.Border,1,0.5)
    updVStat = function() local n=0;for _ in pairs(selV) do n+=1 end;if n==0 then vStatLbl.Text="No targets";vStatLbl.TextColor3=C.TextMute else vStatLbl.Text=n.." target"..(n>1 and "s" or "").." + ESP";vStatLbl.TextColor3=C.Success end end
    
    makeVehRow = function(tgt)
        local mdl=tgt.Model;
        
        -- Если включен автоматический выбор техники, добавляем её в цели при обнаружении
        if selectAllVehiclesActive then
            selV[mdl] = {Model=mdl, HRP=tgt.HRP, Type=tgt.Type, Name=tgt.Name}
            if not vehicleESP[mdl] and mdl.Parent and tgt.HRP and tgt.HRP.Parent then
                vehicleESP[mdl] = createVehESP(mdl, tgt.HRP, tgt.Type)
            end
        end

        local row=Instance.new("Frame");row.Name=tgt.Name;row.Size=UDim2.new(1,-4,0,40);row.BackgroundColor3=C.Card;row.BorderSizePixel=0;row.ZIndex=5;row.Parent=vScroll;cr(row,7);local rowStroke=sk(row,C.Border,1,0.35);addRowGradient(row)
        
        local cb=Instance.new("Frame");cb.Size=UDim2.new(0,14,0,14);cb.Position=UDim2.new(0,6,0.5,-7);cb.BackgroundColor3=C.Input;cb.BorderSizePixel=0;cb.ZIndex=6;cb.Parent=row;cr(cb,4);local cbStroke=sk(cb,C.Border,1,0)
        local cm=Instance.new("TextLabel");cm.Text="";cm.Size=UDim2.new(1,0,1,0);cm.BackgroundTransparency=1;cm.TextColor3=C.White;cm.Font=Enum.Font.GothamBold;cm.TextSize=10;cm.ZIndex=7;cm.Parent=cb
        
        local badge=Instance.new("Frame");badge.Size=UDim2.new(0,36,0,14);badge.Position=UDim2.new(0,26,0.5,-7);badge.BackgroundColor3=vCol[tgt.Type] or C.Card;badge.BackgroundTransparency=0.4;badge.ZIndex=6;badge.Parent=row;cr(badge,4);sk(badge,vCol[tgt.Type] or C.Border,1,0.2)
        local bTxt=Instance.new("TextLabel");bTxt.Text=vShort[tgt.Type] or "??";bTxt.Size=UDim2.new(1,0,1,0);bTxt.BackgroundTransparency=1;bTxt.TextColor3=C.White;bTxt.TextSize=7;bTxt.Font=Enum.Font.GothamBlack;bTxt.ZIndex=7;bTxt.Parent=badge
        
        local nl=Instance.new("TextLabel");nl.Text=tgt.Name;nl.Size=UDim2.new(0,120,0,13);nl.Position=UDim2.new(0,68,0,4);nl.BackgroundTransparency=1;nl.TextColor3=C.Text;nl.Font=Enum.Font.GothamBold;nl.TextSize=10;nl.TextXAlignment=Enum.TextXAlignment.Left;nl.TextTruncate=Enum.TextTruncate.AtEnd;nl.ZIndex=7;nl.Parent=row
        local ol=Instance.new("TextLabel");ol.Name="VehInfo";ol.Size=UDim2.new(0,180,0,10);ol.Position=UDim2.new(0,68,0,19);ol.BackgroundTransparency=1;ol.Font=Enum.Font.Gotham;ol.TextSize=8;ol.TextXAlignment=Enum.TextXAlignment.Left;ol.ZIndex=7;ol.RichText=true;ol.Parent=row
        
        local function updateVehInfo() local p={};if tgt.DisplayName and tgt.DisplayName~="" then p[#p+1]='<font color="#9C84FC">@'..tgt.DisplayName..'</font>' else p[#p+1]='<font color="#50506A">No owner</font>' end;local dist=getDistanceToVeh(tgt.HRP);if dist then p[#p+1]='<font color="#50506A">'..dist..'m</font>' end;ol.Text=table.concat(p,'  ') end;updateVehInfo()
        
        local btn=Instance.new("TextButton");btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1;btn.Text="";btn.ZIndex=8;btn.Parent=row
        
        local function vis() if selV[mdl] then row.BackgroundColor3=C.Sel;rowStroke.Color=C.SelBrd;animateCheckbox(cb,cm,true) else row.BackgroundColor3=C.Card;rowStroke.Color=C.Border;animateCheckbox(cb,cm,false) end end
        
        -- Вызываем vis() изначально, чтобы применилось выделение, если техника добавилась под автоматическим Select All
        vis()
        
        row.MouseEnter:Connect(function()
            TS:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = C.CardH}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            local activeColor = selV[mdl] and C.Sel or C.Card
            local strokeColor = selV[mdl] and C.SelBrd or C.Border
            TS:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = activeColor}):Play()
            TS:Create(rowStroke, TweenInfo.new(0.2), {Color = strokeColor, Transparency = 0.4}):Play()
        end)
        
        btn.MouseButton1Click:Connect(function()
            if selV[mdl] then selV[mdl]=nil;if vehicleESP[mdl] then destroyVehESP(vehicleESP[mdl]);vehicleESP[mdl]=nil end
            else selV[mdl]={Model=mdl,HRP=tgt.HRP,Type=tgt.Type,Name=tgt.Name};if not vehicleESP[mdl] and mdl.Parent and tgt.HRP and tgt.HRP.Parent then vehicleESP[mdl]=createVehESP(mdl,tgt.HRP,tgt.Type) end end;vis();updVStat() end)
        vehEl[mdl]={row=row,vis=vis,tgt=tgt,updateInfo=updateVehInfo}
    end
    
    refreshVeh = function()
        -- Ensure vFolders are up to date! Sometimes map reloads or new folders appear
        pcall(function() 
            local gs = workspace:FindFirstChild("Game Systems")
            if gs then
                for _,n in ipairs({"Helicopter","Plane","Gunship","Boat","Tank","Hovercraft","Vehicle","Submarine","Drone","RC"}) do
                    if not vFolders[n] or not vFolders[n].Parent then
                        vFolders[n] = gs:FindFirstChild(n.." Workspace") 
                    end
                end 
            end 
        end)
        
        scanVehicles()
        
        local currentModels = {}
        for _, t in ipairs(vehInst) do
            currentModels[t.Model] = t
        end
        
        -- 1. Safely remove rows of vehicles that are no longer there (flickerless)
        for m, e in pairs(vehEl) do
            local health, maxHealth = getVehicleHealth(m)
            local isDead = (health and health <= 0)
            
            if not currentModels[m] or not m.Parent or isDead then
                if e.row then e.row:Destroy() end
                vehEl[m] = nil
                if vehicleESP[m] then
                    destroyVehESP(vehicleESP[m])
                    vehicleESP[m] = nil
                end
                if selV[m] then
                    selV[m] = nil
                end
            end
        end
        
        -- 2. Update existing rows or construct new rows cleanly
        for _, t in ipairs(vehInst) do
            local m = t.Model
            local health, maxHealth = getVehicleHealth(m)
            local isDead = (health and health <= 0)
            
            if not isDead then
                if not vehEl[m] then
                    makeVehRow(t)
                    if selV[m] then
                        vehEl[m].vis()
                    end
                else
                    vehEl[m].tgt = t
                    if vehEl[m].updateInfo then
                        pcall(vehEl[m].updateInfo)
                    end
                end
            end
        end
        
        -- 3. Sync ESP with active selections
        for mdl, esp in pairs(vehicleESP) do
            local health, maxHealth = getVehicleHealth(mdl)
            local isDead = (health and health <= 0)
            
            if not currentModels[mdl] or not selV[mdl] or isDead then
                destroyVehESP(esp)
                vehicleESP[mdl] = nil
            end
        end
        
        vCntLbl.Text=#vehInst.." found"
        task.defer(function()
            pcall(function()
                vScroll.CanvasSize=UDim2.new(0,0,0,vLay.AbsoluteContentSize.Y+8)
            end)
        end)
        updVStat()
    end
    
    local function makeSmallBtn(text,xPos,xSize,parent) local btn=Instance.new("TextButton");btn.Text=text;btn.Size=UDim2.new(xSize,-3,1,0);btn.Position=UDim2.new(xPos,1,0,0);btn.BackgroundColor3=C.Card;btn.TextColor3=C.Text;btn.Font=Enum.Font.GothamBold;btn.TextSize=9;btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.ZIndex=5;btn.Parent=parent;cr(btn,5);sk(btn,C.Border,1,0.5);return btn end
    local vBtnFrame=Instance.new("Frame");vBtnFrame.Size=UDim2.new(1,0,0,22);vBtnFrame.Position=UDim2.new(0,0,0,322);vBtnFrame.BackgroundTransparency=1;vBtnFrame.ZIndex=4;vBtnFrame.Parent=vContent
    local vSelAll=makeSmallBtn("Select All",0,0.5,vBtnFrame);local vClearAll=makeSmallBtn("Clear All",0.5,0.5,vBtnFrame)
    makeButtonInteractive(vSelAll); makeButtonInteractive(vClearAll)
    
    vSelAll.MouseButton1Click:Connect(function()
        selectAllVehiclesActive = not selectAllVehiclesActive
        if selectAllVehiclesActive then
            vSelAll.BackgroundColor3 = C.AccentD
            vSelAll.TextColor3 = C.White
            -- Выделяем всю текущую технику
            for m,e in pairs(vehEl) do 
                selV[m]={Model=m,HRP=e.tgt.HRP,Type=e.tgt.Type,Name=e.tgt.Name}
                e.vis()
                if not vehicleESP[m] and m.Parent and e.tgt.HRP and e.tgt.HRP.Parent then 
                    vehicleESP[m]=createVehESP(m,e.tgt.HRP,e.tgt.Type) 
                end 
            end
            notify("Auto-Select Vehicles ENABLED", C.Success, 2)
        else
            vSelAll.BackgroundColor3 = C.Card
            vSelAll.TextColor3 = C.Text
            notify("Auto-Select Vehicles DISABLED", C.TextMute, 2)
        end
        updVStat()
    end)
    
    vClearAll.MouseButton1Click:Connect(function()
        -- Выключаем автовыбор, если нажали очистку
        if selectAllVehiclesActive then
            selectAllVehiclesActive = false
            vSelAll.BackgroundColor3 = C.Card
            vSelAll.TextColor3 = C.Text
        end
        selV={};for _,e in pairs(vehEl) do e.vis() end;for mdl,esp in pairs(vehicleESP) do destroyVehESP(esp) end;vehicleESP={};updVStat()
    end)
    
    vToggle=Instance.new("TextButton");vToggle.Text="ORBITAL STRIKE";vToggle.Size=UDim2.new(1,0,0,34);vToggle.Position=UDim2.new(0,0,0,350);vToggle.BackgroundColor3=C.AccentD;vToggle.TextColor3=C.White;vToggle.Font=Enum.Font.GothamBlack;vToggle.TextSize=12;vToggle.AutoButtonColor=false;vToggle.BorderSizePixel=0;vToggle.ZIndex=5;vToggle.Parent=vContent;cr(vToggle,8);sk(vToggle,C.Accent,1,0.2)
    vGrad=Instance.new("UIGradient");vGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,35,170)),ColorSequenceKeypoint.new(1,Color3.fromRGB(160,25,55))});vGrad.Rotation=90;vGrad.Parent=vToggle
    
    vToggle.MouseButton1Click:Connect(function() vSpamOn=not vSpamOn
        if vSpamOn then local n=0;for _ in pairs(selV) do n+=1 end;if n==0 then vStatLbl.Text="Select targets!";vStatLbl.TextColor3=C.Danger;vSpamOn=false;return end;if not rpgReady then vStatLbl.Text="No RPG!";vStatLbl.TextColor3=C.Danger;vSpamOn=false;return end
            vToggle.Text="STOP VEHICLES";vGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(10,110,75)),ColorSequenceKeypoint.new(1,Color3.fromRGB(15,75,55))});vStatLbl.Text="Active — "..n;vStatLbl.TextColor3=C.Success
            startPulse(vToggle,"vToggle");notify("Vehicle spam started — "..n.." targets",C.Success,3)
            vThreads["main"]=task.spawn(function() while vSpamOn do for _,td in pairs(selV) do if vSpamOn and td.Model and td.Model.Parent then attackVehicle(td);task.wait(0.05) end end;task.wait(0.1) end end)
            
        else vToggle.Text="ORBITAL STRIKE";vGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,35,170)),ColorSequenceKeypoint.new(1,Color3.fromRGB(160,25,55))});vStatLbl.Text="Stopped";vStatLbl.TextColor3=C.TextMute
            stopPulse(vToggle,"vToggle");notify("Vehicle spam stopped",C.TextMute,2)
            for _,th in pairs(vThreads) do pcall(task.cancel,th) end;vThreads={} end end)
end

do
    local ft=Instance.new("TextLabel");ft.Text="AUTO FARM";ft.Size=UDim2.new(1,0,0,24);ft.Position=UDim2.new(0,4,0,6);ft.BackgroundTransparency=1;ft.TextColor3=C.Farm;ft.Font=Enum.Font.GothamBlack;ft.TextSize=15;ft.TextXAlignment=Enum.TextXAlignment.Left;ft.ZIndex=5;ft.Parent=fContent
    local fStats=Instance.new("Frame");fStats.Size=UDim2.new(1,0,0,60);fStats.Position=UDim2.new(0,0,0,34);fStats.BackgroundColor3=C.Card;fStats.BorderSizePixel=0;fStats.ZIndex=4;fStats.Parent=fContent;cr(fStats,8);sk(fStats,C.Border,1,0.4)
    local function makeFStat(text,yPos,color) local lbl=Instance.new("TextLabel");lbl.Text=text;lbl.Size=UDim2.new(1,-14,0,14);lbl.Position=UDim2.new(0,7,0,yPos);lbl.BackgroundTransparency=1;lbl.TextColor3=color or C.Text;lbl.Font=Enum.Font.Gotham;lbl.TextSize=10;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=5;lbl.RichText=true;lbl.Parent=fStats;return lbl end
    local fCycleLbl=makeFStat("Cycles: <font color=\"#E6AA1E\"><b>0</b></font>",4,C.TextSub)
    local fTotalLbl=makeFStat("Total: <font color=\"#E6AA1E\"><b>0</b></font> | <font color=\"#10B981\"><b>$0</b></font>",22,C.Farm);fTotalLbl.Font=Enum.Font.GothamBold
    local fStatusLbl=makeFStat("Status: <font color=\"#707095\">Idle</font>",40,C.TextMute)
    
    local function makeFSetting(labelText,defaultVal,yPos)
        local frame=Instance.new("Frame");frame.Size=UDim2.new(1,0,0,24);frame.Position=UDim2.new(0,0,0,yPos);frame.BackgroundColor3=C.Card;frame.BorderSizePixel=0;frame.ZIndex=4;frame.Parent=fContent;cr(frame,6);local frameStroke=sk(frame,C.Border,1,0.5)
        local lbl=Instance.new("TextLabel");lbl.Text=labelText;lbl.Size=UDim2.new(0,130,1,0);lbl.Position=UDim2.new(0,6,0,0);lbl.BackgroundTransparency=1;lbl.TextColor3=C.TextSub;lbl.Font=Enum.Font.Gotham;lbl.TextSize=10;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=5;lbl.Parent=frame
        local box=Instance.new("TextBox");box.Text=tostring(defaultVal);box.Size=UDim2.new(0,45,0,16);box.Position=UDim2.new(1,-50,0.5,-8);box.BackgroundColor3=C.Input;box.TextColor3=C.Text;box.Font=Enum.Font.GothamBold;box.TextSize=10;box.BorderSizePixel=0;box.ClearTextOnFocus=true;box.ZIndex=5;box.Parent=frame;cr(box,4);local boxStroke=sk(box,C.Border,1,0.5)
        box.Focused:Connect(function()
            TS:Create(boxStroke, TweenInfo.new(0.15), {Color = C.Accent, Transparency = 0}):Play()
        end)
        box.FocusLost:Connect(function()
            TS:Create(boxStroke, TweenInfo.new(0.2), {Color = C.Border, Transparency = 0.5}):Play()
        end)
        return box
    end
    local fDistBox=makeFSetting("Max Distance:",FARM_MAX_DIST,100)
    local fHitsBox=makeFSetting("Hits per object:",FARM_HITS,128)
    fDistBox.FocusLost:Connect(function() local n=tonumber(fDistBox.Text);if n and n>0 then FARM_MAX_DIST=n else fDistBox.Text=tostring(FARM_MAX_DIST) end end)
    fHitsBox.FocusLost:Connect(function() local n=tonumber(fHitsBox.Text);if n and n>=1 then FARM_HITS=math.floor(n) else fHitsBox.Text=tostring(FARM_HITS) end end)
    local function farmLoop()
        while farmActive do char=plr.Character;if not char then fStatusLbl.Text="Status: <font color=\"#EF4444\">Waiting for char...</font>";task.wait(1);continue end;hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then task.wait(1);continue end
            if not rpgReady then pcall(function() rvEv=game.ReplicatedStorage.RocketSystem.Events;fxEv=rvEv.RocketReloadedFX;fireEv=rvEv.FireRocketReplicated;hitEv=rvEv.RocketHit;rocketModel=game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"];rpgReady=true end) end
            if not rpgReady then fStatusLbl.Text="Status: <font color=\"#EF4444\">No RPG!</font>";task.wait(2);continue end;tool=findRPG();if not tool then fStatusLbl.Text="Status: <font color=\"#EF4444\">Need RPG in hand!</font>";task.wait(1);continue end
            local alive=scanAlive()
            if #alive==0 then fStatusLbl.Text="Status: <font color=\"#8080A0\">No targets in range</font>";task.wait(FARM_RESCAN);continue end
            farmCycleCount+=1;fCycleLbl.Text="Cycles: <font color=\"#E6AA1E\"><b>"..farmCycleCount.."</b></font>";fStatusLbl.Text="Status: <font color=\"#10B981\">Destroying "..#alive.."...</font>"
            for _,obj in ipairs(alive) do if not farmActive then break end
                if obj.HitPoint and obj.HitPoint.Parent then farmTotalDestroyed+=1
                    task.spawn(function() for h=1,FARM_HITS do fireRocket(obj.HitPoint.Position,obj.HitPoint) end end)
                    fTotalLbl.Text="Total: <font color=\"#E6AA1E\"><b>"..farmTotalDestroyed.."</b></font> | <font color=\"#10B981\"><b>~$"..(farmTotalDestroyed*200).."</b></font>" end;task.wait() end
            fStatusLbl.Text="Status: <font color=\"#8080A0\">Cycle "..farmCycleCount.." done</font>";task.wait(FARM_RESCAN) end
    end
    local fToggle=Instance.new("TextButton");fToggle.Text="START AUTO FARM";fToggle.Size=UDim2.new(1,0,0,38);fToggle.Position=UDim2.new(0,0,0,160);fToggle.BackgroundColor3=C.FarmD;fToggle.TextColor3=C.White;fToggle.Font=Enum.Font.GothamBlack;fToggle.TextSize=13;fToggle.AutoButtonColor=false;fToggle.BorderSizePixel=0;fToggle.ZIndex=5;fToggle.Parent=fContent;cr(fToggle,8);sk(fToggle,C.Farm,1,0.2)
    local fGrad=Instance.new("UIGradient");fGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(200,150,20)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,80,20))});fGrad.Rotation=90;fGrad.Parent=fToggle
    fToggle.MouseButton1Click:Connect(function() farmActive=not farmActive
        if farmActive then fToggle.Text="STOP AUTO FARM";fGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(10,150,100)),ColorSequenceKeypoint.new(1,Color3.fromRGB(10,100,70))});fStatusLbl.Text="Status: <font color=\"#10B981\">Starting...</font>"
            startPulse(fToggle,"fToggle");notify("Auto farm started",C.Farm,3);farmThread=task.spawn(farmLoop)
        else fToggle.Text="START AUTO FARM";fGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(200,150,20)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,80,20))});fStatusLbl.Text="Status: <font color=\"#707095\">Stopped</font>"
            stopPulse(fToggle,"fToggle");notify("Auto farm stopped",C.TextMute,2);if farmThread then pcall(task.cancel,farmThread);farmThread=nil end end end)
end

local dDotCount, dStatusLbl, drawAtMouse

do
    local dt=Instance.new("TextLabel");dt.Text="RPG DRAW";dt.Size=UDim2.new(0.5,0,0,24);dt.Position=UDim2.new(0,4,0,6);dt.BackgroundTransparency=1;dt.TextColor3=C.Draw;dt.Font=Enum.Font.GothamBlack;dt.TextSize=15;dt.TextXAlignment=Enum.TextXAlignment.Left;dt.ZIndex=5;dt.Parent=dContent
    dDotCount=Instance.new("TextLabel");dDotCount.Size=UDim2.new(0.5,-48,0,24);dDotCount.Position=UDim2.new(0.5,0,0,6);dDotCount.BackgroundTransparency=1;dDotCount.TextColor3=C.TextMute;dDotCount.Font=Enum.Font.Gotham;dDotCount.TextSize=10;dDotCount.TextXAlignment=Enum.TextXAlignment.Right;dDotCount.ZIndex=5;dDotCount.Parent=dContent
    local dCanvas=Instance.new("Frame");dCanvas.Size=UDim2.new(1,0,0,225);dCanvas.Position=UDim2.new(0,0,0,32);dCanvas.BackgroundColor3=Color3.fromRGB(5,5,8);dCanvas.BorderSizePixel=0;dCanvas.ClipsDescendants=true;dCanvas.ZIndex=4;dCanvas.Parent=dContent;cr(dCanvas,6);sk(dCanvas,Color3.fromRGB(30,30,42),1,0.3)
    local dCursor=Instance.new("Frame");dCursor.Size=UDim2.new(0,BRUSH_SIZE,0,BRUSH_SIZE);dCursor.BackgroundColor3=Color3.fromRGB(98,55,210);dCursor.BackgroundTransparency=0.5;dCursor.BorderSizePixel=0;dCursor.ZIndex=10;dCursor.Visible=false;dCursor.Parent=dCanvas;Instance.new("UICorner",dCursor).CornerRadius=UDim.new(1,0)
    local dDotsContainer=Instance.new("Frame");dDotsContainer.Size=UDim2.new(1,0,1,0);dDotsContainer.BackgroundTransparency=1;dDotsContainer.ZIndex=5;dDotsContainer.Parent=dCanvas
    local function dRedrawAll() for _,child in ipairs(dDotsContainer:GetChildren()) do child:Destroy() end;for _,p in ipairs(drawPoints) do local dot=Instance.new("Frame");dot.Size=UDim2.new(0,p.s or BRUSH_SIZE,0,p.s or BRUSH_SIZE);dot.Position=UDim2.new(0,p.x-(p.s or BRUSH_SIZE)/2,0,p.y-(p.s or BRUSH_SIZE)/2);dot.BackgroundColor3=Color3.fromRGB(255,255,255);dot.BorderSizePixel=0;dot.ZIndex=6;dot.Parent=dDotsContainer end end
    local function dAddDot(x,y) local p={x=x,y=y,s=BRUSH_SIZE};table.insert(drawPoints,p);table.insert(drawStrokePoints,p);local dot=Instance.new("Frame");dot.Size=UDim2.new(0,BRUSH_SIZE,0,BRUSH_SIZE);dot.Position=UDim2.new(0,x-BRUSH_SIZE/2,0,y-BRUSH_SIZE/2);dot.BackgroundColor3=Color3.fromRGB(255,255,255);dot.BorderSizePixel=0;dot.ZIndex=6;dot.Parent=dDotsContainer end
    local function dEraseDots(x,y) 
        local radius=BRUSH_SIZE*ERASE_MULT*2 -- Увеличил радиус ластика в 2 раза для комфорта
        local newPts={}
        local removed=false
        for _,p in ipairs(drawPoints) do 
            local dx=p.x-x; local dy=p.y-y
            if math.sqrt(dx*dx+dy*dy) > radius then 
                table.insert(newPts,p) 
            else 
                removed=true 
            end 
        end
        if removed then 
            drawPoints=newPts
            dRedrawAll() 
        end 
    end
    local function dSaveUndo() if #drawStrokePoints>0 then local snap={};for _,p in ipairs(drawStrokePoints) do table.insert(snap,p) end;table.insert(drawUndoStack,snap);if #drawUndoStack>MAX_UNDO then table.remove(drawUndoStack,1) end;drawStrokePoints={} end end
    local function dUndo() if #drawUndoStack==0 then return end;local last=table.remove(drawUndoStack);local rem={};for _,sp in ipairs(last) do rem[sp]=true end;local newPts={};for _,p in ipairs(drawPoints) do if not rem[p] then table.insert(newPts,p) end end;drawPoints=newPts;dRedrawAll() end
    local function getCanvasPos() local mpos=UIS:GetMouseLocation();local cpos=dCanvas.AbsolutePosition;local csize=dCanvas.AbsoluteSize;local rel=mpos-cpos-Vector2.new(0,36);return rel,rel.X>=0 and rel.X<=csize.X and rel.Y>=0 and rel.Y<=csize.Y end
    dCanvas.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then drawMouseDown=true;drawEraseMode=false;drawStrokePoints={};local pos,valid=getCanvasPos();if valid then drawLastPos=pos;dAddDot(pos.X,pos.Y) end
        elseif input.UserInputType==Enum.UserInputType.MouseButton2 then drawMouseDown=true;drawEraseMode=true;local pos,valid=getCanvasPos();if valid then drawLastPos=pos;dEraseDots(pos.X,pos.Y) end end end)
    dCanvas.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then drawMouseDown=false;drawLastPos=nil;dSaveUndo() elseif input.UserInputType==Enum.UserInputType.MouseButton2 then drawMouseDown=false;drawLastPos=nil end end)
    RS.RenderStepped:Connect(function()
        if currentTab~="draw" then dCursor.Visible=false;return end
        local pos,valid=getCanvasPos()
        if valid then dCursor.Visible=true;local sz=drawEraseMode and(BRUSH_SIZE*ERASE_MULT*2) or BRUSH_SIZE;dCursor.Size=UDim2.new(0,sz,0,sz);dCursor.Position=UDim2.new(0,pos.X-sz/2,0,pos.Y-sz/2);dCursor.BackgroundColor3=drawEraseMode and Color3.fromRGB(180,40,40) or Color3.fromRGB(98,55,210)
        else dCursor.Visible=false end
        if not drawMouseDown or not drawLastPos or not valid then return end
        local dx=pos.X-drawLastPos.X;local dy=pos.Y-drawLastPos.Y;local dist=math.sqrt(dx*dx+dy*dy);if dist<DRAW_SPACING then return end
        local steps=math.max(math.floor(dist/DRAW_SPACING),1)
        for i=1,steps do local t=i/steps;local ix=drawLastPos.X+dx*t;local iy=drawLastPos.Y+dy*t;if drawEraseMode then dEraseDots(ix,iy) else dAddDot(ix,iy) end end;drawLastPos=pos end)
    createSlider(dContent,"Brush",1,8,BRUSH_SIZE,262,function(v) BRUSH_SIZE=v end)
    createSlider(dContent,"Scale",1,30,DRAW_SCALE,282,function(v) DRAW_SCALE=v end)
    createSlider(dContent,"Space",4,20,DRAW_SPACING,302,function(v) DRAW_SPACING=v end)
    local dBindRow=Instance.new("Frame");dBindRow.Size=UDim2.new(1,0,0,18);dBindRow.Position=UDim2.new(0,0,0,324);dBindRow.BackgroundColor3=Color3.fromRGB(12,12,17);dBindRow.BorderSizePixel=0;dBindRow.ZIndex=4;dBindRow.Parent=dContent;cr(dBindRow,4)
    local dBindLbl=Instance.new("TextLabel");dBindLbl.Text="Bind: "..DRAW_BIND.Name;dBindLbl.Size=UDim2.new(1,-28,1,0);dBindLbl.Position=UDim2.new(0,4,0,0);dBindLbl.BackgroundTransparency=1;dBindLbl.TextColor3=Color3.fromRGB(70,70,90);dBindLbl.Font=Enum.Font.Gotham;dBindLbl.TextSize=8;dBindLbl.TextXAlignment=Enum.TextXAlignment.Left;dBindLbl.ZIndex=5;dBindLbl.Parent=dBindRow
    local dBindBtn=Instance.new("TextButton");dBindBtn.Text="set";dBindBtn.Size=UDim2.new(0,22,0,12);dBindBtn.Position=UDim2.new(1,-26,0.5,-6);dBindBtn.BackgroundColor3=Color3.fromRGB(32,32,45);dBindBtn.TextColor3=Color3.fromRGB(130,130,150);dBindBtn.Font=Enum.Font.GothamBold;dBindBtn.TextSize=7;dBindBtn.AutoButtonColor=false;dBindBtn.BorderSizePixel=0;dBindBtn.ZIndex=5;dBindBtn.Parent=dBindRow;cr(dBindBtn,3)
    makeButtonInteractive(dBindBtn)
    
    dBindBtn.MouseButton1Click:Connect(function() dWaitBind=true;dBindBtn.Text="?";dBindBtn.BackgroundColor3=Color3.fromRGB(80,45,180) end)
    local dBtnRow=Instance.new("Frame");dBtnRow.Size=UDim2.new(1,0,0,26);dBtnRow.Position=UDim2.new(0,0,0,346);dBtnRow.BackgroundTransparency=1;dBtnRow.ZIndex=4;dBtnRow.Parent=dContent
    local function dMakeBtn(text,xPos,xSize,color) local btn=Instance.new("TextButton");btn.Text=text;btn.Size=UDim2.new(xSize,-2,1,0);btn.Position=UDim2.new(xPos,1,0,0);btn.BackgroundColor3=color;btn.TextColor3=Color3.fromRGB(200,200,215);btn.Font=Enum.Font.GothamBold;btn.TextSize=10;btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.ZIndex=5;btn.Parent=dBtnRow;cr(btn,5);return btn end
    local dUndoBtn=dMakeBtn("UNDO",0,0.25,Color3.fromRGB(35,35,55));local dClearBtn=dMakeBtn("CLEAR",0.25,0.25,Color3.fromRGB(50,20,20));local dDrawBtn=dMakeBtn("DRAW",0.5,0.5,Color3.fromRGB(18,60,35))
    makeButtonInteractive(dUndoBtn, Color3.fromRGB(45, 45, 65)); makeButtonInteractive(dClearBtn, Color3.fromRGB(70, 30, 30)); makeButtonInteractive(dDrawBtn, Color3.fromRGB(28, 80, 45))
    
    dStatusLbl=Instance.new("TextLabel");dStatusLbl.Size=UDim2.new(1,0,0,14);dStatusLbl.Position=UDim2.new(0,0,0,376);dStatusLbl.BackgroundTransparency=1;dStatusLbl.TextColor3=Color3.fromRGB(100,100,120);dStatusLbl.Font=Enum.Font.Gotham;dStatusLbl.TextSize=8;dStatusLbl.TextXAlignment=Enum.TextXAlignment.Left;dStatusLbl.ZIndex=4;dStatusLbl.Parent=dContent
    dUndoBtn.MouseButton1Click:Connect(function() dUndo();dStatusLbl.Text="Undo | "..#drawPoints.." dots" end)
    dClearBtn.MouseButton1Click:Connect(function() drawPoints={};drawUndoStack={};drawStrokePoints={};for _,child in ipairs(dDotsContainer:GetChildren()) do child:Destroy() end;dStatusLbl.Text="Cleared" end)
    drawAtMouse = function()
        char=plr.Character;if not char then return end;hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
        if not rpgReady then dStatusLbl.Text="No RPG system";dStatusLbl.TextColor3=C.Danger;return end;local t=findRPG();if not t then dStatusLbl.Text="Need RPG";dStatusLbl.TextColor3=C.Danger;return end
        local target=Mouse.Target;if not target then dStatusLbl.Text="Aim somewhere";dStatusLbl.TextColor3=C.Danger;return end;if #drawPoints==0 then dStatusLbl.Text="Nothing to draw";dStatusLbl.TextColor3=C.Danger;return end
        local hitPos=Mouse.Hit.Position;local cam=workspace.CurrentCamera;local right=cam.CFrame.RightVector;local up=cam.CFrame.UpVector
        local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
        for _,p in ipairs(drawPoints) do if p.x<minX then minX=p.x end;if p.x>maxX then maxX=p.x end;if p.y<minY then minY=p.y end;if p.y>maxY then maxY=p.y end end
        local centerX=(minX+maxX)/2;local centerY=(minY+maxY)/2;local sf=DRAW_SCALE/math.max(BRUSH_SIZE,1)
        dStatusLbl.Text="Firing "..#drawPoints.."...";dStatusLbl.TextColor3=C.Success;notify("Drawing "..#drawPoints.." explosions",C.Draw,2)
        for _,p in ipairs(drawPoints) do task.spawn(function() local relX=(p.x-centerX)*sf;local relY=-(p.y-centerY)*sf;fireAtDraw(hitPos+right*relX+up*relY) end) end
        task.delay(0.3,function() dStatusLbl.Text=#drawPoints.." explosions fired";dStatusLbl.TextColor3=Color3.fromRGB(140,140,160) end)
    end
    dDrawBtn.MouseButton1Click:Connect(drawAtMouse)
    UIS.InputBegan:Connect(function(input,gp)
        if gp then return end
        if dWaitBind then if input.KeyCode~=Enum.KeyCode.Unknown then DRAW_BIND=input.KeyCode;dBindLbl.Text="Bind: "..input.KeyCode.Name;dBindBtn.Text="set";dBindBtn.BackgroundColor3=Color3.fromRGB(32,32,45);dWaitBind=false end;return end
        if input.KeyCode==DRAW_BIND then drawAtMouse() end
        if input.KeyCode==Enum.KeyCode.Z and currentTab=="draw" then if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then dUndo() end end
    end)
end

do
    local floatBtn=Instance.new("TextButton");floatBtn.Name="Toggle";floatBtn.Text="RPG";floatBtn.Size=UDim2.new(0,42,0,42);floatBtn.Position=UDim2.new(0,12,0.5,-21);floatBtn.BackgroundColor3=C.Bg;floatBtn.TextColor3=C.AccentL;floatBtn.Font=Enum.Font.GothamBlack;floatBtn.TextSize=10;floatBtn.AutoButtonColor=false;floatBtn.BorderSizePixel=0;floatBtn.ZIndex=10;floatBtn.Active=true;floatBtn.Parent=gui;cr(floatBtn,21);local fStr=sk(floatBtn,C.Accent,2,0.3)
    floatBtn.MouseEnter:Connect(function() TS:Create(fStr,TweenInfo.new(0.15),{Transparency=0,Color=C.AccentL}):Play() end)
    floatBtn.MouseLeave:Connect(function() TS:Create(fStr,TweenInfo.new(0.2),{Transparency=0.3,Color=C.Accent}):Play() end)
    
    makeDraggable(floatBtn, floatBtn)
    
    local dragStartPos = nil
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStartPos = floatBtn.AbsolutePosition
        end
    end)
    
    floatBtn.MouseButton1Click:Connect(function()
        local currentPos = floatBtn.AbsolutePosition
        if dragStartPos then
            local dist = (currentPos - dragStartPos).Magnitude
            if dist > 5 then
                return
            end
        end
        toggleGUI()
    end)
end

-- Keybind toggle support for main GUI (Insert / RightShift)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == GUI_TOGGLE_BIND then
        toggleGUI()
    end
end)

plr.CharacterAdded:Connect(function(nc) char=nc;hrp=nc:WaitForChild("HumanoidRootPart");tool=nc:WaitForChild("RPG",5)
    if not tool then local bp=plr:FindFirstChild("Backpack");if bp then tool=bp:FindFirstChild("RPG") end end
    pcall(function() if not rpgReady then rvEv=game.ReplicatedStorage.RocketSystem.Events;fxEv=rvEv.RocketReloadedFX;fireEv=rvEv.FireRocketReplicated;hitEv=rvEv.RocketHit;rocketModel=game.ReplicatedStorage.RocketSystem.Rockets["RPG Rocket"];rpgReady=true end end)
    if rpgReady and rpgDot then rpgDot.BackgroundColor3=C.Success end end)

for _,p in pairs(Players:GetPlayers()) do createPlrEl(p) end;updOnline();updPStat();updateMyBase()
Players.PlayerAdded:Connect(function(p) task.wait(0.5);createPlrEl(p);updOnline();notify(p.DisplayName.." joined",C.TextSub,2) end)
Players.PlayerRemoving:Connect(function(p) notify(p.DisplayName.." left",C.TextMute,2);removePlrEl(p) end)

table.insert(_G.HubThreads, task.spawn(function() while true do for p,el in pairs(plrEl) do if p and p.Parent and el and el.Parent then local si=el:FindFirstChild("ShieldIcon");if si then si.Visible=isShielded(p) end;local uf=el:FindFirstChild("_updateFunc");if uf then pcall(function() uf:Fire() end) end end end
    for m,e in pairs(vehEl) do if e.updateInfo and e.row and e.row.Parent then pcall(e.updateInfo) end end;updateMyBase();task.wait(2) end end))

refreshVeh()
table.insert(_G.HubThreads, task.spawn(function() while true do task.wait(1.5); refreshVeh() end end))
table.insert(_G.HubThreads, task.spawn(function() while true do if rpgDot and rpgDot.Parent then rpgDot.BackgroundColor3=(rpgReady and findRPG()) and C.Success or C.Danger end;task.wait(3) end end))
-- RenderStepped for Smooth ESP updates
local espConn = RS.RenderStepped:Connect(function() 
    for mdl,esp in pairs(vehicleESP) do 
        if not selV[mdl] or not mdl.Parent then 
            destroyVehESP(esp); vehicleESP[mdl]=nil 
        else 
            updateVehESP(esp)
        end 
    end 
end)
if _G.HubConnections then table.insert(_G.HubConnections, espConn) end

table.insert(_G.HubThreads, task.spawn(function() while true do if dDotCount then dDotCount.Text=#drawPoints.." dots" end
    if dStatusLbl and currentTab=="draw" and dStatusLbl.TextColor3==Color3.fromRGB(100,100,120) then dStatusLbl.Text="LMB draw | RMB erase | "..DRAW_BIND.Name.." fire" end;task.wait(1) end end))


-- Auto Break Shield background loop
table.insert(_G.HubThreads, task.spawn(function()
    while true do
        if autoBreakShield then
            for p in pairs(selP) do
                if p and p.Parent and p.Character and not wlP[p] and isShielded(p) then
                    breakShield(p)
                end
            end
        end
        task.wait(0.2)
    end
end))

notify("Nazarkus RPG Hub loaded!",C.Accent,5)
notify("Press [RightShift] to Toggle UI", C.Success, 5)
