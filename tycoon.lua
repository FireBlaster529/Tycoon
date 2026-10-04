-- TBOD Automation
-- Bento GUI with dragging and minimizing.
-- Auto Buy uses simulated touches without moving your character.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local env = getgenv()
local KEY = "__TBOD_Automation"

if env[KEY] and env[KEY].stop then
	env[KEY].stop()
end

if env.__TycoonAutoBuyRebirth and env.__TycoonAutoBuyRebirth.stop then
	env.__TycoonAutoBuyRebirth.stop()
end

local state = {
	running = true,
	buy = false,
	rebirth = false,
	mode = "Ready",
	busy = false,
	lastRebirth = -math.huge,
	connections = {},
}

env[KEY] = state

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.connections, connection)
	return connection
end

local function path(root, ...)
	for _, name in ipairs({...}) do
		root = root and root:FindFirstChild(name)
	end
	return root
end

local function visible(object)
	if not object or not object.Parent then return false end

	while object do
		if object:IsA("GuiObject") and not object.Visible then
			return false
		elseif object:IsA("LayerCollector") and not object.Enabled then
			return false
		end
		object = object.Parent
	end

	return true
end

local function rootPart()
	return player.Character
		and player.Character:FindFirstChild("HumanoidRootPart")
end

local multipliers = {
	K = 1e3, M = 1e6, B = 1e9, T = 1e12,
	Q = 1e15, QA = 1e15, QN = 1e18, QI = 1e18,
	SX = 1e21, SP = 1e24, O = 1e27, N = 1e30, D = 1e33,
}

local function number(text)
	text = tostring(text or ""):upper():gsub(",", "")

	if text:find("FREE", 1, true) then return 0 end

	local value, suffix = text:match("(%d+%.?%d*)%s*(%a*)")
	value = tonumber(value)

	if not value then return nil end
	if suffix ~= "" and not multipliers[suffix] then return nil end

	return value * (multipliers[suffix] or 1)
end

local function cash()
	local stats = player:FindFirstChild("leaderstats")
		or player:FindFirstChild("stats")

	local value = stats and (
		stats:FindFirstChild("Cash")
		or stats:FindFirstChild("Money")
		or stats:FindFirstChild("Coins")
	)

	if value and value:IsA("ValueBase") then
		local amount = tonumber(value.Value) or number(value.Value)
		if amount then return amount end
	end

	local pg = player:FindFirstChild("PlayerGui")
	local label = path(pg, "System", "Main", "Cash", "CashText")
		or path(pg, "System", "PlayerList", "Holder", player.Name, "CashText")

	return label and number(label.Text) or 0
end

-- Bento GUI
local colors = {
	background = Color3.fromRGB(13, 15, 22),
	card = Color3.fromRGB(23, 26, 37),
	border = Color3.fromRGB(43, 48, 65),
	text = Color3.fromRGB(240, 242, 250),
	muted = Color3.fromRGB(151, 160, 181),
	purple = Color3.fromRGB(155, 125, 255),
	green = Color3.fromRGB(91, 220, 167),
}

local gui = Instance.new("ScreenGui")
gui.Name = "TBODAutomation"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService("CoreGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function outline(object)
	local stroke = Instance.new("UIStroke")
	stroke.Color = colors.border
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object
end

local function label(parent, text, x, y, width, height, size, color, bold)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Position = UDim2.fromOffset(x, y)
	object.Size = UDim2.fromOffset(width, height)
	object.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	object.Text = text
	object.TextSize = size
	object.TextColor3 = color or colors.text
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Parent = parent
	return object
end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(390, 338)
frame.Position = UDim2.fromOffset(24, 120)
frame.BackgroundColor3 = colors.background
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = true
frame.Parent = gui
round(frame, 18)
outline(frame)

local scale = Instance.new("UIScale")
scale.Parent = frame

local function fitScreen()
	local camera = Workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(
			math.min((viewport.X - 24) / 390, (viewport.Y - 24) / 338),
			0.4,
			1
		)
	end
end

fitScreen()

if Workspace.CurrentCamera then
	connect(
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
		fitScreen
	)
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 68)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = frame

