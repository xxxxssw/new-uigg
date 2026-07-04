--[[
    UniversalESPLib
    A standalone, modular Roblox Lua ESP library.

    Load with:
    local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPO/main/Library.lua"))()
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function getgenvCompat()
    if getgenv then
        return getgenv()
    end
    return _G
end

local Env = getgenvCompat()

local ESP = {
    Version = "1.0.0",
    Name = "UniversalESPLib",
    Enabled = false,
    Started = false,
    Targets = {},
    TargetList = {},
    TargetByInstance = {},
    TargetCounter = 0,
    Features = {},
    FeatureOrder = {},
    Providers = {},
    ProviderOrder = {},
    Connections = {},
    TagTrackers = {},
    FolderTrackers = {},
    Drawings = {},
    GuiObjects = {},
    RenderMode = "Auto",
    ScreenGui = nil,
    Unloaded = false,
    CurrentRainbowHue = 0,
    Settings = {
        Enabled = true,
        RenderMode = "Auto",
        RefreshInterval = 0,
        ShowLocalPlayer = false,
        TeamCheck = false,
        UseTeamColor = true,
        MaxDistance = 5000,
        MinBoxSize = 4,
        MaxBoxSize = 900,
        TextSize = 13,
        TextFont = 2,
        TextOutline = true,
        ScaleWithDistance = false,
        FadeDistance = true,
        Transparency = 1,
        EnemyColor = Color3.fromRGB(255, 90, 90),
        FriendlyColor = Color3.fromRGB(90, 190, 255),
        NeutralColor = Color3.fromRGB(255, 255, 255),
        TargetColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Box = true,
        BoxStyle = "Corner",
        BoxThickness = 1,
        Box3D = false,
        Name = true,
        DisplayName = true,
        HealthBar = true,
        HealthText = false,
        Distance = true,
        DistanceUnit = "m",
        Tool = true,
        Tracer = false,
        TracerOrigin = "Bottom",
        Skeleton = false,
        SkeletonThickness = 1,
        Chams = false,
        ChamsOutline = true,
        ChamsFillTransparency = 0.72,
        ChamsOutlineTransparency = 0,
        OffscreenArrows = true,
        ArrowRadius = 280,
        ArrowSize = 16,
        HeadDot = false,
        HeadDotRadius = 3,
        LookLine = false,
        LookLineLength = 8,
        Rainbow = false
    }
}

Env.UniversalESPLib = ESP

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(ESP.Connections, connection)
    return connection
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return nil
    end
    local ok, result = pcall(callback, ...)
    if ok then
        return result
    end
    warn("[UniversalESPLib] " .. tostring(result))
    return nil
end

local function isInstance(value)
    return typeof(value) == "Instance"
end

local function isBasePart(value)
    return isInstance(value) and value:IsA("BasePart")
end

local function isModel(value)
    return isInstance(value) and value:IsA("Model")
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    return math.atan(y, x)
end

local function colorToTable(color)
    if typeof(color) ~= "Color3" then
        return color
    end
    return {
        R = math.floor(color.R * 255),
        G = math.floor(color.G * 255),
        B = math.floor(color.B * 255)
    }
end

local function tableToColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) ~= "table" then
        return fallback
    end
    local r = value.R or value.r or value[1]
    local g = value.G or value.g or value[2]
    local b = value.B or value.b or value[3]
    if not r or not g or not b then
        return fallback
    end
    if r <= 1 and g <= 1 and b <= 1 then
        return Color3.new(r, g, b)
    end
    return Color3.fromRGB(r, g, b)
end

local function isPointInViewport(point, viewport)
    return point.X >= 0 and point.X <= viewport.X and point.Y >= 0 and point.Y <= viewport.Y
end

local function vector2FromViewport(vector)
    return Vector2.new(vector.X, vector.Y)
end

local function pointInGui(guiObject, point)
    if not guiObject or not guiObject.Parent or not guiObject.Visible then
        return false
    end
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function getGuiParent()
    if gethui then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end
    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            return playerGui
        end
        local ok, waitedGui = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui", 2)
        end)
        if ok and waitedGui then
            return waitedGui
        end
    end
    return CoreGui
end

