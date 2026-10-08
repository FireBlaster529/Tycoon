-- TBOD Automation: simulated-touch buying + cursor-free Volt rebirth attempts
-- Drag the header. Click +/- to minimize. All toggles start OFF.
-- Discord: paste your channel webhook URL here, then execute the script.
-- Optional paths are relative to LocalPlayer (e.g. {'leaderstats','Bits'}).
local WEBHOOK = {
    URL = 'https://discord.com/api/webhooks/1376617341965701160/IdrQE4RRpYjff8dPmaXirBKSlbDwO6rzpG_ybWIH4QKP4ivyprXScGCkQNDziuAK4jco',
    Enabled = true,
    StatPaths = {Essence = nil, Bits = nil},
}
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local TeleportService = game:GetService('TeleportService')
local CoreGui = game:GetService('CoreGui')
local GuiService = game:GetService('GuiService')
local player = Players.LocalPlayer
local env = getgenv()
local KEY = '__TBOD_Automation'
for _, key in ipairs({KEY, '__TycoonAutoBuyRebirth'}) do
    if env[key] and env[key].stop then pcall(env[key].stop) end
end
local state = {running=true, buy=false, rebirth=false, rejoin=false, disconnected=false, mode='Ready', busy=false, lastRebirth=-math.huge, connections={}}
env[KEY] = state
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(state.connections, connection)
    return connection
end
local function path(root, ...)
    for _, name in ipairs({...}) do root = root and root:FindFirstChild(name) end
    return root
end
local function visible(object)
    if not object or not object.Parent then return false end
    while object do
        if object:IsA('GuiObject') and not object.Visible then return false end
        if object:IsA('LayerCollector') and not object.Enabled then return false end
        object = object.Parent
    end
    return true
end
local function rootPart()
    return player.Character and player.Character:FindFirstChild('HumanoidRootPart')
end
local multipliers = {K=1e3,M=1e6,B=1e9,T=1e12,Q=1e15,QA=1e15,QN=1e18,QI=1e18,SX=1e21,SP=1e24,O=1e27,OC=1e27,N=1e30,NO=1e30,D=1e33,DC=1e33}
local function number(text)
    text = tostring(text or ''):upper():gsub(',', '')
    if text:find('FREE', 1, true) then return 0 end
    local value, suffix = text:match('(%d+%.?%d*)%s*(%a*)')
    value = tonumber(value)
    if not value or (suffix ~= '' and not multipliers[suffix]) then return nil end
    return value * (multipliers[suffix] or 1)
end
local function cash()
    local stats = player:FindFirstChild('leaderstats') or player:FindFirstChild('stats')
    local value = stats and (stats:FindFirstChild('Cash') or stats:FindFirstChild('Money') or stats:FindFirstChild('Coins'))
    if value and value:IsA('ValueBase') then
        local amount = tonumber(value.Value) or number(value.Value)
        if amount then return amount end
    end
    local pg = player:FindFirstChild('PlayerGui')
    local label = path(pg,'System','Main','Cash','CashText') or path(pg,'System','PlayerList','Holder',player.Name,'CashText')
    return label and number(label.Text) or 0
end
-- Bento GUI
local C = {bg=Color3.fromRGB(13,15,22),card=Color3.fromRGB(23,26,37),border=Color3.fromRGB(43,48,65),text=Color3.fromRGB(240,242,250),muted=Color3.fromRGB(151,160,181),purple=Color3.fromRGB(155,125,255),green=Color3.fromRGB(91,220,167)}
local gui = Instance.new('ScreenGui')
gui.Name='TBODAutomation'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=game:GetService('CoreGui')
local function round(object, radius)
    local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,radius); corner.Parent=object
end
local function outline(object)
    local stroke=Instance.new('UIStroke'); stroke.Color=C.border; stroke.Transparency=0.2; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=object
end
local function label(parent,text,x,y,w,h,size,color,bold)
    local obj=Instance.new('TextLabel'); obj.BackgroundTransparency=1; obj.Position=UDim2.fromOffset(x,y); obj.Size=UDim2.fromOffset(w,h)
    obj.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham; obj.Text=text; obj.TextSize=size; obj.TextColor3=color or C.text; obj.TextXAlignment=Enum.TextXAlignment.Left; obj.Parent=parent
    return obj
end
local frame=Instance.new('Frame'); frame.Size=UDim2.fromOffset(390,490); frame.Position=UDim2.fromOffset(24,120); frame.BackgroundColor3=C.bg; frame.BorderSizePixel=0; frame.Active=true; frame.ClipsDescendants=true; frame.Parent=gui
round(frame,18); outline(frame)
local scale=Instance.new('UIScale'); scale.Parent=frame
local cameraConnection
local function fitScreen()
    local camera=Workspace.CurrentCamera
    if camera then local v=camera.ViewportSize; scale.Scale=math.clamp(math.min((v.X-24)/390,(v.Y-24)/490),0.4,1) end
end
local function hookCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    if Workspace.CurrentCamera then cameraConnection=connect(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),fitScreen) end
    fitScreen()
end
connect(Workspace:GetPropertyChangedSignal('CurrentCamera'),hookCamera); hookCamera()
local header=Instance.new('Frame'); header.Size=UDim2.new(1,0,0,68); header.BackgroundTransparency=1; header.Active=true; header.Parent=frame
local logo=Instance.new('Frame'); logo.Position=UDim2.fromOffset(16,17); logo.Size=UDim2.fromOffset(34,34); logo.BackgroundColor3=C.purple; logo.BorderSizePixel=0; logo.Parent=header; round(logo,10)
local logoText=label(logo,'T',0,0,34,34,20,C.bg,true); logoText.TextXAlignment=Enum.TextXAlignment.Center
label(header,'TBOD',60,15,210,23,19,C.text,true); label(header,'Automation dashboard',60,39,230,16,11,C.muted)
local minimize=Instance.new('TextButton'); minimize.Position=UDim2.new(1,-48,0,18); minimize.Size=UDim2.fromOffset(32,32); minimize.BackgroundColor3=C.card; minimize.BorderSizePixel=0; minimize.Text='−'; minimize.Font=Enum.Font.GothamBold; minimize.TextSize=21; minimize.TextColor3=C.text; minimize.Parent=header; round(minimize,10)
local content=Instance.new('Frame'); content.Position=UDim2.fromOffset(16,76); content.Size=UDim2.fromOffset(358,398); content.BackgroundTransparency=1; content.Parent=frame
local function card(x,y,w,h)
    local obj=Instance.new('Frame'); obj.Position=UDim2.fromOffset(x,y); obj.Size=UDim2.fromOffset(w,h); obj.BackgroundColor3=C.card; obj.BorderSizePixel=0; obj.Parent=content; round(obj,14); outline(obj); return obj