local logo = Instance.new("Frame")
logo.Position = UDim2.fromOffset(16, 17)
logo.Size = UDim2.fromOffset(34, 34)
logo.BackgroundColor3 = colors.purple
logo.BorderSizePixel = 0
logo.Parent = header
round(logo, 10)

local logoText = label(logo, "T", 0, 0, 34, 34, 20, colors.background, true)
logoText.TextXAlignment = Enum.TextXAlignment.Center

label(header, "TBOD", 60, 15, 210, 23, 19, colors.text, true)
label(header, "Automation dashboard", 60, 39, 230, 16, 11, colors.muted)

local minimize = Instance.new("TextButton")
minimize.Position = UDim2.new(1, -48, 0, 18)
minimize.Size = UDim2.fromOffset(32, 32)
minimize.BackgroundColor3 = colors.card
minimize.BorderSizePixel = 0
minimize.Text = "−"
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 21
minimize.TextColor3 = colors.text
minimize.Parent = header
round(minimize, 10)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(16, 76)
content.Size = UDim2.fromOffset(358, 246)
content.BackgroundTransparency = 1
content.Parent = frame

local function card(x, y, width, height)
	local object = Instance.new("Frame")
	object.Position = UDim2.fromOffset(x, y)
	object.Size = UDim2.fromOffset(width, height)
	object.BackgroundColor3 = colors.card
	object.BorderSizePixel = 0
	object.Parent = content
	round(object, 14)
	outline(object)
	return object
end

local function toggleCard(x, heading, description, accent)
	local object = card(x, 0, 174, 116)

	local dot = Instance.new("Frame")
	dot.Position = UDim2.fromOffset(14, 16)
	dot.Size = UDim2.fromOffset(7, 7)
	dot.BackgroundColor3 = accent
	dot.BorderSizePixel = 0
	dot.Parent = object
	round(dot, 4)

	label(object, heading, 28, 10, 133, 22, 13, colors.text, true)
	label(object, description, 14, 36, 146, 17, 10, colors.muted)

	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(12, 69)
	button.Size = UDim2.fromOffset(150, 34)
	button.BackgroundColor3 = colors.background
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 11
	button.TextColor3 = colors.muted
	button.AutoButtonColor = false
	button.Parent = object
	round(button, 9)

	connect(button.MouseEnter, function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundTransparency = 0.15,
		}):Play()
	end)

	connect(button.MouseLeave, function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundTransparency = 0,
		}):Play()
	end)

	return button, dot
end

local buyButton, buyDot = toggleCard(
	0, "Auto Buy", "Buy without moving", colors.green
)

local rebirthButton, rebirthDot = toggleCard(
	184, "Auto Rebirth", "Rebirth automatically", colors.purple
)

local triggerCard = card(0, 126, 358, 54)
label(triggerCard, "REBIRTH TRIGGER", 14, 9, 145, 16, 9, colors.muted, true)
label(triggerCard, "Choose when to rebirth", 14, 27, 175, 16, 10, colors.text)

local modeButton = Instance.new("TextButton")
modeButton.Position = UDim2.fromOffset(214, 11)
modeButton.Size = UDim2.fromOffset(132, 32)
modeButton.BackgroundColor3 = Color3.fromRGB(46, 37, 72)
modeButton.BorderSizePixel = 0
modeButton.Font = Enum.Font.GothamBold
modeButton.TextSize = 11
modeButton.TextColor3 = colors.purple
modeButton.Parent = triggerCard
round(modeButton, 9)

local statusCard = card(0, 190, 358, 56)

local statusDot = Instance.new("Frame")
statusDot.Position = UDim2.fromOffset(14, 13)
statusDot.Size = UDim2.fromOffset(6, 6)
statusDot.BackgroundColor3 = colors.muted
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
round(statusDot, 3)

