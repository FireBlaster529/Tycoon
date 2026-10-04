-- Tycoon Auto Buy + Auto Rebirth
-- Rebirth uses the original ClickDetector + GUI confirmation.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local env = getgenv()
local KEY = "__TycoonAutoBuyRebirth"

if env[KEY] and env[KEY].stop then
	env[KEY].stop()
end

local state = {
	running = true,
	autoBuy = false,
	autoRebirth = false,
	rebirthMode = "Ready",
	rebirthing = false,
	lastRebirth = -math.huge,
	connections = {},
	target = nil,
	phase = "select",
	phaseTime = 0,
}

env[KEY] = state

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonAutoBuyRebirth"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 195)
frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
frame.ClipsDescendants = true
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Auto Buy + Auto Rebirth"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1, 1, 1)
title.Active = true
title.Parent = frame

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.connections, connection)
	return connection
end

local function makeButton(y)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(10, y)
	button.Size = UDim2.new(1, -20, 0, 30)
	button.Font = Enum.Font.Gotham
	button.TextSize = 13
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	button.Parent = frame
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	return button
end

local buyButton = makeButton(35)
local rebirthButton = makeButton(70)
local modeButton = makeButton(105)

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(10, 140)
status.Size = UDim2.new(1, -20, 0, 45)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(190, 190, 200)
status.Parent = frame

local minimize = Instance.new("TextButton")
minimize.Position = UDim2.new(1, -32, 0, 2)
minimize.Size = UDim2.fromOffset(28, 26)
minimize.BackgroundTransparency = 1
minimize.Text = "−"
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Parent = frame

local function refresh()
	buyButton.Text = "Auto Buy: " .. (state.autoBuy and "ON" or "OFF")
	rebirthButton.Text = "Auto Rebirth: " .. (state.autoRebirth and "ON" or "OFF")
	modeButton.Text = "Rebirth Trigger: " .. state.rebirthMode

	buyButton.BackgroundColor3 = state.autoBuy
		and Color3.fromRGB(45, 155, 90)
		or Color3.fromRGB(40, 40, 50)

	rebirthButton.BackgroundColor3 = state.autoRebirth
		and Color3.fromRGB(45, 155, 90)
		or Color3.fromRGB(40, 40, 50)
end

local function resetTarget()
	state.target = nil
	state.phase = "select"
	state.buyRoot = nil
end

connect(buyButton.MouseButton1Click, function()
	state.autoBuy = not state.autoBuy
	resetTarget()
	refresh()
end)

connect(rebirthButton.MouseButton1Click, function()
	state.autoRebirth = not state.autoRebirth
	refresh()
end)

connect(modeButton.MouseButton1Click, function()
	state.rebirthMode = state.rebirthMode == "Ready"
		and "Essence Cap" or "Ready"
	refresh()
end)

local minimized = false
connect(minimize.MouseButton1Click, function()
	minimized = not minimized
	frame.Size = UDim2.fromOffset(260, minimized and 30 or 195)
	buyButton.Visible = not minimized
	rebirthButton.Visible = not minimized
	modeButton.Visible = not minimized
	status.Visible = not minimized
	minimize.Text = minimized and "+" or "−"
end)

local dragging, dragStart, frameStart, activeTouch

connect(title.InputBegan, function(input)
	if dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = frame.Position
		activeTouch = input.UserInputType == Enum.UserInputType.Touch
			and input or nil
	end
end)

connect(UserInputService.InputChanged, function(input)
	if not dragging then return end
	if (activeTouch and input == activeTouch)
		or (not activeTouch
			and input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			frameStart.X.Scale, frameStart.X.Offset + delta.X,
			frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
		)
	end
end)

connect(UserInputService.InputEnded, function(input)
	if (activeTouch and input == activeTouch)
		or (not activeTouch
			and input.UserInputType == Enum.UserInputType.MouseButton1) then
		dragging = false
		activeTouch = nil
	end
end)

function state.stop()
	state.running = false
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	gui:Destroy()
	if env[KEY] == state then env[KEY] = nil end
end

refresh()

local multipliers = {
	K = 1e3, M = 1e6, B = 1e9, T = 1e12,
	QA = 1e15, QI = 1e18, SX = 1e21,
	SP = 1e24, O = 1e27, N = 1e30, D = 1e33,
}

