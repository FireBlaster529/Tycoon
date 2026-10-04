-- TBOD Automation: simulated-touch buying + verified rebirth attempts
-- Drag the header. Click +/- to minimize. Both features start OFF.
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local player = Players.LocalPlayer
local env = getgenv()
local KEY = '__TBOD_Automation'
for _, key in ipairs({KEY, '__TycoonAutoBuyRebirth'}) do
    if env[key] and env[key].stop then pcall(env[key].stop) end
end
local state = {running=true, buy=false, rebirth=false, mode='Ready', busy=false, lastRebirth=-math.huge, connections={}}
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
local multipliers = {K=1e3,M=1e6,B=1e9,T=1e12,Q=1e15,QA=1e15,QN=1e18,QI=1e18,SX=1e21,SP=1e24,O=1e27,N=1e30,D=1e33}
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
local frame=Instance.new('Frame'); frame.Size=UDim2.fromOffset(390,338); frame.Position=UDim2.fromOffset(24,120); frame.BackgroundColor3=C.bg; frame.BorderSizePixel=0; frame.Active=true; frame.ClipsDescendants=true; frame.Parent=gui
round(frame,18); outline(frame)
local scale=Instance.new('UIScale'); scale.Parent=frame
local cameraConnection
local function fitScreen()
    local camera=Workspace.CurrentCamera
    if camera then local v=camera.ViewportSize; scale.Scale=math.clamp(math.min((v.X-24)/390,(v.Y-24)/338),0.4,1) end
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
local content=Instance.new('Frame'); content.Position=UDim2.fromOffset(16,76); content.Size=UDim2.fromOffset(358,246); content.BackgroundTransparency=1; content.Parent=frame
local function card(x,y,w,h)
    local obj=Instance.new('Frame'); obj.Position=UDim2.fromOffset(x,y); obj.Size=UDim2.fromOffset(w,h); obj.BackgroundColor3=C.card; obj.BorderSizePixel=0; obj.Parent=content; round(obj,14); outline(obj); return obj
end
local function toggleCard(x,heading,description,accent)
    local obj=card(x,0,174,116)
    local dot=Instance.new('Frame'); dot.Position=UDim2.fromOffset(14,16); dot.Size=UDim2.fromOffset(7,7); dot.BackgroundColor3=accent; dot.BorderSizePixel=0; dot.Parent=obj; round(dot,4)
    label(obj,heading,28,10,133,22,13,C.text,true); label(obj,description,14,36,146,17,10,C.muted)
    local button=Instance.new('TextButton'); button.Position=UDim2.fromOffset(12,69); button.Size=UDim2.fromOffset(150,34); button.BackgroundColor3=C.bg; button.BorderSizePixel=0; button.Font=Enum.Font.GothamBold; button.TextSize=11; button.TextColor3=C.muted; button.AutoButtonColor=false; button.Parent=obj; round(button,9)
    connect(button.MouseEnter,function() TweenService:Create(button,TweenInfo.new(0.12),{BackgroundTransparency=0.15}):Play() end)
    connect(button.MouseLeave,function() TweenService:Create(button,TweenInfo.new(0.12),{BackgroundTransparency=0}):Play() end)
    return button,dot
