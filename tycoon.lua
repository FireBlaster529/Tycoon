local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local env = getgenv()
local KEY = "__TycoonAutoBuyRebirth"

if env[KEY] then
	env[KEY].stop()
end

local state = {
	running = true,
	autoBuy = false,
	autoRebirth = false,
	rebirthing = false,
	connections = {},
	target = nil,
	lastMove = 0,
	lastRebirth = 0,
}

env[KEY] = state

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonAutoBuyRebirth"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 150)
frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Auto Buy + Auto Rebirth"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = frame

local function makeButton(y)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(10, y)
	button.Size = UDim2.new(1, -20, 0, 30)
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = frame
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	return button
end

local buyButton = makeButton(35)
local rebirthButton = makeButton(70)

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(10, 108)
status.Size = UDim2.new(1, -20, 0, 32)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(190, 190, 200)
status.Parent = frame

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.connections, connection)
	return connection
end

local function refreshButtons()
	for _, item in ipairs({
		{buyButton, "Auto Buy", state.autoBuy},
		{rebirthButton, "Auto Rebirth", state.autoRebirth},
	}) do
		item[1].Text = item[2] .. ": " .. (item[3] and "ON" or "OFF")
		item[1].BackgroundColor3 = item[3]
			and Color3.fromRGB(45, 155, 90)
			or Color3.fromRGB(40, 40, 50)
	end
end

connect(buyButton.MouseButton1Click, function()
	state.autoBuy = not state.autoBuy
	state.target = nil
	refreshButtons()
end)

connect(rebirthButton.MouseButton1Click, function()
	state.autoRebirth = not state.autoRebirth
	refreshButtons()
end)

refreshButtons()

function state.stop()
	state.running = false
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	gui:Destroy()
	if env[KEY] == state then
		env[KEY] = nil
	end
end

local multipliers = {
	K = 1e3, M = 1e6, B = 1e9, T = 1e12,
	QA = 1e15, QI = 1e18, SX = 1e21,
	SP = 1e24, O = 1e27, N = 1e30, D = 1e33,
}

local function parseNumber(text)
	text = tostring(text):upper():gsub(",", "")
	if text:find("FREE", 1, true) then
		return 0
	end

	local number, suffix = text:match("(%d+%.?%d*)%s*(%a*)")
	number = tonumber(number)
	if not number then return nil end

	if suffix ~= "" and not multipliers[suffix] then
		return nil
	end

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
	local part = object:FindFirstChild("Head")
		or object:FindFirstChild("Part")
	if part and part:IsA("BasePart") then return part end
	return object:FindFirstChildWhichIsA("BasePart", true)
end

local function active(button)
	if not button or not button:IsDescendantOf(Workspace) then
		return false
	end

	local part = partOf(button)
	if not part or part.Transparency >= 1 or not part.CanCollide then
		return false
	end

	local billboard = button:FindFirstChildWhichIsA("BillboardGui", true)
	return not billboard or billboard.Enabled
end

local cachedPlot, cachedTycoon
local nextResolve = 0

local function resolveTycoon()
	if os.clock() < nextResolve
		and cachedPlot and cachedPlot.Parent
		and cachedTycoon and cachedTycoon.Parent then
		return cachedTycoon
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

	local plotPosition = cachedPlot:GetPivot().Position
	local shortest = math.huge

	for _, tycoon in ipairs(tycoons:GetChildren()) do
		if tycoon:FindFirstChild("Buttons") then
			local distance = (tycoon:GetPivot().Position - plotPosition).Magnitude
			if distance < shortest then
				shortest = distance
				cachedTycoon = tycoon
			end
		end
	end

	return cachedTycoon
end

local function cashAmount()
	local stats = player:FindFirstChild("leaderstats")
		or player:FindFirstChild("stats")
	local value = stats and (
		stats:FindFirstChild("Cash")
		or stats:FindFirstChild("Money")
		or stats:FindFirstChild("Coins")
	)

	if value then
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

local function priceOf(button)
	local cached = priceCache[button]
	if cached and cached.label and cached.label.Parent then
		if not visible(cached.label) then return nil end
		return parseNumber(cached.label.Text)
	end

	local display = button:FindFirstChild("PriceDisplay", true)
	local label = display and (
		display:IsA("TextLabel") and display
		or display:FindFirstChildWhichIsA("TextLabel", true)
	)

	if label then
		priceCache[button] = {label = label}
		return visible(label) and parseNumber(label.Text) or nil
	end

	for _, object in ipairs(button:GetDescendants()) do
		if object:IsA("TextLabel") and visible(object) then
			local text = object.Text
			if text:find("$", 1, true) or text:upper():find("FREE", 1, true) then
				priceCache[button] = {label = object}
				return parseNumber(text)
			end
		end
	end

	if button.Name:upper():find("FREE", 1, true) then return 0 end
	return nil
end