local function parseNumber(text)
	text = tostring(text):upper():gsub(",", "")
	if text:find("FREE", 1, true) then return 0 end
	local number, suffix = text:match("(%d+%.?%d*)%s*(%a*)")
	number = tonumber(number)
	if not number then return nil end
	if suffix ~= "" and not multipliers[suffix] then return nil end
	return number * (multipliers[suffix] or 1)
end

local function visible(object)
	if not object or not object.Parent then return false end
	local current = object
	while current do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		elseif current:IsA("LayerCollector") and not current.Enabled then
			return false
		end
		current = current.Parent
	end
	return true
end

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function partOf(object)
	if object:IsA("BasePart") then return object end
	local part = object:FindFirstChild("Head") or object:FindFirstChild("Part")
	if part and part:IsA("BasePart") then return part end
	return object:FindFirstChildWhichIsA("BasePart", true)
end

local function active(button)
	if not button or not button:IsDescendantOf(Workspace) then return false end
	local part = partOf(button)
	if not part or part.Transparency >= 1 then return false end
	local billboard = button:FindFirstChildWhichIsA("BillboardGui", true)
	return not billboard or billboard.Enabled
end

local function positionOf(object)
	if object:IsA("Model") or object:IsA("BasePart") then
		return object:GetPivot().Position
	end
	local part = partOf(object)
	return part and part.Position
end

local cachedPlot, cachedTycoon
local nextResolve = 0

local function resolveTycoon()
	if os.clock() < nextResolve then
		if cachedPlot and cachedPlot.Parent
			and cachedTycoon and cachedTycoon.Parent then
			return cachedTycoon
		end
		return nil
	end

	nextResolve = os.clock() + 2
	cachedPlot, cachedTycoon = nil, nil

	local plots = Workspace:FindFirstChild("Plots")
	local tycoons = Workspace:FindFirstChild("Tycoons")
	if not plots or not tycoons then return nil end

	for _, plot in ipairs(plots:GetChildren()) do
		local sign = plot:FindFirstChild("SignPlace")
		local label = sign and sign:FindFirstChild("NameLabel", true)
		if label and label:IsA("TextLabel") then
			local name = label.Text:match("^%s*(.-)%s*$"):lower()
			if name == player.Name:lower()
				or name == player.DisplayName:lower() then
				cachedPlot = plot
				break
			end
		end
	end

	if not cachedPlot then return nil end
	local plotPosition = positionOf(cachedPlot)
	if not plotPosition then return nil end

	local shortest = math.huge
	for _, tycoon in ipairs(tycoons:GetChildren()) do
		local position = positionOf(tycoon)
		if position and tycoon:FindFirstChild("Buttons") then
			local distance = (position - plotPosition).Magnitude
			if distance < shortest then
				shortest = distance
				cachedTycoon = tycoon
			end
		end
	end
	return cachedTycoon
end

local function cashAmount()
	local stats = player:FindFirstChild("leaderstats") or player:FindFirstChild("stats")
	local value = stats and (
		stats:FindFirstChild("Cash")
		or stats:FindFirstChild("Money")
		or stats:FindFirstChild("Coins")
	)

	if value and value:IsA("ValueBase") then
		local amount = tonumber(value.Value) or parseNumber(value.Value)
		if amount then return amount end
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	local system = playerGui and playerGui:FindFirstChild("System")
	local list = system and system:FindFirstChild("PlayerList")
	local holder = list and list:FindFirstChild("Holder")
	local ownFrame = holder and holder:FindFirstChild(player.Name)

	if ownFrame then
		for _, object in ipairs(ownFrame:GetDescendants()) do
			if object:IsA("TextLabel") then
				local name = object.Name:lower()
				if name:find("cash") or name:find("money")
					or object.Text:find("$", 1, true) then
					local amount = parseNumber(object.Text)
					if amount then return amount end
				end
			end
		end
	end
	return 0
end

local priceCache = setmetatable({}, {__mode = "k"})
local buyAttempts = setmetatable({}, {__mode = "k"})

local function priceOf(button)
	local label = priceCache[button]
	if label and label.Parent then
		return visible(label) and parseNumber(label.Text) or nil
	end

	local display = button:FindFirstChild("PriceDisplay", true)
	label = display and (
		display:IsA("TextLabel") and display
		or display:FindFirstChildWhichIsA("TextLabel", true)
	)

	if not label then
		for _, object in ipairs(button:GetDescendants()) do
			if object:IsA("TextLabel") and visible(object) then
				if object.Text:find("$", 1, true)
					or object.Text:upper():find("FREE", 1, true) then
					label = object
					break
				end
			end
		end
	end

	if label then
		priceCache[button] = label
		return visible(label) and parseNumber(label.Text) or nil
	end

	if button.Name:upper():find("FREE", 1, true) then return 0 end
	return nil