end
local buyButton,buyDot=toggleCard(0,'Auto Buy','Buy without moving',C.green)
local rebirthButton,rebirthDot=toggleCard(184,'Auto Rebirth','Wait for required cash',C.purple)
local triggerCard=card(0,126,358,54)
label(triggerCard,'REBIRTH TRIGGER',14,9,145,16,9,C.muted,true); label(triggerCard,'Choose when to rebirth',14,27,175,16,10,C.text)
local modeButton=Instance.new('TextButton'); modeButton.Position=UDim2.fromOffset(214,11); modeButton.Size=UDim2.fromOffset(132,32); modeButton.BackgroundColor3=Color3.fromRGB(46,37,72); modeButton.BorderSizePixel=0; modeButton.Font=Enum.Font.GothamBold; modeButton.TextSize=11; modeButton.TextColor3=C.purple; modeButton.Parent=triggerCard; round(modeButton,9)
local statusCard=card(0,190,358,56)
local statusDot=Instance.new('Frame'); statusDot.Position=UDim2.fromOffset(14,13); statusDot.Size=UDim2.fromOffset(6,6); statusDot.BackgroundColor3=C.muted; statusDot.BorderSizePixel=0; statusDot.Parent=statusCard; round(statusDot,3)
label(statusCard,'ACTIVITY',27,7,300,17,9,C.muted,true)
local status=label(statusCard,'Paused',14,25,330,24,11,C.text); status.TextWrapped=true
local function refresh()
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
local minimized,resizeTween=false,nil
connect(minimize.MouseButton1Click,function()
    minimized=not minimized; content.Visible=not minimized; minimize.Text=minimized and '+' or '−'
    if resizeTween then resizeTween:Cancel() end
    resizeTween=TweenService:Create(frame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(390,minimized and 68 or 338)}); resizeTween:Play()
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
    local cost=number(data.price.Text); if cost==nil then return nil end
    return data,cost
end
local function updateBuy()
    if type(firetouchinterest)~='function' then state.buy=false; refresh(); status.Text='Executor missing firetouchinterest'; return end
    local buttons=buttonsOf(tycoon()); local root=rootPart()
    if not buttons or not root then status.Text='Waiting for tycoon / character'; return end
    local balance=cash(); local now=os.clock(); local selected,selectedData; local cheapest=math.huge
    for _,object in ipairs(buttons:GetChildren()) do
        local data,cost=eligible(object)
        if data and cost<=balance and now>=(retries[object] or 0) and cost<cheapest then selected,selectedData,cheapest=object,data,cost end
    end
    if not selected then status.Text='Waiting for cash / next purchase'; return end
    retries[selected]=now+1; status.Text='Buying: '..selected.Name
    local part=selectedData.part; firetouchinterest(root,part,0); task.wait(0.05)
    pcall(function() firetouchinterest(root,part,1) end)
end
-- Rebirth readiness: required cash only, never arbitrary notification text.
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
local function goalFrom(labelObject)
    if not labelObject or not labelObject:IsA('TextLabel') then return nil end
    local _,right=labelObject.Text:match('(.-)%s*/%s*(.+)')
    local goal=right and number(right)
    return goal and goal>0 and goal or nil
end
local function readGoal()
    local pg=player:FindFirstChild('PlayerGui')
    local progress=path(pg,'System','RebirthProgress','Progress')
    local progressLabel=progress and progress:FindFirstChildWhichIsA('TextLabel',true)
    local goal=goalFrom(progressLabel)
    if not goal then goal=goalFrom(rebirthObjects().progress) end
    if goal then cachedGoal=goal end
    return cachedGoal
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
            if value and value:IsA('ValueBase') then local count=number(value.Value); if count then return count end end
        end
    end
    local labelObject=path(player:FindFirstChild('PlayerGui'),'System','PlayerList','Holder',player.Name,'RebsText')
    if labelObject and labelObject:IsA('TextLabel') then return number(labelObject.Text) end
    return nil
end
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
    return beforeCash>=oldGoal and cash()<oldGoal and cash()<beforeCash
        and current~=nil and goal~=nil and current<goal
        and not visible(rebirthObjects().frame)
