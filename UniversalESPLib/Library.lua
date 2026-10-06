--[[
    UniversalESPLib v2
    A standalone, modular Roblox Luau ESP library with a clean, outlined visual style.

    Load with:
    local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/xxxxssw/new-uigg/main/UniversalESPLib/Library.lua"))()
    ESP:Start()

    Rendering uses the Drawing API when the executor provides it and falls back to
    ScreenGui objects otherwise. Every shape is drawn twice (outline + main) so it
    stays readable on any background.
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

-- Draw order. Drawing ZIndex and GuiObject ZIndex both honour these.
local Z = {
    Fill = 1,
    Outline = 2,
    Main = 4,
    Detail = 6,
    Text = 8
}

local ESP = {
    Version = "2.0.0",
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
        -- General
        Enabled = true,
        RenderMode = "Auto",          -- Auto | Drawing | Gui
        RefreshInterval = 0,
        ShowLocalPlayer = false,
        ShowDead = false,
        TeamCheck = false,
        UseTeamColor = false,
        MaxDistance = 2500,
        DistanceOrigin = "Character", -- Character | Camera
        FadeDistance = true,
        FadeSpeed = 10,               -- how fast targets fade in/out (per second)
        Transparency = 1,
        VisibleCheck = false,
        VisibleCheckInterval = 0.08,

        -- Text
        TextSize = 13,
        TextFont = 2,                 -- Drawing font id: 0 UI, 1 System, 2 Plex, 3 Monospace
        TextOutline = true,
        TextUseTargetColor = false,
        ScaleWithDistance = true,
        MinBoxSize = 4,
        MaxBoxSize = 1200,

        -- Colors
        EnemyColor = Color3.fromRGB(255, 86, 86),
        FriendlyColor = Color3.fromRGB(96, 165, 250),
        NeutralColor = Color3.fromRGB(240, 240, 245),
        VisibleColor = Color3.fromRGB(120, 255, 170),
        TargetColor = Color3.fromRGB(240, 240, 245),
        TextColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Outline = true,

        -- Box
        Box = true,
        BoxStyle = "Corner",          -- Corner | Full
        BoxMode = "Precise",          -- Precise (body parts) | Fast (root part)
        BoxThickness = 1,
        BoxFill = true,
        BoxFillTransparency = 0.9,
        Box3D = false,

        -- Labels
        Name = true,
        DisplayName = true,
        HealthBar = true,
        HealthBarSide = "Left",       -- Left | Right
        HealthBarWidth = 2,
        HealthText = true,
        HealthTextAlways = false,
        Distance = true,
        DistanceUnit = "m",
        Tool = true,

        -- Extras
        Tracer = false,
        TracerOrigin = "Bottom",      -- Bottom | Center | Top | Mouse
        TracerThickness = 1,
        Skeleton = false,
        SkeletonThickness = 1,
        Chams = false,
        ChamsOutline = true,
        ChamsFillTransparency = 0.6,
        ChamsOutlineTransparency = 0,
        ChamsFillColor = nil,         -- nil = target color
        ChamsOutlineColor = nil,      -- nil = target color
        OffscreenArrows = true,
        ArrowRadius = 300,
        ArrowSize = 14,
        HeadDot = false,
        HeadDotRadius = 3,
        LookLine = false,
        LookLineLength = 8,
        Rainbow = false,
        RainbowSpeed = 1
    }
}

Env.UniversalESPLib = ESP

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(ESP.Connections, connection)
    return connection
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(callback, ...)
    if ok then
        return a, b
    end
    warn("[UniversalESPLib] " .. tostring(a))
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
        R = math.floor(color.R * 255 + 0.5),
        G = math.floor(color.G * 255 + 0.5),
        B = math.floor(color.B * 255 + 0.5)
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

local function looksLikeColor(value)
    return type(value) == "table" and (value.R or value.r or value[1]) ~= nil and (value.B or value.b or value[3]) ~= nil
end

local function isPointInViewport(point, viewport)
    return point.X >= 0 and point.X <= viewport.X and point.Y >= 0 and point.Y <= viewport.Y
end

-- Smoothly moves `current` towards `goal` at `speed` units per second.
local function approach(current, goal, speed, delta)
    if current < goal then
        return math.min(goal, current + speed * delta)
    end
    return math.max(goal, current - speed * delta)
end

-- Health colour: red -> yellow -> green through HSV so mid values stay vivid.
local function healthColor(percent)
    percent = clamp(percent, 0, 1)
    return Color3.fromHSV(lerp(0, 0.34, percent), 0.82, 1)
end

local GUI_FONTS = {
    [0] = Enum.Font.GothamMedium,
    [1] = Enum.Font.Arial,
    [2] = Enum.Font.Code,
    [3] = Enum.Font.RobotoMono
}

local BODY_PARTS = {
    Head = true,
    UpperTorso = true,
    LowerTorso = true,
    LeftUpperArm = true,
    LeftLowerArm = true,
    LeftHand = true,
    RightUpperArm = true,
    RightLowerArm = true,
    RightHand = true,
    LeftUpperLeg = true,
    LeftLowerLeg = true,
    LeftFoot = true,
    RightUpperLeg = true,
    RightLowerLeg = true,
    RightFoot = true,
    Torso = true,
    ["Left Arm"] = true,
    ["Right Arm"] = true,
    ["Left Leg"] = true,
    ["Right Leg"] = true
}

local CORNER_OFFSETS = {
    Vector3.new(-1, -1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1)
}

local SKELETON_R15 = {
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
    { "RightLowerLeg", "RightFoot" }
}

local SKELETON_R6 = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" }
}