end

local function updateBuy()
	local tycoon = resolveTycoon()
	local buttons = tycoon and tycoon:FindFirstChild("Buttons")
	local root = rootPart()
	local now = os.clock()

	if not buttons or not root then
		resetTarget()
		status.Text = "Waiting for your plot / character"
		return
	end

	local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		resetTarget()
		return
	end

	if state.buyRoot and state.buyRoot ~= root then resetTarget() end

	local cash = cashAmount()
	local target = state.target

	if target then
		local cost = active(target) and priceOf(target)
		if target.Parent ~= buttons or cost == nil or cost > cash then
			buyAttempts[target] = nil
			resetTarget()
			target = nil
		end
	end

	if not target then
		local cheapest, nearest = math.huge, math.huge

		for _, button in ipairs(buttons:GetChildren()) do
			local attempt = buyAttempts[button]
			if active(button) and (not attempt or now >= attempt.retryAt) then
				local cost = priceOf(button)
				local part = partOf(button)
				if cost ~= nil and cost <= cash and part then
					local distance = (part.Position - root.Position).Magnitude
					if cost < cheapest or (cost == cheapest and distance < nearest) then
						target, cheapest, nearest = button, cost, distance
					end
				end
			end
		end

		if not target then
			status.Text = "Waiting for cash / retrying buttons"
			return
		end

		state.target = target
		state.buyRoot = root
		state.phase = "approach"
	end

	local part = partOf(target)
	if not part then resetTarget() return end

	status.Text = "Buying: " .. target.Name

	if state.phase == "approach" then
		-- Leave the touch area before entering again.
		local distance = math.max(part.Size.X, part.Size.Z) / 2 + 5
		local outside = part.Position + Vector3.new(distance, 3, 0)

		root.CFrame = CFrame.new(outside, part.Position)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		state.phase = "enter"
		state.phaseTime = now

	elseif state.phase == "enter" and now - state.phaseTime >= 0.2 then
		local top = part.Position.Y + part.Size.Y / 2
		local rootHeight = humanoid.HipHeight + root.Size.Y / 2

		root.CFrame = CFrame.new(
			part.Position.X,
			top + rootHeight + 0.15,
			part.Position.Z
		)
		root.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
		root.AssemblyAngularVelocity = Vector3.zero

		state.phase = "wait"
		state.phaseTime = now

	elseif state.phase == "wait" and now - state.phaseTime >= 1 then
		-- Retry later, allowing other affordable buttons to be bought.
		local previous = buyAttempts[target]
		local failures = math.min((previous and previous.failures or 0) + 1, 4)
		buyAttempts[target] = {
			failures = failures,
			retryAt = now + failures * 2,
		}
		resetTarget()
	end
end

local function notificationHasText(notice, phrase)
	if not notice then return false end
	for _, object in ipairs(notice:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton"))
			and visible(object) then
			local text = object.Text:lower()
			if phrase then
				if text:find(phrase, 1, true) then return true end
			elseif text:match("%S") and text ~= "n/a" then
				return true
			end
		end
	end
	return false
end

local function rebirthReady()
	local playerGui = player:FindFirstChild("PlayerGui")
	local system = playerGui and playerGui:FindFirstChild("System")
	if not system then return false end

	local notifications = system:FindFirstChild("Notifications")
	local holder = notifications and notifications:FindFirstChild("NotiHolder")

	if state.rebirthMode == "Essence Cap" then
		return notificationHasText(
			holder and holder:FindFirstChild("EssenceCappedTemp"),
			"your essence is capped"
		)
	end

	-- Original RebirthNotification, plus the original progress display.
	if notificationHasText(holder and holder:FindFirstChild("RebirthNotification")) then
		return true
	end

	local progressFrame = system:FindFirstChild("RebirthProgress")
	local progress = progressFrame and progressFrame:FindFirstChild("Progress")
	local label = progress and progress:FindFirstChild("TextLabel")
	if not label or not label:IsA("TextLabel") then return false end

	local text = label.Text
	if text:upper():find("COMPLETE", 1, true) then return true end

	local percent = tonumber(text:match("(%d+%.?%d*)%%"))
	if percent and percent >= 100 then return true end

	local currentText, maximumText = text:match(
		"([%d%,%.%a]+)%s*/%s*([%d%,%.%a]+)"
	)
	if currentText and maximumText then
		local current = parseNumber(currentText)
		local maximum = parseNumber(maximumText)
		if current and maximum and maximum > 0 then
			return math.max(current, cashAmount()) >= maximum
		end
	end

	return false
end

local function clickGui(button)
	if not visible(button) then return end

	local position = button.AbsolutePosition + button.AbsoluteSize / 2
	local screenGui = button:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and not screenGui.IgnoreGuiInset then
		local inset = game:GetService("GuiService"):GetGuiInset()
		position += inset
	end

	local input = game:GetService("VirtualInputManager")
	input:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1)
	task.wait(0.1)
	input:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1)
