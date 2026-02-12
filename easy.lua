local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAddedWait()
local hrp = charWaitForChild(HumanoidRootPart)
local tool = charWaitForChild(RPG)
local ev = game.ReplicatedStorage.RocketSystem.Events
local fx = ev.RocketReloadedFX
local fire = ev.FireRocketReplicated
local hit = ev.RocketHit
local cnt = 0

local TweenService = gameGetService(TweenService)
local RunService = gameGetService(RunService)

local currentGradientColor = Color3.fromRGB(100, 120, 200)
local gradientTime = 0

-- Затемнённые цвета
local Colors = {
    Background = Color3.fromRGB(8, 10, 18),
    Secondary = Color3.fromRGB(12, 15, 28),
    Tertiary = Color3.fromRGB(20, 24, 40),
    Card = Color3.fromRGB(14, 17, 32),
    Selected = Color3.fromRGB(28, 45, 75),
    Success = Color3.fromRGB(40, 100, 75),
    SuccessHover = Color3.fromRGB(50, 125, 90),
    Danger = Color3.fromRGB(120, 40, 50),
    DangerHover = Color3.fromRGB(145, 55, 65),
    Text = Color3.fromRGB(230, 232, 245),
    TextDim = Color3.fromRGB(130, 135, 165),
    TextMuted = Color3.fromRGB(80, 85, 110),
    Border = Color3.fromRGB(45, 52, 85),
    Checkbox = Color3.fromRGB(45, 115, 95),
    Glow = Color3.fromRGB(100, 80, 220)
}

local function lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R)  t,
        c1.G + (c2.G - c1.G)  t,
        c1.B + (c2.B - c1.B)  t
    )
end

local function addCorner(instance, radius)
    local corner = Instance.new(UICorner)
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new(UIStroke)
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1.5
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function addShadow(parent)
    local shadow = Instance.new(ImageLabel)
    shadow.Name = Shadow
    shadow.BackgroundTransparency = 1
    shadow.Image = rbxassetid6014261993
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.2
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 80, 1, 80)
    shadow.Position = UDim2.new(0, -40, 0, -40)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

local function addInnerGlow(parent, color)
    local glow = Instance.new(Frame)
    glow.Name = InnerGlow
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.BackgroundTransparency = 1
    glow.ZIndex = parent.ZIndex
    glow.Parent = parent
    
    local glowStroke = Instance.new(UIStroke)
    glowStroke.Color = color or Colors.Glow
    glowStroke.Thickness = 1.5
    glowStroke.Transparency = 0.6
    glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glowStroke.Parent = glow
    
    addCorner(glow, 20)
    return glow, glowStroke
end

local syncedButtons = {}

local function addSyncedHoverEffect(button, baseColor)
    local data = {button = button, baseColor = baseColor, isHovered = false}
    table.insert(syncedButtons, data)
    
    button.MouseEnterConnect(function()
        data.isHovered = true
        TweenServiceCreate(button, TweenInfo.new(0.15), {BackgroundTransparency = 0})Play()
    end)
    
    button.MouseLeaveConnect(function()
        data.isHovered = false
        TweenServiceCreate(button, TweenInfo.new(0.2), {BackgroundColor3 = baseColor, BackgroundTransparency = 0})Play()
    end)
    
    return data
end

-- GUI
local screenGui = Instance.new(ScreenGui)
screenGui.Name = RPGSpammerGUI
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main frame
local frame = Instance.new(Frame)
frame.Name = MainFrame
frame.Size = UDim2.new(0, 360, 0, 480)
frame.Position = UDim2.new(0.5, -180, 0.5, -240)
frame.BackgroundColor3 = Colors.Background
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.ClipsDescendants = true
addCorner(frame, 20)
addShadow(frame)

local outerGlow, outerGlowStroke = addInnerGlow(frame, Colors.Glow)

-- Gradient container
local gradientContainer = Instance.new(Frame)
gradientContainer.Name = GradientContainer
gradientContainer.Size = UDim2.new(1, 0, 1, 0)
gradientContainer.BackgroundTransparency = 1
gradientContainer.ClipsDescendants = true
gradientContainer.ZIndex = 0
gradientContainer.Parent = frame
addCorner(gradientContainer, 20)