---------------------------------------------------------------------------
-- GUI host
---------------------------------------------------------------------------

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

---------------------------------------------------------------------------
-- Visual primitives
--
-- A "visual" is { Kind, Mode, Object, Extra, Outline? }. When created with
-- outlined = true it carries a second visual of the same kind that is drawn
-- in the outline colour underneath (or as a border on top for filled shapes).
---------------------------------------------------------------------------

function ESP:CanUseDrawing()
    local mode = self.Settings.RenderMode or self.RenderMode
    if mode == "Gui" then
        return false
    end
    if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
        return false
    end
    return true
end

function ESP:CreateGuiVisual(kind)
    local gui = self:GetScreenGui()
    local object
    local extra = {}

    if kind == "Text" then
        object = Instance.new("TextLabel")
        object.BackgroundTransparency = 1
        object.BorderSizePixel = 0
        object.Font = GUI_FONTS[self.Settings.TextFont] or Enum.Font.Code
        object.TextSize = self.Settings.TextSize
        object.TextStrokeTransparency = 0
        object.TextXAlignment = Enum.TextXAlignment.Left
        object.TextYAlignment = Enum.TextYAlignment.Top
        object.Size = UDim2.fromOffset(300, 18)
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
        -- Approximated with a rotated glyph; good enough for off-screen arrows.
        object = Instance.new("TextLabel")
        object.BackgroundTransparency = 1
        object.BorderSizePixel = 0
        object.Font = Enum.Font.GothamBold
        object.Text = ">"
        object.TextSize = 24
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
    object.ZIndex = Z.Main
    object.Parent = gui
    table.insert(self.GuiObjects, object)
    return {
        Kind = kind,
        Mode = "Gui",
        Object = object,
        Extra = extra
    }
end

function ESP:CreateRawVisual(kind)
    if self:CanUseDrawing() then
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

-- CreateVisual(kind) or CreateVisual(kind, true) for an outlined visual.
function ESP:CreateVisual(kind, options)
    local outlined = options == true or (type(options) == "table" and options.Outlined == true)
    local visual = self:CreateRawVisual(kind)
    if outlined and kind ~= "Text" then
        visual.Outline = self:CreateRawVisual(kind)
    end
    return visual
end

local function setDrawingProp(object, property, value)
    pcall(function()
        object[property] = value
    end)
end

function ESP:SetRawVisual(visual, properties)
    local object = visual.Object
    if not object then
        return
    end

    local alpha = properties.Alpha
    if alpha == nil then
        alpha = properties.Transparency
    end
    if alpha == nil then
        alpha = self.Settings.Transparency or 1
    end
    alpha = clamp(alpha, 0, 1)
    local color = properties.Color or self.Settings.TargetColor
    local outlineColor = properties.OutlineColor or self.Settings.OutlineColor
    local zindex = properties.ZIndex or Z.Main
    local kind = visual.Kind

    if visual.Mode == "Drawing" then
        if properties.Visible ~= nil then
            setDrawingProp(object, "Visible", properties.Visible)
        end
        if properties.Visible == false then
            return
        end
        setDrawingProp(object, "Color", color)
        setDrawingProp(object, "Transparency", alpha)
        setDrawingProp(object, "ZIndex", zindex)

        if kind == "Text" then
            setDrawingProp(object, "Text", tostring(properties.Text or ""))
            setDrawingProp(object, "Size", properties.Size or properties.TextSize or self.Settings.TextSize)
            setDrawingProp(object, "Font", properties.Font or self.Settings.TextFont or 2)
            setDrawingProp(object, "Center", properties.Center == true)
            local outline = properties.Outline
            if outline == nil then
                outline = self.Settings.TextOutline
            end
            setDrawingProp(object, "Outline", outline == true and self.Settings.Outline ~= false)
            setDrawingProp(object, "OutlineColor", outlineColor)
            if properties.Position then
                setDrawingProp(object, "Position", properties.Position)
            end
        elseif kind == "Line" then
            if properties.From then
                setDrawingProp(object, "From", properties.From)
            end
            if properties.To then
                setDrawingProp(object, "To", properties.To)
            end
            setDrawingProp(object, "Thickness", properties.Thickness or 1)
        elseif kind == "Square" then
            if properties.Position then
                setDrawingProp(object, "Position", properties.Position)
            end
            if properties.Size then
                setDrawingProp(object, "Size", properties.Size)
            end
            setDrawingProp(object, "Thickness", properties.Thickness or 1)
            setDrawingProp(object, "Filled", properties.Filled == true)
        elseif kind == "Circle" then
            if properties.Position then
                setDrawingProp(object, "Position", properties.Position)
            end
            setDrawingProp(object, "Radius", properties.Radius or 4)
            setDrawingProp(object, "NumSides", properties.NumSides or 24)
            setDrawingProp(object, "Thickness", properties.Thickness or 1)
            setDrawingProp(object, "Filled", properties.Filled == true)
        elseif kind == "Triangle" then
            if properties.PointA then
                setDrawingProp(object, "PointA", properties.PointA)
            end
            if properties.PointB then
                setDrawingProp(object, "PointB", properties.PointB)
            end
            if properties.PointC then
                setDrawingProp(object, "PointC", properties.PointC)
            end
            setDrawingProp(object, "Thickness", properties.Thickness or 1)
            setDrawingProp(object, "Filled", properties.Filled == true)
        end
        return
    end

    -- GUI fallback -----------------------------------------------------------
    if properties.Visible ~= nil then
        object.Visible = properties.Visible
    end
    if properties.Visible == false then
        return
    end
    object.ZIndex = zindex

    if kind == "Text" then
        local size = properties.Size or properties.TextSize or self.Settings.TextSize
        local center = properties.Center == true
        local outline = properties.Outline
        if outline == nil then
            outline = self.Settings.TextOutline
        end
        object.Text = tostring(properties.Text or "")
        object.TextSize = size
        object.Font = GUI_FONTS[properties.Font or self.Settings.TextFont] or Enum.Font.Code
        object.TextColor3 = color
        object.TextStrokeColor3 = outlineColor
        object.TextStrokeTransparency = (outline and self.Settings.Outline ~= false) and (1 - alpha) or 1
        object.TextTransparency = 1 - alpha
        object.TextXAlignment = center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        object.AnchorPoint = center and Vector2.new(0.5, 0) or Vector2.new(0, 0)
        object.Size = UDim2.fromOffset(properties.Width or 320, size + 4)
        if properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)
        end
    elseif kind == "Line" then
        local from = properties.From
        local to = properties.To
        if from and to then
            local delta = to - from
            object.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
            object.Size = UDim2.fromOffset(math.max(1, delta.Magnitude), properties.Thickness or 1)
            object.Rotation = math.deg(atan2(delta.Y, delta.X))
        end
        object.BackgroundColor3 = color
        object.BackgroundTransparency = 1 - alpha
    elseif kind == "Square" then
        if properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X, properties.Position.Y)
        end
        if properties.Size then
            object.Size = UDim2.fromOffset(properties.Size.X, properties.Size.Y)
        end
        local filled = properties.Filled == true
        object.BackgroundColor3 = color
        object.BackgroundTransparency = filled and (1 - alpha) or 1
        local stroke = visual.Extra and visual.Extra.Stroke
        if stroke then
            stroke.Color = color
            stroke.Thickness = properties.Thickness or 1
            stroke.Transparency = 1 - alpha
            stroke.Enabled = not filled
        end
    elseif kind == "Circle" then
        local radius = properties.Radius or 4
        if properties.Position then
            object.Position = UDim2.fromOffset(properties.Position.X - radius, properties.Position.Y - radius)
        end
        object.Size = UDim2.fromOffset(radius * 2, radius * 2)
        object.BackgroundColor3 = color
        object.BackgroundTransparency = properties.Filled and (1 - alpha) or 1
        local stroke = visual.Extra and visual.Extra.Stroke
        if stroke then
            stroke.Color = color
            stroke.Thickness = properties.Thickness or 1
            stroke.Transparency = 1 - alpha
            stroke.Enabled = not properties.Filled
        end
    elseif kind == "Triangle" then
        local a, b, c = properties.PointA, properties.PointB, properties.PointC
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
        object.TextStrokeTransparency = self.Settings.Outline ~= false and (1 - alpha) or 1
        object.TextSize = properties.Size or 22
    end