end

local function findRebirthConfirmation()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	local main = playerGui:FindFirstChild("Main")
	local rebirthGui = main and main:FindFirstChild("Rebirth", true)
	local searchRoot = rebirthGui or playerGui

	for _, object in ipairs(searchRoot:GetDescendants()) do
		if object:IsA("GuiButton") and visible(object) then
			local name = object.Name:upper()
			local text = object:IsA("TextButton") and object.Text:upper() or ""
			if name == "REBIRTH" or name == "REBIRTHBUTTON"
				or text:find("REBIRTH", 1, true) then
				return object
			end
		end
	end
	return nil
end

local function startRebirth()
	if state.rebirthing or os.clock() - state.lastRebirth < 6 then return end

	state.rebirthing = true
	state.lastRebirth = os.clock()
	resetTarget()

	task.spawn(function()
		local success, err = pcall(function()
			status.Text = "Rebirthing..."

			local obelisk = Workspace:FindFirstChild("Obelisk")
			local button = obelisk and obelisk:FindFirstChild("RebirthButton")
			local clickPart = button and button:FindFirstChild("Click")
			local detector = clickPart and clickPart:FindFirstChildOfClass("ClickDetector")

			if not detector then error("Rebirth ClickDetector not found") end
			if type(fireclickdetector) ~= "function" then
				error("Executor does not provide fireclickdetector")
			end

			detector.MaxActivationDistance = math.huge
			fireclickdetector(detector)

			-- Poll briefly so slower-loading confirmation GUIs are handled.
			local deadline = os.clock() + 3
			task.wait(0.4)

			while state.running and state.autoRebirth and os.clock() < deadline do
				local confirmation = findRebirthConfirmation()
				if confirmation then
					clickGui(confirmation)
					break
				end
				task.wait(0.15)
			end

			task.wait(4)
			if not state.running then return end

			nextResolve = 0
			resolveTycoon()

			local root = rootPart()
			if cachedPlot and root then
				local spawn = cachedPlot:FindFirstChild("Spawn")
					or cachedPlot:FindFirstChild("SpawnLocation")
					or cachedPlot:FindFirstChild("ClaimPart")

				local destination
				if spawn and spawn:IsA("BasePart") then
					destination = spawn.CFrame
				elseif cachedPlot:IsA("Model") or cachedPlot:IsA("BasePart") then
					destination = cachedPlot:GetPivot()
				end

				if destination then
					root.CFrame = destination + Vector3.new(0, 8, 0)
				end
			end

			table.clear(buyAttempts)
			resetTarget()
		end)

		state.rebirthing = false
		if state.running and not success then
			status.Text = "Rebirth failed; see console"
			warn("[Tycoon Auto Rebirth]", err)
		end
	end)
end

connect(player.CharacterAdded, function()
	resetTarget()
	nextResolve = 0
end)

task.spawn(function()
	local lastRebirthCheck = -math.huge
	local lastWarning = -math.huge

	while state.running do
		local success, err = pcall(function()
			local now = os.clock()

			if state.autoRebirth and not state.rebirthing
				and now - lastRebirthCheck >= 0.25 then
				lastRebirthCheck = now
				if rebirthReady() then startRebirth() end
			end

			if state.autoBuy and not state.rebirthing then
				updateBuy()
			elseif not state.rebirthing and not state.autoBuy then
				status.Text = state.autoRebirth
					and ("Waiting for rebirth: " .. state.rebirthMode)
					or "Paused"
			end
		end)

		if not success and state.running then
			status.Text = "Waiting / retrying"
			if os.clock() - lastWarning >= 5 then
				lastWarning = os.clock()
				warn("[Tycoon Automation]", err)
			end
		end

		task.wait(0.1)
	end
end)
