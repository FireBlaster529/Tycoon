
-- TBOD: Auto Buy + Auto Rebirth
-- No external UI libraries.
-- Auto Buy requires executor support for firetouchinterest.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local env = getgenv()
local KEY = "__TBOD_Automation"

if env[KEY] and env[KEY].stop then
	env[KEY].stop()
end

-- Stop the earlier combined script if it is still running.
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

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TBODAutomation"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(265, 190)
frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
frame.ClipsDescendants = true
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 30)
title.BackgroundTransparency = 1
title.Text = "TBOD Automation"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1, 1, 1)
title.Active = true
title.Parent = frame

local function button(y)
	local object = Instance.new("TextButton")
	object.Position = UDim2.fromOffset(10, y)
	object.Size = UDim2.new(1, -20, 0, 30)
	object.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.Gotham
	object.TextSize = 13
	object.Parent = frame
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 6)
	return object
end

local buyButton = button(35)
local rebirthButton = button(70)
local modeButton = button(105)

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(10, 140)
status.Size = UDim2.new(1, -20, 0, 40)
status.BackgroundTransparency = 1
status.Text = "Paused"
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
	buyButton.Text = "Auto Buy: " .. (state.buy and "ON" or "OFF")
	rebirthButton.Text = "Auto Rebirth: " .. (state.rebirth and "ON" or "OFF")
	modeButton.Text = "Rebirth Trigger: " .. state.mode

	buyButton.BackgroundColor3 = state.buy
		and Color3.fromRGB(45, 155, 90)
		or Color3.fromRGB(40, 40, 50)

	rebirthButton.BackgroundColor3 = state.rebirth
		and Color3.fromRGB(45, 155, 90)
		or Color3.fromRGB(40, 40, 50)
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
connect(minimize.MouseButton1Click, function()
	minimized = not minimized
	frame.Size = UDim2.fromOffset(265, minimized and 30 or 190)
	for _, object in ipairs({buyButton, rebirthButton, modeButton, status}) do
		object.Visible = not minimized
	end
	minimize.Text = minimized and "+" or "−"
end)

local dragging, dragStart, frameStart, touch

connect(title.InputBegan, function(input)
	if dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = frame.Position
		touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
	end
end)

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
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	gui:Destroy()
	if env[KEY] == state then env[KEY] = nil end
end

refresh()

-- Tycoon lookup: second script's ownership checks,
-- followed by the first script's plot-sign lookup.
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
			local label = sign and sign:FindFirstChild("NameLabel", true)
			local matches = owns(plot)

			if label and label:IsA("TextLabel") then
				local text = label.Text:match("^%s*(.-)%s*$"):lower()
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

local buttonCache = setmetatable({}, {__mode = "k"})
local retries = setmetatable({}, {__mode = "k"})

local function details(object)
	local cached = buttonCache[object]
	if cached and cached.price.Parent and cached.part.Parent then
		return cached
	end

	local display = object:FindFirstChild("PriceDisplay", true)
	local label = display and (
		display:IsA("TextLabel") and display
		or display:FindFirstChildWhichIsA("TextLabel", true)
	)
	if not label then return nil end

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

	cached = {price = label, part = part}
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

	local owned = tycoon()
	local buttons = buttonsOf(owned)
	local root = rootPart()
	if not buttons or not root then
		status.Text = "Waiting for tycoon / character"
		return
	end

	local balance = cash()
	local now = os.clock()
	local selected, selectedData
	local cheapest = math.huge

	-- Every button gets its own retry timer; one failed button
	-- cannot permanently block the others.
	for _, object in ipairs(buttons:GetChildren()) do
		local data, cost = eligible(object)
		if data and cost <= balance
			and now >= (retries[object] or 0) then
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

	-- Always release a started touch, including when toggled off.
	pcall(function()
		firetouchinterest(root, part, 1)
	end)
end

-- Exact rebirth GUI paths from the supplied second script.
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
	local pg = player:FindFirstChild("PlayerGui")
	local notice = path(
		pg, "System", "Notifications", "NotiHolder", "EssenceCappedTemp"
	)
	-- The second script uses this temporary notification's existence.
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
	local label = progress and progress:FindFirstChildWhichIsA("TextLabel", true)
	if label and complete(label.Text) then return true end

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

	-- Use one activation method to avoid executing a handler twice.
	if type(firesignal) == "function" then
		local signalName = state.confirmAttempt % 2 == 1
			and "Activated" or "MouseButton1Click"
		local success = pcall(function()
			firesignal(button[signalName])
		end)
		if success then return true end
	end

	if type(getconnections) == "function" then
		for _, signalName in ipairs({"Activated", "MouseButton1Click"}) do
			local success, connections = pcall(function()
				return getconnections(button[signalName])
			end)

			if success then
				local fired = false
				for _, connection in ipairs(connections) do
					if connection.Enabled ~= false then
						local ok = pcall(function()
							if connection.Fire then
								connection:Fire()
							elseif connection.Function then
								task.spawn(connection.Function)
							else
								error("No callable connection")
							end
						end)
						fired = fired or ok
					end
				end
				if fired then return true end
			end
		end
	end

	local position = button.AbsolutePosition + button.AbsoluteSize / 2
	local screen = button:FindFirstAncestorWhichIsA("ScreenGui")
	if screen and not screen.IgnoreGuiInset then
		local inset = game:GetService("GuiService"):GetGuiInset()
		position += inset
	end

	return pcall(function()
		local input = game:GetService("VirtualInputManager")
		input:SendMouseMoveEvent(position.X, position.Y, game)
		input:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
		task.wait(0.08)
		input:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
	end)
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
				local click = path(Workspace, "Obelisk", "RebirthButton", "Click")
				local detector = click and click:FindFirstChildOfClass("ClickDetector")

				if not detector then error("Rebirth ClickDetector not found") end
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

			state.confirmAttempt = (state.confirmAttempt or 0) + 1
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