end

-- Builds the property table for the outline layer of a visual.
function ESP:BuildOutlineProperties(visual, properties)
    local outline = {}
    for key, value in pairs(properties) do
        outline[key] = value
    end
    outline.Color = properties.OutlineColor or self.Settings.OutlineColor
    outline.OutlineColor = nil
    local zindex = properties.ZIndex or Z.Main
    local kind = visual.Kind

    if properties.Filled then
        -- Filled shapes get a slightly larger filled shape underneath.
        outline.ZIndex = zindex - 1
        if kind == "Square" and properties.Position and properties.Size then
            outline.Position = properties.Position - Vector2.new(1, 1)
            outline.Size = properties.Size + Vector2.new(2, 2)
        elseif kind == "Circle" then
            outline.Radius = (properties.Radius or 4) + 1
        elseif kind == "Triangle" and properties.PointA and properties.PointB and properties.PointC then
            local a, b, c = properties.PointA, properties.PointB, properties.PointC
            local center = (a + b + c) / 3
            local function grow(point)
                local direction = point - center
                if direction.Magnitude < 0.001 then
                    return point
                end
                return point + direction.Unit * 1.5
            end
            outline.PointA = grow(a)
            outline.PointB = grow(b)
            outline.PointC = grow(c)
        end
    else
        -- Stroked shapes get a thicker stroke of the same shape underneath.
        outline.ZIndex = zindex - 1
        outline.Thickness = (properties.Thickness or 1) + 2
        if visual.Mode == "Gui" and kind == "Square" and properties.Position and properties.Size then
            -- UIStroke borders grow outward from the frame, so start the outline 1px inside.
            outline.Position = properties.Position - Vector2.new(1, 1)
            outline.Size = properties.Size + Vector2.new(2, 2)
        end
    end
    return outline
end

function ESP:SetVisual(visual, properties)
    if not visual or not visual.Object then
        return
    end
    properties = properties or {}
    if visual.Outline then
        local wantOutline = properties.Outline ~= false and self.Settings.Outline ~= false
        if properties.Visible ~= false and wantOutline then
            self:SetRawVisual(visual.Outline, self:BuildOutlineProperties(visual, properties))
        else
            self:SetRawVisual(visual.Outline, { Visible = false })
        end
    end
    self:SetRawVisual(visual, properties)
end

function ESP:HideVisual(visual)
    if not visual then
        return
    end
    if visual.Outline then
        self:HideVisual(visual.Outline)
    end
    if visual.Object then
        pcall(function()
            visual.Object.Visible = false
        end)
    end
end

function ESP:RemoveVisual(visual)
    if not visual then
        return
    end
    if visual.Outline then
        self:RemoveVisual(visual.Outline)
        visual.Outline = nil
    end
    if not visual.Object then
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
    for key, child in pairs(value) do
        if key ~= "Highlight" and typeof(child) == "table" then
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
    for key, child in pairs(value) do
        if key ~= "Highlight" and typeof(child) == "table" then
            self:DestroyVisuals(child)
        end
    end
