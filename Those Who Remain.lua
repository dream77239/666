local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dream77239/china-ui/refs/heads/main/main%20(6).lua"))()
local Window = WindUI:CreateWindow({
    Title = "Those Who Remain",
    Icon = "eye",
    IconThemed = true,
    Author = "dick",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(500, 400),
    Transparent = true,
    Theme = "Light",
    Background = nil,
    User = {
        Enabled = true,
        Callback = function() end,
        Anonymous = false
    },
    SideBarWidth = 200,
    ScrollBarEnabled = true
})
local Tab = Window:Tab({  
    Title = "功能",  
    Icon = "house",  
    Locked = false,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local tpOn = false
local tpSpd = 5

Tab:Toggle({
    Title = "速度",
    Value = false,
    Callback = function(state)
        tpOn = state
        if state then
            task.spawn(function()
                while tpOn do
                    local delta = RunService.Heartbeat:Wait()
                    local chr = LocalPlayer.Character
                    if chr then
                        local hrp = chr:FindFirstChild("HumanoidRootPart")
                        local hum = chr:FindFirstChildWhichIsA("Humanoid")
                        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * tpSpd * delta)
                        end
                    end
                end
            end)
        end
    end
})

Tab:Slider({
    Title = "速度值",
    Value = {
        Min = 0,
        Max = 50,
        Default = tpSpd,
    },
    Callback = function(v)
        tpSpd = v
    end
})

local Entities = Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild("Infected")
local Config = {
    SilentAim = false,
    SilentAimFOV = 100,
    PlayerESP = false,
    InfectedESP = false
}

local SilentFOV = Drawing.new("Circle")
SilentFOV.Visible = false
SilentFOV.Radius = Config.SilentAimFOV
SilentFOV.Color = Color3.fromRGB(255, 255, 255)
SilentFOV.Thickness = 1
SilentFOV.Transparency = 1
SilentFOV.Filled = false

local function getTarget(fov)
    if not Entities then return nil end
    local closest, dist = nil, fov
    for _, entity in ipairs(Entities:GetChildren()) do
        local head = entity:FindFirstChild("Head")
        local hum = entity:FindFirstChildOfClass("Humanoid")
        if head and hum and hum.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                if mag < dist then
                    dist = mag
                    closest = head
                end
            end
        end
    end
    return closest
end

local function createESP(object, color)
    if not object:FindFirstChild("ESPHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = object
        highlight.FillTransparency = 1
        highlight.OutlineColor = color
        highlight.Parent = object
    end
end

local function removeESP(object)
    local highlight = object:FindFirstChild("ESPHighlight")
    if highlight then highlight:Destroy() end
end

Tab:Toggle({
    Title = "子追",
    Value = false,
    Callback = function(state)
        Config.SilentAim = state
        SilentFOV.Visible = state
    end
})

Tab:Slider({
    Title = "子追fov大小",
    Value = {
        Min = 10,
        Max = 500,
        Default = 100,
    },
    Callback = function(value)
        Config.SilentAimFOV = value
        SilentFOV.Radius = value
    end
})

Tab:Toggle({
    Title = "玩家透视",
    Value = false,
    Callback = function(state)
        Config.PlayerESP = state
        if not state then
            for _, v in ipairs(Players:GetPlayers()) do
                if v.Character then removeESP(v.Character) end
            end
        end
    end
})

Tab:Toggle({
    Title = "感染者透视",
    Value = false,
    Callback = function(state)
        Config.InfectedESP = state
        if not state then
            if Entities then
                for _, v in ipairs(Entities:GetChildren()) do
                    removeESP(v)
                end
            end
        end
    end
})

local cachedSilentTarget = nil
RunService.RenderStepped:Connect(function()
    SilentFOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if Config.SilentAim then
        cachedSilentTarget = getTarget(Config.SilentAimFOV)
    else
        cachedSilentTarget = nil
    end
    if Config.PlayerESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                createESP(p.Character, Color3.fromRGB(0, 255, 0))
            end
        end
    end
    if Config.InfectedESP and Entities then
        for _, e in ipairs(Entities:GetChildren()) do
            local hum = e:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                createESP(e, Color3.fromRGB(255, 0, 0))
            else
                removeESP(e)
            end
        end
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if Config.SilentAim and not checkcaller() and self == Workspace and (method == "Raycast" or method == "FindPartOnRay") then
        if cachedSilentTarget then
            local origin
            if method == "Raycast" then
                origin = args[1]
                return {
                    Instance = cachedSilentTarget,
                    Position = cachedSilentTarget.Position,
                    Normal = (origin - cachedSilentTarget.Position).Unit,
                    Material = Enum.Material.Plastic
                }
            else
                local ray = args[1]
                if typeof(ray) == "Ray" then
                    origin = ray.Origin
                    return cachedSilentTarget, cachedSilentTarget.Position, (origin - cachedSilentTarget.Position).Unit, Enum.Material.Plastic
                end
            end
        end
    end
    return oldNamecall(self, unpack(args))
end)

local itemsPath = Workspace:FindFirstChild("Ignore") and Workspace.Ignore:FindFirstChild("Items")
local highlightTag = "ItemESP_Highlight"
local billboardTag = "ItemESP_Billboard"
local itemActive = false
local itemConnections = {}

local nameMap = {
    ["Ammo"] = "弹药",
    ["Barbed Wire"] = "铁丝网",
    ["Body Armor"] = "防弹衣",
    ["Clap Bomb"] = "拍手炸弹",
    ["Energy Drink"] = "能量饮料",
    ["Gas Mask"] = "防毒面具",
    ["Jack"] = "千斤顶",
    ["Molotov"] = "燃烧瓶",
    ["Nerve Gas"] = "神经毒气",
    ["Bandages"] = "绷带",
    ["bandages"] = "绷带"
}

local function applyItemESP(obj)
    if not obj or obj:FindFirstChild(highlightTag) then return end
    
    local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = highlightTag
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(170, 0, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = obj
    highlight.Parent = obj

    local billboard = Instance.new("BillboardGui")
    billboard.Name = billboardTag
    billboard.Size = UDim2.new(0, 80, 0, 20)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.ExtentsOffset = Vector3.new(0, 1, 0)
    billboard.Adornee = targetPart
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = nameMap[obj.Name] or obj.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextSize = 10
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard
    
    billboard.Parent = obj
end

local function removeItemESP(obj)
    local h = obj:FindFirstChild(highlightTag)
    local b = obj:FindFirstChild(billboardTag)
    if h then h:Destroy() end
    if b then b:Destroy() end
end

Tab:Toggle({
    Title = "物品透视",
    Value = false,
    Callback = function(state)
        itemActive = state
        if not itemsPath then return end
        
        if itemActive then
            for _, item in ipairs(itemsPath:GetChildren()) do
                applyItemESP(item)
            end
            itemConnections.ChildAdded = itemsPath.ChildAdded:Connect(function(child)
                task.defer(function()
                    if itemActive then applyItemESP(child) end
                end)
            end)
        else
            if itemConnections.ChildAdded then
                itemConnections.ChildAdded:Disconnect()
                itemConnections.ChildAdded = nil
            end
            for _, item in ipairs(itemsPath:GetChildren()) do
                removeItemESP(item)
            end
        end
    end
})
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("RF")

local pickupOn = false
local itemsPath = Workspace:WaitForChild("Ignore"):WaitForChild("Items")

Tab:Toggle({
    Title = "物品拾取光环",
    Value = false,
    Callback = function(state)
        pickupOn = state
        if pickupOn then
            task.spawn(function()
                while pickupOn do
                    task.wait(0.1)
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, item in ipairs(itemsPath:GetChildren()) do
                            local targetPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                            if targetPart then
                                local mag = (hrp.Position - targetPart.Position).Magnitude
                                if mag <= 20 then
                                    local args = {
                                        "CheckInteract",
                                        {
                                            Target = {
                                                Mag = mag,
                                                Type = "Item",
                                                CanInteract = true,
                                                Obj = item
                                            }
                                        }
                                    }
                                    Remote:InvokeServer(unpack(args))
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})
