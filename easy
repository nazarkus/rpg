local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local tool = char:WaitForChild("RPG")
local ev = game.ReplicatedStorage.RocketSystem.Events
local fx = ev.RocketReloadedFX
local fire = ev.FireRocket
local hit = ev.RocketHit
local cnt = 0

-- Create GUI (persistent on death)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPGSpammerGUI"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false -- GUI WON'T DISAPPEAR ON DEATH

-- Main frame with dragging
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 450) -- Increased width
frame.Position = UDim2.new(0.5, -175, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(80, 80, 80)
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

-- Title
local title = Instance.new("TextLabel")
title.Text = "RPG Spammer v3.0 - Multi Select"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- List of selected players (for multi-select)
local selectedPlayers = {}
local selectedButtons = {}

-- Frame for player list with checkboxes
local playersFrame = Instance.new("ScrollingFrame")
playersFrame.Size = UDim2.new(1, -10, 0, 250)
playersFrame.Position = UDim2.new(0, 5, 0, 50)
playersFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playersFrame.ScrollBarThickness = 5
playersFrame.Parent = frame

-- Function to update player list with checkboxes
local function updatePlayerList()
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yPos = 0
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr then
            -- Create container for checkbox and name
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, -10, 0, 40)
            container.Position = UDim2.new(0, 5, 0, yPos)
            container.BackgroundTransparency = 1
            container.Parent = playersFrame
            
            -- Checkbox
            local checkbox = Instance.new("TextButton")
            checkbox.Name = "Checkbox"
            checkbox.Size = UDim2.new(0, 30, 0, 30)
            checkbox.Position = UDim2.new(0, 0, 0.5, -15)
            checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            checkbox.Text = selectedPlayers[player] and "✓" or ""
            checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
            checkbox.Font = Enum.Font.SourceSansBold
            checkbox.TextSize = 20
            checkbox.Parent = container
            
            -- Player name
            local nameLabel = Instance.new("TextButton")
            nameLabel.Text = player.Name
            nameLabel.Size = UDim2.new(1, -40, 1, 0)
            nameLabel.Position = UDim2.new(0, 35, 0, 0)
            nameLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextSize = 16
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = container
            
            -- Function to toggle selection
            local function togglePlayerSelection()
                if selectedPlayers[player] then
                    -- Remove from selection
                    selectedPlayers[player] = nil
                    checkbox.Text = ""
                    checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    nameLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                else
                    -- Add to selection
                    selectedPlayers[player] = true
                    checkbox.Text = "✓"
                    checkbox.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
                end
                
                -- Update status
                updateStatusLabel()
            end
            
            checkbox.MouseButton1Click:Connect(togglePlayerSelection)
            nameLabel.MouseButton1Click:Connect(togglePlayerSelection)
            
            -- Restore state if player already selected
            if selectedPlayers[player] then
                checkbox.Text = "✓"
                checkbox.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                nameLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
            end
            
            yPos = yPos + 45
            selectedButtons[player] = container
        end
    end
    
    playersFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Quick selection buttons
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(1, -10, 0, 40)
buttonsFrame.Position = UDim2.new(0, 5, 0, 310)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = frame

-- Select all
local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Text = "✅ SELECT ALL"
selectAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllBtn.Font = Enum.Font.SourceSansBold
selectAllBtn.TextSize = 14
selectAllBtn.Parent = buttonsFrame

selectAllBtn.MouseButton1Click:Connect(function()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr then
            selectedPlayers[player] = true
        end
    end
    updatePlayerList()
    updateStatusLabel()
end)

-- Clear selection
local clearBtn = Instance.new("TextButton")
clearBtn.Text = "🗑️ CLEAR"
clearBtn.Size = UDim2.new(0.48, 0, 1, 0)
clearBtn.Position = UDim2.new(0.52, 0, 0, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.SourceSansBold
clearBtn.TextSize = 14
clearBtn.Parent = buttonsFrame

clearBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    updatePlayerList()
    updateStatusLabel()
end)

-- Refresh list button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Text = "🔄 REFRESH LIST"
refreshBtn.Size = UDim2.new(1, -10, 0, 35)
refreshBtn.Position = UDim2.new(0, 5, 0, 355)
refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 150)
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.TextSize = 16
refreshBtn.Parent = frame

refreshBtn.MouseButton1Click:Connect(updatePlayerList)

-- Selection status
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 0, 400)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Parent = frame

-- Function to update status
local function updateStatusLabel()
    local selectedCount = 0
    for _ in pairs(selectedPlayers) do
        selectedCount = selectedCount + 1
    end
    
    if selectedCount == 0 then
        statusLabel.Text = "❌ No targets selected"
    else
        statusLabel.Text = "✅ Targets selected: " .. selectedCount
    end
end

-- Spam start/stop button
local spamActive = false
local spamThreads = {}

local toggleBtn = Instance.new("TextButton")
toggleBtn.Text = "▶️ START SPAM"
toggleBtn.Size = UDim2.new(1, -10, 0, 40)
toggleBtn.Position = UDim2.new(0, 5, 0, 430)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18
toggleBtn.Parent = frame