end

function ESP:GetTextHeight(size)
    return (size or self.Settings.TextSize) + 2
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

function ESP:SetSetting(key, value)
    if looksLikeColor(value) then
        value = tableToColor(value, self.Settings[key])
    end
    self.Settings[key] = value
    if key == "Enabled" then
        self.Enabled = value == true
    end
    return self
end

function ESP:SetSettings(settings)
    for key, value in pairs(settings or {}) do
        if looksLikeColor(value) then
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

---------------------------------------------------------------------------
-- Target resolution
---------------------------------------------------------------------------

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
        local player = target.Player
        if self:GetSetting(target, "DisplayName") and player.DisplayName and player.DisplayName ~= player.Name then
            return player.DisplayName .. " (@" .. player.Name .. ")"
        end
        return player.Name
    end
    if target.Instance and target.Instance.Name then
        return target.Instance.Name
    end
    return tostring(target.Key)
end

function ESP:IsFriendly(target)
    local player = target.Player
    if not player or not LocalPlayer or player == LocalPlayer then
        return false
    end
    if player.Team ~= nil and LocalPlayer.Team ~= nil then
        return player.Team == LocalPlayer.Team
    end
    return false
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
    local player = target.Player
    if player then
        if self.Settings.UseTeamColor and player.Team ~= nil then
            return player.TeamColor.Color
        end
        if LocalPlayer and player.Team ~= nil and LocalPlayer.Team ~= nil then
            if player.Team == LocalPlayer.Team then
                return self.Settings.FriendlyColor
            end
            return self.Settings.EnemyColor
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
    local model, root, humanoid, head

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

    local health, maxHealth
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
        Head = head or (humanoid == nil and root or nil),
        Humanoid = humanoid,
        Health = health,
        MaxHealth = maxHealth,
        Tool = self:GetToolName(model)
    }
end

-- Body parts used for the precise box. Cached per target and refreshed every second.
function ESP:GetBodyParts(target, model)
    local cache = target.PartCache
    local now = os.clock()
    if cache and cache.Model == model and now - cache.Time < 1 then
        return cache.Parts
    end
    local parts = {}
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and BODY_PARTS[child.Name] then
            table.insert(parts, child)
        end
    end
    if #parts == 0 then
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                table.insert(parts, child)
                if #parts >= 24 then
                    break
                end
            end
        end
    end
    target.PartCache = { Model = model, Parts = parts, Time = now }
    return parts
end

function ESP:GetBoundingData(target, info)
    if info.Humanoid and info.Model and self:GetSetting(target, "BoxMode") ~= "Fast" then
        local parts = self:GetBodyParts(target, info.Model)
        if #parts > 0 then
            return info.Root.CFrame, nil, parts
        end
    end
    if info.Model and not info.Humanoid then
        local ok, cf, size = pcall(function()
            return info.Model:GetBoundingBox()
        end)
        if ok and cf and size then
            return cf, size, nil
        end
    end
    if info.Humanoid then
        -- Fast mode: a fixed box around the root part.
        local root = info.Root
        local size = Vector3.new(4, 5.6, 4)
        if root.Size.Y <= 1 then
            size = Vector3.new(3, 3.5, 3)
        end
        return root.CFrame, size, nil
    end
    return info.Root.CFrame, info.Root.Size, nil
end

function ESP:GetScreenBounds(camera, target, info, want3D)
    local cf, size, parts = self:GetBoundingData(target, info)
    if not cf then
        return nil
    end

    local viewport = camera.ViewportSize
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false
    local behind = false

    local function project(world)
        local screen, visible = camera:WorldToViewportPoint(world)
        if screen.Z <= 0 then
            behind = true
            return
        end
        if screen.X < minX then minX = screen.X end
        if screen.Y < minY then minY = screen.Y end
        if screen.X > maxX then maxX = screen.X end
        if screen.Y > maxY then maxY = screen.Y end
        if visible or isPointInViewport(screen, viewport) then
            anyOnScreen = true
        end
    end

    local corners = nil
    if parts then
        -- Precise: union of every body part's corners.
        local localMin, localMax
        if want3D then
            localMin = Vector3.new(math.huge, math.huge, math.huge)
            localMax = Vector3.new(-math.huge, -math.huge, -math.huge)
        end
        for _, part in ipairs(parts) do
            if part.Parent then
                local partCF = part.CFrame
                local half = part.Size / 2
                for _, offset in ipairs(CORNER_OFFSETS) do
                    local world = partCF:PointToWorldSpace(Vector3.new(half.X * offset.X, half.Y * offset.Y, half.Z * offset.Z))
                    project(world)
                    if want3D then
                        local localPoint = cf:PointToObjectSpace(world)
                        localMin = Vector3.new(math.min(localMin.X, localPoint.X), math.min(localMin.Y, localPoint.Y), math.min(localMin.Z, localPoint.Z))
                        localMax = Vector3.new(math.max(localMax.X, localPoint.X), math.max(localMax.Y, localPoint.Y), math.max(localMax.Z, localPoint.Z))
                    end
                end
            end
        end
        if want3D and localMin.X ~= math.huge then
            corners = {}
            for index, offset in ipairs(CORNER_OFFSETS) do
                local localPoint = Vector3.new(
                    offset.X < 0 and localMin.X or localMax.X,
                    offset.Y < 0 and localMin.Y or localMax.Y,
                    offset.Z < 0 and localMin.Z or localMax.Z
                )
                local screen = camera:WorldToViewportPoint(cf:PointToWorldSpace(localPoint))
                if screen.Z > 0 then
                    corners[index] = Vector2.new(screen.X, screen.Y)
                end
            end
        end
    else
        local half = size / 2
        corners = want3D and {} or nil
        for index, offset in ipairs(CORNER_OFFSETS) do
            local world = cf:PointToWorldSpace(Vector3.new(half.X * offset.X, half.Y * offset.Y, half.Z * offset.Z))
            project(world)
            if want3D then
                local screen = camera:WorldToViewportPoint(world)
                if screen.Z > 0 then
                    corners[index] = Vector2.new(screen.X, screen.Y)
                end
            end
        end
    end

    local rootScreen = camera:WorldToViewportPoint(info.Root.Position)
    local rootPoint = Vector2.new(rootScreen.X, rootScreen.Y)

    if behind or minX == math.huge then
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

    local minSize = self.Settings.MinBoxSize or 4
    local maxSize = self.Settings.MaxBoxSize or 1200
    local width = clamp(maxX - minX, minSize, maxSize)
    local height = clamp(maxY - minY, minSize, maxSize)
    -- Snap to whole pixels so 1px lines stay crisp.
    local x = math.floor(minX + 0.5)
    local y = math.floor(minY + 0.5)
    width = math.floor(width + 0.5)
    height = math.floor(height + 0.5)
    local center = Vector2.new(x + width / 2, y + height / 2)

    return {
        Root = rootPoint,
        RootDepth = rootScreen.Z,
        OnScreen = rootScreen.Z > 0 and anyOnScreen,
        Corners = corners,
        Position = Vector2.new(x, y),
        Size = Vector2.new(width, height),
        Center = center,
        Top = Vector2.new(center.X, y),
        Bottom = Vector2.new(center.X, y + height)
    }