-- Градиент 1 - затемнённый
local gradientFrame1 = Instance.new(Frame)
gradientFrame1.Name = Gradient1
gradientFrame1.Size = UDim2.new(2.5, 0, 2.5, 0)
gradientFrame1.Position = UDim2.new(-0.75, 0, -0.75, 0)
gradientFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
gradientFrame1.BackgroundTransparency = 0.65
gradientFrame1.BorderSizePixel = 0
gradientFrame1.ZIndex = 0
gradientFrame1.Parent = gradientContainer

local gradient1 = Instance.new(UIGradient)
gradient1.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 60, 180)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(60, 110, 200)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 160, 200)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150, 90, 200)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 80, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 60, 180))
})
gradient1.Rotation = 0
gradient1.Parent = gradientFrame1

-- Градиент 2
local gradientFrame2 = Instance.new(Frame)
gradientFrame2.Name = Gradient2
gradientFrame2.Size = UDim2.new(2.5, 0, 2.5, 0)
gradientFrame2.Position = UDim2.new(-0.75, 0, -0.75, 0)
gradientFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
gradientFrame2.BackgroundTransparency = 0.7
gradientFrame2.BorderSizePixel = 0
gradientFrame2.ZIndex = 0
gradientFrame2.Parent = gradientContainer

local gradient2 = Instance.new(UIGradient)
gradient2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 160)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(100, 180, 200)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(160, 120, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 150, 200))
})
gradient2.Rotation = 60
gradient2.Parent = gradientFrame2

-- Градиент 3 - пульсирующий
local gradientFrame3 = Instance.new(Frame)
gradientFrame3.Name = Gradient3
gradientFrame3.Size = UDim2.new(1.2, 0, 0.7, 0)
gradientFrame3.Position = UDim2.new(-0.1, 0, -0.1, 0)
gradientFrame3.BackgroundColor3 = Color3.fromRGB(120, 140, 200)
gradientFrame3.BackgroundTransparency = 0.55
gradientFrame3.BorderSizePixel = 0
gradientFrame3.ZIndex = 0
gradientFrame3.Parent = gradientContainer
addCorner(gradientFrame3, 20)

local gradient3 = Instance.new(UIGradient)
gradient3.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.3, 0.4),
    NumberSequenceKeypoint.new(0.7, 0.8),
    NumberSequenceKeypoint.new(1, 1)
})
gradient3.Rotation = 90
gradient3.Parent = gradientFrame3

-- Частицы
local particles = {}
for i = 1, 6 do
    local particle = Instance.new(Frame)
    particle.Name = Particle .. i
    particle.Size = UDim2.new(0, math.random(25, 60), 0, math.random(25, 60))
    particle.Position = UDim2.new(math.random()  0.8, 0, math.random()  0.8, 0)
    particle.BackgroundColor3 = Color3.fromRGB(150, 130, 200)
    particle.BackgroundTransparency = 0.75
    particle.BorderSizePixel = 0
    particle.ZIndex = 0
    particle.Parent = gradientContainer
    addCorner(particle, 50)
    
    table.insert(particles, {
        frame = particle,
        speedX = (math.random() - 0.5)  0.25,
        speedY = (math.random() - 0.5)  0.25,
        phase = math.random()  math.pi  2
    })
end

-- Анимация
local animationConnection