local function protectGui(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

function ESP:GetScreenGui()
    if self.ScreenGui and self.ScreenGui.Parent then
        return self.ScreenGui
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "UniversalESPLib"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999998
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protectGui(gui)
    gui.Parent = getGuiParent()
    self.ScreenGui = gui
    return gui
end

function ESP:GetCamera()
    return workspace.CurrentCamera
end

function ESP:CanUseDrawing(kind)
    if self.RenderMode == "Gui" or self.Settings.RenderMode == "Gui" then
        return false
    end
    if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
        return false
    end
    if kind == "Triangle" or kind == "Circle" or kind == "Line" or kind == "Square" or kind == "Text" then
        return true
    end
    return false
end

function ESP:CreateGuiVisual(kind)
    local gui = self:GetScreenGui()
    local object
    local extra = {}

    if kind == "Text" then
        object = Instance.new("TextLabel")
        object.BackgroundTransparency = 1
        object.BorderSizePixel = 0
        object.Font = Enum.Font.Code
        object.TextSize = self.Settings.TextSize
        object.TextStrokeTransparency = 0
        object.TextXAlignment = Enum.TextXAlignment.Left
        object.TextYAlignment = Enum.TextYAlignment.Center
        object.Size = UDim2.fromOffset(260, 18)
    elseif kind == "Line" then
        object = Instance.new("Frame")
        object.BorderSizePixel = 0
        object.AnchorPoint = Vector2.new(0.5, 0.5)
        object.Size = UDim2.fromOffset(1, 1)
    elseif kind == "Square" then
        object = Instance.new("Frame")
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
        object.Size = UDim2.fromOffset(10, 10)
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.LineJoinMode = Enum.LineJoinMode.Miter
        stroke.Thickness = 1
        stroke.Parent = object
        extra.Stroke = stroke
    elseif kind == "Circle" then
        object = Instance.new("Frame")
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
        object.Size = UDim2.fromOffset(8, 8)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = object
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 1
        stroke.Parent = object
        extra.Stroke = stroke
    elseif kind == "Triangle" then
        object = Instance.new("TextLabel")
        object.BackgroundTransparency = 1
        object.BorderSizePixel = 0
        object.Font = Enum.Font.Code
        object.Text = ">"
        object.TextSize = 22
        object.TextStrokeTransparency = 0
        object.TextXAlignment = Enum.TextXAlignment.Center
        object.TextYAlignment = Enum.TextYAlignment.Center
        object.Size = UDim2.fromOffset(28, 28)
    else
        object = Instance.new("Frame")
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
    end

    object.Name = kind
    object.Visible = false
    object.Parent = gui
    table.insert(self.GuiObjects, object)
    return {
        Kind = kind,
        Mode = "Gui",
        Object = object,
        Extra = extra
    }
end

function ESP:CreateVisual(kind)
    if self:CanUseDrawing(kind) then
        local ok, drawing = pcall(function()
            return Drawing.new(kind)
        end)
        if ok and drawing then
            drawing.Visible = false
            table.insert(self.Drawings, drawing)
            return {
                Kind = kind,
                Mode = "Drawing",
                Object = drawing
            }
        end
    end
    return self:CreateGuiVisual(kind)
end

function ESP:SetVisual(visual, properties)
    if not visual or not visual.Object then
        return
    end

    local object = visual.Object
    local alpha = properties.Transparency or properties.Alpha or self.Settings.Transparency or 1
    local color = properties.Color or self.Settings.TargetColor
    local outlineColor = properties.OutlineColor or self.Settings.OutlineColor

    if visual.Mode == "Drawing" then
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
        if properties.Alpha ~= nil then
            pcall(function()
                object.Transparency = properties.Alpha
            end)
        end
        return
    end

    if properties.Visible ~= nil then
        object.Visible = properties.Visible
    end

    if visual.Kind == "Text" then
        object.Text = tostring(properties.Text or object.Text or "")
        object.TextSize = properties.Size or properties.TextSize or self.Settings.TextSize
        object.TextColor3 = color
        object.TextStrokeColor3 = outlineColor
        object.TextStrokeTransparency = self.Settings.TextOutline and (1 - alpha) or 1
        object.TextTransparency = 1 - alpha
        local center = properties.Center == true
        object.TextXAlignment = center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        local width = properties.Width or 260
        local height = properties.Height or math.max(16, object.TextSize + 4)
        object.Size = UDim2.fromOffset(width, height)
        if properties.Position then
            local x = center and properties.Position.X - (width / 2) or properties.Position.X
            object.Position = UDim2.fromOffset(x, properties.Position.Y)
        end
    elseif visual.Kind == "Line" then
        local from = properties.From
        local to = properties.To
        if from and to then
            local delta = to - from
            local length = delta.Magnitude
            object.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
            object.Size = UDim2.fromOffset(math.max(1, length), properties.Thickness or 1)
            object.Rotation = math.deg(atan2(delta.Y, delta.X))
        end
        object.BackgroundColor3 = color
        object.BackgroundTransparency = 1 - alpha
    elseif visual.Kind == "Square" then
        if properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)
        end
        if properties.Size then
            object.Size = UDim2.fromOffset(properties.Size.X, properties.Size.Y)
        end
        local filled = properties.Filled == true
        object.BackgroundColor3 = properties.FilledColor or color
        object.BackgroundTransparency = filled and (1 - alpha) or 1
        if visual.Extra and visual.Extra.Stroke then
            visual.Extra.Stroke.Color = color
            visual.Extra.Stroke.Thickness = properties.Thickness or 1
            visual.Extra.Stroke.Transparency = 1 - alpha
            visual.Extra.Stroke.Enabled = properties.Stroke ~= false
        end
    elseif visual.Kind == "Circle" then
        local radius = properties.Radius or 4
        if properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X - radius, properties.Position.Y - radius)
        end
        object.Size = UDim2.fromOffset(radius * 2, radius * 2)
        object.BackgroundColor3 = color
        object.BackgroundTransparency = properties.Filled and (1 - alpha) or 1
        if visual.Extra and visual.Extra.Stroke then
            visual.Extra.Stroke.Color = color
            visual.Extra.Stroke.Thickness = properties.Thickness or 1
            visual.Extra.Stroke.Transparency = 1 - alpha
        end
    elseif visual.Kind == "Triangle" then
        local a = properties.PointA
        local b = properties.PointB
        local c = properties.PointC
        if a and b and c then
            local center = Vector2.new((a.X + b.X + c.X) / 3, (a.Y + b.Y + c.Y) / 3)
            local base = Vector2.new((b.X + c.X) / 2, (b.Y + c.Y) / 2)
            local direction = a - base
            object.Position = UDim2.fromOffset(center.X - 14, center.Y - 14)
            object.Rotation = math.deg(atan2(direction.Y, direction.X))
        elseif properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X - 14, properties.Position.Y - 14)
        end
        object.TextColor3 = color
        object.TextStrokeColor3 = outlineColor
        object.TextTransparency = 1 - alpha
        object.TextStrokeTransparency = self.Settings.TextOutline and (1 - alpha) or 1
        object.TextSize = properties.Size or 22
    end
end

function ESP:HideVisual(visual)
    if visual and visual.Object then
        pcall(function()
            visual.Object.Visible = false
        end)
    end
end

function ESP:RemoveVisual(visual)
    if not visual or not visual.Object then
        return
    end
    if visual.Mode == "Drawing" then
        pcall(function()
            visual.Object:Remove()
        end)
    else
        pcall(function()
            visual.Object:Destroy()
        end)
    end
    visual.Object = nil
end

function ESP:HideVisuals(value)
    if type(value) ~= "table" then
        return
    end
    if value.Highlight then
        pcall(function()
            value.Highlight.Enabled = false
        end)
    end
    if value.Object and value.Kind then
        self:HideVisual(value)
        return
    end
    for _, child in pairs(value) do
        if type(child) == "table" then
            self:HideVisuals(child)
        end
    end
end