-- Function to attack specific player
local function attackPlayer(player)
    if not player or not player.Character then return end
    local wHrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not wHrp then return end
    
    local pos = wHrp.Position
    local dir = (pos - hrp.Position).Unit
    
    -- Fire FX only (rocket visual effect)
    fx:FireServer(tool, true)
    
    -- REMOVED FIRE INVOKE SERVER LINE HERE
    
    hit:FireServer(
        Vector3.new(pos.X, pos.Y, pos.Z),
        Vector3.new(dir.X, dir.Y, dir.Z),
        tool,
        tool,
        wHrp,
        nil,
        plr.Name .. "Rocket" .. cnt
    )
    
    cnt = cnt + 1
end

-- Function to attack ALL selected players
local function attackAllSelected()
    for player, _ in pairs(selectedPlayers) do
        attackPlayer(player)
    end
end

-- Spam toggle
toggleBtn.MouseButton1Click:Connect(function()
    spamActive = not spamActive
    
    if spamActive then
        local selectedCount = 0
        for _ in pairs(selectedPlayers) do
            selectedCount = selectedCount + 1
        end
        
        if selectedCount == 0 then
            statusLabel.Text = "❌ ERROR: No targets selected!"
            spamActive = false
            return
        end
        
        toggleBtn.Text = "⏹️ STOP SPAM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusLabel.Text = "🔥 SPAM ACTIVE! Targets: " .. selectedCount
        
        -- Start spam thread for ALL selected players
        spamThreads["main"] = task.spawn(function()
            while spamActive do
                -- Attack all selected players
                for player, _ in pairs(selectedPlayers) do
                    if player and player.Character then
                        -- Multi-attack: 3 shots per player per cycle
                        for i = 1, 3 do
                            task.spawn(function()
                                attackPlayer(player)
                            end)
                        end
                    end
                end
                task.wait(0.05) -- High speed
            end
        end)
        
        -- Additional threads for more speed
        for i = 1, 3 do
            spamThreads["extra_" .. i] = task.spawn(function()
                while spamActive do
                    for player, _ in pairs(selectedPlayers) do
                        if player and player.Character then
                            task.spawn(function()
                                attackPlayer(player)
                            end)
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
        
    else
        toggleBtn.Text = "▶️ START SPAM"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "💤 Spam stopped"
        
        -- Stop all threads
        for name, thread in pairs(spamThreads) do
            task.cancel(thread)
        end
        spamThreads = {}
    end
end)

-- Quick shot button (all selected)
local quickBtn = Instance.new("TextButton")
quickBtn.Text = "🔥 SINGLE BURST"
quickBtn.Size = UDim2.new(1, -10, 0, 30)
quickBtn.Position = UDim2.new(0, 5, 0, 395)
quickBtn.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
quickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
quickBtn.Font = Enum.Font.SourceSansBold
quickBtn.TextSize = 14
quickBtn.Parent = frame

quickBtn.MouseButton1Click:Connect(function()
    local selectedCount = 0
    for _ in pairs(selectedPlayers) do
        selectedCount = selectedCount + 1
    end
    
    if selectedCount == 0 then
        statusLabel.Text = "❌ Select targets first!"
        return
    end
    
    -- Single burst at all selected
    for player, _ in pairs(selectedPlayers) do
        task.spawn(function()
            attackPlayer(player)
        end)
    end
    
    statusLabel.Text = "💥 Burst at " .. selectedCount .. " targets!"
end)

-- Initialize
updatePlayerList()
updateStatusLabel()

-- Update list on player join/leave
game.Players.PlayerAdded:Connect(function(player)
    task.wait(1) -- Wait for initialization
    updatePlayerList()
    updateStatusLabel()
end)

game.Players.PlayerRemoving:Connect(function(player)
    -- Remove player from selection if they leave
    selectedPlayers[player] = nil
    task.wait(0.5)
    updatePlayerList()
    updateStatusLabel()
end)

-- GUI control buttons
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✖"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.Parent = frame

closeBtn.MouseButton1Click:Connect(function()
    -- Stop spam before closing
    spamActive = false
    for name, thread in pairs(spamThreads) do
        task.cancel(thread)
    end
    screenGui:Destroy()
end)

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Text = "─"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.Parent = frame

local isMinimized = false
local originalSize = frame.Size
local minimizedSize = UDim2.new(0, 350, 0, 40)

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        frame.Size = minimizedSize
        minimizeBtn.Text = "□"
        title.Text = "RPG Spammer (minimized)"
        
        -- Hide all elements except title and buttons
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= title and child ~= closeBtn and child ~= minimizeBtn then
                child.Visible = false
            end
        end
    else
        frame.Size = originalSize
        minimizeBtn.Text = "─"
        title.Text = "RPG Spammer v3.0 - Multi Select"
        
        -- Show all elements
        for _, child in ipairs(frame:GetChildren()) do
            child.Visible = true
        end
    end
end)

-- Auto update on respawn
plr.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    tool = newChar:WaitForChild("RPG")
    
    -- Check if tool exists, if not - search in backpack
    if not tool then
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then
            tool = backpack:FindFirstChild("RPG")
        end
    end
end)

print("✅ RPG Spammer v3.0 with multi-select loaded!")
print("🎯 Features:")
print("   • Multi-select players")
print("   • Shoot at all selected")
print("   • GUI persistent on death")
print("   • Select All / Clear buttons")