animationConnection = RunService.RenderSteppedConnect(function(dt)
    gradientTime = gradientTime + dt  1.8
    
    gradient1.Rotation = gradientTime  25
    gradient1.Offset = Vector2.new(
        math.sin(gradientTime  0.9)  0.35,
        math.cos(gradientTime  0.7)  0.35
    )
    
    gradient2.Rotation = -gradientTime  18 + 60
    gradient2.Offset = Vector2.new(
        math.cos(gradientTime  0.8)  0.4,
        math.sin(gradientTime  1.1)  0.4
    )
    
    gradient3.Offset = Vector2.new(math.sin(gradientTime  1.5)  0.25, 0)
    gradientFrame3.BackgroundTransparency = 0.5 + math.sin(gradientTime)  0.15
    
    local hue = (gradientTime  0.06) % 1
    local dynamicColor = Color3.fromHSV(hue  0.35 + 0.55, 0.55, 0.85)
    gradientFrame3.BackgroundColor3 = dynamicColor
    
    currentGradientColor = Color3.fromHSV(hue  0.35 + 0.55, 0.65, 0.95)
    
    outerGlowStroke.Color = Color3.fromHSV((hue  0.35 + 0.6) % 1, 0.45, 0.9)
    outerGlowStroke.Transparency = 0.55 + math.sin(gradientTime  2.5)  0.15
    
    for _, p in ipairs(particles) do
        local x = 0.5 + math.sin(gradientTime  p.speedX + p.phase)  0.45
        local y = 0.5 + math.cos(gradientTime  p.speedY + p.phase)  0.45
        p.frame.Position = UDim2.new(x, -p.frame.Size.X.Offset2, y, -p.frame.Size.Y.Offset2)
        p.frame.BackgroundTransparency = 0.7 + math.sin(gradientTime  2 + p.phase)  0.2
        p.frame.BackgroundColor3 = Color3.fromHSV((hue + p.phase10) % 1  0.3 + 0.55, 0.4, 0.85)
    end
    
    for _, data in ipairs(syncedButtons) do
        if data.isHovered and data.button and data.button.Parent then
            local hoverColor = lerpColor(data.baseColor, currentGradientColor, 0.55)
            data.button.BackgroundColor3 = hoverColor
        end
    end
end)

-- Title bar
local titleBar = Instance.new(Frame)
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 2
titleBar.Parent = frame

-- Dragging
local dragging, dragInput, dragStart, startPos

titleBar.InputBeganConnect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.ChangedConnect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChangedConnect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

gameGetService(UserInputService).InputChangedConnect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        TweenServiceCreate(frame, TweenInfo.new(0.06), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        })Play()
    end
end)

-- Иконка
local iconBg = Instance.new(Frame)
iconBg.Size = UDim2.new(0, 38, 0, 38)
iconBg.Position = UDim2.new(0, 14, 0, 10)
iconBg.BackgroundColor3 = Colors.Tertiary
iconBg.BackgroundTransparency = 0.2
iconBg.ZIndex = 2
iconBg.Parent = titleBar
addCorner(iconBg, 12)

local icon = Instance.new(TextLabel)
icon.Text = 🚀
icon.Size = UDim2.new(1, 0, 1, 0)
icon.BackgroundTransparency = 1
icon.TextSize = 20
icon.Font = Enum.Font.SourceSans
icon.ZIndex = 3
icon.Parent = iconBg

-- Title
local title = Instance.new(TextLabel)
title.Text = RPG Spammer
title.Size = UDim2.new(1, -130, 0, 24)
title.Position = UDim2.new(0, 60, 0, 10)
title.BackgroundTransparency = 1
title.TextColor3 = Colors.Text
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = titleBar

-- Version badge
local versionBadge = Instance.new(Frame)
versionBadge.Size = UDim2.new(0, 45, 0, 18)
versionBadge.Position = UDim2.new(0, 60, 0, 35)
versionBadge.BackgroundColor3 = Colors.Checkbox
versionBadge.BackgroundTransparency = 0.2
versionBadge.ZIndex = 2
versionBadge.Parent = titleBar
addCorner(versionBadge, 9)

local version = Instance.new(TextLabel)
version.Text = v5.0
version.Size = UDim2.new(1, 0, 1, 0)
version.BackgroundTransparency = 1
version.TextColor3 = Colors.Text
version.Font = Enum.Font.GothamBold
version.TextSize = 10
version.ZIndex = 3
version.Parent = versionBadge

-- Button container
local btnContainer = Instance.new(Frame)
btnContainer.Size = UDim2.new(0, 70, 0, 34)
btnContainer.Position = UDim2.new(1, -84, 0, 12)
btnContainer.BackgroundColor3 = Colors.Secondary
btnContainer.BackgroundTransparency = 0.2
btnContainer.ZIndex = 2
btnContainer.Parent = titleBar
addCorner(btnContainer, 10)