function ESP:DestroyVisuals(value)
    if type(value) ~= "table" then
        return
    end
    if value.Highlight then
        pcall(function()
            value.Highlight:Destroy()
        end)
        value.Highlight = nil
    end
    if value.Object and value.Kind then
        self:RemoveVisual(value)
        return
    end
    for _, child in pairs(value) do
        if type(child) == "table" then
            self:DestroyVisuals(child)
        end
    end
end

function ESP:SetSetting(key, value)
    if self.Settings[key] ~= nil then
        self.Settings[key] = value
    else
        self.Settings[key] = value
    end
    if key == "Enabled" then
        self.Enabled = value == true
    end
    return self
end

function ESP:SetSettings(settings)
    for key, value in pairs(settings or {}) do
        if typeof(self.Settings[key]) == "Color3" then
            self.Settings[key] = tableToColor(value, self.Settings[key])
        else
            self.Settings[key] = value
        end
    end
    if settings and settings.Enabled ~= nil then
        self.Enabled = settings.Enabled == true
    end
    return self
end

function ESP:GetSetting(target, key)
    if target and target.Options and target.Options[key] ~= nil then
        return target.Options[key]
    end
    return self.Settings[key]
end

function ESP:GetSettings()
    local data = {}
    for key, value in pairs(self.Settings) do
        data[key] = colorToTable(value)
    end
    return data
end

function ESP:JSONEncode(value)
    return HttpService:JSONEncode(value)
end

function ESP:JSONDecode(value)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(value)
    end)
    if ok then
        return decoded
    end
    return nil
end

function ESP:GetTargetName(target, info)
    if target.Options and target.Options.Name then
        return tostring(target.Options.Name)
    end
    if target.Options and type(target.Options.GetName) == "function" then
        local name = safeCallback(target.Options.GetName, target, info)
        if name then
            return tostring(name)
        end
    end
    if target.Player then
        if self:GetSetting(target, "DisplayName") and target.Player.DisplayName and target.Player.DisplayName ~= target.Player.Name then
            return target.Player.DisplayName .. " (@" .. target.Player.Name .. ")"
        end
        return target.Player.Name
    end
    if target.Instance and target.Instance.Name then
        return target.Instance.Name
    end
    return tostring(target.Key)
end

function ESP:GetTargetColor(target)
    if target.Options and target.Options.Color then
        return tableToColor(target.Options.Color, self.Settings.TargetColor)
    end
    if target.Options and type(target.Options.GetColor) == "function" then
        local color = safeCallback(target.Options.GetColor, target)
        if typeof(color) == "Color3" then
            return color
        end
    end
    if target.Player and self.Settings.UseTeamColor and target.Player.TeamColor then
        return target.Player.TeamColor.Color
    end
    if target.Player and LocalPlayer and target.Player.Team ~= nil and LocalPlayer.Team ~= nil then
        if target.Player.Team == LocalPlayer.Team then
            return self.Settings.FriendlyColor
        end
        return self.Settings.EnemyColor
    end
    return self.Settings.NeutralColor
end

function ESP:GetTargetRoot(instance)
    if not instance then
        return nil
    end
    if isBasePart(instance) then
        return instance
    end
    if isModel(instance) then
        return instance:FindFirstChild("HumanoidRootPart")
            or instance.PrimaryPart
            or instance:FindFirstChild("UpperTorso")
            or instance:FindFirstChild("Torso")
            or instance:FindFirstChild("Head")
            or instance:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

function ESP:GetToolName(model)
    if not model then
        return nil
    end
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return nil
end

function ESP:ResolveTarget(target)
    local instance = target.Instance
    local player = target.Player
    local model = nil
    local root = nil
    local humanoid = nil
    local head = nil

    if player then
        instance = player.Character
    end

    if target.Options and type(target.Options.GetAdornee) == "function" then
        local custom = safeCallback(target.Options.GetAdornee, target)
        if custom then
            instance = custom
        end
    end

    if not instance or not instance.Parent then
        return { Exists = false }
    end

    if isModel(instance) then
        model = instance
        humanoid = model:FindFirstChildOfClass("Humanoid")
        root = self:GetTargetRoot(model)
        head = model:FindFirstChild("Head")
    elseif isBasePart(instance) then
        root = instance
        model = instance:FindFirstAncestorOfClass("Model")
        if model then
            humanoid = model:FindFirstChildOfClass("Humanoid")
            head = model:FindFirstChild("Head")
        end
    else
        root = self:GetTargetRoot(instance)
        model = root and root:FindFirstAncestorOfClass("Model") or nil
        if model then
            humanoid = model:FindFirstChildOfClass("Humanoid")
            head = model:FindFirstChild("Head")
        end
    end

    if not root or not root.Parent then
        return { Exists = false }
    end

    local health = nil
    local maxHealth = nil
    if humanoid then
        health = humanoid.Health
        maxHealth = humanoid.MaxHealth
    end
    if target.Options and type(target.Options.GetHealth) == "function" then
        local customHealth, customMax = safeCallback(target.Options.GetHealth, target)
        if customHealth then
            health = customHealth
            maxHealth = customMax or maxHealth or 100
        end
    end

    return {
        Exists = true,
        Instance = instance,
        Player = player,
        Model = model,
        Root = root,
        Head = head,
        Humanoid = humanoid,
        Health = health,
        MaxHealth = maxHealth,
        Tool = self:GetToolName(model)
    }
end

function ESP:GetBoundingData(info)
    local cf
    local size
    if info.Model then
        local ok, boxCf, boxSize = pcall(function()
            return info.Model:GetBoundingBox()
        end)
        if ok and boxCf and boxSize then
            cf = boxCf
            size = boxSize
        end
    end
    if not cf and info.Root then
        cf = info.Root.CFrame
        size = info.Root.Size
    end
    if not cf then
        return nil
    end
    return cf, size or Vector3.new(2, 5, 2)
end