local function updateBuy()
	local tycoon = resolveTycoon()
	local buttons = tycoon and tycoon:FindFirstChild("Buttons")
	local root = rootPart()

	if not buttons or not root then
		state.target = nil
		status.Text = "Waiting for your plot / character"
		return
	end

	local cash = cashAmount()
	local target = state.target
	local price = target and active(target) and priceOf(target)

	if not target or target.Parent ~= buttons
		or not price or price > cash then
		target = nil
		local cheapest, nearest = math.huge, math.huge

		for _, button in ipairs(buttons:GetChildren()) do
			if active(button) then
				local cost = priceOf(button)
				if cost and cost <= cash then
					local distance = (partOf(button).Position - root.Position).Magnitude
					if cost < cheapest or (cost == cheapest and distance < nearest) then
						target, cheapest, nearest = button, cost, distance
					end
				end
			end
		end

		state.target = target
		state.lastMove = 0
	end

	if not target then
		status.Text = "Waiting for an affordable button"
		return
	end

	status.Text = "Buying: " .. target.Name

	if os.clock() - state.lastMove >= 0.8 then
		state.lastMove = os.clock()
		root.CFrame = CFrame.new(partOf(target).Position + Vector3.new(0, 3, 0))
	end
end

local function essenceCapped()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return false end

	local system = playerGui:FindFirstChild("System")
	local notifications = system and system:FindFirstChild("Notifications")
	local holder = notifications and notifications:FindFirstChild("NotiHolder")
	local notice = holder and holder:FindFirstChild("EssenceCappedTemp")

	if notice then
		for _, object in ipairs(notice:GetDescendants()) do
			if (object:IsA("TextLabel") or object:IsA("TextButton"))
				and visible(object)
				and object.Text:lower():find("your essence is capped", 1, true) then
				return true
			end
		end
	end

	return false
end

local function clickGui(button)
	if not visible(button) then return end

	local inset = game:GetService("GuiService"):GetGuiInset()
	local screenGui = button:FindFirstAncestorWhichIsA("ScreenGui")
	local position = button.AbsolutePosition + button.AbsoluteSize / 2

	if screenGui and not screenGui.IgnoreGuiInset then
		position += inset
	end

	local input = game:GetService("VirtualInputManager")
	input:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1)
	task.wait(0.1)
	input:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1)
end

local function startRebirth()
	if state.rebirthing or os.clock() - state.lastRebirth < 8 then return end

	state.rebirthing = true
	state.lastRebirth = os.clock()
	state.target = nil

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

			task.wait(0.6)
			if not state.running or not state.autoRebirth then return end

			local playerGui = player:FindFirstChild("PlayerGui")
			local main = playerGui and playerGui:FindFirstChild("Main")
			local rebirthGui = main and main:FindFirstChild("Rebirth", true)
			local searchRoot = rebirthGui or playerGui

			if searchRoot then
				for _, object in ipairs(searchRoot:GetDescendants()) do
					if object:IsA("GuiButton") and visible(object) then
						local name = object.Name:upper()
						local text = object:IsA("TextButton") and object.Text:upper() or ""
						if name == "REBIRTH" or name == "REBIRTHBUTTON"
							or text:find("REBIRTH", 1, true) then
							clickGui(object)
							break
						end
					end
				end
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

				root.CFrame = (
					spawn and spawn:IsA("BasePart") and spawn.CFrame
					or cachedPlot:GetPivot()
				) + Vector3.new(0, 8, 0)
			end
		end)

		state.rebirthing = false
		if state.running and not success then
			status.Text = "Rebirth failed; see console"
			warn("[Tycoon Auto Rebirth]", err)
		end
	end)
end

task.spawn(function()
	local lastRebirthCheck = 0

	while state.running do
		local success, err = pcall(function()
			if state.autoRebirth and os.clock() - lastRebirthCheck >= 1 then
				lastRebirthCheck = os.clock()
				if essenceCapped() then startRebirth() end
			end

			if state.autoBuy and not state.rebirthing then
				updateBuy()
			end
		end)

		if not success then
			status.Text = "Waiting / retrying"
			warn("[Tycoon Automation]", err)
		end

		task.wait(0.2)
	end
end)
local UserInputService = game:GetService("UserInputService")

title.Active = true
title.Size = UDim2.new(1, -35, 0, 30)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Position = UDim2.new(1, -32, 0, 2)
minimizeButton.Size = UDim2.fromOffset(28, 26)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "−"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 20
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Parent = frame

local minimized = false
local expandedSize = frame.Size
frame.ClipsDescendants = true

connect(minimizeButton.MouseButton1Click, function()
	minimized = not minimized

	frame.Size = minimized
		and UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 30)
		or expandedSize

	buyButton.Visible = not minimized
	rebirthButton.Visible = not minimized
	status.Visible = not minimized
	minimizeButton.Text = minimized and "+" or "−"
end)

local dragging = false
local dragStart
local frameStart
local activeTouch

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

	local isDragInput = activeTouch and input == activeTouch
		or not activeTouch
			and input.UserInputType == Enum.UserInputType.MouseMovement

	if isDragInput then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
	end
end)

connect(UserInputService.InputEnded, function(input)
	if input == activeTouch
		or not activeTouch
			and input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
		activeTouch = nil
	end
end)