end
local function toggleCard(x,heading,description,accent)
    local obj=card(x,0,174,116)
    local dot=Instance.new('Frame'); dot.Position=UDim2.fromOffset(14,16); dot.Size=UDim2.fromOffset(7,7); dot.BackgroundColor3=accent; dot.BorderSizePixel=0; dot.Parent=obj; round(dot,4)
    label(obj,heading,28,10,133,22,13,C.text,true); label(obj,description,14,36,146,17,10,C.muted)
    local button=Instance.new('TextButton'); button.Position=UDim2.fromOffset(12,69); button.Size=UDim2.fromOffset(150,34); button.BackgroundColor3=C.bg; button.BorderSizePixel=0; button.Font=Enum.Font.GothamBold; button.TextSize=11; button.TextColor3=C.muted; button.AutoButtonColor=false; button.Parent=obj; round(button,9)
    local hoverTween
    local function hover(transparency)
        if hoverTween then hoverTween:Cancel() end
        hoverTween=TweenService:Create(button,TweenInfo.new(0.12),{BackgroundTransparency=transparency})
        hoverTween:Play()
    end
    connect(button.MouseEnter,function() hover(0.15) end)
    connect(button.MouseLeave,function() hover(0) end)
    return button,dot
end
local buyButton,buyDot=toggleCard(0,'Auto Buy','Buy without moving',C.green)
local rebirthButton,rebirthDot=toggleCard(184,'Auto Rebirth','Wait for required cash',C.purple)
local triggerCard=card(0,126,358,54)
label(triggerCard,'REBIRTH TRIGGER',14,9,145,16,9,C.muted,true); local readinessLabel=label(triggerCard,'Checking progress...',14,27,190,16,9,C.text)
local modeButton=Instance.new('TextButton'); modeButton.Position=UDim2.fromOffset(214,11); modeButton.Size=UDim2.fromOffset(132,32); modeButton.BackgroundColor3=Color3.fromRGB(46,37,72); modeButton.BorderSizePixel=0; modeButton.Font=Enum.Font.GothamBold; modeButton.TextSize=11; modeButton.TextColor3=C.purple; modeButton.Parent=triggerCard; round(modeButton,9)
local statusCard=card(0,190,358,56)
local statusDot=Instance.new('Frame'); statusDot.Position=UDim2.fromOffset(14,13); statusDot.Size=UDim2.fromOffset(6,6); statusDot.BackgroundColor3=C.muted; statusDot.BorderSizePixel=0; statusDot.Parent=statusCard; round(statusDot,3)
label(statusCard,'ACTIVITY',27,7,300,17,9,C.muted,true)
local status=label(statusCard,'Paused',14,25,330,24,11,C.text); status.TextWrapped=true
local bitTimerCard=card(0,256,358,66)
label(bitTimerCard,'NEXT BITS',14,8,190,16,9,C.muted,true)
local bitTimerNote=label(bitTimerCard,'Open generator once to sync',14,30,224,22,10,C.muted)
local bitTimerLabel=label(bitTimerCard,'--:--',242,16,102,34,24,C.green,true)
bitTimerLabel.TextXAlignment=Enum.TextXAlignment.Right
local rejoinCard=card(0,332,358,66)
label(rejoinCard,'AUTO REJOIN',14,8,190,16,9,C.muted,true)
local rejoinNote=label(rejoinCard,'Return to this server after disconnect',14,30,214,26,10,C.muted)
rejoinNote.TextWrapped=true
local rejoinButton=Instance.new('TextButton')
rejoinButton.Position=UDim2.fromOffset(242,17); rejoinButton.Size=UDim2.fromOffset(102,32)
rejoinButton.BackgroundColor3=C.bg; rejoinButton.BorderSizePixel=0
rejoinButton.Font=Enum.Font.GothamBold; rejoinButton.TextSize=11
rejoinButton.TextColor3=C.muted; rejoinButton.AutoButtonColor=false; rejoinButton.Parent=rejoinCard
round(rejoinButton,9)
local function refresh()
    rejoinButton.Text=state.rejoin and 'ON  •' or 'OFF'
    rejoinButton.BackgroundColor3=state.rejoin and Color3.fromRGB(27,66,52) or C.bg
    rejoinButton.TextColor3=state.rejoin and C.green or C.muted
    buyButton.Text=state.buy and 'ENABLED  •' or 'ENABLE AUTO BUY'
    rebirthButton.Text=state.rebirth and 'ENABLED  •' or 'ENABLE REBIRTH'
    modeButton.Text=state.mode..'  ↔'
    buyButton.BackgroundColor3=state.buy and Color3.fromRGB(27,66,52) or C.bg
    buyButton.TextColor3=state.buy and C.green or C.muted; buyDot.BackgroundColor3=buyButton.TextColor3
    rebirthButton.BackgroundColor3=state.rebirth and Color3.fromRGB(46,37,72) or C.bg
    rebirthButton.TextColor3=state.rebirth and C.purple or C.muted; rebirthDot.BackgroundColor3=rebirthButton.TextColor3
    statusDot.BackgroundColor3=(state.buy or state.rebirth) and C.green or C.muted
end
connect(buyButton.MouseButton1Click,function()
    if not state.buy and type(firetouchinterest)~='function' then status.Text='Executor missing firetouchinterest'; return end
    state.buy=not state.buy; refresh()
end)
connect(rebirthButton.MouseButton1Click,function() state.rebirth=not state.rebirth; refresh() end)
connect(modeButton.MouseButton1Click,function() state.mode=state.mode=='Ready' and 'Essence Cap' or 'Ready'; refresh() end)
-- Remember the exact server; never silently fall back to a different server.
local rejoinPlaceId,rejoinJobId=game.PlaceId,game.JobId
local rejoinNextAttempt,rejoinAttempts=0,0
local rejoinInFlight=false
connect(rejoinButton.MouseButton1Click,function()
    state.rejoin=not state.rejoin
    rejoinNextAttempt=0; rejoinAttempts=0
    rejoinNote.Text=state.rejoin and 'Watching for a disconnect' or 'Return to this server after disconnect'
    refresh()
end)
-- The engine error channel avoids depending on the prompt hierarchy or language.
-- Some executors cannot access it, so retain a protected CoreGui fallback.
local function engineDisconnected()
    local ok,message=pcall(function() return GuiService:GetErrorMessage() end)
    return ok and type(message)=='string' and message~=''
end
local function disconnectText(text)
    text=tostring(text or ''):lower()
    for _,phrase in ipairs({'disconnected','lost connection','connection lost','kicked',
        'check your internet','please rejoin','reconnect','shutdown','shut down','timed out'}) do
        if text:find(phrase,1,true) then return true end
    end
    for digits in text:gmatch('%d+') do
        if digits=='260' or digits=='266' or digits=='267' or digits=='277'
            or digits=='279' or digits=='282' or digits=='285' or digits=='288' then return true end
    end
    return false