-- Close button
local closeBtn = Instance.new(TextButton)
closeBtn.Text = ×
closeBtn.Size = UDim2.new(0, 30, 0, 28)
closeBtn.Position = UDim2.new(1, -33, 0.5, -14)
closeBtn.BackgroundColor3 = Colors.Danger
closeBtn.BackgroundTransparency = 0.3
closeBtn.TextColor3 = Colors.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.ZIndex = 3
closeBtn.Parent = btnContainer
addCorner(closeBtn, 8)
addSyncedHoverEffect(closeBtn, Colors.Danger)

-- Minimize button
local minimizeBtn = Instance.new(TextButton)
minimizeBtn.Text = −
minimizeBtn.Size = UDim2.new(0, 30, 0, 28)
minimizeBtn.Position = UDim2.new(0, 3, 0.5, -14)
minimizeBtn.BackgroundColor3 = Colors.Tertiary
minimizeBtn.BackgroundTransparency = 0.2
minimizeBtn.TextColor3 = Colors.Text
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 3
minimizeBtn.Parent = btnContainer
addCorner(minimizeBtn, 8)
addSyncedHoverEffect(minimizeBtn, Colors.Tertiary)

-- Content
local content = Instance.new(Frame)
content.Name = Content
content.Size = UDim2.new(1, -28, 1, -65)
content.Position = UDim2.new(0, 14, 0, 60)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = frame

-- Targets section
local targetsSection = Instance.new(Frame)
targetsSection.Size = UDim2.new(1, 0, 0, 250)
targetsSection.BackgroundColor3 = Colors.Card
targetsSection.BackgroundTransparency = 0.15
targetsSection.BorderSizePixel = 0
targetsSection.ZIndex = 2
targetsSection.Parent = content
addCorner(targetsSection, 14)
addStroke(targetsSection, Colors.Border, 1, 0.4)

-- Section header
local sectionHeader = Instance.new(Frame)
sectionHeader.Size = UDim2.new(1, 0, 0, 36)
sectionHeader.BackgroundTransparency = 1
sectionHeader.ZIndex = 3
sectionHeader.Parent = targetsSection

local targetsLabel = Instance.new(TextLabel)
targetsLabel.Text = 🎯 TARGETS
targetsLabel.Size = UDim2.new(0.5, 0, 1, 0)
targetsLabel.Position = UDim2.new(0, 14, 0, 0)
targetsLabel.BackgroundTransparency = 1
targetsLabel.TextColor3 = Colors.TextDim
targetsLabel.Font = Enum.Font.GothamBold
targetsLabel.TextSize = 11
targetsLabel.TextXAlignment = Enum.TextXAlignment.Left
targetsLabel.ZIndex = 3
targetsLabel.Parent = sectionHeader

local onlineLabel = Instance.new(TextLabel)
onlineLabel.Name = OnlineLabel
onlineLabel.Size = UDim2.new(0.5, -14, 1, 0)
onlineLabel.Position = UDim2.new(0.5, 0, 0, 0)
onlineLabel.BackgroundTransparency = 1
onlineLabel.TextColor3 = Colors.TextMuted
onlineLabel.Font = Enum.Font.GothamMedium
onlineLabel.TextSize = 10
onlineLabel.TextXAlignment = Enum.TextXAlignment.Right
onlineLabel.ZIndex = 3
onlineLabel.Parent = sectionHeader

-- Players list
local playersFrame = Instance.new(ScrollingFrame)
playersFrame.Size = UDim2.new(1, -16, 1, -44)
playersFrame.Position = UDim2.new(0, 8, 0, 38)
playersFrame.BackgroundTransparency = 1
playersFrame.ScrollBarThickness = 3
playersFrame.ScrollBarImageColor3 = Colors.Glow
playersFrame.ScrollBarImageTransparency = 0.3
playersFrame.BorderSizePixel = 0
playersFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playersFrame.ZIndex = 3
playersFrame.Parent = targetsSection

local listLayout = Instance.new(UIListLayout)
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = playersFrame

local listPadding = Instance.new(UIPadding)
listPadding.PaddingTop = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 2)
listPadding.PaddingLeft = UDim.new(0, 2)
listPadding.PaddingRight = UDim.new(0, 2)
listPadding.Parent = playersFrame

local selectedPlayers = {}
local playerElements = {}

