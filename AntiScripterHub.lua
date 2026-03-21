-- AntiScripter (versão atualizada: limites de WalkSpeed/JumpHeight removidos)
-- Correções: anti-fling R15 (restauração robusta), detector refinado, cam bypass reforçado.
-- Removidos limites máximos para WalkSpeed e JumpHeight/JumpPower (aplicados apenas limites inferiores).

task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = workspace

    local player = Players.LocalPlayer
    if not player then
        repeat task.wait() player = Players.LocalPlayer until player
    end

    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    local OWNER_USERID = player.UserId
    local PLACE_KEY = tostring(game.PlaceId)

    local function onlyOwner()
        return Players.LocalPlayer and Players.LocalPlayer.UserId == OWNER_USERID
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AntiScripterGUI_" .. tostring(OWNER_USERID)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    gui.DisplayOrder = 2147483647

    gui:GetPropertyChangedSignal("Parent"):Connect(function()
        if gui.Parent ~= playerGui then
            pcall(function() gui.Parent = playerGui end)
        end
    end)
    gui.AncestryChanged:Connect(function()
        if not gui:IsDescendantOf(playerGui) then
            pcall(function() gui.Parent = playerGui end)
        end
    end)

    do
        local heartbeatConn
        heartbeatConn = RunService.Heartbeat:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr:FindFirstChild("PlayerGui") then
                    local otherGui = plr.PlayerGui:FindFirstChild(gui.Name)
                    if otherGui then
                        pcall(function() otherGui:Destroy() end)
                    end
                end
            end
        end)
    end

    -- touch triple to destroy gui
    local touchCount = 0
    local lastTouchTime = 0
    local TOUCH_TRIPLE_RESET = 1.2

    UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
        if processedByUI then return end

        local currentTime = tick()

        if currentTime - lastTouchTime > TOUCH_TRIPLE_RESET then
            touchCount = 1
        else
            touchCount = touchCount + 1
        end

        lastTouchTime = currentTime

        if touchCount >= 3 then
            if onlyOwner() then
                pcall(function()
                    gui:Destroy()
                    touchCount = 0
                end)
            end
        end

        task.delay(TOUCH_TRIPLE_RESET, function()
            if tick() - lastTouchTime >= TOUCH_TRIPLE_RESET then
                touchCount = 0
            end
        end)
    end)

    local function secureConnect(button, fn)
        button.MouseButton1Click:Connect(function(...)
            if not onlyOwner() then return end
            pcall(fn, ...)
        end)
    end

    -- UI (estrutura mantida)
    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(0, 50, 0, 50)
    local savedX = player:GetAttribute("BotaoPosX") or 40
    local savedY = player:GetAttribute("BotaoPosY") or 40
    mainBtn.Position = UDim2.new(0, savedX, 0, savedY)
    mainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainBtn.Text = "🛠"
    mainBtn.TextSize = 32
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextColor3 = Color3.new(1,1,1)
    mainBtn.ZIndex = 10000
    mainBtn.Parent = gui
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 18)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 3
    mainStroke.Color = Color3.fromRGB(15, 15, 15)
    mainStroke.Transparency = 0
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.LineJoinMode = Enum.LineJoinMode.Round
    mainStroke.Parent = mainBtn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 350)
    frame.Position = UDim2.new(0.5, -250, 0.5, -175)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Visible = false
    frame.ZIndex = 9998
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34)
    closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 22
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 9999
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    secureConnect(closeBtn, function() frame.Visible = false end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "ANTI SCRIPTER"
    title.TextColor3 = Color3.fromRGB(255, 220, 80)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -55)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = frame

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.CellSize = UDim2.new(0, 215, 0, 45)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.Parent = content

    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 30)
    end)

    local teleportFrame = Instance.new("Frame")
    teleportFrame.Size = UDim2.new(1, -20, 1, -50)
    teleportFrame.Position = UDim2.new(0, 10, 0, 40)
    teleportFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    teleportFrame.Visible = false
    teleportFrame.Parent = frame
    Instance.new("UICorner", teleportFrame).CornerRadius = UDim.new(0, 10)

    local tpTitle = Instance.new("TextLabel")
    tpTitle.Size = UDim2.new(1,0,0,35)
    tpTitle.BackgroundTransparency = 1
    tpTitle.Text = "Selecione um jogador para teleportar"
    tpTitle.TextColor3 = Color3.fromRGB(200, 180, 255)
    tpTitle.TextSize = 16
    tpTitle.Font = Enum.Font.GothamSemibold
    tpTitle.Parent = teleportFrame

    local tpScroll = Instance.new("ScrollingFrame")
    tpScroll.Size = UDim2.new(1, -20, 1, -80)
    tpScroll.Position = UDim2.new(0, 10, 0, 40)
    tpScroll.BackgroundTransparency = 1
    tpScroll.ScrollBarThickness = 5
    tpScroll.CanvasSize = UDim2.new(0,0,0,0)
    tpScroll.Parent = teleportFrame

    local tpListLayout = Instance.new("UIListLayout")
    tpListLayout.Padding = UDim.new(0, 6)
    tpListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tpListLayout.Parent = tpScroll

    tpListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tpScroll.CanvasSize = UDim2.new(0, 0, 0, tpListLayout.AbsoluteContentSize.Y + 20)
    end)

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 100, 0, 30)
    backBtn.Position = UDim2.new(0.5, -50, 1, -35)
    backBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    backBtn.Text = "Voltar"
    backBtn.TextColor3 = Color3.new(1,1,1)
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 15
    backBtn.Parent = teleportFrame
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0,8)
    secureConnect(backBtn, function()
        teleportFrame.Visible = false
        content.Visible = true
    end)

    local function makeBtn(text)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 15
        b.Font = Enum.Font.GothamSemibold
        b.Parent = content
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local noclipBtn = makeBtn("NOCLIP OFF")
    local antiFlingBtn = makeBtn("ANTI-FLING OFF")
    local detectorBtn = makeBtn("DETECTOR OFF")
    local highlightBtn = makeBtn("HIGHLIGHT OFF")
    local camBypassBtn = makeBtn("CAM BYPASS OFF")

    local flyBtn = makeBtn("FLY OFF")
    local teleportBtn = makeBtn("TELEPORT → PLAYER")
    teleportBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)

    local walkJumpBtn = makeBtn("WALK/JUMP")
    walkJumpBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)

    local walkJumpFrame = Instance.new("Frame")
    walkJumpFrame.Size = UDim2.new(1, -20, 1, -50)
    walkJumpFrame.Position = UDim2.new(0, 10, 0, 40)
    walkJumpFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    walkJumpFrame.Visible = false
    walkJumpFrame.Parent = frame
    Instance.new("UICorner", walkJumpFrame).CornerRadius = UDim.new(0, 10)

    local wjTitle = Instance.new("TextLabel")
    wjTitle.Size = UDim2.new(1,0,0,40)
    wjTitle.BackgroundTransparency = 1
    wjTitle.Text = "WALK / JUMP SETTINGS"
    wjTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
    wjTitle.TextSize = 18
    wjTitle.Font = Enum.Font.GothamBold
    wjTitle.Parent = walkJumpFrame

    local wsContainer = Instance.new("Frame")
    wsContainer.Size = UDim2.new(0.9, 0, 0, 40)
    wsContainer.Position = UDim2.new(0.05, 0, 0, 55)
    wsContainer.BackgroundTransparency = 1
    wsContainer.Parent = walkJumpFrame

    local wsLabel = Instance.new("TextLabel")
    wsLabel.Size = UDim2.new(0.35, 0, 1, 0)
    wsLabel.BackgroundTransparency = 1
    wsLabel.Text = "WalkSpeed:"
    wsLabel.TextColor3 = Color3.new(1,1,1)
    wsLabel.TextSize = 14
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.TextXAlignment = Enum.TextXAlignment.Left
    wsLabel.Parent = wsContainer

    local wsBox = Instance.new("TextBox")
    wsBox.Size = UDim2.new(0.62, 0, 1, 0)
    wsBox.Position = UDim2.new(0.36, 0, 0, 0)
    wsBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    wsBox.Text = "16"
    wsBox.TextColor3 = Color3.new(1,1,1)
    wsBox.TextSize = 14
    wsBox.Font = Enum.Font.Gotham
    wsBox.Parent = wsContainer
    Instance.new("UICorner", wsBox).CornerRadius = UDim.new(0, 6)

    local jhContainer = Instance.new("Frame")
    jhContainer.Size = UDim2.new(0.9, 0, 0, 40)
    jhContainer.Position = UDim2.new(0.05, 0, 0, 105)
    jhContainer.BackgroundTransparency = 1
    jhContainer.Parent = walkJumpFrame

    local jhLabel = Instance.new("TextLabel")
    jhLabel.Size = UDim2.new(0.35, 0, 1, 0)
    jhLabel.BackgroundTransparency = 1
    jhLabel.Text = "JumpHeight:"
    jhLabel.TextColor3 = Color3.new(1,1,1)
    jhLabel.TextSize = 14
    jhLabel.Font = Enum.Font.Gotham
    jhLabel.TextXAlignment = Enum.TextXAlignment.Left
    jhLabel.Parent = jhContainer

    local jhBox = Instance.new("TextBox")
    jhBox.Size = UDim2.new(0.62, 0, 1, 0)
    jhBox.Position = UDim2.new(0.36, 0, 0, 0)
    jhBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    jhBox.Text = "7.2"
    jhBox.TextColor3 = Color3.new(1,1,1)
    jhBox.TextSize = 14
    jhBox.Font = Enum.Font.Gotham
    jhBox.Parent = jhContainer
    Instance.new("UICorner", jhBox).CornerRadius = UDim.new(0, 6)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.6, 0, 0, 40)
    applyBtn.Position = UDim2.new(0.2, 0, 0, 170)
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    applyBtn.Text = "APLICAR"
    applyBtn.TextColor3 = Color3.new(1,1,1)
    applyBtn.TextSize = 18
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.Parent = walkJumpFrame
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 8)

    local bypassBtnWJ = Instance.new("TextButton")
    bypassBtnWJ.Size = UDim2.new(0.28, 0, 0, 35)
    bypassBtnWJ.Position = UDim2.new(0.2, 0, 0, 220)
    bypassBtnWJ.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    bypassBtnWJ.Text = "BYPASS OFF"
    bypassBtnWJ.TextColor3 = Color3.new(1,1,1)
    bypassBtnWJ.TextSize = 15
    bypassBtnWJ.Font = Enum.Font.GothamBold
    bypassBtnWJ.Parent = walkJumpFrame
    Instance.new("UICorner", bypassBtnWJ).CornerRadius = UDim.new(0, 8)

    local velocityBtnWJ = Instance.new("TextButton")
    velocityBtnWJ.Size = UDim2.new(0.28, 0, 0, 35)
    velocityBtnWJ.Position = UDim2.new(0.52, 0, 0, 220)
    velocityBtnWJ.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    velocityBtnWJ.Text = "VELOCITY OFF"
    velocityBtnWJ.TextColor3 = Color3.new(1,1,1)
    velocityBtnWJ.TextSize = 15
    velocityBtnWJ.Font = Enum.Font.GothamBold
    velocityBtnWJ.Parent = walkJumpFrame
    Instance.new("UICorner", velocityBtnWJ).CornerRadius = UDim.new(0, 8)

    local resetBtnWJ = Instance.new("TextButton")
    resetBtnWJ.Size = UDim2.new(0.6, 0, 0, 35)
    resetBtnWJ.Position = UDim2.new(0.2, 0, 0, 265)
    resetBtnWJ.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    resetBtnWJ.Text = "RESETAR"
    resetBtnWJ.TextColor3 = Color3.new(1,1,1)
    resetBtnWJ.TextSize = 15
    resetBtnWJ.Font = Enum.Font.GothamBold
    resetBtnWJ.Parent = walkJumpFrame
    Instance.new("UICorner", resetBtnWJ).CornerRadius = UDim.new(0, 8)

    local backBtnWJ = Instance.new("TextButton")
    backBtnWJ.Size = UDim2.new(0, 34, 0, 34)
    backBtnWJ.Position = UDim2.new(1, -38, 0, 4)
    backBtnWJ.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    backBtnWJ.Text = "←"
    backBtnWJ.TextColor3 = Color3.new(1,1,1)
    backBtnWJ.TextSize = 24
    backBtnWJ.Font = Enum.Font.GothamBold
    backBtnWJ.ZIndex = 9999
    backBtnWJ.Parent = walkJumpFrame
    Instance.new("UICorner", backBtnWJ).CornerRadius = UDim.new(0, 8)
    secureConnect(backBtnWJ, function()
        walkJumpFrame.Visible = false
        content.Visible = true
    end)

    -- state variables
    local noclipActive = false
    local antiFlingActive = false
    local detectorActive = false
    local highlightActive = false
    local camBypassActive = false
    local bypassActive = true
    local velocityActive = false
    local flying = false

    local noclipConn = nil
    local antiFlingEnforcerConn = nil
    local movementEnforcerConn = nil
    local velocityConn = nil
    local velocityDeathConn = nil
    local camBypassConn = nil
    local antiRubberConn = nil

    local savedWalkSpeed = 16
    local savedJumpHeight = 7.2

    local FLIGHT_BASE_SPEED = 80

    local ownershipConn = nil

    local originalCameraMaxZoom = player.CameraMaxZoomDistance or 128
    local originalCameraMinZoom = player.CameraMinZoomDistance or 0.5

    local savedCanCollide = {}
    local originalHipHeight = nil

    local function maintainNetworkOwnership()
        if ownershipConn then ownershipConn:Disconnect() end
        ownershipConn = RunService.Heartbeat:Connect(function()
            if not onlyOwner() then return end
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                pcall(function()
                    root:SetNetworkOwner(player)
                end)
            end
        end)
    end

    local function stopNetworkOwnership()
        if ownershipConn then
            ownershipConn:Disconnect()
            ownershipConn = nil
        end
    end

    local function getSavedDefaultsForPlace()
        local wsAttr = player:GetAttribute("DefaultWS_" .. PLACE_KEY)
        local jhAttr = player:GetAttribute("DefaultJH_" .. PLACE_KEY)
        return tonumber(wsAttr), tonumber(jhAttr)
    end
    local function setSavedDefaultsForPlace(ws, jh)
        if type(ws) == "number" then player:SetAttribute("DefaultWS_" .. PLACE_KEY, ws) end
        if type(jh) == "number" then player:SetAttribute("DefaultJH_" .. PLACE_KEY, jh) end
    end

    local flingOffenders = {}
    local launchedPlayers = {}

    local ANGULAR_SPEED_LIMIT = 30

    local suspectTimers = {}

    local SUSPICIOUS_GUI_KEYWORDS = {
        "fluxus", "delta", "synapse", "krnl", "solara", "wave", "celery", "vega", "executor",
        "infyield", "iy", "dex", "darkdex", "synx", "scripthub", "console", "menu", "hub"
    }

    local function detectSuspiciousGUI(plr)
        if not plr or not plr:FindFirstChild("PlayerGui") then return nil end
        local playerGui = plr.PlayerGui
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if obj:IsA("GuiObject") then
                local nameLower = obj.Name:lower()
                if nameLower:find("antiscripter") or nameLower:find("anti scripter") then continue end
                for _, keyword in ipairs(SUSPICIOUS_GUI_KEYWORDS) do
                    if nameLower:find(keyword) then
                        return obj.Name
                    end
                end
            end
        end
        return nil
    end

    local function enforceMovementOnHumanoid(hum)
        if not hum then return end
        pcall(function()
            if not velocityActive then
                if type(savedWalkSpeed) == "number" and savedWalkSpeed > 0 then
                    -- removed upper clamp: allow any positive WalkSpeed
                    hum.WalkSpeed = math.max(savedWalkSpeed, 0)
                end
            end

            if type(savedJumpHeight) == "number" and savedJumpHeight >= 0 then
                local gravity = Workspace.Gravity or 196.2
                local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
                -- removed upper clamp on JumpPower/JumpHeight
                hum.JumpPower = jumpPower
                pcall(function() hum.JumpHeight = savedJumpHeight end)
            end
        end)
    end

    local function enforceMovement()
        if not onlyOwner() then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            enforceMovementOnHumanoid(hum)
        end)
    end

    local function startMovementEnforcer()
        if movementEnforcerConn then movementEnforcerConn:Disconnect() end
        movementEnforcerConn = RunService.Stepped:Connect(enforceMovement)
    end

    local function stopMovementEnforcer()
        if movementEnforcerConn then
            movementEnforcerConn:Disconnect()
            movementEnforcerConn = nil
        end
    end

    local humanoidWatchConnections = {}

    local function disconnectWatcherForHumanoid(hum)
        if not hum then return end
        local entry = humanoidWatchConnections[hum]
        if not entry then return end
        if entry.renderConn then entry.renderConn:Disconnect() end
        if entry.diedConn then entry.diedConn:Disconnect() end
        if entry.propConns then
            for _, c in ipairs(entry.propConns) do
                if c then c:Disconnect() end
            end
        end
        humanoidWatchConnections[hum] = nil
    end

    local function watchHumanoid(hum)
        if not hum or humanoidWatchConnections[hum] then return end

        local renderConn
        local propConns = {}
        local diedConn

        renderConn = RunService.RenderStepped:Connect(function()
            if bypassActive or not onlyOwner() then return end
            if not hum or hum.Health <= 0 then return end
            pcall(function()
                if not velocityActive then
                    if type(savedWalkSpeed) == "number" and savedWalkSpeed > 0 then
                        hum.WalkSpeed = math.max(savedWalkSpeed, 0)
                    end
                end
                if type(savedJumpHeight) == "number" and savedJumpHeight >= 0 then
                    local gravity = Workspace.Gravity or 196.2
                    local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
                    hum.JumpPower = jumpPower
                    pcall(function() hum.JumpHeight = savedJumpHeight end)
                end
            end)
        end)

        local function makePropWatcher(propName, applyFunc)
            local conn = hum:GetPropertyChangedSignal(propName):Connect(function()
                if bypassActive or not onlyOwner() then return end
                task.spawn(function()
                    for i = 1, 6 do
                        if bypassActive or not onlyOwner() then break end
                        if not hum or hum.Health <= 0 then break end
                        pcall(applyFunc)
                        task.wait(0.01)
                    end
                end)
            end)
            table.insert(propConns, conn)
        end

        makePropWatcher("WalkSpeed", function()
            if not velocityActive then
                hum.WalkSpeed = math.max(savedWalkSpeed, 0)
            end
        end)
        makePropWatcher("JumpPower", function()
            local gravity = Workspace.Gravity or 196.2
            local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
            hum.JumpPower = jumpPower
        end)
        makePropWatcher("JumpHeight", function()
            hum.JumpHeight = savedJumpHeight
        end)

        diedConn = hum.Died:Connect(function()
            disconnectWatcherForHumanoid(hum)
        end)

        humanoidWatchConnections[hum] = {renderConn = renderConn, propConns = propConns, diedConn = diedConn}
    end

    local function disconnectAllHumanoidWatchers()
        for hum, _ in pairs(humanoidWatchConnections) do
            disconnectWatcherForHumanoid(hum)
        end
    end

    local function enableEnforcement()
        if onlyOwner() then
            startMovementEnforcer()
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid") or player.Character:WaitForChild("Humanoid", 2)
                if hum then
                    watchHumanoid(hum)
                end
            end
        end
    end

    local function disableEnforcement()
        stopMovementEnforcer()
        disconnectAllHumanoidWatchers()
    end

    local function computeJumpHeightFromPower(jumpPower)
        local gravity = Workspace.Gravity or 196.2
        if type(jumpPower) ~= "number" or jumpPower <= 0 then return nil end
        return (jumpPower * jumpPower) / (2 * gravity)
    end

    local function captureGameDefaultsIfMissing()
        local savedWS, savedJH = getSavedDefaultsForPlace()
        if savedWS and savedJH then
            return savedWS, savedJH
        end

        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local detectedWS = hum.WalkSpeed or nil
            local detectedJH = nil
            if hum.JumpHeight and type(hum.JumpHeight) == "number" and hum.JumpHeight > 0 then
                detectedJH = hum.JumpHeight
            elseif hum.JumpPower and type(hum.JumpPower) == "number" and hum.JumpPower > 0 then
                detectedJH = computeJumpHeightFromPower(hum.JumpPower)
            end

            if detectedWS and detectedJH then
                setSavedDefaultsForPlace(detectedWS, detectedJH)
                return detectedWS, detectedJH
            end
        end

        setSavedDefaultsForPlace(savedWalkSpeed, savedJumpHeight)
        return savedWalkSpeed, savedJumpHeight
    end

    local flingOffenders = {}
    local launchedPlayers = {}

    local function updateAntiFling()
        if not onlyOwner() then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            root.CanCollide = not antiFlingActive

            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BodyMover") or obj:IsA("BodyForce") or obj:IsA("BodyVelocity")
                or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyGyro") or obj:IsA("VectorForce")
                or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("AlignPosition")
                or obj:IsA("AlignOrientation") then
                    if obj.Parent == root or obj.Parent == char or obj.Parent:IsDescendantOf(char) then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end)
    end

    local function findGroundY(fromPos, maxDistance)
        maxDistance = maxDistance or 20
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {player.Character}
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.IgnoreWater = true
        local result = Workspace:Raycast(fromPos, Vector3.new(0, -1, 0) * maxDistance, params)
        if result and result.Position then
            return result.Position.Y, result
        end
        return nil, nil
    end

    local function restoreAfterAntiFling()
        pcall(function()
            local char = player.Character
            if not char then return end

            if next(savedCanCollide) then
                for part, original in pairs(savedCanCollide) do
                    if part and part.Parent then
                        pcall(function() part.CanCollide = original end)
                    end
                end
            else
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end

            task.wait(0.06)

            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if root then
                pcall(function()
                    local ok, av = pcall(function() return root.AssemblyLinearVelocity end)
                    if ok and av then
                        root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(av.Y, -50, 50), 0)
                    else
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end)
            end

            if hum then
                pcall(function() hum.PlatformStand = false end)
                hum.Sit = false
                hum.AutoRotate = true

                if originalHipHeight ~= nil then
                    pcall(function() hum.HipHeight = originalHipHeight end)
                    originalHipHeight = nil
                end

                if root and root:IsA("BasePart") then
                    local groundY = nil
                    local tries = 0
                    while tries < 3 and not groundY do
                        local y, _ = findGroundY(root.Position + Vector3.new(0, 1.5, 0), 20)
                        groundY = y
                        tries = tries + 1
                        if not groundY then task.wait(0.03) end
                    end

                    if groundY then
                        local offset = 2
                        if hum and type(hum.HipHeight) == "number" then
                            offset = hum.HipHeight + 0.5
                        else
                            offset = (root.Size.Y / 2) + 0.5
                        end
                        local desiredY = groundY + offset
                        local dy = root.Position.Y - desiredY
                        if math.abs(dy) > 0.12 then
                            pcall(function() root:SetNetworkOwner(player) end)
                            root.CFrame = CFrame.new(root.Position.X, desiredY, root.Position.Z, root.CFrame:ToOrientation())
                        end
                    end
                end

                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
                task.wait(0.06)
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            pcall(function()
                local cam = Workspace.CurrentCamera
                if cam and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        cam.CameraSubject = hum
                        cam.CameraType = Enum.CameraType.Custom
                    end
                end
            end)
        end)
    end

    local function startAntiFlingEnforcer()
        if antiFlingEnforcerConn then antiFlingEnforcerConn:Disconnect() end
        antiFlingEnforcerConn = RunService.Stepped:Connect(function()
            if not antiFlingActive or not onlyOwner() then return end
            pcall(function()
                local char = player.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local ok, av = pcall(function() return root.AssemblyLinearVelocity end)
                if ok and av and av.Magnitude > 40 then
                    root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(av.Y, -50, 50), 0)
                end
                local ok2, aa = pcall(function() return root.AssemblyAngularVelocity end)
                if ok2 and aa and aa.Magnitude > ANGULAR_SPEED_LIMIT then
                    root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end

                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored then
                        if savedCanCollide[part] == nil then
                            savedCanCollide[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    end
                end
            end)
        end)
    end

    local function stopAntiFlingEnforcer()
        if antiFlingEnforcerConn then
            antiFlingEnforcerConn:Disconnect()
            antiFlingEnforcerConn = nil
        end
    end

    local function enableNoclip()
        if not onlyOwner() then return end
        if noclipConn then noclipConn:Disconnect() end

        savedCanCollide = {}
        originalHipHeight = nil

        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and originalHipHeight == nil then
                        pcall(function() originalHipHeight = hum.HipHeight end)
                    end

                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and not part.Anchored then
                            if savedCanCollide[part] == nil then
                                savedCanCollide[part] = part.CanCollide
                            end
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end)
        maintainNetworkOwnership()
    end

    local function disableNoclip()
        if not onlyOwner() then return end
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        pcall(function()
            local char = player.Character
            if not char then
                savedCanCollide = {}
                originalHipHeight = nil
                return
            end

            for part, original in pairs(savedCanCollide) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = original
                    end)
                end
            end
            savedCanCollide = {}

            task.wait(0.06)

            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if root then
                pcall(function()
                    local ok, av = pcall(function() return root.AssemblyLinearVelocity end)
                    if ok and av then
                        root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(av.Y, -50, 50), 0)
                    else
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end)
            end

            if hum then
                if originalHipHeight ~= nil then
                    pcall(function() hum.HipHeight = originalHipHeight end)
                    originalHipHeight = nil
                end

                pcall(function() hum.PlatformStand = false end)
                hum.Sit = false
                hum.AutoRotate = true

                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
                task.wait(0.06)
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
        end)
    end

    local function updateTeleportList()
        if not onlyOwner() then return end
        for _, child in ipairs(tpScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local playersList = Players:GetPlayers()
        table.sort(playersList, function(a,b) return a.Name:lower() < b.Name:lower() end)

        for _, plr in ipairs(playersList) do
            if plr == player then continue end

            local displayName = plr.DisplayName or ""
            local userName = plr.Name or ""
            local charIndicator = plr.Character and " ✓" or " (sem char)"
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.92, 0, 0, 38)
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
            btn.Text = string.format("%s (@%s)%s", displayName, userName, charIndicator)
            btn.TextColor3 = plr.Character and Color3.fromRGB(220,220,255) or Color3.fromRGB(140,140,140)
            btn.TextSize = 15
            btn.Font = Enum.Font.GothamSemibold
            btn.Parent = tpScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

            btn.MouseButton1Click:Connect(function()
                if not onlyOwner() then return end
                local targetChar = plr.Character
                if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return end

                local myChar = player.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local root = myChar.HumanoidRootPart
                    local targetCF = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)

                    task.spawn(function()
                        for i = 1, 20 do
                            root.CFrame = root.CFrame:Lerp(targetCF, i / 20)
                            task.wait()
                        end
                        root.CFrame = targetCF
                        pcall(function() root:SetNetworkOwner(player) end)
                    end)
                end

                teleportFrame.Visible = false
                content.Visible = true
            end)
        end
    end

    local highlightConnections = {}
    local highlightEnforcerConnections = {}

    local function clearHighlightForCharacter(char)
        if not char then return end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name == "AntiScripterHighlight" then
                obj:Destroy()
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local old = head:FindFirstChild("HighlightName")
            if old then old:Destroy() end
            local suspect = head:FindFirstChild("SuspectTag")
            if suspect then suspect:Destroy() end
        end
    end

    local function ensureBillboard(plr)
        if not plr or not plr.Character then return end
        local char = plr.Character
        local head = char:FindFirstChild("Head")
        if not head then return end

        local bg = head:FindFirstChild("HighlightName")
        if not bg then
            bg = Instance.new("BillboardGui")
            bg.Name = "HighlightName"
            bg.Adornee = head
            bg.Size = UDim2.new(0, 180, 0, 28)
            bg.StudsOffset = Vector3.new(0, 3.2, 0)
            bg.AlwaysOnTop = true
            bg.Parent = head
        end

        local label = bg:FindFirstChildOfClass("TextLabel")
        if not label then
            label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(0, 255, 0)
            label.Parent = bg
        end

        label.Text = plr.DisplayName and (plr.DisplayName .. " (@" .. plr.Name .. ")") or ("@" .. plr.Name)
    end

    local function createOrUpdateOurHighlight(char)
        if not char then return end
        local ourHl = nil
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name == "AntiScripterHighlight" then
                ourHl = obj
                break
            end
        end

        if not ourHl then
            ourHl = Instance.new("Highlight")
            ourHl.Name = "AntiScripterHighlight"
            ourHl.Parent = char
        end

        ourHl.FillTransparency = 1
        ourHl.OutlineColor = Color3.fromRGB(0, 255, 0)
        ourHl.OutlineTransparency = 0
        ourHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    local function neutralizeOtherHighlights(char)
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Highlight") and obj.Name ~= "AntiScripterHighlight" then
                pcall(function()
                    obj.OutlineTransparency = 1
                    obj.FillTransparency = 1
                end)
            end
        end
    end

    local function startHighlightEnforcerForPlayer(plr)
        if not plr then return end
        if highlightEnforcerConnections[plr] then return end
        local conn = RunService.RenderStepped:Connect(function()
            if not highlightActive then return end
            if not plr.Character then return end
            createOrUpdateOurHighlight(plr.Character)
            neutralizeOtherHighlights(plr.Character)
            ensureBillboard(plr)
        end)
        highlightEnforcerConnections[plr] = conn
    end

    local function stopHighlightEnforcerForPlayer(plr)
        local conn = highlightEnforcerConnections[plr]
        if conn then
            conn:Disconnect()
            highlightEnforcerConnections[plr] = nil
        end
    end

    local function applyHighlight(plr, active)
        pcall(function()
            if not plr or plr == player then return end
            local char = plr.Character
            if not char then return end

            if active then
                createOrUpdateOurHighlight(char)
                ensureBillboard(plr)
                startHighlightEnforcerForPlayer(plr)
            else
                stopHighlightEnforcerForPlayer(plr)
                clearHighlightForCharacter(char)
            end
        end)
    end

    local function connectHighlightForPlayer(plr)
        if not plr then return end
        if highlightConnections[plr] then
            if highlightConnections[plr].charConn then highlightConnections[plr].charConn:Disconnect() end
            if highlightConnections[plr].nameConn then highlightConnections[plr].nameConn:Disconnect() end
            if highlightConnections[plr].removingConn then highlightConnections[plr].removingConn:Disconnect() end
            highlightConnections[plr] = nil
        end

        local charConn = plr.CharacterAdded:Connect(function(char)
            local head = char:WaitForChild("Head", 2)
            task.wait(0.03)
            if highlightActive then
                applyHighlight(plr, true)
            else
                clearHighlightForCharacter(char)
            end
        end)

        local nameConn = plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
            if plr.Character then
                ensureBillboard(plr)
            end
        end)

        local removingConn = plr.AncestryChanged:Connect(function()
            if not plr:IsDescendantOf(game) then
                stopHighlightEnforcerForPlayer(plr)
                highlightConnections[plr] = nil
            end
        end)

        highlightConnections[plr] = {charConn = charConn, nameConn = nameConn, removingConn = removingConn}
    end

    local function disconnectHighlightForPlayer(plr)
        if not plr then return end
        if highlightConnections[plr] then
            if highlightConnections[plr].charConn then highlightConnections[plr].charConn:Disconnect() end
            if highlightConnections[plr].nameConn then highlightConnections[plr].nameConn:Disconnect() end
            if highlightConnections[plr].removingConn then highlightConnections[plr].removingConn:Disconnect() end
            highlightConnections[plr] = nil
        end
        stopHighlightEnforcerForPlayer(plr)
        if plr.Character then
            clearHighlightForCharacter(plr.Character)
        end
    end

    local function enableHighlightsForAll()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                connectHighlightForPlayer(plr)
                if plr.Character then
                    applyHighlight(plr, true)
                end
            end
        end
    end

    local function disableHighlightsForAll()
        for _, plr in ipairs(Players:GetPlayers()) do
            disconnectHighlightForPlayer(plr)
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                clearHighlightForCharacter(plr.Character)
            end
        end
    end

    local function containsPlayer(list, plr)
        for i, v in ipairs(list) do
            if v == plr then return i end
        end
        return nil
    end

    local function addFlingOffender(plr)
        if not plr then return end
        if containsPlayer(flingOffenders, plr) then return end
        table.insert(flingOffenders, plr)
    end

    local function addLaunchedPlayer(plr)
        if not plr then return end
        if containsPlayer(launchedPlayers, plr) then return end
        table.insert(launchedPlayers, plr)
    end

    local function markSuspect(plr, reason)
        pcall(function()
            if not plr or plr == player then return end
            local char = plr.Character
            if not char then return end
            local head = char:FindFirstChild("Head")
            if not head then return end

            local bg = head:FindFirstChild("SuspectTag")
            if bg then bg:Destroy() end

            bg = Instance.new("BillboardGui")
            bg.Name = "SuspectTag"
            bg.Adornee = head
            bg.Size = UDim2.new(0, 300, 0, 60)
            bg.StudsOffset = Vector3.new(0, 3.5, 0)
            bg.AlwaysOnTop = true
            bg.Parent = head

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(255, 60, 60)
            label.TextWrapped = true
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.Text = (plr.DisplayName or plr.Name) .. "\n[DETECTADO: " .. reason .. "]"
            label.Parent = bg

            if reason:lower():find("fling") or reason:lower():find("spin") then
                addFlingOffender(plr)
            end
            if reason:lower():find("lanço") or reason:lower():find("teleport") or reason:lower():find("teleporte") or reason:lower():find("posição") then
                addLaunchedPlayer(plr)
            end

            suspectTimers[plr] = tick() + 8
        end)
    end

    -- Detector refinado
    local DETECTION_THRESHOLD = 48
    local DECAY_PER_SECOND    = 6
    local SUSTAINED_TOOL_TIME = 0.9

    local playerData = {}

    local function resetData(plr)
        playerData[plr] = {
            score          = 0,
            lastPos        = nil,
            lastVel        = Vector3.zero,
            lastAng        = Vector3.zero,
            lastHealth     = nil,
            airTime        = 0,
            horizShort     = {},
            horizMedium    = {},
            angHistory     = {},
            tpStreak       = 0,
            speedStreak    = 0,
            flyStreak      = 0,
            godStreak      = 0,
            aimSnapStreak  = 0,
            lastToolAttack = nil,
            lastUpdate     = tick(),
            lastGuiCheck   = 0,
            mildSpeedStreak = 0,
            flyToolDetectedSince = 0,
            flyToolCount = 0
        }
    end

    RunService.Heartbeat:Connect(function(dt)
        if not detectorActive then return end

        local now = tick()
        local tpCountThisFrame = 0
        local recentTps = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == player then continue end

            local char = plr.Character
            if not char then
                playerData[plr] = nil
                continue
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then continue end

            local data = playerData[plr] or (resetData(plr) and playerData[plr])

            local deltaT = now - data.lastUpdate
            data.lastUpdate = now

            data.score = math.max(0, data.score - DECAY_PER_SECOND * deltaT)

            local violated = false
            local reasons = {}

            local flyToolCount = 0
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") or obj:IsA("BodyForce")
                or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity")
                or obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("VectorForce") then
                    local parentName = obj.Parent and obj.Parent.Name or ""
                    if parentName:lower():find("safe") or parentName:lower():find("vehicle") then
                    else
                        flyToolCount = flyToolCount + 1
                    end
                end
            end

            if flyToolCount > 0 then
                if data.flyToolDetectedSince == 0 then
                    data.flyToolDetectedSince = now
                    data.flyToolCount = flyToolCount
                else
                    if flyToolCount ~= data.flyToolCount then
                        data.flyToolDetectedSince = now
                        data.flyToolCount = flyToolCount
                    end
                end
            else
                data.flyToolDetectedSince = 0
                data.flyToolCount = 0
            end

            local sustainedFlyTool = (data.flyToolDetectedSince > 0 and (now - data.flyToolDetectedSince) >= SUSTAINED_TOOL_TIME)

            if sustainedFlyTool then
                table.insert(reasons, "Fly tool sustentado detectado")
                data.score = data.score + 22
                violated = true
            end

            if hum:GetState() == Enum.HumanoidStateType.Dead
            or hum:GetState() == Enum.HumanoidStateType.Ragdoll
            or hum.PlatformStand
            or hum.Sit then
                data.airTime = 0
                data.score = math.max(0, data.score - 12 * deltaT)
                continue
            end

            if hum:GetState() == Enum.HumanoidStateType.Freefall
            or hum:GetState() == Enum.HumanoidStateType.Jumping then
                data.airTime = data.airTime + deltaT
            else
                data.airTime = 0
            end

            local pos = root.Position
            local vel = root.AssemblyLinearVelocity
            local ang = root.AssemblyAngularVelocity

            if data.lastPos then
                local dPos = (pos - data.lastPos).Magnitude
                if dPos > 120 and deltaT < 0.25 then
                    recentTps[plr] = true
                    tpCountThisFrame = tpCountThisFrame + 1
                    data.tpStreak = data.tpStreak + 1
                    if data.tpStreak >= 4 then
                        table.insert(reasons, "Teleporte repetido")
                        data.score = data.score + 20
                        violated = true
                    end
                else
                    data.tpStreak = 0
                end
            end

            local hSpeed = Vector3.new(vel.X,0,vel.Z).Magnitude
            local expMax = (hum.WalkSpeed or 16) * 1.45 + 25

            table.insert(data.horizShort, hSpeed)
            if #data.horizShort > 18 then table.remove(data.horizShort,1) end

            table.insert(data.horizMedium, hSpeed)
            if #data.horizMedium > 150 then table.remove(data.horizMedium,1) end

            local avgShort   = 0; for _,v in ipairs(data.horizShort)   do avgShort   = avgShort + v end; avgShort   = avgShort / math.max(1,#data.horizShort)
            local avgMedium  = 0; for _,v in ipairs(data.horizMedium)  do avgMedium  = avgMedium + v end; avgMedium  = avgMedium / math.max(1,#data.horizMedium)

            if avgShort > expMax * 1.9 then
                data.speedStreak = data.speedStreak + 1
                if data.speedStreak >= 6 then
                    table.insert(reasons, "Velocidade horizontal alta sustentada")
                    data.score = data.score + 10
                    violated = true
                end
            else
                data.speedStreak = 0
            end

            local vAbs = math.abs(vel.Y)
            if data.airTime > 2.6 then
                if vAbs < 9 then
                    data.flyStreak = data.flyStreak + 1
                    if data.flyStreak >= 8 or sustainedFlyTool then
                        table.insert(reasons, "Fly / levitação prolongada")
                        data.score = data.score + 16
                        violated = true
                    end
                elseif vel.Y > 48 and data.airTime < 1.6 then
                    table.insert(reasons, "Subida vertical anormal")
                    data.score = data.score + 12
                    violated = true
                end
            else
                if sustainedFlyTool and vAbs > 1 then
                    table.insert(reasons, "Fly tool detectado com movimento anômalo")
                    data.score = data.score + 10
                    violated = true
                end
            end

            local angMag = ang.Magnitude
            table.insert(data.angHistory, angMag)
            if #data.angHistory > 15 then table.remove(data.angHistory,1) end

            local avgAng = 0; for _,v in ipairs(data.angHistory) do avgAng = avgAng + v end; avgAng = avgAng / math.max(1,#data.angHistory)

            if avgAng > 140 or angMag > 220 then
                table.insert(reasons, "Rotação angular extrema")
                data.score = data.score + 14
                violated = true
            end

            if data.lastHealth then
                if hum.Health > data.lastHealth + 10 then
                    data.godStreak = data.godStreak + 1
                    if data.godStreak >= 4 then
                        table.insert(reasons, "Regeneração / godmode suspeito")
                        data.score = data.score + 14
                        violated = true
                    end
                end
            end
            data.lastHealth = hum.Health

            if data.lastAng then
                local dAng = (ang - data.lastAng).Magnitude
                if dAng > 160 and hSpeed > 18 then
                    data.aimSnapStreak = data.aimSnapStreak + 1
                    if data.aimSnapStreak >= 5 then
                        table.insert(reasons, "Aim snap / rotação suspeita")
                        data.score = data.score + 10
                        violated = true
                    end
                else
                    data.aimSnapStreak = 0
                end
            end
            data.lastAng = ang

            if now - (data.lastGuiCheck or 0) > 3.5 then
                data.lastGuiCheck = now
                local guiName = detectSuspiciousGUI(plr)
                if guiName then
                    table.insert(reasons, "GUI de Executor: " .. guiName)
                    data.score = data.score + 90
                    violated = true
                end
            end

            local currentWS = hum.WalkSpeed or 16
            if currentWS > 18 then
                data.mildSpeedStreak = (data.mildSpeedStreak or 0) + 1
                if data.mildSpeedStreak >= 30 then
                    table.insert(reasons, "WalkSpeed sutil aumentado (speed hack)")
                    data.score = data.score + 10
                    violated = true
                end
            else
                data.mildSpeedStreak = 0
            end

            local head = char:FindFirstChild("Head")
            if head and head.Transparency > 0.75 and hSpeed > 8 then
                table.insert(reasons, "Invisibilidade suspeita (cabeça)")
                data.score = data.score + 18
                violated = true
            end

            if violated and data.score >= DETECTION_THRESHOLD then
                local msg = table.concat(reasons, " + ") .. "  (score: " .. math.floor(data.score) .. ")"
                markSuspect(plr, msg)
                data.score = math.max(0, data.score - 20)
            end

            data.lastPos = pos
            data.lastVel = vel
        end

        if tpCountThisFrame >= 4 then
            for tplr, _ in pairs(recentTps) do
                local data = playerData[tplr]
                if data then
                    data.tpStreak = 0
                    data.score = math.max(0, data.score - 30)
                end
            end
        end

        for plrExpire, expireTime in pairs(suspectTimers) do
            if now > expireTime then
                pcall(function()
                    if plrExpire and plrExpire.Character then
                        local head = plrExpire.Character:FindFirstChild("Head")
                        if head then
                            local tag = head:FindFirstChild("SuspectTag")
                            if tag then tag:Destroy() end
                        end
                    end
                end)
                suspectTimers[plrExpire] = nil
            end
        end

        for plr in pairs(playerData) do
            if not table.find(Players:GetPlayers(), plr) then
                playerData[plr] = nil
            end
        end
    end)

    -- FLY implementation (mantive)
    local cam = workspace.CurrentCamera

    local SPRINT_MULT = 1.6
    local SMOOTHNESS = 0.18
    local MAX_FORCE = 1e5
    local TOUCH_DESCEND_SIDE = 0.5

    local rootPart, humanoid
    local bv, bg
    local currentVelocity = Vector3.new()
    local targetVelocity = Vector3.new()
    local verticalTarget = 0
    local sprinting = false

    local invertForward = false
    local invertRight = false

    local gamepadStick = Vector2.new(0,0)

    local function startFly()
        if not onlyOwner() then return end
        if not player.Character then return end
        rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then return end
        if flying then return end
        flying = true

        pcall(function() humanoid.PlatformStand = true end)

        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(MAX_FORCE, MAX_FORCE, MAX_FORCE)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = rootPart

        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(MAX_FORCE, MAX_FORCE, MAX_FORCE)
        bg.P = 1e5
        bg.D = 0
        bg.CFrame = rootPart.CFrame
        bg.Parent = rootPart

        cam = workspace.CurrentCamera or cam
        flyBtn.Text = "FLY ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        maintainNetworkOwnership()
    end

    local function stopFly()
        if not onlyOwner() then return end
        flying = false
        if humanoid then pcall(function() humanoid.PlatformStand = false end) end
        if bv then bv:Destroy(); bv = nil end
        if bg then bg:Destroy(); bg = nil end
        currentVelocity = Vector3.new()
        targetVelocity = Vector3.new()
        verticalTarget = 0

        flyBtn.Text = "FLY OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
            if input.KeyCode == Enum.KeyCode.Thumbstick1 or input.KeyCode == Enum.KeyCode.Thumbstick2 then
                local v = input.Position
                gamepadStick = Vector2.new(v.X, v.Y)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftAlt then
            sprinting = true
        elseif input.KeyCode == Enum.KeyCode.Space then
            verticalTarget = 1
        elseif input.KeyCode == Enum.KeyCode.I then
            invertForward = not invertForward
        elseif input.KeyCode == Enum.KeyCode.O then
            invertRight = not invertRight
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftAlt then
            sprinting = false
        elseif input.KeyCode == Enum.KeyCode.Space then
            verticalTarget = 0
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        verticalTarget = 1
        task.delay(0.12, function()
            if verticalTarget == 1 then verticalTarget = 0 end
        end)
    end)

    UserInputService.TouchStarted:Connect(function(t, g)
        if g then return end
        local screenX = UserInputService:GetScreenResolution().X
        if t.Position.X > screenX * TOUCH_DESCEND_SIDE then
            verticalTarget = -1
        end
    end)
    UserInputService.TouchEnded:Connect(function(t, g)
        if g then return end
        local screenX = UserInputService:GetScreenResolution().X
        if t.Position.X > screenX * TOUCH_DESCEND_SIDE then
            if verticalTarget == -1 then verticalTarget = 0 end
        end
    end)

    local function getInputAxes()
        local inputX, inputZ = 0, 0

        if humanoid then
            local md = humanoid.MoveDirection
            if md and md.Magnitude > 0.01 and cam then
                local camLook = cam.CFrame.LookVector
                local camRight = cam.CFrame.RightVector

                local forwardFlat = Vector3.new(camLook.X, 0, camLook.Z)
                if forwardFlat.Magnitude > 0 then forwardFlat = forwardFlat.Unit end

                local rightFlat = Vector3.new(camRight.X, 0, camRight.Z)
                if rightFlat.Magnitude > 0 then rightFlat = rightFlat.Unit end

                local forwardAmount = md:Dot(forwardFlat)
                local rightAmount = md:Dot(rightFlat)

                inputZ = forwardAmount
                inputX = rightAmount

                if math.abs(inputX) > 0.01 or math.abs(inputZ) > 0.01 then
                    if invertForward then inputZ = -inputZ end
                    if invertRight then inputX = -inputX end

                    local mag = math.sqrt(inputX*inputX + inputZ*inputZ)
                    if mag > 1 then
                        inputX = inputX / mag
                        inputZ = inputZ / mag
                    end
                    return inputX, inputZ
                end
            end
        end

        if gamepadStick.Magnitude > 0.01 then
            inputX = gamepadStick.X
            inputZ = -gamepadStick.Y
            if invertForward then inputZ = -inputZ end
            if invertRight then inputX = -inputX end
            local mag = math.sqrt(inputX*inputX + inputZ*inputZ)
            if mag > 1 then
                inputX = inputX / mag
                inputZ = inputZ / mag
            end
            return inputX, inputZ
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputZ = inputZ + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputZ = inputZ - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputX = inputX + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputX = inputX - 1 end

        if invertForward then inputZ = -inputZ end
        if invertRight then inputX = -inputX end

        local mag = math.sqrt(inputX*inputX + inputZ*inputZ)
        if mag > 1 then
            inputX = inputX / mag
            inputZ = inputZ / mag
        end

        return inputX, inputZ
    end

    RunService.RenderStepped:Connect(function(dt)
        if flying and rootPart and bv and bg and cam and onlyOwner() then
            local ix, iz = getInputAxes()

            local camLook = cam.CFrame.LookVector
            local forward = camLook
            if forward.Magnitude > 0 then forward = forward.Unit end

            local camRight = cam.CFrame.RightVector
            local right = Vector3.new(camRight.X, 0, camRight.Z)
            if right.Magnitude > 0 then right = right.Unit end

            local worldDir = (forward * iz) + (right * ix)
            if worldDir.Magnitude > 0 then
                worldDir = worldDir.Unit
            else
                worldDir = Vector3.new(0,0,0)
            end

            local speed = FLIGHT_BASE_SPEED * (sprinting and SPRINT_MULT or 1)
            local horiz = Vector3.new(worldDir.X, 0, worldDir.Z) * speed

            local vy = 0
            if verticalTarget > 0 then
                vy = speed
            elseif verticalTarget < 0 then
                vy = -speed
            end

            local desiredY
            if math.abs(forward.Y) > 0.001 and math.abs(iz) > 0.001 then
                desiredY = forward.Y * iz * speed
            else
                desiredY = vy
            end

            targetVelocity = Vector3.new(horiz.X, desiredY, horiz.Z)

            local alpha = 1 - math.exp(-SMOOTHNESS * math.max(dt, 0.001) * 60)
            currentVelocity = currentVelocity:Lerp(targetVelocity, math.clamp(alpha, 0, 1))
            if bv then bv.Velocity = currentVelocity end

            if bg and rootPart then
                bg.CFrame = CFrame.new(rootPart.Position, rootPart.Position + cam.CFrame.LookVector)
            end

            if rootPart and rootPart:IsA("BasePart") then
                rootPart.AssemblyLinearVelocity = bv and bv.Velocity or Vector3.new(0,0,0)
                rootPart.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    player.CharacterAdded:Connect(function(char)
        task.wait(0.35)
        stopFly()
        if velocityActive then
            if velocityConn then
                velocityConn:Disconnect(); velocityConn = nil
            end
            if velocityDeathConn then
                velocityDeathConn:Disconnect(); velocityDeathConn = nil
            end
            task.delay(0.08, function()
                if not velocityActive then return end
                local charNow = player.Character
                if charNow ~= char then return end
                local root = charNow:FindFirstChild("HumanoidRootPart")
                local hum = charNow:FindFirstChildOfClass("Humanoid")
                local tries = 0
                while (not root or not hum) and tries < 40 do
                    task.wait(0.03)
                    root = charNow:FindFirstChild("HumanoidRootPart")
                    hum = charNow:FindFirstChildOfClass("Humanoid")
                    tries = tries + 1
                end
                if root and hum and velocityActive then
                    pcall(function()
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        root.RotVelocity = Vector3.new(0, 0, 0)
                        hum.PlatformStand = false
                        hum.Sit = false
                        hum.AutoRotate = true
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                    if velocityConn then
                        velocityConn:Disconnect()
                        velocityConn = nil
                    end
                    startVelocityMode()
                end
            end)
        end
    end)

    if player.Character then
        task.wait(0.35)
        stopFly()
    end

    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            stopFly()
        end
    end)

    local function clearVelocityDeathWatcher()
        if velocityDeathConn then
            velocityDeathConn:Disconnect()
            velocityDeathConn = nil
        end
    end

    local function attachHumanoidDeathWatcher()
        clearVelocityDeathWatcher()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        velocityDeathConn = hum.Died:Connect(function()
            if velocityConn then
                velocityConn:Disconnect()
                velocityConn = nil
            end
            pcall(function()
                stopVelocityMode()
            end)
            velocityActive = false
            if velocityBtnWJ and velocityBtnWJ:IsA("TextButton") then
                velocityBtnWJ.Text = "VELOCITY OFF"
                velocityBtnWJ.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            end
        end)
    end

    local function startVelocityMode()
        if velocityConn then return end

        velocityConn = RunService.Heartbeat:Connect(function(dt)
            if not velocityActive or not onlyOwner() then return end

            local char = player.Character
            if not char then return end

            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then return end

            local currentY = 0
            local ok, av = pcall(function() return root.AssemblyLinearVelocity end)
            if ok and av then currentY = av.Y end

            local md = hum.MoveDirection or Vector3.new(0,0,0)
            local horiz = Vector3.new(md.X, 0, md.Z)
            if horiz.Magnitude > 0 then horiz = horiz.Unit else horiz = Vector3.new(0,0,0) end

            local speed = math.max(tonumber(savedWalkSpeed) or 0, 0)

            local desiredVel = Vector3.new(horiz.X * speed, currentY, horiz.Z * speed)

            pcall(function()
                root.AssemblyLinearVelocity = desiredVel
                root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                root.RotVelocity = Vector3.new(0,0,0)
            end)

            pcall(function()
                if hum and hum.Parent then
                    hum.WalkSpeed = 0.01
                    hum.PlatformStand = false
                    hum.AutoRotate = true
                end
            end)
        end)

        attachHumanoidDeathWatcher()
    end

    local function stopVelocityMode()
        if velocityConn then
            velocityConn:Disconnect()
            velocityConn = nil
        end
        clearVelocityDeathWatcher()
        pcall(function()
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local y = 0
                    local ok, av = pcall(function() return root.AssemblyLinearVelocity end)
                    if ok and av then y = av.Y end
                    root.AssemblyLinearVelocity = Vector3.new(0, y, 0)
                    root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = math.max(savedWalkSpeed, 0)
                    hum.PlatformStand = false
                    hum.Sit = false
                    hum.AutoRotate = true
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end

    local antiRubberConn = nil
    local function startAntiRubberband()
        if antiRubberConn then return end
        antiRubberConn = RunService.Stepped:Connect(function()
            if not onlyOwner() then return end
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then return end

            pcall(function()
                root:SetNetworkOwner(player)
                root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                root.RotVelocity = Vector3.new(0,0,0)

                local vel = root.AssemblyLinearVelocity
                if vel.Magnitude > 120 then
                    root.AssemblyLinearVelocity = vel * 0.92
                end
            end)
        end)
    end

    local function stopAntiRubberband()
        if antiRubberConn then
            antiRubberConn:Disconnect()
            antiRubberConn = nil
        end
    end

    local function updateAntiRubberbandState()
        local shouldRun = noclipActive or flying or velocityActive or (not bypassActive)
        if shouldRun then
            startAntiRubberband()
        else
            stopAntiRubberband()
        end
    end

    local camForceConn = nil
    local function enableCamBypass()
        if not onlyOwner() then return end
        if camBypassConn then camBypassConn:Disconnect() end

        originalCameraMaxZoom = player.CameraMaxZoomDistance or 128
        originalCameraMinZoom = player.CameraMinZoomDistance or 0.5

        camBypassConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local camera = workspace.CurrentCamera
                if camera then
                    if camera.CameraType ~= Enum.CameraType.Custom then
                        camera.CameraType = Enum.CameraType.Custom
                    end
                    local char = player.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and camera.CameraSubject ~= hum then
                            camera.CameraSubject = hum
                        end
                    end
                end
                if player then
                    if player.CameraMaxZoomDistance ~= 10000 then player.CameraMaxZoomDistance = 10000 end
                    if player.CameraMinZoomDistance ~= 0.5 then player.CameraMinZoomDistance = 0.5 end
                    if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
                end
            end)
        end)

        if workspace.CurrentCamera then
            if camForceConn then camForceConn:Disconnect() end
            camForceConn = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                pcall(function()
                    local camera = workspace.CurrentCamera
                    if camera and player and player.Character then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then camera.CameraSubject = hum end
                    end
                end)
            end)
        end
    end

    local function disableCamBypass()
        if camBypassConn then
            camBypassConn:Disconnect()
            camBypassConn = nil
        end
        if camForceConn then
            camForceConn:Disconnect()
            camForceConn = nil
        end
        pcall(function()
            if player then
                player.CameraMaxZoomDistance = originalCameraMaxZoom
                player.CameraMinZoomDistance = originalCameraMinZoom
            end
            local camera = workspace.CurrentCamera
            if camera then
                if player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        camera.CameraSubject = hum
                    end
                end
                camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end

    -- Dragging main button
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()

    mainBtn.InputBegan:Connect(function(input)
        if not onlyOwner() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    player:SetAttribute("BotaoPosX", mainBtn.Position.X.Offset)
                    player:SetAttribute("BotaoPosY", mainBtn.Position.Y.Offset)
                end
            end)
        end
    end)

    mainBtn.InputChanged:Connect(function(input)
        if not onlyOwner() then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                mainBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    mainBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        frame.Visible = not frame.Visible
    end)

    teleportBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        content.Visible = false
        teleportFrame.Visible = true
        updateTeleportList()
    end)

    walkJumpBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        content.Visible = false
        walkJumpFrame.Visible = true
        wsBox.Text = tostring(savedWalkSpeed)
        jhBox.Text = tostring(savedJumpHeight)
    end)

    noclipBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        noclipActive = not noclipActive
        if noclipActive then
            enableNoclip()
            noclipBtn.Text = "NOCLIP ON"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        else
            disableNoclip()
            noclipBtn.Text = "NOCLIP OFF"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        end
        updateAntiRubberbandState()
    end)

    antiFlingBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        antiFlingActive = not antiFlingActive
        if antiFlingActive then
            updateAntiFling()
            startAntiFlingEnforcer()
            antiFlingBtn.Text = "ANTI-FLING ON"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        else
            stopAntiFlingEnforcer()
            antiFlingBtn.Text = "ANTI-FLING OFF"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            updateAntiFling()
            restoreAfterAntiFling()
        end
    end)

    detectorBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        detectorActive = not detectorActive
        detectorBtn.Text = "DETECTOR " .. (detectorActive and "ON" or "OFF")
        detectorBtn.BackgroundColor3 = detectorActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 45)
        if not detectorActive then
            for plr, _ in pairs(suspectTimers) do
                if plr and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local tag = head:FindFirstChild("SuspectTag")
                        if tag then tag:Destroy() end
                    end
                end
            end
            suspectTimers = {}
            playerData = {}
        end
    end)

    highlightBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        highlightActive = not highlightActive
        if highlightActive then
            highlightBtn.Text = "HIGHLIGHT ON"
            highlightBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            enableHighlightsForAll()
        else
            highlightBtn.Text = "HIGHLIGHT OFF"
            highlightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            disableHighlightsForAll()
        end
    end)

    camBypassBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        camBypassActive = not camBypassActive
        if camBypassActive then
            enableCamBypass()
            camBypassBtn.Text = "CAM BYPASS ON"
            camBypassBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        else
            disableCamBypass()
            camBypassBtn.Text = "CAM BYPASS OFF"
            camBypassBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        end
    end)

    flyBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        if not flying then
            startFly()
        else
            stopFly()
        end
        updateAntiRubberbandState()
    end)

    applyBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        local valWS = tonumber(wsBox.Text) or savedWalkSpeed
        -- removed upper limit clamp; only ensure non-negative
        valWS = math.max(valWS, 0)
        savedWalkSpeed = valWS
        player:SetAttribute("SavedWalkSpeed", savedWalkSpeed)
        FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * 5, 10, 1000)

        local valJH = tonumber(jhBox.Text) or savedJumpHeight
        valJH = math.max(valJH, 0)
        savedJumpHeight = valJH
        player:SetAttribute("SavedJumpHeight", savedJumpHeight)

        if not bypassActive then
            enforceMovement()
        end

        if velocityActive then
            if velocityConn then
                velocityConn:Disconnect()
                velocityConn = nil
            end
            task.delay(0, function()
                if velocityActive then startVelocityMode() end
            end)
        end
    end)

    bypassBtnWJ.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        bypassActive = not bypassActive
        if bypassActive then
            bypassBtnWJ.Text = "BYPASS OFF"
            bypassBtnWJ.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            disableEnforcement()
        else
            bypassBtnWJ.Text = "BYPASS ON"
            bypassBtnWJ.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            enableEnforcement()
        end
        updateAntiRubberbandState()
    end)

    velocityBtnWJ.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        velocityActive = not velocityActive
        if velocityActive then
            velocityBtnWJ.Text = "VELOCITY ON"
            velocityBtnWJ.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            pcall(function()
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        root.RotVelocity = Vector3.new(0, 0, 0)
                    end
                    if hum then
                        hum.PlatformStand = false
                        hum.Sit = false
                        hum.AutoRotate = true
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end)
            if velocityConn then
                velocityConn:Disconnect()
                velocityConn = nil
            end
            startVelocityMode()
        else
            velocityBtnWJ.Text = "VELOCITY OFF"
            velocityBtnWJ.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            stopVelocityMode()
            if not bypassActive then
                enforceMovement()
            end
        end
        updateAntiRubberbandState()
    end)

    resetBtnWJ.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        local defaultWS, defaultJH = captureGameDefaultsIfMissing()
        if defaultWS and defaultJH then
            savedWalkSpeed = defaultWS
            savedJumpHeight = defaultJH
            wsBox.Text = tostring(savedWalkSpeed)
            jhBox.Text = tostring(savedJumpHeight)
            player:SetAttribute("SavedWalkSpeed", savedWalkSpeed)
            player:SetAttribute("SavedJumpHeight", savedJumpHeight)

            FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * 5, 10, 1000)

            if not bypassActive then
                enforceMovement()
            end
        end
    end)

    local function initializeDefaultsOnJoin()
        local defaultWS, defaultJH = getSavedDefaultsForPlace()
        if not (defaultWS and defaultJH) then
            defaultWS, defaultJH = captureGameDefaultsIfMissing()
        end

        local userSavedWS = tonumber(player:GetAttribute("SavedWalkSpeed"))
        local userSavedJH = tonumber(player:GetAttribute("SavedJumpHeight"))

        if userSavedWS and userSavedJH then
            savedWalkSpeed = userSavedWS
            savedJumpHeight = userSavedJH
        else
            savedWalkSpeed = defaultWS or savedWalkSpeed
            savedJumpHeight = defaultJH or savedJumpHeight
        end

        wsBox.Text = tostring(savedWalkSpeed)
        jhBox.Text = tostring(savedJumpHeight)

        FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * 5, 10, 1000)
    end

    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = player.Character:WaitForChild("Humanoid", 2)
        end
        initializeDefaultsOnJoin()
        task.delay(0.06, function()
            if bypassActive then
                disableEnforcement()
            else
                enableEnforcement()
            end
            updateAntiRubberbandState()
        end)
    else
        player.CharacterAdded:Connect(function()
            task.wait(0.4)
            initializeDefaultsOnJoin()

            task.delay(0.06, function()
                if bypassActive then
                    disableEnforcement()
                else
                    enableEnforcement()
                end
                updateAntiRubberbandState()
            end)
        end)
    end

    Players.PlayerAdded:Connect(function(plr)
        updateTeleportList()
        connectHighlightForPlayer(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.06)
            if highlightActive then applyHighlight(plr, true) end
            updateTeleportList()
        end)
    end)
    Players.PlayerRemoving:Connect(function(plr)
        updateTeleportList()
        disconnectHighlightForPlayer(plr)
        flingOffenders[plr] = nil
        launchedPlayers[plr] = nil
        suspectTimers[plr] = nil
        playerData[plr] = nil
        stopHighlightEnforcerForPlayer(plr)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        connectHighlightForPlayer(plr)
        if highlightActive and plr ~= player and plr.Character then
            applyHighlight(plr, true)
        end
    end

    disableEnforcement()
    updateAntiRubberbandState()

    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            if detectorActive then detectorActive = false end
            if antiFlingEnforcerConn then stopAntiFlingEnforcer() end
            stopMovementEnforcer()
            stopHighlightEnforcerForPlayer(player)
            disableNoclip()
            if camBypassActive then disableCamBypass() end
            if velocityActive then
                velocityActive = false
                stopVelocityMode()
            end
            stopNetworkOwnership()
            stopAntiRubberband()
        end
    end)

    player.CharacterAdded:Connect(function(char)
        task.wait(0.12)
        if velocityActive then
            if velocityConn then
                velocityConn:Disconnect()
                velocityConn = nil
            end
            if velocityDeathConn then
                velocityDeathConn:Disconnect()
                velocityDeathConn = nil
            end
            task.delay(0.08, function()
                if velocityActive and player.Character == char then
                    startVelocityMode()
                end
            end)
        end
        maintainNetworkOwnership()
        updateAntiRubberbandState()
    end)

    maintainNetworkOwnership()
end)