end

function ESP:GetLocalRoot()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character.PrimaryPart
end

function ESP:GetDistanceOrigin(camera)
    if self.Settings.DistanceOrigin == "Character" then
        local root = self:GetLocalRoot()
        if root then
            return root.Position
        end
    end
    return camera.CFrame.Position
end

-- Line-of-sight check from the camera to the target's head, throttled per target.
function ESP:IsVisibleToCamera(target, info, camera)
    local state = target.VisibleState
    local now = os.clock()
    local interval = self.Settings.VisibleCheckInterval or 0.08
    if state and now - state.Time < interval then
        return state.Visible
    end

    local origin = camera.CFrame.Position
    local point = info.Head or info.Root
    local params = self.RaycastParams
    if not params then
        params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        self.RaycastParams = params
    end
    local ignore = { camera }
    if LocalPlayer and LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    if info.Model then
        table.insert(ignore, info.Model)
    elseif info.Root then
        table.insert(ignore, info.Root)
    end
    params.FilterDescendantsInstances = ignore

    local direction = point.Position - origin
    local visible = true
    local ok, result = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)
    if ok and result and result.Instance then
        visible = result.Instance.Transparency >= 0.95 or result.Instance.CanCollide == false and result.Instance.Transparency > 0.5
    end
    target.VisibleState = { Time = now, Visible = visible }
    return visible
end

function ESP:GetTextSize(target, distance)
    local size = self:GetSetting(target, "TextSize") or 13
    if self:GetSetting(target, "ScaleWithDistance") then
        local maxDistance = self:GetSetting(target, "MaxDistance") or 2500
        local t = clamp(distance / math.max(maxDistance, 1), 0, 1)
        size = size * (1 - 0.3 * t)
        size = math.max(size, (self:GetSetting(target, "TextSize") or 13) * 0.7)
    end
    return math.floor(size + 0.5)
end

function ESP:BuildContext(target, info, delta)
    local camera = self:GetCamera()
    local fadeSpeed = self.Settings.FadeSpeed or 10
    if not camera or not info.Exists or not info.Root then
        target.Fade = approach(target.Fade or 0, 0, fadeSpeed, delta or 0)
        return {
            Exists = false,
            Visible = false,
            OnScreen = false,
            Draw = false,
            Fade = target.Fade
        }
    end

    local distance = (self:GetDistanceOrigin(camera) - info.Root.Position).Magnitude
    local maxDistance = self:GetSetting(target, "MaxDistance") or math.huge
    local visible = distance <= maxDistance

    if target.Player == LocalPlayer and not self:GetSetting(target, "ShowLocalPlayer") then
        visible = false
    end

    if visible and self:GetSetting(target, "TeamCheck") and self:IsFriendly(target) then
        visible = false
    end

    if visible and info.Humanoid and info.Health ~= nil and info.Health <= 0 and not self:GetSetting(target, "ShowDead") then
        visible = false
    end

    if visible and target.Options and type(target.Options.Filter) == "function" then
        local allowed = safeCallback(target.Options.Filter, target, info)
        if allowed == false then
            visible = false
        end
    end

    target.Fade = approach(target.Fade or 0, visible and 1 or 0, fadeSpeed, delta or 0)
    local fade = target.Fade
    if fade <= 0.01 then
        return {
            Exists = true,
            Visible = false,
            OnScreen = false,
            Draw = false,
            Fade = fade,
            Camera = camera,
            Distance = distance,
            Info = info
        }
    end

    local want3D = self:GetSetting(target, "Box3D") == true
    local bounds = self:GetScreenBounds(camera, target, info, want3D)

    local alpha = (self:GetSetting(target, "Transparency") or 1) * fade
    if self:GetSetting(target, "FadeDistance") and maxDistance and maxDistance > 0 and maxDistance < math.huge then
        local t = clamp((distance / maxDistance - 0.6) / 0.4, 0, 1)
        alpha = alpha * lerp(1, 0.3, t)
    end

    local color = self:GetTargetColor(target)
    local visibleToCamera = nil
    if self:GetSetting(target, "VisibleCheck") then
        visibleToCamera = self:IsVisibleToCamera(target, info, camera)
        if visibleToCamera and not (target.Options and target.Options.Color) then
            color = self.Settings.VisibleColor
        end
    end
    if self.Settings.Rainbow then
        color = Color3.fromHSV(self.CurrentRainbowHue, 0.85, 1)
    end

    local textSize = self:GetTextSize(target, distance)

    return {
        Exists = true,
        Visible = visible or fade > 0.01,
        OnScreen = bounds and bounds.OnScreen == true or false,
        Draw = bounds ~= nil and bounds.OnScreen == true,
        Fade = fade,
        Camera = camera,
        Distance = distance,
        Bounds = bounds,
        Color = color,
        TextColor = self:GetSetting(target, "TextUseTargetColor") and color or self.Settings.TextColor,
        TextSize = textSize,
        TextHeight = self:GetTextHeight(textSize),
        VisibleToCamera = visibleToCamera,
        Alpha = clamp(alpha, 0, 1),
        Info = info,
        TopOffset = 0,
        BottomOffset = 0,
        LeftOffset = 0,
        RightOffset = 0
    }