function ESP:GetScreenBounds(camera, info, distance)
    local cf, size = self:GetBoundingData(info)
    if not cf then
        return nil
    end

    local half = size / 2
    local offsets = {
        Vector3.new(-half.X, -half.Y, -half.Z),
        Vector3.new(-half.X, -half.Y, half.Z),
        Vector3.new(-half.X, half.Y, -half.Z),
        Vector3.new(-half.X, half.Y, half.Z),
        Vector3.new(half.X, -half.Y, -half.Z),
        Vector3.new(half.X, -half.Y, half.Z),
        Vector3.new(half.X, half.Y, -half.Z),
        Vector3.new(half.X, half.Y, half.Z)
    }

    local viewport = camera.ViewportSize
    local points = {}
    local corners = {}
    local anyOnScreen = false

    for index, offset in ipairs(offsets) do
        local world = cf:PointToWorldSpace(offset)
        local screen, visible = camera:WorldToViewportPoint(world)
        if screen.Z > 0 then
            local point = Vector2.new(screen.X, screen.Y)
            table.insert(points, point)
            corners[index] = point
            if visible or isPointInViewport(point, viewport) then
                anyOnScreen = true
            end
        end
    end

    local rootScreen = camera:WorldToViewportPoint(info.Root.Position)
    local rootPoint = Vector2.new(rootScreen.X, rootScreen.Y)

    if #points < 2 then
        if rootScreen.Z <= 0 then
            return {
                Root = rootPoint,
                RootDepth = rootScreen.Z,
                OnScreen = false,
                Corners = corners,
                Position = rootPoint,
                Size = Vector2.new(0, 0),
                Center = rootPoint,
                Top = rootPoint,
                Bottom = rootPoint
            }
        end
        local height = clamp((size.Y * 1200) / math.max(distance, 1), self.Settings.MinBoxSize, self.Settings.MaxBoxSize)
        local width = clamp(height * math.max(0.35, size.X / math.max(size.Y, 0.01)), self.Settings.MinBoxSize, self.Settings.MaxBoxSize)
        local pos = Vector2.new(rootPoint.X - width / 2, rootPoint.Y - height / 2)
        return {
            Root = rootPoint,
            RootDepth = rootScreen.Z,
            OnScreen = isPointInViewport(rootPoint, viewport),
            Corners = corners,
            Position = pos,
            Size = Vector2.new(width, height),
            Center = rootPoint,
            Top = Vector2.new(rootPoint.X, pos.Y),
            Bottom = Vector2.new(rootPoint.X, pos.Y + height)
        }
    end

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge

    for _, point in ipairs(points) do
        minX = math.min(minX, point.X)
        minY = math.min(minY, point.Y)
        maxX = math.max(maxX, point.X)
        maxY = math.max(maxY, point.Y)
    end

    local width = clamp(maxX - minX, self.Settings.MinBoxSize, self.Settings.MaxBoxSize)
    local height = clamp(maxY - minY, self.Settings.MinBoxSize, self.Settings.MaxBoxSize)
    local position = Vector2.new(minX, minY)
    local center = Vector2.new(minX + width / 2, minY + height / 2)

    return {
        Root = rootPoint,
        RootDepth = rootScreen.Z,
        OnScreen = rootScreen.Z > 0 and anyOnScreen,
        Corners = corners,
        Position = position,
        Size = Vector2.new(width, height),
        Center = center,
        Top = Vector2.new(center.X, minY),
        Bottom = Vector2.new(center.X, minY + height)
    }
end

function ESP:BuildContext(target, info)
    local camera = self:GetCamera()
    if not camera or not info.Exists or not info.Root then
        return {
            Exists = false,
            Visible = false,
            OnScreen = false,
            Draw = false
        }
    end

    local cameraPos = camera.CFrame.Position
    local distance = (cameraPos - info.Root.Position).Magnitude
    local maxDistance = self:GetSetting(target, "MaxDistance") or math.huge
    local visible = distance <= maxDistance
    local localTeam = LocalPlayer and LocalPlayer.Team or nil

    if target.Player == LocalPlayer and not self:GetSetting(target, "ShowLocalPlayer") then
        visible = false
    end

    if self:GetSetting(target, "TeamCheck") and target.Player and localTeam and target.Player.Team == localTeam then
        visible = false
    end

    if target.Options and type(target.Options.Filter) == "function" then
        local allowed = safeCallback(target.Options.Filter, target, info)
        if allowed == false then
            visible = false
        end
    end

    local bounds = self:GetScreenBounds(camera, info, distance)
    if not bounds then
        visible = false
    end

    local alpha = self:GetSetting(target, "Transparency") or 1
    if self:GetSetting(target, "FadeDistance") and maxDistance and maxDistance > 0 then
        alpha = alpha * clamp(1 - (distance / maxDistance), 0.18, 1)
    end

    return {
        Exists = true,
        Visible = visible,
        OnScreen = bounds and bounds.OnScreen == true or false,
        Draw = visible and bounds and bounds.OnScreen == true or false,
        Camera = camera,
        Distance = distance,
        Bounds = bounds,
        Color = self:GetTargetColor(target),
        Alpha = alpha,
        Info = info,
        TopOffset = 0,
        BottomOffset = 0
    }
end