-- Status bar
local statusBar = Instance.new(Frame)
statusBar.Size = UDim2.new(1, 0, 0, 32)
statusBar.Position = UDim2.new(0, 0, 0, 258)
statusBar.BackgroundColor3 = Colors.Card
statusBar.BackgroundTransparency = 0.15
statusBar.ZIndex = 2
statusBar.Parent = content
addCorner(statusBar, 10)
addStroke(statusBar, Colors.Border, 1, 0.4)

local statusLabel = Instance.new(TextLabel)
statusLabel.Name = StatusLabel
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Colors.TextDim
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 12
statusLabel.ZIndex = 3
statusLabel.Parent = statusBar

local function updateStatusLabel()
    local count = 0
    for _ in pairs(selectedPlayers) do count = count + 1 end
    
    if count == 0 then
        statusLabel.Text = ✨ No targets selected
        statusLabel.TextColor3 = Colors.TextDim
    else
        statusLabel.Text = ✅  .. count ..  target .. (count  1 and s or ) ..  selected
        statusLabel.TextColor3 = Colors.Checkbox
    end
end

local function updateOnlineCount()
    local count = #game.PlayersGetPlayers() - 1
    onlineLabel.Text = 👥  .. count ..  online
end

local function createPlayerElement(player)
    if player == plr then return end
    if playerElements[player] then return end
    
    local container = Instance.new(Frame)
    container.Name = player.Name
    container.Size = UDim2.new(1, -4, 0, 44)
    container.BackgroundColor3 = Colors.Secondary
    container.BackgroundTransparency = 0.2
    container.BorderSizePixel = 0
    container.ZIndex = 4
    container.Parent = playersFrame
    addCorner(container, 10)
    
    local checkbox = Instance.new(Frame)
    checkbox.Size = UDim2.new(0, 22, 0, 22)
    checkbox.Position = UDim2.new(0, 12, 0.5, -11)
    checkbox.BackgroundColor3 = Colors.Tertiary
    checkbox.BorderSizePixel = 0
    checkbox.ZIndex = 5
    checkbox.Parent = container
    addCorner(checkbox, 7)
    addStroke(checkbox, Colors.Border, 1.5, 0.2)
    
    local checkmark = Instance.new(TextLabel)
    checkmark.Text = 
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.TextColor3 = Colors.Text
    checkmark.Font = Enum.Font.GothamBold
    checkmark.TextSize = 14
    checkmark.ZIndex = 6
    checkmark.Parent = checkbox
    
    local avatarHolder = Instance.new(Frame)
    avatarHolder.Size = UDim2.new(0, 30, 0, 30)
    avatarHolder.Position = UDim2.new(0, 42, 0.5, -15)
    avatarHolder.BackgroundColor3 = Colors.Tertiary
    avatarHolder.ZIndex = 5
    avatarHolder.Parent = container
    addCorner(avatarHolder, 15)
    addStroke(avatarHolder, Colors.Border, 1, 0.4)
    
    local avatar = Instance.new(ImageLabel)
    avatar.Size = UDim2.new(1, -2, 1, -2)
    avatar.Position = UDim2.new(0, 1, 0, 1)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 6
    avatar.Parent = avatarHolder
    addCorner(avatar, 14)
    
    task.spawn(function()
        local success, result = pcall(function()
            return game.PlayersGetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if success and avatar and avatar.Parent then
            avatar.Image = result
        end
    end)
    
    local nameContainer = Instance.new(Frame)
    nameContainer.Size = UDim2.new(1, -90, 1, 0)
    nameContainer.Position = UDim2.new(0, 80, 0, 0)
    nameContainer.BackgroundTransparency = 1
    nameContainer.ZIndex = 5
    nameContainer.Parent = container
    
    local nameLabel = Instance.new(TextLabel)
    nameLabel.Text = player.DisplayName
    nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Colors.Text
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 6
    nameLabel.Parent = nameContainer
    
    local usernameLabel = Instance.new(TextLabel)
    usernameLabel.Text = @ .. player.Name
    usernameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    usernameLabel.Position = UDim2.new(0, 0, 0.5, 2)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.TextColor3 = Colors.TextMuted
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextSize = 10
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    usernameLabel.ZIndex = 6
    usernameLabel.Parent = nameContainer
    
    local clickBtn = Instance.new(TextButton)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = 
    clickBtn.ZIndex = 7
    clickBtn.Parent = container
    
    local containerData = {button = container, baseColor = Colors.Secondary, isHovered = false}
    table.insert(syncedButtons, containerData)
    
    local function updateVisual()
        if selectedPlayers[player] then
            TweenServiceCreate(container, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Selected, BackgroundTransparency = 0.1})Play()
            TweenServiceCreate(checkbox, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Checkbox})Play()
            checkboxFindFirstChildOfClass(UIStroke).Color = Colors.Checkbox
            checkboxFindFirstChildOfClass(UIStroke).Transparency = 0
            checkmark.Text = ✓
            containerData.baseColor = Colors.Selected
        else
            TweenServiceCreate(container, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Secondary, BackgroundTransparency = 0.2})Play()
            TweenServiceCreate(checkbox, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Tertiary})Play()
            checkboxFindFirstChildOfClass(UIStroke).Color = Colors.Border
            checkboxFindFirstChildOfClass(UIStroke).Transparency = 0.2
            checkmark.Text = 
            containerData.baseColor = Colors.Secondary
        end
    end
    
    clickBtn.MouseButton1ClickConnect(function()
        selectedPlayers[player] = not selectedPlayers[player] or nil
        updateVisual()
        updateStatusLabel()
    end)
    
    clickBtn.MouseEnterConnect(function()
        containerData.isHovered = true
    end)
    
    clickBtn.MouseLeaveConnect(function()
        containerData.isHovered = false
        if selectedPlayers[player] then
            TweenServiceCreate(container, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Selected})Play()
        else
            TweenServiceCreate(container, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary})Play()
        end
    end)
    
    playerElements[player] = container
    
    task.defer(function()
        playersFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
end

local function removePlayerElement(player)
    selectedPlayers[player] = nil
    if playerElements[player] then
        for i, data in ipairs(syncedButtons) do
            if data.button == playerElements[player] then
                table.remove(syncedButtons, i)
                break
            end
        end
        playerElements[player]Destroy()
        playerElements[player] = nil
    end
    updateStatusLabel()
    updateOnlineCount()
    task.defer(function()
        playersFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
end

local function initPlayerList()
    for _, player in pairs(game.PlayersGetPlayers()) do
        createPlayerElement(player)
    end
    updateOnlineCount()
    updateStatusLabel()
end

game.Players.PlayerAddedConnect(function(player)
    task.wait(0.5)
    createPlayerElement(player)
    updateOnlineCount()
end)

game.Players.PlayerRemovingConnect(function(player)
    removePlayerElement(player)
end)

-- Action buttons
local actionBtns = Instance.new(Frame)
actionBtns.Size = UDim2.new(1, 0, 0, 38)
actionBtns.Position = UDim2.new(0, 0, 0, 298)
actionBtns.BackgroundTransparency = 1
actionBtns.ZIndex = 2
actionBtns.Parent = content

local selectAllBtn = Instance.new(TextButton)
selectAllBtn.Text = Select All
selectAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
selectAllBtn.BackgroundColor3 = Colors.Tertiary
selectAllBtn.BackgroundTransparency = 0.1
selectAllBtn.TextColor3 = Colors.Text
selectAllBtn.Font = Enum.Font.GothamBold
selectAllBtn.TextSize = 12
selectAllBtn.ZIndex = 2
selectAllBtn.Parent = actionBtns
addCorner(selectAllBtn, 10)
addStroke(selectAllBtn, Colors.Border, 1, 0.4)
addSyncedHoverEffect(selectAllBtn, Colors.Tertiary)

selectAllBtn.MouseButton1ClickConnect(function()
    for player, element in pairs(playerElements) do
        selectedPlayers[player] = true
        local checkbox = elementFindFirstChild(Frame)
        if checkbox then
            TweenServiceCreate(element, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Selected, BackgroundTransparency = 0.1})Play()
            TweenServiceCreate(checkbox, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Checkbox})Play()
            local stroke = checkboxFindFirstChildOfClass(UIStroke)
            if stroke then stroke.Color = Colors.Checkbox stroke.Transparency = 0 end
            local check = checkboxFindFirstChildOfClass(TextLabel)
            if check then check.Text = ✓ end
        end
        for _, data in ipairs(syncedButtons) do
            if data.button == element then
                data.baseColor = Colors.Selected
                break
            end
        end
    end
    updateStatusLabel()
end)