label(statusCard, "ACTIVITY", 27, 7, 300, 17, 9, colors.muted, true)

local status = label(statusCard, "Paused", 14, 25, 330, 24, 11, colors.text)
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Center

local function refresh()
	buyButton.Text = state.buy and "ENABLED  •" or "ENABLE AUTO BUY"
	rebirthButton.Text = state.rebirth and "ENABLED  •" or "ENABLE REBIRTH"
	modeButton.Text = state.mode .. "  ↔"

	buyButton.BackgroundColor3 = state.buy
		and Color3.fromRGB(27, 66, 52) or colors.background
	buyButton.TextColor3 = state.buy and colors.green or colors.muted
	buyDot.BackgroundColor3 = state.buy and colors.green or colors.muted

	rebirthButton.BackgroundColor3 = state.rebirth
		and Color3.fromRGB(46, 37, 72) or colors.background
	rebirthButton.TextColor3 = state.rebirth and colors.purple or colors.muted
	rebirthDot.BackgroundColor3 = state.rebirth and colors.purple or colors.muted

	statusDot.BackgroundColor3 = (state.buy or state.rebirth)
		and colors.green or colors.muted
end

connect(buyButton.MouseButton1Click, function()
	if not state.buy and type(firetouchinterest) ~= "function" then
		status.Text = "Executor missing firetouchinterest"
		return
	end

	state.buy = not state.buy
	refresh()
end)

connect(rebirthButton.MouseButton1Click, function()
	state.rebirth = not state.rebirth
	refresh()
end)

connect(modeButton.MouseButton1Click, function()
	state.mode = state.mode == "Ready" and "Essence Cap" or "Ready"
	refresh()
end)

local minimized = false
local resizeTween

connect(minimize.MouseButton1Click, function()
	minimized = not minimized
	content.Visible = not minimized
	minimize.Text = minimized and "+" or "−"

	if resizeTween then resizeTween:Cancel() end
	resizeTween = TweenService:Create(
		frame,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.fromOffset(390, minimized and 68 or 338)}
	)
	resizeTween:Play()
end)

local dragging, dragStart, frameStart, touch

local function beginDrag(input)
	if dragging then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = frame.Position
		touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
	end
end

connect(header.InputBegan, beginDrag)

-- Explicit drag surface above the title, leaving minimize accessible.
local dragSurface = Instance.new("Frame")
dragSurface.BackgroundTransparency = 1
dragSurface.Size = UDim2.new(1, -56, 1, 0)
dragSurface.Active = true
dragSurface.ZIndex = 5
dragSurface.Parent = header
connect(dragSurface.InputBegan, beginDrag)

connect(UIS.InputChanged, function(input)
	if not dragging then return end

	if (touch and input == touch)
		or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			frameStart.X.Scale, frameStart.X.Offset + delta.X,
			frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
		)
	end
end)