end

---------------------------------------------------------------------------
-- Registries
---------------------------------------------------------------------------

function ESP:RegisterFeature(name, feature)
    feature.Name = name
    feature.Order = feature.Order or (#self.FeatureOrder + 1)
    if not self.Features[name] then
        table.insert(self.FeatureOrder, name)
    end
    self.Features[name] = feature
    table.sort(self.FeatureOrder, function(a, b)
        return (self.Features[a].Order or 0) < (self.Features[b].Order or 0)
    end)
    return feature
end

function ESP:SetFeatureEnabled(name, enabled)
    self.Settings[name] = enabled == true
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

---------------------------------------------------------------------------
-- Tracking
---------------------------------------------------------------------------

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
    if isInstance(instance) and instance:IsA("Player") then
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
        Fade = 0,
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
        Fade = 0,
        Created = os.clock()
    }
    self.Targets[target.Key] = target
    table.insert(self.TargetList, target)
    target.CharacterConnection = connect(player.CharacterAdded, function(character)
        target.Instance = character
        target.PartCache = nil
        target.Fade = 0
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

---------------------------------------------------------------------------
-- Helpers used by features
---------------------------------------------------------------------------

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
    local segments = {}
    local names = model:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
    for _, pair in ipairs(names) do
        local a = model:FindFirstChild(pair[1])
        local b = model:FindFirstChild(pair[2])
        if isBasePart(a) and isBasePart(b) then
            table.insert(segments, { a, b })
        end
    end
    return segments
end

-- Draws a label above the box and advances context.TopOffset.
function ESP:DrawTopText(visual, context, text, color)
    local height = context.TextHeight
    local y = context.Bounds.Position.Y - height - 2 - context.TopOffset
    context.TopOffset = context.TopOffset + height
    self:SetVisual(visual, {
        Visible = true,
        Text = text,
        Position = Vector2.new(context.Bounds.Top.X, y),
        Color = color or context.TextColor,
        Alpha = context.Alpha,
        Center = true,
        Size = context.TextSize,
        ZIndex = Z.Text
    })
end

-- Draws a label below the box and advances context.BottomOffset.
function ESP:DrawBottomText(visual, context, text, color)
    local height = context.TextHeight
    local y = context.Bounds.Position.Y + context.Bounds.Size.Y + 2 + context.BottomOffset
    context.BottomOffset = context.BottomOffset + height
    self:SetVisual(visual, {
        Visible = true,
        Text = text,
        Position = Vector2.new(context.Bounds.Bottom.X, y),
        Color = color or context.TextColor,
        Alpha = context.Alpha,
        Center = true,
        Size = context.TextSize,
        ZIndex = Z.Text
    })
end

---------------------------------------------------------------------------
-- Render loop
---------------------------------------------------------------------------

function ESP:Step(delta)
    if self.Unloaded then
        return
    end
    self.CurrentRainbowHue = (self.CurrentRainbowHue + delta * (self.Settings.RainbowSpeed or 1) / 8) % 1

    if not self.Enabled or not self.Settings.Enabled then
        if not self.HiddenAll then
            for _, target in ipairs(self.TargetList) do
                self:HideVisuals(target.FeatureState)
                target.Fade = 0
            end
            self.HiddenAll = true
        end
        return
    end
    self.HiddenAll = false

    self.LastStep = self.LastStep or 0
    local refresh = self.Settings.RefreshInterval or 0
    if refresh > 0 then
        self.LastStep = self.LastStep + delta
        if self.LastStep < refresh then
            return
        end
        delta = self.LastStep
        self.LastStep = 0
    end

    for _, target in ipairs(self.TargetList) do
        local info = self:ResolveTarget(target)
        local context = self:BuildContext(target, info, delta)
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

function ESP:Toggle()
    return self:SetEnabled(not self.Enabled)
end

function ESP:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    self.Enabled = false
    for _, provider in pairs(self.Providers) do
        if provider.Stop then
            pcall(provider.Stop, provider)
        end
    end
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
    if Env.UniversalESPLib == self then
        Env.UniversalESPLib = nil
    end
end

---------------------------------------------------------------------------
-- Built-in features
---------------------------------------------------------------------------

local function hideFeature(esp, state)
    esp:HideVisuals(state)
end

-- Box: outlined corner or full box with an optional translucent fill.
ESP:RegisterFeature("Box", {
    Order = 10,
    Create = function(_, _, state, esp)
        state.Fill = esp:CreateVisual("Square")
        state.Full = esp:CreateVisual("Square", true)
        state.Corners = {}
        for index = 1, 8 do
            state.Corners[index] = esp:CreateVisual("Line", true)
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

        if esp:GetSetting(target, "BoxFill") then
            esp:SetVisual(state.Fill, {
                Visible = true,
                Position = bounds.Position,
                Size = bounds.Size,
                Color = color,
                Alpha = alpha * (1 - clamp(esp:GetSetting(target, "BoxFillTransparency") or 0.9, 0, 1)),
                Filled = true,
                Outline = false,
                ZIndex = Z.Fill
            })
        else
            esp:HideVisual(state.Fill)
        end

        if style == "Full" then
            esp:SetVisual(state.Full, {
                Visible = true,
                Position = bounds.Position,
                Size = bounds.Size,
                Color = color,
                Alpha = alpha,
                Thickness = thickness,
                ZIndex = Z.Main
            })
            for _, line in ipairs(state.Corners) do
                esp:HideVisual(line)
            end
            return
        end

        esp:HideVisual(state.Full)
        local x, y = bounds.Position.X, bounds.Position.Y
        local w, h = bounds.Size.X, bounds.Size.Y
        local l = math.max(3, math.floor(math.min(w, h) * 0.24 + 0.5))
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
                Thickness = thickness,
                ZIndex = Z.Main
            })
        end
    end
})