local clearBtn = Instance.new(TextButton)
clearBtn.Text = Clear All
clearBtn.Size = UDim2.new(0.48, 0, 1, 0)
clearBtn.Position = UDim2.new(0.52, 0, 0, 0)
clearBtn.BackgroundColor3 = Colors.Tertiary
clearBtn.BackgroundTransparency = 0.1
clearBtn.TextColor3 = Colors.Text
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 12
clearBtn.ZIndex = 2
clearBtn.Parent = actionBtns
addCorner(clearBtn, 10)
addStroke(clearBtn, Colors.Border, 1, 0.4)
addSyncedHoverEffect(clearBtn, Colors.Tertiary)

clearBtn.MouseButton1ClickConnect(function()
    for player, element in pairs(playerElements) do
        selectedPlayers[player] = nil
        local checkbox = elementFindFirstChild(Frame)
        if checkbox then
            TweenServiceCreate(element, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Secondary, BackgroundTransparency = 0.2})Play()
            TweenServiceCreate(checkbox, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Tertiary})Play()
            local stroke = checkboxFindFirstChildOfClass(UIStroke)
            if stroke then stroke.Color = Colors.Border stroke.Transparency = 0.2 end
            local check = checkboxFindFirstChildOfClass(TextLabel)
            if check then check.Text =  end
        end
        for _, data in ipairs(syncedButtons) do
            if data.button == element then
                data.baseColor = Colors.Secondary
                break
            end
        end
    end
    updateStatusLabel()