end
local function mouseClick(button, addInset)
    if not button or not button:IsA('GuiButton') or not visible(button) then return false end
    local camera=Workspace.CurrentCamera; if not camera then return false end
    local position=button.AbsolutePosition+button.AbsoluteSize/2
    if addInset then local inset=game:GetService('GuiService'):GetGuiInset(); position=position+inset end
    local viewport=camera.ViewportSize
    if button.AbsoluteSize.X<=0 or button.AbsoluteSize.Y<=0 or position.X<0 or position.Y<0 or position.X>=viewport.X or position.Y>=viewport.Y then return false end
    -- Hide this dashboard briefly so it cannot intercept the confirmation click.
    local enabled=gui.Enabled
    gui.Enabled=false
    local ok,err=pcall(function()
        local input=game:GetService('VirtualInputManager')
        input:SendMouseMoveEvent(position.X,position.Y,game); task.wait(0.15)
        input:SendMouseButtonEvent(position.X,position.Y,0,true,game,0); task.wait(0.15)
        input:SendMouseButtonEvent(position.X,position.Y,0,false,game,0)
    end)
    if state.running then gui.Enabled=enabled end
    if not ok then warn('[TBOD Rebirth mouse]',err) end
    return ok
end
local function connectedClick(button, signalName)
    if not button or not button:IsA('GuiButton') or not visible(button) then return false end
    if type(getconnections)~='function' then return false end
    local ok,connections=pcall(function() return getconnections(button[signalName]) end)
    if not ok or type(connections)~='table' then return false end
    warn('[TBOD Rebirth] '..signalName..' connections: '..tostring(#connections))
    local invoked=false
    for _,connection in ipairs(connections) do
        local worked,result=pcall(function()
            if connection.Enabled==false then return false end
            if type(connection.Fire)=='function' then
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
    if not button or not visible(button) or type(firesignal)~='function' then return false end
    local ok,err=pcall(function()
        if signalName=='Activated' then firesignal(button.Activated,nil,1)
        else firesignal(button.MouseButton1Click) end
    end)
    if not ok then warn('[TBOD Rebirth signal]',err) end
    return ok
end
local function activeRebirth() return state.running and state.rebirth end
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
                error('No visible GuiButton inside exact rebirth control')
            end
            task.wait(0.4)
            if not activeRebirth() then return end
            -- Re-check the exact menu goal before clicking.
            local menuGoal=goalFrom(rebirthObjects().progress)
            if menuGoal then goal=menuGoal; cachedGoal=menuGoal end
            if cash()<goal then status.Text='Waiting for required cash'; return end
            if state.mode=='Essence Cap' and not essenceCapped() then status.Text='Waiting for essence cap'; return end
            local button=rebirthObjects().button
            warn('[TBOD Rebirth] Confirmation target: '..button:GetFullName()..' ['..button.ClassName..']')
            local methods={
                {name='mouse / standard inset',run=function(b)
                    local screen=b:FindFirstAncestorWhichIsA('ScreenGui')
                    return mouseClick(b,screen and not screen.IgnoreGuiInset)
                end},
                {name='MouseButton1Click connection',run=function(b) return connectedClick(b,'MouseButton1Click') end},
                {name='Activated connection',run=function(b) return connectedClick(b,'Activated') end},
                {name='mouse / alternate inset',run=function(b)
                    local screen=b:FindFirstAncestorWhichIsA('ScreenGui')
                    return mouseClick(b,not (screen and not screen.IgnoreGuiInset))
                end},
                {name='MouseButton1Click signal',run=function(b) return signalClick(b,'MouseButton1Click') end},
                {name='Activated signal',run=function(b) return signalClick(b,'Activated') end},
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
                local sent=method.run(button)
                if sent then confirmed=waitConfirmation(beforeCount,beforeCash,goal,3) end
                if confirmed then break end
            end
            if confirmed then
                cachedGoal=nil; nextLookup=0; table.clear(retries)
                status.Text='Rebirth verified'
                task.wait(1)
            elseif activeRebirth() then
                error('Rebirth not verified; confirmation will retry')
            end
        end)
        state.busy=false
        if not success and state.running then status.Text='Rebirth not confirmed; see console'; warn('[TBOD Rebirth]',err) end
    end)
end
connect(player.CharacterAdded,function() nextLookup=0; table.clear(retries) end)
-- Independent workers: rebirth watches cash even while buying is enabled.
task.spawn(function()
    local lastWarning=-math.huge
    while state.running do
        if state.buy and not state.busy then
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
            if state.rebirth and not state.busy then
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