-- Box3D: oriented bounding box around the rig.
ESP:RegisterFeature("Box3D", {
    Order = 11,
    Create = function(_, _, state, esp)
        state.Lines = {}
        for index = 1, 12 do
            state.Lines[index] = esp:CreateVisual("Line", true)
        end
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Box3D") or not context.Draw or not context.Bounds.Corners then
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
                    Alpha = context.Alpha * 0.9,
                    Thickness = esp:GetSetting(target, "BoxThickness") or 1,
                    ZIndex = Z.Main
                })
            else
                esp:HideVisual(state.Lines[index])
            end
        end
    end
})

-- Name: centred above the box.
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
        esp:DrawTopText(state.Text, context, esp:GetTargetName(target, context.Info))
    end
})

-- HealthBar: vertical bar beside the box with an outlined track and a value label.
ESP:RegisterFeature("HealthBar", {
    Order = 30,
    Create = function(_, _, state, esp)
        state.Back = esp:CreateVisual("Square", true)
        state.Fill = esp:CreateVisual("Square")
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(_, target, state, context, esp)
        local info = context.Info
        if not esp:GetSetting(target, "HealthBar") or not context.Draw or not info.Health or not info.MaxHealth then
            hideFeature(esp, state)
            return
        end
        local bounds = context.Bounds
        local alpha = context.Alpha
        local percent = clamp(info.Health / math.max(info.MaxHealth, 1), 0, 1)
        local width = math.max(1, esp:GetSetting(target, "HealthBarWidth") or 2)
        local height = bounds.Size.Y
        local fillHeight = math.floor(height * percent + 0.5)
        local side = esp:GetSetting(target, "HealthBarSide") or "Left"
        local gap = 4
        local x
        if side == "Right" then
            x = bounds.Position.X + bounds.Size.X + gap + context.RightOffset
            context.RightOffset = context.RightOffset + width + gap
        else
            x = bounds.Position.X - gap - width - context.LeftOffset
            context.LeftOffset = context.LeftOffset + width + gap
        end
        local y = bounds.Position.Y
        local color = healthColor(percent)

        esp:SetVisual(state.Back, {
            Visible = true,
            Position = Vector2.new(x, y),
            Size = Vector2.new(width, height),
            Color = Color3.fromRGB(28, 28, 32),
            Alpha = alpha * 0.9,
            Filled = true,
            ZIndex = Z.Main
        })
        esp:SetVisual(state.Fill, {
            Visible = fillHeight > 0,
            Position = Vector2.new(x, y + height - fillHeight),
            Size = Vector2.new(width, fillHeight),
            Color = color,
            Alpha = alpha,
            Filled = true,
            ZIndex = Z.Detail
        })

        local showText = esp:GetSetting(target, "HealthText") and (esp:GetSetting(target, "HealthTextAlways") or percent < 0.999)
        if showText then
            local size = math.max(8, context.TextSize - 3)
            local textY = clamp(y + height - fillHeight - size / 2, y - size, y + height - size)
            local textX = side == "Right" and (x + width + 3) or (x - 3)
            local props = {
                Visible = true,
                Text = tostring(math.floor(info.Health + 0.5)),
                Position = Vector2.new(textX, textY),
                Color = color,
                Alpha = alpha,
                Center = false,
                Size = size,
                ZIndex = Z.Text
            }
            if state.Text.Mode == "Drawing" then
                esp:SetVisual(state.Text, props)
                if side ~= "Right" then
                    -- Right-align against the bar using the measured text width.
                    local ok, textBounds = pcall(function()
                        return state.Text.Object.TextBounds
                    end)
                    if ok and textBounds then
                        state.Text.Object.Position = Vector2.new(textX - textBounds.X, textY)
                    end
                end
            else
                props.Width = 40
                if side ~= "Right" then
                    props.Position = Vector2.new(textX - 40, textY)
                end
                esp:SetVisual(state.Text, props)
                state.Text.Object.TextXAlignment = side == "Right" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
            end
        else
            esp:HideVisual(state.Text)
        end
    end
})

