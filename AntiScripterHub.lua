-- LocalScript: AntiScripter (colar em StarterPlayerScripts)
-- Versão completa e protegida: onlyOwner checks, watchdog, e todas as features integradas.
-- Observação: este script foi reconstruído para ser autossuficiente e proteger a GUI contra reparent/clonagem local.
-- A defesa definitiva contra exploits exige validação server-side.

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

    -- Dono fixo do GUI (capturado no load)
    local OWNER_USERID = player.UserId
    local PLACE_KEY = tostring(game.PlaceId)

    local function onlyOwner()
        return Players.LocalPlayer and Players.LocalPlayer.UserId == OWNER_USERID
    end

    -- ===== ScreenGui único =====
    local gui = Instance.new("ScreenGui")
    gui.Name = "AntiScripterGUI_" .. tostring(OWNER_USERID)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Proteção: reparent automático se alguém tentar mover/destroy
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

    -- Watchdog: detecta cópias em outros PlayerGui e remove localmente
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

    -- util para conectar botões de forma segura (só executa se for dono)
    local function secureConnect(button, fn)
        button.MouseButton1Click:Connect(function(...)
            if not onlyOwner() then return end
            pcall(fn, ...)
        end)
    end

    -- ===== UI =====
    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(0, 50, 0, 50)
    local savedX = player:GetAttribute("BotaoPosX") or 40
    local savedY = player:GetAttribute("BotaoPosY") or 40
    mainBtn.Position = UDim2.new(0, savedX, 0, savedY)
    mainBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 220)
    mainBtn.Text = "🛠"
    mainBtn.TextSize = 32
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextColor3 = Color3.new(1,1,1)
    mainBtn.ZIndex = 10000
    mainBtn.Parent = gui
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 18)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 420)
    frame.Position = UDim2.new(0.5, -190, 0.5, -210)
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
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = content

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)

    -- Teleport frame
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

    -- makeBtn helper
    local function makeBtn(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.7, 0, 0, 35)
        b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 14
        b.Font = Enum.Font.GothamSemibold
        b.Parent = content
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local noclipBtn = makeBtn("NOCLIP OFF")
    local antiFlingBtn = makeBtn("ANTI-FLING OFF")
    local detectorBtn = makeBtn("DETECTOR OFF")
    local highlightBtn = makeBtn("HIGHLIGHT OFF")
    local hitboxBtn = makeBtn("HITBOX OFF")

    local flyBtn = makeBtn("FLY OFF")
    flyBtn.Size = UDim2.new(0.7, 0, 0, 40)
    flyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

    local teleportBtn = makeBtn("TELEPORT → PLAYER")
    teleportBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
    teleportBtn.Size = UDim2.new(0.7, 0, 0, 40)

    local bypassBtn = makeBtn("BYPASS OFF")
    bypassBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

    -- WalkSpeed / JumpHeight UI
    local wsContainer = Instance.new("Frame")
    wsContainer.Size = UDim2.new(0.7, 0, 0, 35)
    wsContainer.BackgroundTransparency = 1
    wsContainer.Parent = content

    local wsLabel = Instance.new("TextLabel")
    wsLabel.Size = UDim2.new(0.3, 0, 1, 0)
    wsLabel.BackgroundTransparency = 1
    wsLabel.Text = "WalkSpeed:"
    wsLabel.TextColor3 = Color3.new(1,1,1)
    wsLabel.TextSize = 13
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.TextXAlignment = Enum.TextXAlignment.Left
    wsLabel.Parent = wsContainer

    local wsBox = Instance.new("TextBox")
    wsBox.Size = UDim2.new(0.5, 0, 1, 0)
    wsBox.Position = UDim2.new(0.3, 0, 0, 0)
    wsBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    wsBox.Text = "16"
    wsBox.TextColor3 = Color3.new(1,1,1)
    wsBox.TextSize = 13
    wsBox.Font = Enum.Font.Gotham
    wsBox.Parent = wsContainer
    Instance.new("UICorner", wsBox).CornerRadius = UDim.new(0, 6)

    local applyWsCheck = Instance.new("TextButton")
    applyWsCheck.Size = UDim2.new(0, 35, 0, 35)
    applyWsCheck.Position = UDim2.new(0.85, 0, 0, 0)
    applyWsCheck.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    applyWsCheck.Text = "✓"
    applyWsCheck.TextColor3 = Color3.new(1,1,1)
    applyWsCheck.TextSize = 20
    applyWsCheck.Font = Enum.Font.GothamBold
    applyWsCheck.Parent = wsContainer
    Instance.new("UICorner", applyWsCheck).CornerRadius = UDim.new(0, 8)

    local jhContainer = Instance.new("Frame")
    jhContainer.Size = UDim2.new(0.7, 0, 0, 35)
    jhContainer.BackgroundTransparency = 1
    jhContainer.Parent = content

    local jhLabel = Instance.new("TextLabel")
    jhLabel.Size = UDim2.new(0.3, 0, 1, 0)
    jhLabel.BackgroundTransparency = 1
    jhLabel.Text = "JumpHeight:"
    jhLabel.TextColor3 = Color3.new(1,1,1)
    jhLabel.TextSize = 13
    jhLabel.Font = Enum.Font.Gotham
    jhLabel.TextXAlignment = Enum.TextXAlignment.Left
    jhLabel.Parent = jhContainer

    local jhBox = Instance.new("TextBox")
    jhBox.Size = UDim2.new(0.5, 0, 1, 0)
    jhBox.Position = UDim2.new(0.3, 0, 0, 0)
    jhBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    jhBox.Text = "7.2"
    jhBox.TextColor3 = Color3.new(1,1,1)
    jhBox.TextSize = 13
    jhBox.Font = Enum.Font.Gotham
    jhBox.Parent = jhContainer
    Instance.new("UICorner", jhBox).CornerRadius = UDim.new(0, 6)

    local applyJhCheck = Instance.new("TextButton")
    applyJhCheck.Size = UDim2.new(0, 35, 0, 35)
    applyJhCheck.Position = UDim2.new(0.85, 0, 0, 0)
    applyJhCheck.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    applyJhCheck.Text = "✓"
    applyJhCheck.TextColor3 = Color3.new(1,1,1)
    applyJhCheck.TextSize = 20
    applyJhCheck.Font = Enum.Font.GothamBold
    applyJhCheck.Parent = jhContainer
    Instance.new("UICorner", applyJhCheck).CornerRadius = UDim.new(0, 8)

    local resetBtn = makeBtn("RESET WALK/JUMP")

    -- ===== Estado =====
    local noclipActive = false
    local antiFlingActive = false
    local detectorActive = false
    local highlightActive = false
    local hitboxActive = false
    local bypassActive = false -- when true, enforcement is disabled (allows sprint/dash)

    local noclipConn = nil
    local antiFlingEnforcerConn = nil
    local movementEnforcerConn = nil
    local hitboxOriginals = {}
    local hitboxOriginalTransparency = {}
    local hitboxOriginalCanCollide = {}

    -- savedWalkSpeed / savedJumpHeight são os valores que o enforcer aplica ao jogador
    local savedWalkSpeed = 16
    local savedJumpHeight = 7.2

    -- Flight global parameter
    local FLIGHT_BASE_SPEED = 80 -- will be updated when user changes WalkSpeed (multiplied)

    -- defaults por jogo (serão carregados/gravados em atributos do player)
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

    local HISTORY_SIZE = 6
    local SPIKE_DELTA_THRESHOLD = 150
    local SPIKE_SPEED_MIN = 60
    local WALK_SPEED_LIMIT = 200 -- allow higher if desired
    local JUMP_HEIGHT_LIMIT = 50
    local ANGULAR_SPEED_LIMIT = 30
    local LAUNCH_Y_THRESHOLD = -50
    local SUSTAINED_FRAMES = 3 -- frames required to confirm sustained abnormal speed

    -- addLog no-op (barra removida)
    local function addLog(...) end

    -- ===== Enforcer WalkSpeed + JumpPower =====
    local function enforceMovementOnHumanoid(hum)
        if not hum then return end
        pcall(function()
            if type(savedWalkSpeed) == "number" and savedWalkSpeed > 0 then
                hum.WalkSpeed = math.clamp(savedWalkSpeed, 0, WALK_SPEED_LIMIT)
            end

            if type(savedJumpHeight) == "number" and savedJumpHeight >= 0 then
                local gravity = Workspace.Gravity or 196.2
                local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
                local maxJumpPower = math.sqrt(JUMP_HEIGHT_LIMIT * 2 * gravity)
                hum.JumpPower = math.clamp(jumpPower, 0, maxJumpPower)
                pcall(function() hum.JumpHeight = math.clamp(savedJumpHeight, 0, JUMP_HEIGHT_LIMIT) end)
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

    player.CharacterAdded:Connect(function()
        task.wait(0.4)
        if not bypassActive and onlyOwner() then
            enforceMovement()
        end
    end)

    -- ===== AGGRESSIVE HUMANOID WATCH (vence loops locais e sprints) =====
    local humanoidWatchConnections = {} -- [humanoid] = {renderConn, propConns = {}, diedConn}

    local function disconnectWatcherForHumanoid(hum)
        if not hum then return end
        local entry = humanoidWatchConnections[hum]
        if not entry then return end
        if entry.renderConn then
            entry.renderConn:Disconnect()
        end
        if entry.diedConn then
            entry.diedConn:Disconnect()
        end
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

        -- continuous high-frequency enforcement (RenderStepped)
        renderConn = RunService.RenderStepped:Connect(function()
            if bypassActive or not onlyOwner() then return end
            if not hum or hum.Health <= 0 then return end
            pcall(function()
                if type(savedWalkSpeed) == "number" and savedWalkSpeed > 0 then
                    hum.WalkSpeed = math.clamp(savedWalkSpeed, 0, WALK_SPEED_LIMIT)
                end
                if type(savedJumpHeight) == "number" and savedJumpHeight >= 0 then
                    local gravity = Workspace.Gravity or 196.2
                    local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
                    hum.JumpPower = math.clamp(jumpPower, 0, math.sqrt(JUMP_HEIGHT_LIMIT * 2 * gravity))
                    pcall(function() hum.JumpHeight = math.clamp(savedJumpHeight, 0, JUMP_HEIGHT_LIMIT) end)
                end
            end)
        end)

        -- property watchers with quick retries
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
            hum.WalkSpeed = math.clamp(savedWalkSpeed, 0, WALK_SPEED_LIMIT)
        end)
        makePropWatcher("JumpPower", function()
            local gravity = Workspace.Gravity or 196.2
            local jumpPower = math.sqrt(math.max(savedJumpHeight, 0) * 2 * gravity)
            hum.JumpPower = math.clamp(jumpPower, 0, math.sqrt(JUMP_HEIGHT_LIMIT * 2 * gravity))
        end)
        makePropWatcher("JumpHeight", function()
            hum.JumpHeight = math.clamp(savedJumpHeight, 0, JUMP_HEIGHT_LIMIT)
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
        bypassActive = false
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
        bypassActive = true
        stopMovementEnforcer()
        disconnectAllHumanoidWatchers()
    end

    -- start enforcement by default
    enableEnforcement()

    -- ===== Funções para detectar e armazenar defaults do jogo atual =====
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

        local char = player.Character
        if not char then
            char = player.Character or player.CharacterAdded:Wait()
        end
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local detectedWS = hum.WalkSpeed or nil
            local detectedJH = nil
            if hum.JumpHeight and type(hum.JumpHeight) == "number" and hum.JumpHeight > 0 then
                detectedJH = hum.JumpHeight
            else
                if hum.JumpPower and type(hum.JumpPower) == "number" and hum.JumpPower > 0 then
                    detectedJH = computeJumpHeightFromPower(hum.JumpPower)
                end
            end

            if detectedWS and type(detectedWS) == "number" and detectedJH and type(detectedJH) == "number" then
                setSavedDefaultsForPlace(detectedWS, detectedJH)
                return detectedWS, detectedJH
            end
        end

        setSavedDefaultsForPlace(savedWalkSpeed, savedJumpHeight)
        return savedWalkSpeed, savedJumpHeight
    end

    -- ===== Hitbox remover =====
    local function removeHitboxes()
        if not onlyOwner() then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                for _, part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name == "Head" then
                        if not hitboxOriginals[part] then
                            hitboxOriginals[part] = part.Size
                            hitboxOriginalTransparency[part] = part.Transparency
                            hitboxOriginalCanCollide[part] = part.CanCollide
                        end
                        part.Size = Vector3.new(0.01, 0.01, 0.01)
                        part.Transparency = 1
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    local function revertHitboxes()
        if not onlyOwner() then return end
        for part, original in pairs(hitboxOriginals) do
            if part and part.Parent then
                part.Size = original
                if hitboxOriginalTransparency[part] ~= nil then
                    part.Transparency = hitboxOriginalTransparency[part]
                end
                if hitboxOriginalCanCollide[part] ~= nil then
                    part.CanCollide = hitboxOriginalCanCollide[part]
                end
            end
        end
        hitboxOriginals = {}
        hitboxOriginalTransparency = {}
        hitboxOriginalCanCollide = {}
    end

    -- ===== Anti-fling =====
    local function updateAntiFling()
        if not onlyOwner() then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            root.CanCollide = not antiFlingActive

            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("BodyMover") or obj:IsA("BodyForce") or obj:IsA("BodyVelocity")
                or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyGyro") or obj:IsA("VectorForce")
                or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity") or obj:IsA("AlignPosition")
                or obj:IsA("AlignOrientation") then
                    obj:Destroy()
                end
            end
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

                if root.AssemblyAngularVelocity.Magnitude > ANGULAR_SPEED_LIMIT then
                    root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end
                if root.AssemblyLinearVelocity.Magnitude > 40 then
                    root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(root.AssemblyLinearVelocity.Y, -50, 50), 0)
                end

                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored then
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

    -- ===== Noclip =====
    local function enableNoclip()
        if not onlyOwner() then return end
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and not part.Anchored then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end)
    end

    local function disableNoclip()
        if not onlyOwner() then return end
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end

        pcall(function()
            local char = player.Character
            if not char then return end

            for i = 1, 4 do
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
                task.wait()
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                root.Velocity = Vector3.new(0,0,0)
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
                task.wait(0.05)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.05)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    -- ===== Teleport list update =====
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
                if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
                    addLog("Não foi possível teleportar para " .. plr.Name)
                    return
                end

                local myChar = player.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                    addLog("Teleportado para → " .. displayName .. " (@" .. userName .. ")")
                end

                teleportFrame.Visible = false
                content.Visible = true
            end)
        end
    end

    -- ===== Highlight (reaplica nome e outline automaticamente) =====
    local highlightConnections = {} -- [player] = {charConn = connection, nameConn = connection, removingConn = connection}
    local highlightEnforcerConnections = {} -- [player] = RenderStepped connection to enforce our highlight properties

    local function clearHighlightForCharacter(char)
        if not char then return end
        -- remove our highlight(s) and billboards
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
        -- ensure only our highlight has the special name
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

        -- enforce properties that make it render on top and visible
        ourHl.FillTransparency = 1
        ourHl.OutlineColor = Color3.fromRGB(0, 255, 0)
        ourHl.OutlineTransparency = 0
        ourHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    local function neutralizeOtherHighlights(char)
        -- try to neutralize other highlights created by the game by increasing their transparency
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
            -- enforce our highlight and neutralize others every frame
            createOrUpdateOurHighlight(plr.Character)
            neutralizeOtherHighlights(plr.Character)
            -- ensure billboard text updated
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
            if not plr then return end
            if plr == player then return end -- skip local player if desired
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
            -- espera head aparecer (mais robusto para resets)
            local head = char:FindFirstChild("Head")
            if not head then
                head = char:WaitForChild("Head", 2)
            end
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

        -- If character removed, ensure we stop enforcer and cleanup
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
                    local head = plr.Character:FindFirstChild("Head")
                    if not head then
                        head = plr.Character:FindFirstChild("Head") or plr.Character:WaitForChild("Head", 1)
                    end
                    if head then
                        applyHighlight(plr, true)
                    end
                end
            end
        end
    end

    local function disableHighlightsForAll()
        for _, plr in ipairs(Players:GetPlayers()) do
            disconnectHighlightForPlayer(plr)
        end
        -- also clear any leftover highlights in workspace characters
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                clearHighlightForCharacter(plr.Character)
            end
        end
    end

    -- ===== Suspect helpers =====
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

    local suspectTimers = {}
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
            bg.Size = UDim2.new(0, 220, 0, 35)
            bg.StudsOffset = Vector3.new(0, 3.5, 0)
            bg.AlwaysOnTop = true
            bg.Parent = head

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(255, 60, 60)
            label.Text = plr.DisplayName and (plr.DisplayName .. " - Suspeito") or (plr.Name .. " - Suspeito")
            label.Parent = bg

            if reason:lower():find("fling") or reason:lower():find("spin") then
                addFlingOffender(plr)
            end
            if reason:lower():find("lanço") or reason:lower():find("teleport") or reason:lower():find("posição") then
                addLaunchedPlayer(plr)
            end

            suspectTimers[plr] = tick() + 8
        end)
    end

    -- ===== Detector aprimorado (reduz falsos positivos) =====
    local speedHist = {}        -- [plr] = {speeds...}
    local sustainedCount = {}   -- [plr] = frames with high speed
    RunService.Heartbeat:Connect(function(dt)
        if not detectorActive then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == player then continue end
            local char = plr.Character
            if not char then continue end

            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then continue end

            local vel = root.AssemblyLinearVelocity or Vector3.new(0,0,0)
            local angVel = root.AssemblyAngularVelocity or Vector3.new(0,0,0)
            local speed = vel.Magnitude
            local angSpeed = angVel.Magnitude

            speedHist[plr] = speedHist[plr] or {}
            table.insert(speedHist[plr], 1, speed)
            while #speedHist[plr] > HISTORY_SIZE do table.remove(speedHist[plr]) end

            local prev = speedHist[plr][2] or 0
            local delta = speed - prev

            sustainedCount[plr] = sustainedCount[plr] or 0

            local isSpike = (speed > SPIKE_SPEED_MIN and delta > SPIKE_DELTA_THRESHOLD)
            if isSpike then
                sustainedCount[plr] = sustainedCount[plr] + 1
            elseif speed > SPIKE_SPEED_MIN then
                sustainedCount[plr] = sustainedCount[plr] + 1
            else
                sustainedCount[plr] = 0
            end

            local reason = nil
            if hum.WalkSpeed and hum.WalkSpeed > WALK_SPEED_LIMIT then
                reason = "WalkSpeed alto"
            end
            if (hum.JumpHeight and hum.JumpHeight > JUMP_HEIGHT_LIMIT) or (hum.JumpPower and hum.JumpPower > 100) then
                reason = reason or "Jump alterado"
            end
            if (isSpike and speed > SPIKE_SPEED_MIN) or (sustainedCount[plr] >= SUSTAINED_FRAMES and speed > SPIKE_SPEED_MIN) then
                reason = reason or "Fling detectado (velocity)"
            end
            if angSpeed > ANGULAR_SPEED_LIMIT then
                reason = reason or "Spin/Fling detectado (angular)"
            end
            if vel.Y and vel.Y < LAUNCH_Y_THRESHOLD then
                reason = reason or "Lanço vertical extremo"
            end

            if reason then
                markSuspect(plr, reason)
            end
        end

        -- clear expired suspect tags
        local now = tick()
        for plr, expire in pairs(suspectTimers) do
            if now > expire then
                if plr.Character and plr.Character:FindFirstChild("Head") then
                    local head = plr.Character.Head
                    local tag = head:FindFirstChild("SuspectTag")
                    if tag then tag:Destroy() end
                end
                suspectTimers[plr] = nil
            end
        end
    end)

    -- ===== Fly substituído pelo novo Fly (PC / Mobile / Gamepad) =====
    local cam = workspace.CurrentCamera

    -- ====== CONFIG (uses FLIGHT_BASE_SPEED defined above) ======
    local SPRINT_MULT = 1.6
    local ASCEND_SPEED = 60
    local SMOOTHNESS = 0.18
    local MAX_FORCE = 1e5
    local TOUCH_DESCEND_SIDE = 0.5
    -- ====================

    -- Estado
    local flying = false
    local rootPart, humanoid
    local bv, bg
    local currentVelocity = Vector3.new()
    local targetVelocity = Vector3.new()
    local verticalTarget = 0
    local sprinting = false

    -- Inversões manuais (se precisar)
    local invertForward = false
    local invertRight = false

    -- Variáveis para gamepad thumbstick
    local gamepadStick = Vector2.new(0,0)

    -- Inicia forças de voo
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

        -- ensure camera reference
        cam = workspace.CurrentCamera or cam
        -- update UI button
        flyBtn.Text = "FLY ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        addLog("Fly ativado")
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

        -- update UI button
        flyBtn.Text = "FLY OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        addLog("Fly desativado")
    end

    -- Entradas
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 then
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
        delay(0.12, function()
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

    -- Função que unifica inputs
    local function getInputAxes()
        local inputX, inputZ = 0, 0

        -- 1) Prioriza Humanoid.MoveDirection (joystick padrão mobile)
        if humanoid then
            local md = humanoid.MoveDirection
            if md and md.Magnitude > 0.01 and cam then
                -- Use a projeção horizontal da câmera para calcular forward (evita problema ao olhar 90 graus)
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

                -- Se o resultado for insignificante, não use esse caminho (deixe cair para gamepad/teclado)
                if math.abs(inputX) > 0.01 or math.abs(inputZ) > 0.01 then
                    if invertForward then inputZ = -inputZ end
                    if invertRight then inputX = -inputX end

                    -- normalizar se necessário
                    local mag = math.sqrt(inputX*inputX + inputZ*inputZ)
                    if mag > 1 then
                        inputX = inputX / mag
                        inputZ = inputZ / mag
                    end

                    return inputX, inputZ
                end
            end
        end

        -- 2) Gamepad thumbstick (mapeamento comum: Y negativo = frente)
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

        -- 3) Teclado WASD
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

    -- Loop principal com correção de lateralidade e ajuste instantâneo de rotação (inclui pitch)
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

            -- vertical: prioridade para input direto (space / touch), senão usa componente Y do look * inputZ
            local vy = 0
            if verticalTarget > 0 then
                vy = ASCEND_SPEED
            elseif verticalTarget < 0 then
                vy = -ASCEND_SPEED
            else
                vy = 0
            end

            local desiredY
            if math.abs(forward.Y) > 0.001 and math.abs(iz) > 0.001 then
                desiredY = math.clamp(forward.Y * iz * speed, -ASCEND_SPEED, ASCEND_SPEED)
            else
                desiredY = vy
            end

            targetVelocity = Vector3.new(horiz.X, desiredY, horiz.Z)

            -- suavização dependente de frame-rate (melhora resposta)
            local alpha = 1 - math.exp(-SMOOTHNESS * math.max(dt, 0.001) * 60)
            currentVelocity = currentVelocity:Lerp(targetVelocity, math.clamp(alpha, 0, 1))
            if bv then bv.Velocity = currentVelocity end

            -- Atualiza BodyGyro para olhar exatamente na direção da câmera (inclui pitch)
            if bg and rootPart then
                bg.CFrame = CFrame.new(rootPart.Position, rootPart.Position + cam.CFrame.LookVector)
            end

            -- Sincroniza a velocidade física para evitar "puxões" e zera rotação residual
            if rootPart and rootPart:IsA("BasePart") then
                rootPart.AssemblyLinearVelocity = bv and bv.Velocity or Vector3.new(0,0,0)
                rootPart.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    -- Respawn / inicialização
    player.CharacterAdded:Connect(function(char)
        wait(0.35)
        stopFly()
    end)

    -- Do NOT auto-start fly on script load; user must press the button
    if player.Character then
        wait(0.35)
        stopFly()
    end

    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            stopFly()
        end
    end)

    -- ===== UI Interactions (draggable corrigido e protegido) =====
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

    noclipBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        noclipActive = not noclipActive
        if noclipActive then
            enableNoclip()
            noclipBtn.Text = "NOCLIP ON"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            addLog("Noclip ativado")
        else
            disableNoclip()
            noclipBtn.Text = "NOCLIP OFF"
            noclipBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            addLog("Noclip desativado")
        end
    end)

    antiFlingBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        antiFlingActive = not antiFlingActive
        if antiFlingActive then
            startAntiFlingEnforcer()
            antiFlingBtn.Text = "ANTI-FLING ON"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            addLog("Anti-fling ativado")
        else
            stopAntiFlingEnforcer()
            antiFlingBtn.Text = "ANTI-FLING OFF"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            updateAntiFling()
            addLog("Anti-fling desativado")
        end
    end)

    detectorBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        detectorActive = not detectorActive
        detectorBtn.Text = "DETECTOR " .. (detectorActive and "ON" or "OFF")
        detectorBtn.BackgroundColor3 = detectorActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(45, 45, 45)
        addLog("Detector " .. (detectorActive and "ativado" or "desativado"))
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
            speedHist = {}
            sustainedCount = {}
        end
    end)

    highlightBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        highlightActive = not highlightActive
        if highlightActive then
            highlightBtn.Text = "HIGHLIGHT ON"
            highlightBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            addLog("Highlight ativado")
            enableHighlightsForAll()
        else
            highlightBtn.Text = "HIGHLIGHT OFF"
            highlightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            addLog("Highlight desativado")
            disableHighlightsForAll()
        end
    end)

    hitboxBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        hitboxActive = not hitboxActive
        if hitboxActive then
            hitboxBtn.Text = "HITBOX REMOVED"
            hitboxBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            addLog("Hitbox removida (Head minimizado)")
            removeHitboxes()
        else
            hitboxBtn.Text = "HITBOX OFF"
            hitboxBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            addLog("Hitbox restaurada")
            revertHitboxes()
        end
    end)

    bypassBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        bypassActive = not bypassActive
        if bypassActive then
            bypassBtn.Text = "BYPASS ON"
            bypassBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            -- disable enforcement so sprint/dash works
            disableEnforcement()
            addLog("Bypass Walk/Jump ativado (enforcement desligado)")
        else
            bypassBtn.Text = "BYPASS OFF"
            bypassBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            -- re-enable enforcement
            enableEnforcement()
            addLog("Bypass Walk/Jump desativado (enforcement ligado)")
        end
    end)

    flyBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        if not flying then
            startFly()
        else
            stopFly()
        end
    end)

    applyWsCheck.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        local val = tonumber(wsBox.Text) or savedWalkSpeed
        val = math.clamp(val, 0, WALK_SPEED_LIMIT)
        savedWalkSpeed = val
        player:SetAttribute("SavedWalkSpeed", savedWalkSpeed)

        -- Also update flight base speed: use a multiplier so flight remains noticeably faster.
        local multiplier = 5
        FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * multiplier, 10, 1000)

        if not bypassActive then
            enforceMovement()
        end
        addLog("WalkSpeed definido para " .. tostring(savedWalkSpeed) .. " (Flight speed = " .. tostring(FLIGHT_BASE_SPEED) .. ")")
    end)

    applyJhCheck.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        local val = tonumber(jhBox.Text) or savedJumpHeight
        val = math.clamp(val, 0, JUMP_HEIGHT_LIMIT)
        savedJumpHeight = val
        player:SetAttribute("SavedJumpHeight", savedJumpHeight)
        if not bypassActive then
            enforceMovement()
        end
        addLog("JumpHeight definido para " .. tostring(savedJumpHeight))
    end)

    resetBtn.MouseButton1Click:Connect(function()
        if not onlyOwner() then return end
        local defaultWS, defaultJH = captureGameDefaultsIfMissing()
        if defaultWS and defaultJH then
            savedWalkSpeed = defaultWS
            savedJumpHeight = defaultJH
            wsBox.Text = tostring(savedWalkSpeed)
            jhBox.Text = tostring(savedJumpHeight)
            player:SetAttribute("SavedWalkSpeed", savedWalkSpeed)
            player:SetAttribute("SavedJumpHeight", savedJumpHeight)

            -- update flight speed accordingly
            FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * 5, 10, 1000)

            if not bypassActive then
                enforceMovement()
            end
            addLog("Walk/Jump resetados para os defaults deste jogo: " .. tostring(savedWalkSpeed) .. " / " .. tostring(savedJumpHeight))
        else
            addLog("Não foi possível detectar defaults do jogo; mantendo valores atuais")
        end
    end)

    -- ===== Inicialização: ao entrar no jogo, captura defaults se necessário e aplica valores salvos =====
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

        -- set flight speed based on saved walk speed
        FLIGHT_BASE_SPEED = math.clamp(savedWalkSpeed * 5, 10, 1000)

        if not bypassActive then
            enforceMovement()
        end
    end

    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = player.Character:WaitForChild("Humanoid", 2)
        end
        initializeDefaultsOnJoin()
    else
        player.CharacterAdded:Connect(function()
            task.wait(0.4)
            initializeDefaultsOnJoin()
        end)
    end

    -- Update teleport list and highlight connections when players join/leave
    Players.PlayerAdded:Connect(function(plr)
        updateTeleportList()
        connectHighlightForPlayer(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.06)
            if highlightActive then applyHighlight(plr, true) end
            if hitboxActive then removeHitboxes() end
            updateTeleportList()
        end)
    end)
    Players.PlayerRemoving:Connect(function(plr)
        updateTeleportList()
        disconnectHighlightForPlayer(plr)
        flingOffenders[plr] = nil
        launchedPlayers[plr] = nil
        speedHist[plr] = nil
        sustainedCount[plr] = nil
        suspectTimers[plr] = nil
        stopHighlightEnforcerForPlayer(plr)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        connectHighlightForPlayer(plr)
        if highlightActive and plr ~= player and plr.Character then
            applyHighlight(plr, true)
        end
    end

    -- Inicializações finais
    wsBox.Text = tostring(savedWalkSpeed)
    jhBox.Text = tostring(savedJumpHeight)

    if onlyOwner() then enableEnforcement() else disableEnforcement() end

    -- Cleanup on leave
    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            -- disconnect everything
            if detectorActive then detectorActive = false end
            if antiFlingEnforcerConn then stopAntiFlingEnforcer() end
            stopMovementEnforcer()
            stopHighlightEnforcerForPlayer(player)
            disableNoclip()
            revertHitboxes()
        end
    end)
end)
