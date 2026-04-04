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
local LocalPlayer = Players.LocalPlayer

local tpOn = false
local tpSpd = 5

Tab:Toggle({
    Title = "速度",
    Value = false,
    Callback = function(state)
        tpOn = state
        if state then
            spawn(function()
                while tpOn do
                    local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = chr:FindFirstChild("HumanoidRootPart")
                    local hum = chr:FindFirstChildWhichIsA("Humanoid")
                    local delta = RunService.Heartbeat:Wait()
                    if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * tpSpd * delta)
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
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Entities = Workspace:WaitForChild("Entities"):WaitForChild("Infected")

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
SilentFOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function getTarget(fov)
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
    if highlight then
        highlight:Destroy()
    end
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
            for _, v in ipairs(Entities:GetChildren()) do
                removeESP(v)
            end
        end
    end
})

local cachedSilentTarget = nil

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    SilentFOV.Position = center

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

    if Config.InfectedESP then
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
            else
                local ray = args[1]
                if typeof(ray) == "Ray" then origin = ray.Origin end
            end
            
            if origin then
                if method == "Raycast" then
                    return {
                        Instance = cachedSilentTarget,
                        Position = cachedSilentTarget.Position,
                        Normal = (origin - cachedSilentTarget.Position).Unit,
                        Material = Enum.Material.Plastic
                    }
                else
                    return cachedSilentTarget, cachedSilentTarget.Position, (origin - cachedSilentTarget.Position).Unit, Enum.Material.Plastic
                end
            end
        end
    end
    return oldNamecall(self, unpack(args))
end)
local itemsPath = workspace:WaitForChild("Ignore"):WaitForChild("Items")
local highlightTag = "ItemESP_Highlight"
local billboardTag = "ItemESP_Billboard"
local active = false
local connections = {}

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

local function getChineseName(obj)
    local originalName = obj.Name
    return nameMap[originalName] or originalName
end

local function removeESP(obj)
    local highlight = obj:FindFirstChild(highlightTag)
    if highlight then highlight:Destroy() end
    
    local billboard = obj:FindFirstChild(billboardTag)
    if billboard then billboard:Destroy() end
end

local function applyESP(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = highlightTag
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(170, 0, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = obj
    highlight.Parent = obj

    local billboard = Instance.new("BillboardGui")
    billboard.Name = billboardTag
    billboard.Size = UDim2.new(0, 60, 0, 20)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.ExtentsOffset = Vector3.new(0, 1, 0)
    billboard.Adornee = obj
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = getChineseName(obj)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextSize = 8
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard
    
    billboard.Parent = obj
end

local function updateESP()
    for _, item in ipairs(itemsPath:GetChildren()) do
        if active then
            if not item:FindFirstChild(highlightTag) then
                applyESP(item)
            end
        else
            removeESP(item)
        end
    end
end

Tab:Toggle({
    Title = "物品透视",
    Value = false,
    Callback = function(state)
        active = state
        
        if active then
            updateESP()
            connections.ChildAdded = itemsPath.ChildAdded:Connect(function(child)
                task.wait(0.1)
                if active then applyESP(child) end
            end)
        else
            if connections.ChildAdded then
                connections.ChildAdded:Disconnect()
                connections.ChildAdded = nil
            end
            for _, item in ipairs(itemsPath:GetChildren()) do
                removeESP(item)
            end
        end
    end
})