-- Distance: below the box.
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
        esp:DrawBottomText(state.Text, context, text)
    end
})

-- Tool: equipped tool name below the distance.
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
        esp:DrawBottomText(state.Text, context, "[" .. context.Info.Tool .. "]")
    end
})

-- Tracer: outlined line from the chosen origin to the bottom of the box.
ESP:RegisterFeature("Tracer", {
    Order = 50,
    Create = function(_, _, state, esp)
        state.Line = esp:CreateVisual("Line", true)
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
            Thickness = esp:GetSetting(target, "TracerThickness") or 1,
            ZIndex = Z.Main
        })
    end
})

-- Skeleton: outlined bone lines for R6 and R15 rigs.
ESP:RegisterFeature("Skeleton", {
    Order = 60,
    Create = function(_, _, state, esp)
        state.Lines = {}
        for index = 1, 14 do
            state.Lines[index] = esp:CreateVisual("Line", true)
        end
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "Skeleton") or not context.Draw then
            hideFeature(esp, state)
            return
        end
        local segments = esp:GetSkeletonSegments(context.Info)
        local camera = context.Camera
        for index, line in ipairs(state.Lines) do
            local segment = segments[index]
            if segment then
                local a = camera:WorldToViewportPoint(segment[1].Position)
                local b = camera:WorldToViewportPoint(segment[2].Position)
                if a.Z > 0 and b.Z > 0 then
                    esp:SetVisual(line, {
                        Visible = true,
                        From = Vector2.new(a.X, a.Y),
                        To = Vector2.new(b.X, b.Y),
                        Color = context.Color,
                        Alpha = context.Alpha,
                        Thickness = esp:GetSetting(target, "SkeletonThickness") or 1,
                        ZIndex = Z.Detail
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

-- HeadDot: filled, outlined dot on the head.
ESP:RegisterFeature("HeadDot", {
    Order = 70,
    Create = function(_, _, state, esp)
        state.Circle = esp:CreateVisual("Circle", true)
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "HeadDot") or not context.Draw or not context.Info.Head then
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
            Filled = true,
            Thickness = 1,
            ZIndex = Z.Detail
        })
    end
})

-- LookLine: short outlined line showing where the head is facing.
ESP:RegisterFeature("LookLine", {
    Order = 71,
    Create = function(_, _, state, esp)
        state.Line = esp:CreateVisual("Line", true)
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "LookLine") or not context.Draw or not context.Info.Head then
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
            Thickness = 1,
            ZIndex = Z.Detail
        })
    end
})

-- OffscreenArrows: filled, outlined arrow on a ring around the screen centre.
ESP:RegisterFeature("OffscreenArrows", {
    Order = 80,
    Create = function(_, _, state, esp)
        state.Arrow = esp:CreateVisual("Triangle", true)
    end,
    Update = function(_, target, state, context, esp)
        if not esp:GetSetting(target, "OffscreenArrows") or not context.Visible or context.OnScreen or not context.Info.Root then
            hideFeature(esp, state)
            return
        end
        local camera = context.Camera
        local viewport = camera.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        -- Direction in camera space keeps arrows correct even when the target is behind us.
        local relative = camera.CFrame:PointToObjectSpace(context.Info.Root.Position)
        local direction = Vector2.new(relative.X, -relative.Y)
        if direction.Magnitude < 0.001 then
            hideFeature(esp, state)
            return
        end
        direction = direction.Unit
        local radius = esp:GetSetting(target, "ArrowRadius") or 300
        local size = esp:GetSetting(target, "ArrowSize") or 14
        local anchor = center + direction * math.min(radius, math.min(viewport.X, viewport.Y) * 0.46)
        local perp = Vector2.new(-direction.Y, direction.X)
        local tip = anchor + direction * size
        local left = anchor - direction * (size * 0.6) + perp * (size * 0.6)
        local right = anchor - direction * (size * 0.6) - perp * (size * 0.6)
        esp:SetVisual(state.Arrow, {
            Visible = true,
            PointA = tip,
            PointB = left,
            PointC = right,
            Color = context.Color,
            Alpha = context.Alpha,
            Filled = true,
            Thickness = 1,
            ZIndex = Z.Detail
        })
    end
})

-- Chams: Highlight-based fill and outline through walls.
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
        local fillColor = esp:GetSetting(target, "ChamsFillColor")
        local outlineColor = esp:GetSetting(target, "ChamsOutlineColor")
        local highlight = state.Highlight
        highlight.Adornee = context.Info.Model
        highlight.Enabled = true
        highlight.FillColor = typeof(fillColor) == "Color3" and fillColor or context.Color
        highlight.OutlineColor = typeof(outlineColor) == "Color3" and outlineColor or context.Color
        local fillTransparency = esp:GetSetting(target, "ChamsFillTransparency") or 0.6
        highlight.FillTransparency = 1 - (1 - fillTransparency) * context.Fade
        if esp:GetSetting(target, "ChamsOutline") then
            local outlineTransparency = esp:GetSetting(target, "ChamsOutlineTransparency") or 0
            highlight.OutlineTransparency = 1 - (1 - outlineTransparency) * context.Fade
        else
            highlight.OutlineTransparency = 1
        end
    end,
    Destroy = function(_, _, state)
        if state.Highlight then
            state.Highlight:Destroy()
            state.Highlight = nil
        end
    end
})

---------------------------------------------------------------------------
-- Built-in provider
---------------------------------------------------------------------------

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
            provider.Targets = {}
        end
        provider.Started = false
    end
})

return ESP