function ESP:RegisterFeature(name, feature)
    feature.Name = name
    feature.Order = feature.Order or (#self.FeatureOrder + 1)
    self.Features[name] = feature
    table.insert(self.FeatureOrder, name)
    table.sort(self.FeatureOrder, function(a, b)
        local left = self.Features[a]
        local right = self.Features[b]
        return (left.Order or 0) < (right.Order or 0)
    end)
    return feature
end

function ESP:SetFeatureEnabled(name, enabled)
    if self.Settings[name] ~= nil then
        self.Settings[name] = enabled == true
    end
    return self
end

function ESP:RegisterProvider(name, provider)
    provider.Name = name
    provider.ESP = self
    self.Providers[name] = provider
    table.insert(self.ProviderOrder, name)
    return provider
end

function ESP:StartProvider(name, options)
    local provider = self.Providers[name]
    if provider and provider.Start then
        provider:Start(options or {})
    end
    return provider
end

function ESP:StopProvider(name)
    local provider = self.Providers[name]
    if provider and provider.Stop then
        provider:Stop()
    end
    return provider
end

function ESP:GetTargetKey(instance, options)
    if options and options.Key then
        return tostring(options.Key)
    end
    if isInstance(instance) and self.TargetByInstance[instance] then
        return self.TargetByInstance[instance].Key
    end
    self.TargetCounter = self.TargetCounter + 1
    if isInstance(instance) then
        return instance.ClassName .. "_" .. instance.Name .. "_" .. tostring(self.TargetCounter)
    end
    return "Target_" .. tostring(self.TargetCounter)
end

function ESP:Track(instance, options)
    options = options or {}
    if typeof(instance) == "Instance" and instance:IsA("Player") then
        return self:TrackPlayer(instance, options)
    end
    if not instance then
        return nil
    end
    if isInstance(instance) and self.TargetByInstance[instance] then
        local existing = self.TargetByInstance[instance]
        for key, value in pairs(options) do
            existing.Options[key] = value
        end
        return existing
    end

    local key = self:GetTargetKey(instance, options)
    local target = {
        Key = key,
        Type = options.Type or "Object",
        Instance = instance,
        Player = options.Player,
        Options = options,
        FeatureState = {},
        Created = os.clock()
    }

    self.Targets[key] = target
    table.insert(self.TargetList, target)
    if isInstance(instance) then
        self.TargetByInstance[instance] = target
        target.AncestryConnection = connect(instance.AncestryChanged, function(_, parent)
            if not parent then
                self:Untrack(target)
            end
        end)
    end
    return target
end

function ESP:TrackPlayer(player, options)
    local targetOptions = {}
    for key, value in pairs(options or {}) do
        targetOptions[key] = value
    end
    targetOptions.Player = player
    targetOptions.Type = targetOptions.Type or "Player"
    local key = targetOptions.Key or ("Player_" .. tostring(player.UserId))
    if self.Targets[key] then
        return self.Targets[key]
    end
    local target = {
        Key = key,
        Type = "Player",
        Player = player,
        Instance = player.Character,
        Options = targetOptions,
        FeatureState = {},
        Created = os.clock()
    }
    self.Targets[target.Key] = target
    table.insert(self.TargetList, target)
    target.CharacterConnection = connect(player.CharacterAdded, function(character)
        target.Instance = character
    end)
    return target
end

function ESP:Untrack(targetOrKey)
    local target = targetOrKey
    if type(targetOrKey) == "string" then
        target = self.Targets[targetOrKey]
    elseif isInstance(targetOrKey) then
        target = self.TargetByInstance[targetOrKey]
    end
    if not target then
        return false
    end

    for featureName, state in pairs(target.FeatureState) do
        local feature = self.Features[featureName]
        if feature and feature.Destroy then
            safeCallback(feature.Destroy, feature, target, state, self)
        else
            self:DestroyVisuals(state)
        end
    end

    if target.AncestryConnection then
        pcall(function()
            target.AncestryConnection:Disconnect()
        end)
    end
    if target.CharacterConnection then
        pcall(function()
            target.CharacterConnection:Disconnect()
        end)
    end

    self.Targets[target.Key] = nil
    if isInstance(target.Instance) then
        self.TargetByInstance[target.Instance] = nil
    end
    for index = #self.TargetList, 1, -1 do
        if self.TargetList[index] == target then
            table.remove(self.TargetList, index)
        end
    end
    return true
end

function ESP:ClearTargets()
    for index = #self.TargetList, 1, -1 do
        self:Untrack(self.TargetList[index])
    end
end

function ESP:TrackTag(tag, options)
    options = options or {}
    local tracker = {
        Tag = tag,
        Options = options,
        Targets = {},
        Connections = {}
    }
    local function add(instance)
        local merged = {}
        for key, value in pairs(options) do
            if key ~= "Key" then
                merged[key] = value
            end
        end
        merged.Type = merged.Type or tag
        tracker.Targets[instance] = self:Track(instance, merged)
    end
    local function remove(instance)
        local target = tracker.Targets[instance]
        if target then
            self:Untrack(target)
            tracker.Targets[instance] = nil
        end
    end
    for _, instance in ipairs(CollectionService:GetTagged(tag)) do
        add(instance)
    end
    table.insert(tracker.Connections, connect(CollectionService:GetInstanceAddedSignal(tag), add))
    table.insert(tracker.Connections, connect(CollectionService:GetInstanceRemovedSignal(tag), remove))
    self.TagTrackers[tag] = tracker
    return tracker
end

function ESP:UntrackTag(tag)
    local tracker = self.TagTrackers[tag]
    if not tracker then
        return false
    end
    for _, connection in ipairs(tracker.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    for _, target in pairs(tracker.Targets) do
        self:Untrack(target)
    end
    self.TagTrackers[tag] = nil
    return true
end

function ESP:TrackFolder(folder, options)
    options = options or {}
    local tracker = {
        Folder = folder,
        Options = options,
        Targets = {},
        Connections = {}
    }
    local function shouldTrack(instance)
        local filter = options.TrackFilter or options.Filter
        if type(filter) == "function" then
            return safeCallback(filter, instance) ~= false
        end
        return isBasePart(instance) or isModel(instance)
    end
    local function add(instance)
        if shouldTrack(instance) then
            local merged = {}
            for key, value in pairs(options) do
                if key ~= "Key" and key ~= "TrackFilter" and key ~= "Filter" and key ~= "TargetFilter" then
                    merged[key] = value
                end
            end
            if options.TargetFilter then
                merged.Filter = options.TargetFilter
            end
            tracker.Targets[instance] = self:Track(instance, merged)
        end
    end
    local function remove(instance)
        local target = tracker.Targets[instance]
        if target then
            self:Untrack(target)
            tracker.Targets[instance] = nil
        end
    end
    for _, child in ipairs(folder:GetDescendants()) do
        add(child)
    end
    table.insert(tracker.Connections, connect(folder.DescendantAdded, add))
    table.insert(tracker.Connections, connect(folder.DescendantRemoving, remove))
    table.insert(self.FolderTrackers, tracker)
    return tracker
end

function ESP:GetLineOrigin()
    local camera = self:GetCamera()
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local origin = self.Settings.TracerOrigin
    if origin == "Top" then
        return Vector2.new(viewport.X / 2, 0)
    elseif origin == "Center" then
        return Vector2.new(viewport.X / 2, viewport.Y / 2)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    end
    return Vector2.new(viewport.X / 2, viewport.Y)
end

function ESP:GetSkeletonSegments(info)
    local model = info.Model
    if not model then
        return {}
    end
    local names = {
        { "Head", "UpperTorso" },
        { "UpperTorso", "LowerTorso" },
        { "UpperTorso", "LeftUpperArm" },
        { "LeftUpperArm", "LeftLowerArm" },
        { "LeftLowerArm", "LeftHand" },
        { "UpperTorso", "RightUpperArm" },
        { "RightUpperArm", "RightLowerArm" },
        { "RightLowerArm", "RightHand" },
        { "LowerTorso", "LeftUpperLeg" },
        { "LeftUpperLeg", "LeftLowerLeg" },
        { "LeftLowerLeg", "LeftFoot" },
        { "LowerTorso", "RightUpperLeg" },
        { "RightUpperLeg", "RightLowerLeg" },
        { "RightLowerLeg", "RightFoot" },
        { "Head", "Torso" },
        { "Torso", "Left Arm" },
        { "Torso", "Right Arm" },
        { "Torso", "Left Leg" },
        { "Torso", "Right Leg" }
    }
    local segments = {}
    for _, pair in ipairs(names) do
        local a = model:FindFirstChild(pair[1])
        local b = model:FindFirstChild(pair[2])
        if isBasePart(a) and isBasePart(b) then
            table.insert(segments, { a, b })
        end
    end
    return segments
end

function ESP:Step(delta)
    if self.Unloaded then
        return
    end
    self.CurrentRainbowHue = (self.CurrentRainbowHue + delta / 8) % 1
    if not self.Enabled or not self.Settings.Enabled then
        for _, target in ipairs(self.TargetList) do
            self:HideVisuals(target.FeatureState)
        end
        return
    end

    self.LastStep = self.LastStep or 0
    local refresh = self.Settings.RefreshInterval or 0
    if refresh > 0 then
        self.LastStep = self.LastStep + delta
        if self.LastStep < refresh then
            return
        end
        self.LastStep = 0
    end

    for _, target in ipairs(self.TargetList) do
        local info = self:ResolveTarget(target)
        local context = self:BuildContext(target, info)
        if self.Settings.Rainbow then
            context.Color = Color3.fromHSV(self.CurrentRainbowHue, 0.9, 1)
        end
        for _, featureName in ipairs(self.FeatureOrder) do
            local feature = self.Features[featureName]
            if feature then
                local state = target.FeatureState[featureName]
                if not state then
                    state = {}
                    target.FeatureState[featureName] = state
                    if feature.Create then
                        safeCallback(feature.Create, feature, target, state, self)
                    end
                end
                if feature.Update then
                    safeCallback(feature.Update, feature, target, state, context, self)
                end
            end
        end
    end
end

function ESP:Start()
    if self.Started then
        self.Enabled = true
        self.Settings.Enabled = true
        return self
    end
    self.Started = true
    self.Enabled = true
    self.Settings.Enabled = true
    self:StartProvider("Players")
    self.RenderConnection = connect(RunService.RenderStepped, function(delta)
        self:Step(delta)
    end)
    return self
end

function ESP:SetEnabled(enabled)
    self.Enabled = enabled == true
    self.Settings.Enabled = self.Enabled
    if self.Enabled and not self.Started then
        self:Start()
    end
    return self
end

function ESP:Enable()
    return self:SetEnabled(true)
end

function ESP:Disable()
    return self:SetEnabled(false)
end

function ESP:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    self.Enabled = false
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    for key in pairs(self.Connections) do
        self.Connections[key] = nil
    end
    self:ClearTargets()
    for _, drawing in ipairs(self.Drawings) do
        pcall(function()
            drawing:Remove()
        end)
    end
    for _, object in ipairs(self.GuiObjects) do
        pcall(function()
            object:Destroy()
        end)
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

local function hideFeature(esp, state)
    esp:HideVisuals(state)
end

ESP:RegisterFeature("Box", {
    Order = 10,
    Create = function(_, _, state, esp)
        state.Full = esp:CreateVisual("Square")
        state.Corners = {}
        for index = 1, 8 do
            state.Corners[index] = esp:CreateVisual("Line")
        end
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Box") or not context.Draw then
            hideFeature(esp, state)
            return
        end
        local bounds = context.Bounds
        local color = context.Color
        local alpha = context.Alpha
        local style = esp:GetSetting(target, "BoxStyle")
        local thickness = esp:GetSetting(target, "BoxThickness") or 1
        if style == "Full" then
            esp:SetVisual(state.Full, {
                Visible = true,
                Position = bounds.Position,
                Size = bounds.Size,
                Color = color,
                Alpha = alpha,
                Thickness = thickness
            })
            for _, line in ipairs(state.Corners) do
                esp:HideVisual(line)
            end
            return
        end

        esp:HideVisual(state.Full)
        local x = bounds.Position.X
        local y = bounds.Position.Y
        local w = bounds.Size.X
        local h = bounds.Size.Y
        local l = math.min(w, h) * 0.26
        local points = {
            { Vector2.new(x, y), Vector2.new(x + l, y) },
            { Vector2.new(x, y), Vector2.new(x, y + l) },
            { Vector2.new(x + w, y), Vector2.new(x + w - l, y) },
            { Vector2.new(x + w, y), Vector2.new(x + w, y + l) },
            { Vector2.new(x, y + h), Vector2.new(x + l, y + h) },
            { Vector2.new(x, y + h), Vector2.new(x, y + h - l) },
            { Vector2.new(x + w, y + h), Vector2.new(x + w - l, y + h) },
            { Vector2.new(x + w, y + h), Vector2.new(x + w, y + h - l) }
        }
        for index, pair in ipairs(points) do
            esp:SetVisual(state.Corners[index], {
                Visible = true,
                From = pair[1],
                To = pair[2],
                Color = color,
                Alpha = alpha,
                Thickness = thickness
            })
        end
    end
})

ESP:RegisterFeature("Box3D", {
    Order = 11,
    Create = function(_, _, state, esp)
        state.Lines = {}
        for index = 1, 12 do
            state.Lines[index] = esp:CreateVisual("Line")
        end
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Box3D") or not context.Visible or not context.Bounds or not context.Bounds.Corners then
            hideFeature(esp, state)
            return
        end
        local corners = context.Bounds.Corners
        local edges = {
            { 1, 2 }, { 1, 3 }, { 1, 5 }, { 8, 7 }, { 8, 6 }, { 8, 4 },
            { 2, 4 }, { 2, 6 }, { 3, 4 }, { 3, 7 }, { 5, 6 }, { 5, 7 }
        }
        for index, edge in ipairs(edges) do
            local a = corners[edge[1]]
            local b = corners[edge[2]]
            if a and b then
                esp:SetVisual(state.Lines[index], {
                    Visible = true,
                    From = a,
                    To = b,
                    Color = context.Color,
                    Alpha = context.Alpha,
                    Thickness = esp:GetSetting(target, "BoxThickness") or 1
                })
            else
                esp:HideVisual(state.Lines[index])
            end
        end
    end
})

ESP:RegisterFeature("Name", {
    Order = 20,
    Create = function(_, _, state, esp)
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Name") or not context.Draw then
            hideFeature(esp, state)
            return
        end
        local text = esp:GetTargetName(target, context.Info)
        local position = Vector2.new(context.Bounds.Top.X, context.Bounds.Position.Y - 17 - context.TopOffset)
        context.TopOffset = context.TopOffset + 15
        esp:SetVisual(state.Text, {
            Visible = true,
            Text = text,
            Position = position,
            Color = context.Color,
            Alpha = context.Alpha,
            Center = true,
            Size = esp:GetSetting(target, "TextSize")
        })
    end
})

ESP:RegisterFeature("HealthBar", {
    Order = 30,
    Create = function(_, _, state, esp)
        state.Back = esp:CreateVisual("Square")
        state.Fill = esp:CreateVisual("Square")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "HealthBar") or not context.Draw or not context.Info.Health or not context.Info.MaxHealth then
            hideFeature(esp, state)
            return
        end
        local bounds = context.Bounds
        local percent = clamp(context.Info.Health / math.max(context.Info.MaxHealth, 1), 0, 1)
        local height = bounds.Size.Y
        local fillHeight = height * percent
        local x = bounds.Position.X - 6
        local y = bounds.Position.Y
        esp:SetVisual(state.Back, {
            Visible = true,
            Position = Vector2.new(x, y),
            Size = Vector2.new(3, height),
            Color = esp.Settings.OutlineColor,
            Filled = true,
            Alpha = context.Alpha
        })
        esp:SetVisual(state.Fill, {
            Visible = true,
            Position = Vector2.new(x, y + height - fillHeight),
            Size = Vector2.new(3, fillHeight),
            Color = Color3.fromRGB(lerp(255, 80, percent), lerp(60, 255, percent), 80),
            Filled = true,
            Alpha = context.Alpha
        })
    end
})

ESP:RegisterFeature("HealthText", {
    Order = 31,
    Create = function(_, _, state, esp)
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "HealthText") or not context.Draw or not context.Info.Health then
            hideFeature(esp, state)
            return
        end
        local health = math.floor(context.Info.Health + 0.5)
        local position = Vector2.new(context.Bounds.Position.X + context.Bounds.Size.X + 4, context.Bounds.Position.Y - 1)
        esp:SetVisual(state.Text, {
            Visible = true,
            Text = tostring(health),
            Position = position,
            Color = context.Color,
            Alpha = context.Alpha,
            Center = false,
            Size = esp:GetSetting(target, "TextSize")
        })
    end
})