end
local function disconnectPrompt()
    if engineDisconnected() then return true end
    local promptGui=CoreGui:FindFirstChild('RobloxPromptGui')
    if not promptGui then return false end
    for _,prompt in ipairs(promptGui:GetDescendants()) do
        if prompt.Name=='ErrorPrompt' and visible(prompt) then
            local parts={}
            for _,object in ipairs(prompt:GetDescendants()) do
                if object:IsA('TextLabel') and visible(object) then parts[#parts+1]=object.Text end
            end
            if disconnectText(table.concat(parts,' ')) then return true end
        end
    end
    return false
end
local function markDisconnected()
    if not state.running or state.disconnected then return end
    state.disconnected=true
    rejoinNextAttempt=os.clock()+3
    rejoinNote.Text=state.rejoin and 'Disconnected; rejoining shortly' or 'Disconnected; enable to rejoin'
    warn('[TBOD Auto Rejoin] Disconnect detected')
end
pcall(function()
    connect(GuiService.ErrorMessageChanged,function()
        if engineDisconnected() then markDisconnected() end
    end)
end)
connect(TeleportService.TeleportInitFailed,function(failedPlayer,_,message,placeId)
    if failedPlayer~=player or placeId~=rejoinPlaceId or not rejoinInFlight then return end
    rejoinInFlight=false
    rejoinNextAttempt=os.clock()+math.min(10*math.max(rejoinAttempts,1),30)
    if state.rejoin then
        rejoinNote.Text='Rejoin failed; retrying shortly'
        warn('[TBOD Auto Rejoin] '..tostring(message))
    end
end)
task.spawn(function()
    local lastWarning=-math.huge
    while state.running do
        local ok,err=pcall(function()
            -- Keep the disconnect latched even if the error prompt changes during retries.
            if not state.disconnected and disconnectPrompt() then
                markDisconnected()
            end
            if not state.rejoin or not state.disconnected then return end
            if rejoinJobId=='' or rejoinPlaceId<=0 then
                state.rejoin=false; refresh()
                rejoinNote.Text='No live server ID; rejoin unavailable'
                return
            end
            local now=os.clock()
            if now<rejoinNextAttempt then return end
            -- A missing TeleportInitFailed event must not leave retries stuck forever.
            rejoinAttempts=rejoinAttempts+1
            rejoinInFlight=true
            rejoinNextAttempt=now+30
            rejoinNote.Text='Rejoining same server: attempt '..rejoinAttempts
            warn('[TBOD Auto Rejoin] Attempt '..rejoinAttempts..' to server '..rejoinJobId)
            local attempt=rejoinAttempts
            task.spawn(function()
                local sent,message=pcall(function()
                    TeleportService:TeleportToPlaceInstance(rejoinPlaceId,rejoinJobId,player)
                end)
                if not state.running or not state.rejoin or attempt~=rejoinAttempts then return end
                if not sent then
                    rejoinInFlight=false
                    rejoinNextAttempt=os.clock()+math.min(10*rejoinAttempts,30)
                    rejoinNote.Text='Waiting for connection; will retry'
                    warn('[TBOD Auto Rejoin] '..tostring(message))
                end
            end)
        end)
        if not ok and os.clock()-lastWarning>=10 then
            lastWarning=os.clock(); warn('[TBOD Auto Rejoin]',err)
        end
        task.wait(1)
    end
end)
local minimized,resizeTween=false,nil
connect(minimize.MouseButton1Click,function()
    minimized=not minimized; content.Visible=not minimized; minimize.Text=minimized and '+' or '−'
    if resizeTween then resizeTween:Cancel() end
    resizeTween=TweenService:Create(frame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(390,minimized and 68 or 490)}); resizeTween:Play()
end)
local dragging,dragStart,frameStart,touch
local dragSurface=Instance.new('Frame'); dragSurface.BackgroundTransparency=1; dragSurface.Size=UDim2.new(1,-56,1,0); dragSurface.Active=true; dragSurface.ZIndex=5; dragSurface.Parent=header
connect(dragSurface.InputBegan,function(input)
    if dragging then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; frameStart=frame.Position; touch=input.UserInputType==Enum.UserInputType.Touch and input or nil
    end
end)
connect(UIS.InputChanged,function(input)
    if dragging and ((touch and input==touch) or (not touch and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        local delta=input.Position-dragStart
        frame.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
    end
end)
connect(UIS.InputEnded,function(input)
    if (touch and input==touch) or (not touch and input.UserInputType==Enum.UserInputType.MouseButton1) then dragging,touch=false,nil end
end)
function state.stop()
    state.running=false
    if resizeTween then resizeTween:Cancel() end
    for _,connection in ipairs(state.connections) do connection:Disconnect() end
    gui:Destroy(); if env[KEY]==state then env[KEY]=nil end
end
refresh()
-- Bit generator: sync to the game's label, then count down independently of the popup.
local function bitTimerSeconds(text)
    text=tostring(text or ''):gsub('<[^>]->',''):match('^%s*(.-)%s*$')
    local minutes,seconds=text:match('^(%d+):(%d%d)$')
    minutes,seconds=tonumber(minutes),tonumber(seconds)
    if not minutes or not seconds or seconds>=60 then return nil end
    local total=minutes*60+seconds
    if total>1800 then return nil end
    return total
end
local function bitTimerRemaining(deadline,now)
    local left=math.ceil(deadline-now)
    if left>=0 then return left,false end
    -- Automatic generation repeats every 30 minutes. Later cycles are estimates
    -- until the game updates its label again; zero itself does not prove a payout.
    local cycles=math.floor((now-deadline)/1800)+1
    return math.ceil(deadline+cycles*1800-now),true
end
task.spawn(function()
    local source,lastText,wasVisible,deadline,lastSync=nil,nil,false,nil,nil
    local lastWarning=-math.huge
    while state.running do
        local ok,err=pcall(function()
            local current=path(player:FindFirstChild('PlayerGui'),'System','BitsGenerator','Holder','Output','Stats','Time')
            local now=os.clock()
            if current~=source then
                source=current; lastText=nil; wasVisible=false
            end
            if source and source:IsA('TextLabel') then
                local text=source.Text
                local shown=visible(source)
                local seconds=bitTimerSeconds(text)
                -- Hidden labels can contain an old session/default countdown. Only
                -- trust them after seeing an update, or while the popup is visible.
                local updated=lastText~=nil and text~=lastText
                if seconds and ((shown and (text~=lastText or not wasVisible)) or updated) then
                    deadline=now+seconds; lastSync=now
                end
                lastText=text; wasVisible=shown
            end
            if deadline then
                local remaining,nextCycle=bitTimerRemaining(deadline,now)
                bitTimerLabel.Text=string.format('%02d:%02d',math.floor(remaining/60),remaining%60)
                local estimated=nextCycle or now-lastSync>3
                bitTimerNote.Text=estimated and 'Estimated from last generator sync' or 'Synced with generator'
            else
                bitTimerLabel.Text='--:--'
                bitTimerNote.Text='Open generator once to sync'
            end
        end)
        if not ok and os.clock()-lastWarning>=10 then
            lastWarning=os.clock(); warn('[TBOD Bit Timer]',err)
        end
        task.wait(0.25)
    end
end)
-- Ownership lookup
local cachedTycoon,nextLookup=nil,0
local function owns(object)
    for _,name in ipairs({'Owner','OwnerId','Player','User'}) do
        local owner=object:FindFirstChild(name)
        if owner then
            if owner:IsA('ObjectValue') and owner.Value==player then return true end
            if owner:IsA('StringValue') or owner:IsA('IntValue') or owner:IsA('NumberValue') then
                local value=tostring(owner.Value); if value==player.Name or value==tostring(player.UserId) then return true end
            end
        end
    end
    return object:GetAttribute('Owner')==player.Name or object:GetAttribute('Owner')==player.UserId or tostring(object:GetAttribute('OwnerId'))==tostring(player.UserId)
end
local function positionOf(object)
    if object:IsA('Model') or object:IsA('BasePart') then return object:GetPivot().Position end
    local part=object:FindFirstChildWhichIsA('BasePart',true); return part and part.Position
end
local function buttonsOf(object)
    return object and (object:FindFirstChild('Buttons') or object:FindFirstChild('ButtonFolder'))
end
local function tycoon()
    if os.clock()<nextLookup then return cachedTycoon and cachedTycoon.Parent and cachedTycoon or nil end
    nextLookup=os.clock()+2; cachedTycoon=nil
    local folder=Workspace:FindFirstChild('Tycoons') or Workspace:FindFirstChild('Tycoon') or Workspace:FindFirstChild('Plots')
    if not folder then return nil end
    local candidates={}
    for _,object in ipairs(folder:GetChildren()) do
        if buttonsOf(object) then
            table.insert(candidates,object)
            if owns(object) then cachedTycoon=object; return object end
        end
    end
    local plots=Workspace:FindFirstChild('Plots'); local plotPosition
    if plots then
        for _,plot in ipairs(plots:GetChildren()) do
            local sign=plot:FindFirstChild('SignPlace'); local nameLabel=sign and sign:FindFirstChild('NameLabel',true); local matches=owns(plot)
            if nameLabel and nameLabel:IsA('TextLabel') then
                local text=nameLabel.Text:match('^%s*(.-)%s*$'):lower(); matches=matches or text==player.Name:lower() or text==player.DisplayName:lower()
            end
            if matches then
                if buttonsOf(plot) then cachedTycoon=plot; return plot end
                plotPosition=positionOf(plot); break
            end
        end
    end
    if plotPosition then
        local shortest=math.huge
        for _,object in ipairs(candidates) do local position=positionOf(object)
            if position then local distance=(position-plotPosition).Magnitude; if distance<shortest then shortest,cachedTycoon=distance,object end end
        end
    elseif #candidates==1 then cachedTycoon=candidates[1] end
    return cachedTycoon
end
-- Working Auto Buy operation retained.
local buttonCache=setmetatable({},{__mode='k'})
local retries=setmetatable({},{__mode='k'})
local function details(object)
    local cached=buttonCache[object]
    if cached and cached.price.Parent and cached.part.Parent then return cached end
    local display=object:FindFirstChild('PriceDisplay',true)
    local priceLabel=display and (display:IsA('TextLabel') and display or display:FindFirstChildWhichIsA('TextLabel',true))
    if not priceLabel then return nil end
    local part
    if object:IsA('BasePart') then part=object else
        for _,descendant in ipairs(object:GetDescendants()) do
            if descendant:IsA('TouchTransmitter') and descendant.Parent:IsA('BasePart') then part=descendant.Parent; break end
        end
        part=part or object:FindFirstChild('Head') or object:FindFirstChild('Part') or object:FindFirstChildWhichIsA('BasePart',true)
    end
    if not part or not part:IsA('BasePart') then return nil end
    cached={price=priceLabel,part=part}; buttonCache[object]=cached; return cached
end
local function eligible(object)
    if not object:IsDescendantOf(Workspace) then return nil end
    local data=details(object); if not data or not visible(data.price) then return nil end
    local display=object:FindFirstChild('NameDisplay',true)
    local nameLabel=display and (display:IsA('TextLabel') and display or display:FindFirstChildWhichIsA('TextLabel',true))
    if nameLabel and not nameLabel.Text:match('%S') then return nil end
    -- Reparse only when the displayed price changes, including invalid text.
    local text=data.price.Text
    if data.lastPriceText~=text then
        data.lastPriceText=text
        data.lastPrice=number(text)
    end
    local cost=data.lastPrice; if cost==nil then return nil end
    return data,cost
end
local function updateBuy()
    if type(firetouchinterest)~='function' then state.buy=false; refresh(); status.Text='Executor missing firetouchinterest'; return end
    local buttons=buttonsOf(tycoon()); local root=rootPart()
    if not buttons or not root then status.Text='Waiting for tycoon / character'; return end
    local balance=cash(); local now=os.clock(); local selected,selectedData; local cheapest=math.huge
    for _,object in ipairs(buttons:GetChildren()) do
        -- A cooling-down button cannot be selected; skip its GUI searches.
        if now>=(retries[object] or 0) then
            local data,cost=eligible(object)
            if data and cost<=balance and cost<cheapest then
                selected,selectedData,cheapest=object,data,cost
            end
        end
    end
    if not selected then status.Text='Waiting for cash / next purchase'; return end
    retries[selected]=now+1; status.Text='Buying: '..selected.Name
    local part=selectedData.part; firetouchinterest(root,part,0); task.wait(0.05)
    pcall(function() firetouchinterest(root,part,1) end)
end
-- Rebirth readiness: numeric cash goal or completed exact progress display.
local cachedGoal
local function rebirthObjects()
    local pg=player:FindFirstChild('PlayerGui')
    local menu=path(pg,'Main','Rebirth')
    local inner=path(menu,'Main','Inner')
    local progress=inner and inner:FindFirstChild('Progress')
    local target=inner and inner:FindFirstChild('Rebirth')
    local button
    if target then
        if target:IsA('GuiButton') then button=target else
            for _,object in ipairs(target:GetDescendants()) do
                if object:IsA('GuiButton') and visible(object) then button=object; break end
            end
        end
    end
    return {frame=menu,button=button,target=target,progress=progress and progress:FindFirstChildWhichIsA('TextLabel',true)}
end
local goalParseCache=setmetatable({},{__mode='k'})
local function goalFrom(labelObject)
    if not labelObject or not labelObject:IsA('TextLabel') then return nil end
    local text=labelObject.Text
    local cached=goalParseCache[labelObject]
    if cached and cached.text==text then return cached.goal end
    local _,right=text:match('(.-)%s*/%s*(.+)')
    local goal=right and number(right)
    goal=goal and goal>0 and goal or nil
    goalParseCache[labelObject]={text=text,goal=goal}
    return goal
end
local function progressSaysReady(labelObject)
    if not labelObject or not labelObject:IsA('TextLabel') then return false end
    local text=labelObject.Text:gsub('<[^>]->',''):upper():match('^%s*(.-)%s*$')
    -- Only the game's exact rebirth progress labels are used here.
    -- Arbitrary notifications cannot trigger rebirth.
    if text:find('NOT COMPLETE',1,true) or text:find('INCOMPLETE',1,true)
        or text:find('NOT READY',1,true) then return false end
    local percent=tonumber(text:match('(%d+%.?%d*)%%'))
    if percent then return percent>=100 end
    for word in text:gmatch('%a+') do
        if word=='COMPLETE' or word=='COMPLETED' or word=='MAX' or word=='DONE' or word=='READY' then
            return true
        end
    end
    return false
end
local function readGoal()
    local pg=player:FindFirstChild('PlayerGui')
    local progress=path(pg,'System','RebirthProgress','Progress')
    local progressLabel=progress and (progress:FindFirstChild('TextLabel') or progress:FindFirstChildWhichIsA('TextLabel',true))
    local objects=rebirthObjects()
    -- The live progress display takes priority over a hidden menu's stale goal.
    if progressSaysReady(progressLabel) then
        state.readiness='Ready: live progress complete'
        readinessLabel.Text='Ready to rebirth'
        return 0
    end
    local goal=goalFrom(progressLabel)
    if goal then
        cachedGoal=goal
        state.readiness='Cash '..tostring(cash())..' / goal '..tostring(goal)
        readinessLabel.Text=cash()>=goal and 'Cash goal reached' or 'Waiting for required cash'
        return goal
    end
    -- A visible menu is the next reliable source. Do not trust a hidden
    -- menu's COMPLETE label as proof that the current rebirth is ready.
    if visible(objects.frame) and progressSaysReady(objects.progress) then
        state.readiness='Ready: visible rebirth menu complete'
        readinessLabel.Text='Ready to rebirth'
        return 0
    end
    goal=goalFrom(objects.progress)
    if goal then
        cachedGoal=goal
        state.readiness='Menu goal '..tostring(goal)..'; cash '..tostring(cash())
        readinessLabel.Text=cash()>=goal and 'Cash goal reached' or 'Waiting for required cash'
        return goal
    end
    if cachedGoal then
        state.readiness='Cached goal '..tostring(cachedGoal)..'; cash '..tostring(cash())
        readinessLabel.Text=cash()>=cachedGoal and 'Cash goal reached' or 'Waiting for required cash'
        return cachedGoal
    end
    local raw=progressLabel and progressLabel.Text or '(label missing)'
    state.readiness='Cannot read rebirth readiness. Live text: '..tostring(raw)
    readinessLabel.Text='Progress: '..tostring(raw):gsub('<[^>]->',''):sub(1,36)
    return nil
end
local function essenceCapped()
    local notice=path(player:FindFirstChild('PlayerGui'),'System','Notifications','NotiHolder','EssenceCappedTemp')
    if not notice then return false end
    for _,object in ipairs(notice:GetDescendants()) do
        if (object:IsA('TextLabel') or object:IsA('TextButton')) and visible(object) and object.Text:lower():find('your essence is capped',1,true) then return true end
    end
    return false
end
local function rebirthCount()
    local stats=player:FindFirstChild('leaderstats') or player:FindFirstChild('stats')
    if stats then
        for _,name in ipairs({'Rebirths','Rebirth','RebirthsCount'}) do
            local value=stats:FindFirstChild(name)
            if value and value:IsA('ValueBase') then local count=tonumber(value.Value) or tonumber(tostring(value.Value):gsub(',',''):match('%d+')); if count then return count end end
        end
    end
    local labelObject=path(player:FindFirstChild('PlayerGui'),'System','PlayerList','Holder',player.Name,'RebsText')
    if labelObject and not (labelObject:IsA('TextLabel') or labelObject:IsA('TextButton')) then
        labelObject=labelObject:FindFirstChildWhichIsA('TextLabel',true)
    end
    -- Count labels may say '123 Rebirths'; their trailing word is not a cash suffix.
    if labelObject and (labelObject:IsA('TextLabel') or labelObject:IsA('TextButton')) then
        return tonumber(labelObject.Text:gsub('<[^>]->',''):gsub(',',''):match('%d+'))
    end
    return nil
end
-- Discord notifications run independently of automation toggles.
local HttpService=game:GetService('HttpService')
local webhookQueue={}
local statAliases={
    Essence={'Essence','Essences','EssenceCount','EssenceText'},
    Bits={'Bits','Bit','BitCount','BitsCount','BitsText','BitText'},
}
local function webhookNumber(value)
    local text=tostring(value or ''):gsub('<[^>]->',''):gsub(',','')
    local raw,suffix=text:upper():match('(%d+%.?%d*)%s*([A-Z]*)')
    if not raw then return nil end
    return tonumber(raw)*(multipliers[suffix] or 1)
end
local function objectBalance(object)
    if not object then return nil end
    if object:IsA('ValueBase') then return webhookNumber(object.Value) end
    if object:IsA('TextLabel') or object:IsA('TextButton') then return webhookNumber(object.Text) end
    local label=object:FindFirstChildWhichIsA('TextLabel',true)
    return label and webhookNumber(label.Text) or nil
end
local function webhookBalance(kind)
    local explicit=WEBHOOK.StatPaths[kind]
    if explicit then return objectBalance(path(player,table.unpack(explicit))) end
    -- Prefer replicated balances over rounded GUI displays and generator output.
    for _,folderName in ipairs({'leaderstats','stats','Stats','Data','PlayerData'}) do
        local folder=player:FindFirstChild(folderName)
        if folder then
            for _,name in ipairs(statAliases[kind]) do
                local value=objectBalance(folder:FindFirstChild(name,true))
                if value~=nil then return value end
            end
        end
    end
    for _,name in ipairs(statAliases[kind]) do
        local value=webhookNumber(player:GetAttribute(name))
        if value~=nil then return value end
    end
    local pg=player:FindFirstChild('PlayerGui')
    for _,root in ipairs({path(pg,'System','PlayerList','Holder',player.Name) or false,
        path(pg,'System','Main') or false}) do
        if root then
            for _,name in ipairs(statAliases[kind]) do
                local value=objectBalance(root:FindFirstChild(name,true))
                if value~=nil then return value end
            end
        end
    end
    return nil
end
local function queueWebhook(title,essence,rebirths,bits,gain)
    if not WEBHOOK.Enabled or WEBHOOK.URL=='' then return end
    local function display(value) return value~=nil and tostring(value) or 'Unavailable' end
    table.insert(webhookQueue,{
        username='TBOD Notifications', allowed_mentions={parse={}},
        embeds={{title=title,color=gain and 6012071 or 10190335,
            description=player.Name..(gain and (' gained '..display(gain)..' bits.') or ' rebirthed.'),
            fields={
                {name='Essence',value=display(essence),inline=true},
                {name='Rebirths',value=display(rebirths),inline=true},
                {name='Bits',value=display(bits),inline=true},
            },timestamp=os.date('!%Y-%m-%dT%H:%M:%SZ')}},
    })
end
local lastWebhookRebirth=nil
local function notifyRebirth(count)
    if count~=nil and lastWebhookRebirth==count then return end
    lastWebhookRebirth=count
    task.spawn(function()
        -- Allow the game's reward balances to replicate before reading them.
        task.wait(1)
        if state.running then queueWebhook('Rebirth complete',webhookBalance('Essence'),count or rebirthCount(),webhookBalance('Bits')) end
    end)
end
local observedRebirth,observedBits=rebirthCount(),webhookBalance('Bits')
lastWebhookRebirth=observedRebirth
local function observeWebhookStats()
    local count,bits=rebirthCount(),webhookBalance('Bits')
    if count~=nil then
        if observedRebirth~=nil and count>observedRebirth then notifyRebirth(count) end
        observedRebirth=count
    end
    if bits~=nil then
        if observedBits~=nil and bits>observedBits then
            queueWebhook('Bits received',webhookBalance('Essence'),count,bits,bits-observedBits)
        end
        -- Spending establishes a new baseline; initial loading never sends a gain.
        observedBits=bits
    end
end
-- Value changes capture successive rewards between GUI polling intervals.
local watchedValues=setmetatable({}, {__mode='k'})
local function watchWebhookValue(object)
    if not object:IsA('ValueBase') or watchedValues[object] then return end
    local relevant=false
    for _,aliases in pairs(statAliases) do
        for _,name in ipairs(aliases) do if object.Name==name then relevant=true end end
    end
    for _,name in ipairs({'Rebirths','Rebirth','RebirthsCount'}) do if object.Name==name then relevant=true end end
    for _,explicit in pairs(WEBHOOK.StatPaths) do
        if object==path(player,table.unpack(explicit)) then relevant=true end
    end
    if relevant then watchedValues[object]=true; connect(object.Changed,function() pcall(observeWebhookStats) end) end
end
for _,object in ipairs(player:GetDescendants()) do watchWebhookValue(object) end
connect(player.DescendantAdded,watchWebhookValue)
task.spawn(function()
    local warned=false
    while state.running do
        local ok=pcall(observeWebhookStats)
        if not ok and not warned then warned=true; warn('[TBOD Webhook] Unable to read balances; set WEBHOOK.StatPaths.') end
        task.wait(0.5)
    end
end)
task.spawn(function()
    while state.running do
        if #webhookQueue==0 then task.wait(0.25) else
            local payload=webhookQueue[1]
            local sender=env.request or env.http_request or (env.syn and env.syn.request) or request or http_request or (syn and syn.request)
            if type(sender)~='function' then
                warn('[TBOD Webhook] Executor HTTP request API unavailable; notifications disabled.')
                table.clear(webhookQueue); return
            end
            if not WEBHOOK.Enabled or WEBHOOK.URL=='' then table.remove(webhookQueue,1) else
                local ok,response=pcall(function()
                    return sender({Url=WEBHOOK.URL,Method='POST',Headers={['Content-Type']='application/json'},Body=HttpService:JSONEncode(payload)})
                end)
                local code=ok and type(response)=='table' and tonumber(response.StatusCode or response.Status) or nil
                if code==429 then
                    local decodedOk,body=pcall(function() return HttpService:JSONDecode(response.Body or '{}') end)
                    task.wait(math.max(1,decodedOk and type(body)=='table' and tonumber(body.retry_after) or 2))
                else
                    table.remove(webhookQueue,1)
                    if not code or code<200 or code>=300 then
                        -- Never print the webhook URL/token or executor error text.
                        warn('[TBOD Webhook] Notification failed (HTTP '..tostring(code or 'request error')..').')
                    end
                    task.wait(1)
                end
            end
        end
    end
end)

local function rebirthConfirmed(beforeCount,beforeCash,oldGoal)
    local afterCount=rebirthCount()
    if beforeCount~=nil and afterCount~=nil then return afterCount>beforeCount end
    -- If no count is exposed, require a cash reset, incomplete new progress,
    -- and a closed menu. Auto Buy is paused during these checks.
    local pg=player:FindFirstChild('PlayerGui')
    local progress=path(pg,'System','RebirthProgress','Progress')
    local labelObject=progress and progress:FindFirstChildWhichIsA('TextLabel',true)
    local left,right
    if labelObject then left,right=labelObject.Text:match('(.-)%s*/%s*(.+)') end
    local current,goal=left and number(left),right and number(right)
    local afterCash=cash()
    local cashReset=afterCash<beforeCash and (oldGoal==0 or afterCash<oldGoal)
    return beforeCash>=oldGoal and cashReset
        and current~=nil and goal~=nil and current<goal
        and not visible(rebirthObjects().frame)
end
local function diagnoseRebirth()
    local objects=rebirthObjects()
    local root=objects.target or objects.frame
    warn('[TBOD Rebirth diagnostic] cash='..tostring(cash())..' mode='..state.mode
        ..' firesignal='..type(firesignal)..' getconnections='..type(getconnections))
    warn('[TBOD Rebirth diagnostic] rebirthCount='..tostring(rebirthCount()))
    local row=path(player:FindFirstChild('PlayerGui'),'System','PlayerList','Holder',player.Name)
    if row then
        for _,object in ipairs(row:GetDescendants()) do
            if (object:IsA('TextLabel') or object:IsA('TextButton')) and object.Name~='CashText' then
                warn('[TBOD Rebirth diagnostic] player label '..object:GetFullName()..'='..object.Text:sub(1,120))
            end
        end
    end
    for _,folderName in ipairs({'leaderstats','stats'}) do
        local folder=player:FindFirstChild(folderName)
        if folder then
            for _,value in ipairs(folder:GetChildren()) do
                if value:IsA('ValueBase') then
                    warn('[TBOD Rebirth diagnostic] stat '..value:GetFullName()..'='..tostring(value.Value))
                end
            end
        else warn('[TBOD Rebirth diagnostic] '..folderName..' missing') end
    end
    local pg=player:FindFirstChild('PlayerGui')
    for _,labelObject in ipairs({path(pg,'System','Main','Cash','CashText') or false,
        path(pg,'System','PlayerList','Holder',player.Name,'CashText') or false}) do
        if labelObject and (labelObject:IsA('TextLabel') or labelObject:IsA('TextButton')) then
            warn('[TBOD Rebirth diagnostic] cash label '..labelObject:GetFullName()..'='..labelObject.Text)
        end
    end
    if root then
        local ancestor=root
        while ancestor do
            if ancestor:IsA('GuiObject') and not ancestor.Visible then
                warn('[TBOD Rebirth diagnostic] Hidden ancestor: '..ancestor:GetFullName())
            elseif ancestor:IsA('LayerCollector') and not ancestor.Enabled then
                warn('[TBOD Rebirth diagnostic] Disabled GUI: '..ancestor:GetFullName())
            end
            ancestor=ancestor.Parent
        end
    end
    if not root then warn('[TBOD Rebirth diagnostic] Exact rebirth menu/control missing'); return end
    local nodes={root}
    for _,object in ipairs(root:GetDescendants()) do nodes[#nodes+1]=object end
    local reported=0
    for _,object in ipairs(nodes) do
        if object:IsA('GuiObject') then
            reported=reported+1
            if reported>60 then warn('[TBOD Rebirth diagnostic] Control list truncated at 60'); break end
            local description=object:GetFullName()..' ['..object.ClassName..'] visible='..tostring(visible(object))
                ..' active='..tostring(object.Active)
            if object:IsA('TextButton') or object:IsA('TextLabel') then description=description..' text='..object.Text:sub(1,120) end
            local readable,interactable=pcall(function() return object.Interactable end)
            if readable then description=description..' interactable='..tostring(interactable) end
            warn('[TBOD Rebirth diagnostic] '..description)
            if type(getconnections)=='function' then
                for _,name in ipairs({'MouseButton1Click','Activated','MouseButton1Down','MouseButton1Up','InputBegan','InputEnded'}) do
                    local found,signal=pcall(function() return object[name] end)
                    if found and typeof(signal)=='RBXScriptSignal' then
                        local ok,connections=pcall(getconnections,signal)
                        if ok and type(connections)=='table' then
                            local enabled,foreign,callbacks=0,0,0
                            for index,connection in ipairs(connections) do
                                local details={}
                                for _,property in ipairs({'Enabled','ForeignState','LuaConnection','LuaWaitConnection','Function','Thread','Fire','Defer'}) do
                                    local readable,value=pcall(function() return connection[property] end)
                                    local info=readable and (type(value)=='boolean' and tostring(value) or typeof(value)) or ('ERROR '..tostring(value))
                                    details[#details+1]=property..'='..info
                                    if readable and property=='Enabled' and value~=false then enabled=enabled+1 end
                                    if readable and property=='ForeignState' and value then foreign=foreign+1 end
                                    if readable and property=='Function' and type(value)=='function' then callbacks=callbacks+1 end
                                end
                                warn('[TBOD Rebirth diagnostic] '..name..' connection '..index..' '..table.concat(details,' '))
                            end
                            warn('[TBOD Rebirth diagnostic] '..name..': total='..#connections
                                ..' enabled='..enabled..' foreign='..foreign..' callbacks='..callbacks)
                        else warn('[TBOD Rebirth diagnostic] '..name..' inspection failed: '..tostring(connections)) end
                    end
                end
            end
        end
    end
end
local function replicatedClick(button)
    if not button or not visible(button) then return false end
    if type(cansignalreplicate)~='function' or type(replicatesignal)~='function' then
        warn('[TBOD Rebirth] Volt replication APIs unavailable'); return false
    end
    local signal=button.MouseButton1Click
    local checked,supported=pcall(cansignalreplicate,signal)
    warn('[TBOD Rebirth] MouseButton1Click replication supported='..tostring(checked and supported==true))
    if not checked or supported~=true then return false end
    -- MouseButton1Click has no user arguments. Refuse any unexpected engine signature.
    if type(getsignalarguments)=='function' then
        local ok,args=pcall(getsignalarguments,signal)
        if not ok or type(args)~='table' then
            warn('[TBOD Rebirth] Cannot inspect replication signature'); return false
        end
        if #args~=0 then
            warn('[TBOD Rebirth] Unexpected MouseButton1Click signature ('..#args..' arguments); skipped'); return false
        end
    end
    local ok,err=pcall(replicatesignal,signal)
    if not ok then warn('[TBOD Rebirth replication]',err) end
    return ok
end
local function connectedClick(button, signalName, direct, deferred)
    if not button or not button:IsA('GuiButton') or not visible(button) then return false end
    if type(getconnections)~='function' then return false end
    local ok,connections=pcall(function() return getconnections(button[signalName]) end)
    if not ok or type(connections)~='table' then return false end
    warn('[TBOD Rebirth] '..signalName..' connections: '..tostring(#connections))
    local invoked=false
    for _,connection in ipairs(connections) do
        local worked,result=pcall(function()
            if connection.Enabled==false then return false end
            if deferred then
                if type(connection.Defer)~='function' then return false end
                if signalName=='Activated' then connection:Defer(nil,1) else connection:Defer() end
                return true
            end
            if not direct and type(connection.Fire)=='function' then
                if signalName=='Activated' then connection:Fire(nil,1) else connection:Fire() end
                return true
            end
            local callback=connection.Function
            if type(callback)=='function' then
                task.spawn(function()
                    local success,err
                    if signalName=='Activated' then success,err=pcall(callback,nil,1) else success,err=pcall(callback) end
                    if not success then warn('[TBOD Rebirth callback]',err) end
                end)
                return true
            end
            return false
        end)
        if not worked then warn('[TBOD Rebirth connection]',result) end
        invoked=invoked or (worked and result==true)
    end
    return invoked
end
local function signalClick(button, signalName)
    if not button or not button:IsA('GuiButton') or not visible(button) or type(firesignal)~='function' then return false end
    local ok,err=pcall(function()
        if signalName=='Activated' then firesignal(button.Activated,nil,1)
        elseif signalName=='MouseButton1Down' or signalName=='MouseButton1Up' then
            local position=button.AbsolutePosition+button.AbsoluteSize/2
            firesignal(button[signalName],position.X,position.Y)
        else firesignal(button[signalName]) end
    end)
    if not ok then warn('[TBOD Rebirth signal]',signalName,err) end
    return ok
end
local function pressReleaseClick(button)
    -- These are GUI signals only; they do not send mouse input or move the cursor.
    local down=signalClick(button,'MouseButton1Down')
    task.wait(0.1)
    if not state.running or not state.rebirth or not visible(button) then return down end
    local up=signalClick(button,'MouseButton1Up')
    return down or up
end
local function activeRebirth() return state.running and state.rebirth and not state.disconnected end
local function waitConfirmation(beforeCount,beforeCash,oldGoal,duration)
    local deadline=os.clock()+duration
    repeat
        if rebirthConfirmed(beforeCount,beforeCash,oldGoal) then return true end
        if not activeRebirth() then return false end
        task.wait(0.15)
    until os.clock()>=deadline
    return rebirthConfirmed(beforeCount,beforeCash,oldGoal)
end
local function startRebirth(goal)
    if state.busy or os.clock()-state.lastRebirth<8 then return end
    if cash()<goal or (state.mode=='Essence Cap' and not essenceCapped()) then return end
    state.busy=true; state.lastRebirth=os.clock()
    task.spawn(function()
        local success,err=pcall(function()
            if not activeRebirth() then return end
            local beforeCount,beforeCash=rebirthCount(),cash()
            local objects=rebirthObjects()
            if not visible(objects.button) then
                status.Text='Opening rebirth: cash goal reached'
                local click=path(Workspace,'Obelisk','RebirthButton','Click')
                local detector=click and click:FindFirstChildOfClass('ClickDetector')
                if not detector then error('Rebirth ClickDetector not found') end
                if type(fireclickdetector)~='function' then error('Executor missing fireclickdetector') end
                fireclickdetector(detector)
            end
            local deadline=os.clock()+4
            repeat
                if not activeRebirth() then return end
                objects=rebirthObjects(); if visible(objects.button) then break end
                task.wait(0.15)
            until os.clock()>=deadline
            if not objects.button or not visible(objects.button) then
                local target=objects.target
                warn('[TBOD Rebirth] Inner.Rebirth: '..(target and (target:GetFullName()..' ['..target.ClassName..']') or 'missing'))
                pcall(diagnoseRebirth)
                error('No visible GuiButton inside exact rebirth control')
            end
            task.wait(0.4)
            if not activeRebirth() then return end
            -- Re-check the exact menu goal before clicking.
            local menuGoal=goalFrom(rebirthObjects().progress)
            -- Keep a live COMPLETE readiness token authoritative.
            if menuGoal and goal>0 then goal=menuGoal; cachedGoal=menuGoal end
            if cash()<goal then status.Text='Waiting for required cash'; return end
            if state.mode=='Essence Cap' and not essenceCapped() then status.Text='Waiting for essence cap'; return end
            local button=rebirthObjects().button
            if not button or not visible(button) then error('Rebirth button disappeared before confirmation') end
            warn('[TBOD Rebirth] Confirmation target: '..button:GetFullName()..' ['..button.ClassName..']')
            -- Volt's documented signal/connection APIs do not need OS mouse input.
            local methods={
                {name='supported engine replication',run=replicatedClick},
                {name='MouseButton1Click deferred connection',run=function(b) return connectedClick(b,'MouseButton1Click',false,true) end},
                {name='MouseButton1Click signal',run=function(b) return signalClick(b,'MouseButton1Click') end},
                {name='Activated signal',run=function(b) return signalClick(b,'Activated') end},
                {name='MouseButton1Click connection',run=function(b) return connectedClick(b,'MouseButton1Click') end},
                {name='Activated connection',run=function(b) return connectedClick(b,'Activated') end},
                {name='MouseButton1Click callback',run=function(b) return connectedClick(b,'MouseButton1Click',true) end},
                {name='Activated callback',run=function(b) return connectedClick(b,'Activated',true) end},
                {name='GUI press/release signals',run=pressReleaseClick},
            }
            local confirmed=false
            for _,method in ipairs(methods) do
                if not activeRebirth() then break end
                if rebirthConfirmed(beforeCount,beforeCash,goal) then confirmed=true; break end
                -- Stop clicking after the menu closes; allow the reset to finish.
                button=rebirthObjects().button
                if not visible(button) then
                    confirmed=waitConfirmation(beforeCount,beforeCash,goal,5)
                    break
                end
                status.Text='Confirming: '..method.name
                warn('[TBOD Rebirth] Trying '..method.name)
                local worked,sent=pcall(method.run,button)
                if not worked then warn('[TBOD Rebirth method]',method.name,sent) end
                if worked and sent then confirmed=waitConfirmation(beforeCount,beforeCash,goal,3) end
                if confirmed then break end
            end
            if confirmed then
                cachedGoal=nil; nextLookup=0; table.clear(retries)
                status.Text='Rebirth verified'
                notifyRebirth(rebirthCount())
                task.wait(1)
            elseif activeRebirth() then
                pcall(diagnoseRebirth)
                error('Cursor-free rebirth not verified; send the TBOD Rebirth diagnostic messages')
            end
        end)
        state.busy=false
        if not success and state.running then status.Text='Rebirth confirmation failed; see console'; warn('[TBOD Rebirth]',err) end
    end)
end
connect(player.CharacterAdded,function() nextLookup=0; table.clear(retries) end)
-- Independent workers: rebirth watches cash even while buying is enabled.
task.spawn(function()
    local lastWarning=-math.huge
    while state.running do
        if state.buy and not state.busy and not state.disconnected then
            local ok,err=pcall(updateBuy)
            if not ok and os.clock()-lastWarning>=5 then lastWarning=os.clock(); warn('[TBOD Auto Buy]',err) end
        end
        task.wait(0.15)
    end
end)
task.spawn(function()
    local lastWarning=-math.huge
    while state.running do
        local ok,err=pcall(function()
            local goal=readGoal()
            local readinessKey=(goal==0 and 'complete') or (goal and (cash()>=goal and 'cash-ready' or 'cash-wait')) or 'unknown'
            readinessKey=readinessKey..':'..state.mode
            if state.rebirth and readinessKey~=state.lastReadinessLog then
                state.lastReadinessLog=readinessKey
                print('[TBOD Readiness] '..tostring(state.readiness)..'; mode='..state.mode)
            end
            if state.rebirth and not state.busy and not state.disconnected then
                if goal and cash()>=goal and (state.mode=='Ready' or essenceCapped()) then
                    startRebirth(goal)
                elseif not state.buy then
                    status.Text=not goal and 'Waiting for readable rebirth cash goal'
                        or (state.mode=='Essence Cap' and cash()>=goal and 'Waiting for essence cap' or 'Waiting for required rebirth cash')
                end
            elseif not state.buy and not state.busy then status.Text='Paused' end
        end)
        if not ok and os.clock()-lastWarning>=5 then lastWarning=os.clock(); warn('[TBOD Rebirth monitor]',err) end
        task.wait(0.25)
    end
end)