end)

-- Toggle button
local spamActive = false
local spamThreads = {}

local toggleBtn = Instance.new(TextButton)
toggleBtn.Text = ⚡️ START
toggleBtn.Size = UDim2.new(1, 0, 0, 52)
toggleBtn.Position = UDim2.new(0, 0, 0, 344)
toggleBtn.BackgroundColor3 = Colors.Danger
toggleBtn.BackgroundTransparency = 0.05
toggleBtn.TextColor3 = Colors.Text
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 16
toggleBtn.ZIndex = 2
toggleBtn.Parent = content
addCorner(toggleBtn, 14)

local toggleStroke = addStroke(toggleBtn, Colors.Danger, 2, 0.2)

local toggleGlow = Instance.new(Frame)
toggleGlow.Size = UDim2.new(1, 4, 1, 4)
toggleGlow.Position = UDim2.new(0, -2, 0, -2)
toggleGlow.BackgroundTransparency = 1
toggleGlow.ZIndex = 1
toggleGlow.Parent = toggleBtn

local toggleGlowStroke = Instance.new(UIStroke)
toggleGlowStroke.Color = Colors.Danger
toggleGlowStroke.Thickness = 3
toggleGlowStroke.Transparency = 0.6
toggleGlowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
toggleGlowStroke.Parent = toggleGlow
addCorner(toggleGlow, 16)

-- Attack
local function attackPlayer(player)
    if not player or not player.Character then return end
    local wHrp = player.CharacterFindFirstChild(HumanoidRootPart)
    if not wHrp then return end
    
    local pos = wHrp.Position
    local dir = (pos - hrp.Position).Unit
    
    fxFireServer(tool, false)
    
    local fireArgs = {
        [Direction] = dir,
        [Settings] = {[expShake] = {[fadeInTime] = 0.05, [magnitude] = 3, [rotInfluence] = Vector3.new(0.4, 0, 0.4), [fadeOutTime] = 0.5, [posInfluence] = Vector3.new(1, 1, 0), [roughness] = 3}, [gravity] = Vector3.new(0, -20, 0), [HelicopterDamage] = 450, [FireRate] = 15, [VehicleDamage] = 350, [ExpName] = RPG, [RocketAmount] = 1, [ExpRadius] = 12, [BoatDamage] = 300, [TankDamage] = 300, [Acceleration] = 8, [ShieldDamage] = 170, [Distance] = 4000, [PlaneDamage] = 500, [GunshipDamage] = 170, [velocity] = 200, [ExplosionDamage] = 120},
        [Origin] = hrp.Position, [PlrFired] = plr, [Vehicle] = tool,
        [RocketModel] = game.ReplicatedStorage.RocketSystem.Rockets[RPG Rocket], [Weapon] = tool,
    }
    
    pcall(function() fireFireServer(fireArgs) end)
    
    local hitArgs = {[Normal] = Vector3.new(0, 1, 0), [HitPart] = wHrp, [Position] = pos, [Label] = plr.Name .. Rocket .. cnt, [Vehicle] = tool, [Player] = plr, [Weapon] = tool}
    pcall(function() hitFireServer(hitArgs) end)
    cnt = cnt + 1