ESP:RegisterFeature("Distance", {
    Order = 40,
    Create = function(_, _, state, esp)
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Distance") or not context.Draw then
            hideFeature(esp, state)
            return
        end
        local unit = esp:GetSetting(target, "DistanceUnit") or "m"
        local text = tostring(math.floor(context.Distance + 0.5)) .. unit
        local position = Vector2.new(context.Bounds.Bottom.X, context.Bounds.Position.Y + context.Bounds.Size.Y + 1 + context.BottomOffset)
        context.BottomOffset = context.BottomOffset + 15
        esp:SetVisual(state.Text, {
            Visible = true,
            Text = text,
            Position = position,
            Color = context.Color,
            Alpha = context.Alpha,
            Center = true,
            Size = esp:GetSetting(target, "TextSize")
        })
    end
})

ESP:RegisterFeature("Tool", {
    Order = 41,
    Create = function(_, _, state, esp)
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Tool") or not context.Draw or not context.Info.Tool then
            hideFeature(esp, state)
            return
        end
        local position = Vector2.new(context.Bounds.Bottom.X, context.Bounds.Position.Y + context.Bounds.Size.Y + 1 + context.BottomOffset)
        context.BottomOffset = context.BottomOffset + 15
        esp:SetVisual(state.Text, {
            Visible = true,
            Text = "[" .. context.Info.Tool .. "]",
            Position = position,
            Color = context.Color,
            Alpha = context.Alpha,
            Center = true,
            Size = esp:GetSetting(target, "TextSize")
        })
    end
})