connect(UIS.InputEnded, function(input)
	if (touch and input == touch)
		or (not touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
		dragging, touch = false, nil
	end
end)

function state.stop()
	state.running = false
	if resizeTween then resizeTween:Cancel() end

	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end

	gui:Destroy()
	if env[KEY] == state then env[KEY] = nil end
end

refresh()

-- Tycoon lookup
local cachedTycoon
local nextLookup = 0

local function owns(object)
	for _, name in ipairs({"Owner", "OwnerId", "Player", "User"}) do
		local owner = object:FindFirstChild(name)

		if owner then
			if owner:IsA("ObjectValue") and owner.Value == player then
				return true
			elseif owner:IsA("StringValue") or owner:IsA("IntValue")
				or owner:IsA("NumberValue") then
				local value = tostring(owner.Value)
				if value == player.Name or value == tostring(player.UserId) then
					return true
				end
			end
		end
	end

	local owner = object:GetAttribute("Owner")
	local ownerId = object:GetAttribute("OwnerId")

	return owner == player.Name or owner == player.UserId
		or tostring(ownerId) == tostring(player.UserId)
end

local function positionOf(object)
	if object:IsA("Model") or object:IsA("BasePart") then
		return object:GetPivot().Position
	end

	local part = object:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

local function buttonsOf(object)
	return object and (
		object:FindFirstChild("Buttons")
		or object:FindFirstChild("ButtonFolder")
	)
end

local function tycoon()
	local now = os.clock()

	if now < nextLookup then
		return cachedTycoon and cachedTycoon.Parent and cachedTycoon or nil
	end

	nextLookup = now + 2
	cachedTycoon = nil

	local folder = Workspace:FindFirstChild("Tycoons")
		or Workspace:FindFirstChild("Tycoon")
		or Workspace:FindFirstChild("Plots")

	if not folder then return nil end

	local candidates = {}

	for _, object in ipairs(folder:GetChildren()) do
		if buttonsOf(object) then
			table.insert(candidates, object)

			if owns(object) then
				cachedTycoon = object
				return object
			end
		end
	end

	local plots = Workspace:FindFirstChild("Plots")
	local plotPosition

	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			local sign = plot:FindFirstChild("SignPlace")
			local nameLabel = sign and sign:FindFirstChild("NameLabel", true)
			local matches = owns(plot)

			if nameLabel and nameLabel:IsA("TextLabel") then
				local text = nameLabel.Text:match("^%s*(.-)%s*$"):lower()
				matches = matches or text == player.Name:lower()
					or text == player.DisplayName:lower()
			end

			if matches then
				if buttonsOf(plot) then
					cachedTycoon = plot
					return plot
				end

				plotPosition = positionOf(plot)
				break
			end
		end
	end

	if plotPosition then
		local shortest = math.huge

		for _, object in ipairs(candidates) do
			local position = positionOf(object)

			if position then
				local distance = (position - plotPosition).Magnitude
				if distance < shortest then
					shortest, cachedTycoon = distance, object
				end
			end
		end
	elseif #candidates == 1 then
		cachedTycoon = candidates[1]
	end

	return cachedTycoon
end

-- Auto Buy: simulated touches
local buttonCache = setmetatable({}, {__mode = "k"})
local retries = setmetatable({}, {__mode = "k"})

local function details(object)
	local cached = buttonCache[object]

	if cached and cached.price.Parent and cached.part.Parent then
		return cached
	end

	local display = object:FindFirstChild("PriceDisplay", true)
	local priceLabel = display and (
		display:IsA("TextLabel") and display
		or display:FindFirstChildWhichIsA("TextLabel", true)
	)

	if not priceLabel then return nil end

	local part

	if object:IsA("BasePart") then
		part = object
	else
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA("TouchTransmitter")
				and descendant.Parent:IsA("BasePart") then
				part = descendant.Parent
				break
			end
		end

		part = part or object:FindFirstChild("Head")
			or object:FindFirstChild("Part")
			or object:FindFirstChildWhichIsA("BasePart", true)
	end

	if not part or not part:IsA("BasePart") then return nil end

	cached = {price = priceLabel, part = part}
	buttonCache[object] = cached
	return cached
end

local function eligible(object)
	if not object:IsDescendantOf(Workspace) then return nil end

	local data = details(object)
	if not data or not visible(data.price) then return nil end

	local nameDisplay = object:FindFirstChild("NameDisplay", true)
	local nameLabel = nameDisplay and (
		nameDisplay:IsA("TextLabel") and nameDisplay
		or nameDisplay:FindFirstChildWhichIsA("TextLabel", true)
	)

	if nameLabel and not nameLabel.Text:match("%S") then return nil end

	local cost = number(data.price.Text)
	if cost == nil then return nil end

	return data, cost
end

local function updateBuy()
	if type(firetouchinterest) ~= "function" then
		state.buy = false
		refresh()
		status.Text = "Executor missing firetouchinterest"
		return
	end

	local buttons = buttonsOf(tycoon())
	local root = rootPart()

	if not buttons or not root then
		status.Text = "Waiting for tycoon / character"
		return
	end

	local balance = cash()
	local now = os.clock()
	local selected, selectedData
	local cheapest = math.huge

	for _, object in ipairs(buttons:GetChildren()) do
		local data, cost = eligible(object)

		if data and cost <= balance and now >= (retries[object] or 0) then
			if cost < cheapest then
				selected, selectedData, cheapest = object, data, cost
			end
		end
	end

	if not selected then
		status.Text = "Waiting for cash / next purchase"
		return
	end

	retries[selected] = now + 1
	status.Text = "Buying: " .. selected.Name

	local part = selectedData.part
	firetouchinterest(root, part, 0)
	task.wait(0.05)

	pcall(function()
		firetouchinterest(root, part, 1)
	end)
end

-- Auto Rebirth
local function rebirthObjects()
	local pg = player:FindFirstChild("PlayerGui")
	local rebirthFrame = path(pg, "Main", "Rebirth")
	local inner = path(rebirthFrame, "Main", "Inner")
	local progress = inner and inner:FindFirstChild("Progress")

	return {
		frame = rebirthFrame,
		button = inner and inner:FindFirstChild("Rebirth"),
		progress = progress and progress:FindFirstChildWhichIsA("TextLabel", true),
	}
end

local function complete(text)
	text = tostring(text or ""):upper()

	if text:find("COMPLETE", 1, true)
		or text:find("MAX", 1, true)
		or text:find("DONE", 1, true) then
		return true
	end

	local percent = tonumber(text:match("(%d+%.?%d*)%%"))
	if percent and percent >= 100 then return true end

	local currentText, goalText = text:match("(.-)%s*/%s*(.+)")

	if currentText and goalText then
		local current, goal = number(currentText), number(goalText)

		if current and goal and goal > 0 then
			return current >= goal or cash() >= goal
		end
	end

	return false
end

local function essenceCapped()
	local notice = path(
		player:FindFirstChild("PlayerGui"),
		"System", "Notifications", "NotiHolder", "EssenceCappedTemp"
	)

	if not notice then return false end

	for _, object in ipairs(notice:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton"))
			and visible(object)
			and object.Text:lower():find("your essence is capped", 1, true) then
			return true
		end
	end

	return false
end

local function ready()
	if state.mode == "Essence Cap" then return essenceCapped() end

	local pg = player:FindFirstChild("PlayerGui")
	local progress = path(pg, "System", "RebirthProgress", "Progress")
	local progressLabel = progress
		and progress:FindFirstChildWhichIsA("TextLabel", true)

	if progressLabel and complete(progressLabel.Text) then return true end

	local objects = rebirthObjects()
	if objects.progress and complete(objects.progress.Text) then return true end

	local notice = path(
		pg, "System", "Notifications", "NotiHolder", "RebirthNotification"
	)

	if notice then
		for _, object in ipairs(notice:GetDescendants()) do
			if (object:IsA("TextLabel") or object:IsA("TextButton"))
				and visible(object) and object.Text:match("%S") then
				return true
			end
		end
	end

	return false
end

local function activate(button)
	if not button or not button:IsA("GuiButton") or not visible(button) then
		return false
	end

	-- Try actual connected callbacks instead of returning after firesignal.
	if type(getconnections) == "function" then
		for _, signalName in ipairs({"Activated", "MouseButton1Click"}) do
			local success, connections = pcall(function()
				return getconnections(button[signalName])
			end)

			if success and type(connections) == "table" then
				local invoked = false

				for _, connection in ipairs(connections) do
					local ok, callback = pcall(function()
						if connection.Enabled == false then return nil end
						return connection.Function
					end)

					if ok and type(callback) == "function" then
						invoked = true

						task.spawn(function()
							local worked, err = pcall(callback)
							if not worked then
								warn("[TBOD Rebirth callback]", err)
							end
						end)
					end
				end

				if invoked then return true end
			end
		end
	end

	-- Fall back to an actual mouse click.
	local camera = Workspace.CurrentCamera
	if not camera then return false end

	local position = button.AbsolutePosition + button.AbsoluteSize / 2
	local screen = button:FindFirstAncestorWhichIsA("ScreenGui")

	if screen and not screen.IgnoreGuiInset then
		local inset = game:GetService("GuiService"):GetGuiInset()
		position += inset
	end

	local viewport = camera.ViewportSize

	if button.AbsoluteSize.X <= 0 or button.AbsoluteSize.Y <= 0
		or position.X < 0 or position.Y < 0
		or position.X >= viewport.X or position.Y >= viewport.Y then
		warn("[TBOD Rebirth] Confirmation button is outside the screen")
		return false
	end

	local success, err = pcall(function()
		local input = game:GetService("VirtualInputManager")

		input:SendMouseMoveEvent(position.X, position.Y, game)
		task.wait(0.15)

		input:SendMouseButtonEvent(
			position.X, position.Y, 0, true, game, 0
		)

		task.wait(0.1)

		input:SendMouseButtonEvent(
			position.X, position.Y, 0, false, game, 0
		)
	end)

	if not success then
		warn("[TBOD Rebirth mouse click]", err)
	end

	return success
end

local function startRebirth()
	if state.busy or os.clock() - state.lastRebirth < 6 then return end

	state.busy = true
	state.lastRebirth = os.clock()

	task.spawn(function()
		local success, err = pcall(function()
			status.Text = "Opening rebirth..."
			local objects = rebirthObjects()

			if not visible(objects.frame) then
				local click = path(
					Workspace, "Obelisk", "RebirthButton", "Click"
				)

				local detector = click
					and click:FindFirstChildOfClass("ClickDetector")

				if not detector then
					error("Rebirth ClickDetector not found")
				end

				if type(fireclickdetector) ~= "function" then
					error("Executor missing fireclickdetector")
				end

				fireclickdetector(detector)
			end

			local deadline = os.clock() + 4

			repeat
				if not state.running or not state.rebirth then return end
				objects = rebirthObjects()

				if visible(objects.button) then break end
				task.wait(0.15)
			until os.clock() >= deadline

			if not visible(objects.button) then
				error("Exact rebirth confirmation button not available")
			end

			task.wait(0.35)
			if not state.running or not state.rebirth then return end

			objects = rebirthObjects()
			status.Text = "Confirming rebirth..."

			if not activate(objects.button) then
				error("Could not activate rebirth confirmation")
			end

			task.wait(3)
			if not state.running then return end

			nextLookup = 0
			table.clear(retries)

			objects = rebirthObjects()

			status.Text = visible(objects.frame)
				and "Confirmation sent; retrying if needed"
				or "Rebirth confirmation sent"
		end)

		state.busy = false

		if not success and state.running then
			status.Text = tostring(err):match("[^\n]+") or "Rebirth failed"
			warn("[TBOD Rebirth]", err)
		end
	end)
end

connect(player.CharacterAdded, function()
	nextLookup = 0
	table.clear(retries)
end)

task.spawn(function()
	local lastRebirthCheck = -math.huge
	local lastWarning = -math.huge

	while state.running do
		local success, err = pcall(function()
			local now = os.clock()

			if state.rebirth and not state.busy
				and now - lastRebirthCheck >= 0.3 then
				lastRebirthCheck = now

				if ready() then startRebirth() end
			end

			if state.buy and not state.busy then
				updateBuy()
			elseif not state.busy then
				status.Text = state.rebirth
					and ("Waiting: " .. state.mode)
					or "Paused"
			end
		end)

		if not success and state.running then
			status.Text = "Error; retrying (see console)"

			if os.clock() - lastWarning >= 5 then
				lastWarning = os.clock()
				warn("[TBOD Automation]", err)
			end
		end

		task.wait(0.15)
	end
end)