end

-- Toggle
toggleBtn.MouseButton1ClickConnect(function()
    spamActive = not spamActive
    
    if spamActive then
        local count = 0
        for _ in pairs(selectedPlayers) do count = count + 1 end
        
        if count == 0 then
            statusLabel.Text = ❌ Select targets first!
            statusLabel.TextColor3 = Colors.Danger
            spamActive = false
            return
        end
        
        toggleBtn.Text = ⏹️ STOP
        TweenServiceCreate(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3 = Colors.Success})Play()
        TweenServiceCreate(toggleStroke, TweenInfo.new(0.25), {Color = Colors.Success})Play()
        TweenServiceCreate(toggleGlowStroke, TweenInfo.new(0.25), {Color = Colors.Success, Transparency = 0.4})Play()
        statusLabel.Text = 🔥 Active —  .. count ..  target .. (count  1 and s or )
        statusLabel.TextColor3 = Colors.Success
        
        spamThreads[main] = task.spawn(function()
            while spamActive do
                for player in pairs(selectedPlayers) do
                    if player and player.Character then
                        for i = 1, 3 do task.spawn(attackPlayer, player) end
                    end
                end
                task.wait(0.05)
            end
        end)
        
        for i = 1, 3 do
            spamThreads[t .. i] = task.spawn(function()
                while spamActive do
                    for player in pairs(selectedPlayers) do
                        if player and player.Character then task.spawn(attackPlayer, player) end
                    end
                    task.wait(0.03)
                end
            end)
        end
    else
        toggleBtn.Text = ⚡️ START
        TweenServiceCreate(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3 = Colors.Danger})Play()
        TweenServiceCreate(toggleStroke, TweenInfo.new(0.25), {Color = Colors.Danger})Play()
        TweenServiceCreate(toggleGlowStroke, TweenInfo.new(0.25), {Color = Colors.Danger, Transparency = 0.6})Play()
        statusLabel.Text = 💤 Stopped
        statusLabel.TextColor3 = Colors.TextDim
        
        for _, thread in pairs(spamThreads) do pcall(task.cancel, thread) end
        spamThreads = {}
    end
end)

-- Close
closeBtn.MouseButton1ClickConnect(function()
    spamActive = false
    for _, thread in pairs(spamThreads) do pcall(task.cancel, thread) end
    if animationConnection then animationConnectionDisconnect() end
    
    TweenServiceCreate(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })Play()
    TweenServiceCreate(outerGlowStroke, TweenInfo.new(0.2), {Transparency = 1})Play()
    task.wait(0.3)
    screenGuiDestroy()
end)

-- Minimize
local isMinimized = false
local originalSize = frame.Size

minimizeBtn.MouseButton1ClickConnect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        TweenServiceCreate(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 360, 0, 60)})Play()
        minimizeBtn.Text = +
        content.Visible = false
    else
        TweenServiceCreate(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = originalSize})Play()
        minimizeBtn.Text = −
        task.wait(0.15)
        content.Visible = true
    end
end)

-- Respawn
plr.CharacterAddedConnect(function(newChar)
    char = newChar
    hrp = newCharWaitForChild(HumanoidRootPart)
    tool = newCharWaitForChild(RPG, 5)
    if not tool then
        local backpack = plrFindFirstChild(Backpack)
        if backpack then tool = backpackFindFirstChild(RPG) end
    end
end)

initPlayerList()

print(✅ RPG Spammer Pro loaded)