ESP:RegisterFeature("Tracer", {
    Order = 50,
    Create = function(_, _, state, esp)
        state.Line = esp:CreateVisual("Line")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Tracer") or not context.Draw then
            hideFeature(esp, state)
            return
        end
        esp:SetVisual(state.Line, {
            Visible = true,
            From = esp:GetLineOrigin(),
            To = context.Bounds.Bottom,
            Color = context.Color,
            Alpha = context.Alpha,
            Thickness = esp:GetSetting(target, "BoxThickness") or 1
        })
    end
})

ESP:RegisterFeature("Skeleton", {
    Order = 60,
    Create = function(_, _, state, esp)
        state.Lines = {}
        for index = 1, 20 do
            state.Lines[index] = esp:CreateVisual("Line")
        end
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Skeleton") or not context.Visible or not context.Camera then
            hideFeature(esp, state)
            return
        end
        local segments = esp:GetSkeletonSegments(context.Info)
        for index, line in ipairs(state.Lines) do
            local segment = segments[index]
            if segment then
                local a = context.Camera:WorldToViewportPoint(segment[1].Position)
                local b = context.Camera:WorldToViewportPoint(segment[2].Position)
                if a.Z > 0 and b.Z > 0 then
                    esp:SetVisual(line, {
                        Visible = true,
                        From = Vector2.new(a.X, a.Y),
                        To = Vector2.new(b.X, b.Y),
                        Color = context.Color,
                        Alpha = context.Alpha,
                        Thickness = esp:GetSetting(target, "SkeletonThickness") or 1
                    })
                else
                    esp:HideVisual(line)
                end
            else
                esp:HideVisual(line)
            end
        end
    end
})

ESP:RegisterFeature("HeadDot", {
    Order = 70,
    Create = function(_, _, state, esp)
        state.Circle = esp:CreateVisual("Circle")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "HeadDot") or not context.Visible or not context.Info.Head then
            hideFeature(esp, state)
            return
        end
        local screen = context.Camera:WorldToViewportPoint(context.Info.Head.Position)
        if screen.Z <= 0 then
            hideFeature(esp, state)
            return
        end
        esp:SetVisual(state.Circle, {
            Visible = true,
            Position = Vector2.new(screen.X, screen.Y),
            Radius = esp:GetSetting(target, "HeadDotRadius") or 3,
            Color = context.Color,
            Alpha = context.Alpha,
            Thickness = 1
        })
    end
})

ESP:RegisterFeature("LookLine", {
    Order = 71,
    Create = function(_, _, state, esp)
        state.Line = esp:CreateVisual("Line")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "LookLine") or not context.Visible or not context.Info.Head then
            hideFeature(esp, state)
            return
        end
        local length = esp:GetSetting(target, "LookLineLength") or 8
        local from = context.Info.Head.Position
        local to = from + context.Info.Head.CFrame.LookVector * length
        local a = context.Camera:WorldToViewportPoint(from)
        local b = context.Camera:WorldToViewportPoint(to)
        if a.Z <= 0 or b.Z <= 0 then
            hideFeature(esp, state)
            return
        end
        esp:SetVisual(state.Line, {
            Visible = true,
            From = Vector2.new(a.X, a.Y),
            To = Vector2.new(b.X, b.Y),
            Color = context.Color,
            Alpha = context.Alpha,
            Thickness = 1
        })
    end
})

ESP:RegisterFeature("OffscreenArrows", {
    Order = 80,
    Create = function(_, _, state, esp)
        state.Arrow = esp:CreateVisual("Triangle")
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "OffscreenArrows") or not context.Visible or not context.Bounds or context.OnScreen then
            hideFeature(esp, state)
            return
        end
        local camera = context.Camera
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        local root = context.Bounds.Root
        local direction = root - center
        if context.Bounds.RootDepth <= 0 then
            direction = direction * -1
        end
        if direction.Magnitude < 1 then
            hideFeature(esp, state)
            return
        end
        direction = direction.Unit
        local radius = esp:GetSetting(target, "ArrowRadius") or 280
        local size = esp:GetSetting(target, "ArrowSize") or 16
        local anchor = center + direction * math.min(radius, math.min(viewport.X, viewport.Y) * 0.45)
        local perp = Vector2.new(-direction.Y, direction.X)
        local tip = anchor + direction * size
        local left = anchor - direction * (size * 0.75) + perp * (size * 0.55)
        local right = anchor - direction * (size * 0.75) - perp * (size * 0.55)
        esp:SetVisual(state.Arrow, {
            Visible = true,
            PointA = tip,
            PointB = left,
            PointC = right,
            Color = context.Color,
            Alpha = context.Alpha,
            Filled = true,
            Thickness = 1
        })
    end
})

ESP:RegisterFeature("Chams", {
    Order = 90,
    Create = function()
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Chams") or not context.Visible or not context.Info.Model then
            if state.Highlight then
                state.Highlight.Enabled = false
            end
            return
        end
        if not state.Highlight or not state.Highlight.Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = "UniversalESPHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = esp:GetScreenGui()
            state.Highlight = highlight
        end
        state.Highlight.Adornee = context.Info.Model
        state.Highlight.Enabled = true
        state.Highlight.FillColor = context.Color
        state.Highlight.OutlineColor = context.Color
        state.Highlight.FillTransparency = esp:GetSetting(target, "ChamsFillTransparency") or 0.72
        state.Highlight.OutlineTransparency = esp:GetSetting(target, "ChamsOutline") and (esp:GetSetting(target, "ChamsOutlineTransparency") or 0) or 1
    end,
    Destroy = function(_, _, state)
        if state.Highlight then
            state.Highlight:Destroy()
            state.Highlight = nil
        end
    end
})

ESP:RegisterProvider("Players", {
    Start = function(provider, options)
        if provider.Started then
            return
        end
        provider.Started = true
        provider.Options = options or {}
        provider.Targets = provider.Targets or {}
        local esp = provider.ESP
        local function add(player)
            provider.Targets[player] = esp:TrackPlayer(player, provider.Options)
        end
        local function remove(player)
            local target = provider.Targets[player]
            if target then
                esp:Untrack(target)
                provider.Targets[player] = nil
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            add(player)
        end
        provider.Added = connect(Players.PlayerAdded, add)
        provider.Removing = connect(Players.PlayerRemoving, remove)
    end,
    Stop = function(provider)
        if provider.Added then
            provider.Added:Disconnect()
        end
        if provider.Removing then
            provider.Removing:Disconnect()
        end
        if provider.Targets then
            for _, target in pairs(provider.Targets) do
                provider.ESP:Untrack(target)
            end
        end
        provider.Started = false
    end
})

return ESP
