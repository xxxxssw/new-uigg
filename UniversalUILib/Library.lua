--[[
    UniversalUILib
    A standalone Roblox Lua UI library with a Linoria-style API surface.

    Load with:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPO/main/Library.lua"))()
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function getgenvCompat()
    if getgenv then
        return getgenv()
    end
    return _G
end

local Env = getgenvCompat()
local Toggles = Env.Toggles or {}
local Options = Env.Options or {}
Env.Toggles = Toggles
Env.Options = Options

local Library = {
    Version = "1.0.0",
    Name = "UniversalUILib",
    Flags = Options,
    Toggles = Toggles,
    Options = Options,
    Windows = {},
    Registry = {},
    Connections = {},
    UnloadCallbacks = {},
    Notifications = {},
    DependencyBoxes = {},
    OpenFrames = {},
    OpenFrameOwners = {},
    Unloaded = false,
    NotifyOnError = true,
    ToggleKeybind = nil,
    CurrentRainbowHue = 0,
    CurrentRainbowColor = Color3.fromRGB(255, 0, 0),
    Theme = {
        Font = Enum.Font.Code,
        TextSize = 13,
        Background = Color3.fromRGB(17, 18, 22),
        Main = Color3.fromRGB(26, 27, 33),
        Panel = Color3.fromRGB(31, 33, 40),
        PanelLight = Color3.fromRGB(38, 41, 50),
        Outline = Color3.fromRGB(61, 65, 78),
        Accent = Color3.fromRGB(0, 170, 255),
        AccentDark = Color3.fromRGB(0, 112, 170),
        Text = Color3.fromRGB(240, 244, 248),
        MutedText = Color3.fromRGB(166, 173, 186),
        Risk = Color3.fromRGB(240, 80, 80),
        Black = Color3.fromRGB(0, 0, 0),
        White = Color3.fromRGB(255, 255, 255)
    }
}

local Utility = {}
local BaseControl = {}
BaseControl.__index = BaseControl

local DEFAULT_WINDOW_SIZE = Vector2.new(620, 520)
local DEFAULT_WINDOW_POSITION = Vector2.new(160, 120)
local INPUT_TYPES = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3"
}
local INPUT_NAMES = {
    MB1 = Enum.UserInputType.MouseButton1,
    MB2 = Enum.UserInputType.MouseButton2,
    MB3 = Enum.UserInputType.MouseButton3
}

local function merge(defaults, overrides)
    local result = {}
    for key, value in pairs(defaults or {}) do
        result[key] = value
    end
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

local function safeName(value)
    return tostring(value or "UniversalUILib"):gsub("[^%w_%-]", "_")
end

local function listContains(list, value)
    if type(list) ~= "table" then
        return false
    end
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

local function roundTo(value, places)
    places = places or 0
    local mult = 10 ^ places
    return math.floor(value * mult + 0.5) / mult
end

local function clamp(value, min, max)
    return math.clamp(tonumber(value) or min, min, max)
end

local function rgbToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function hexToRgb(hex)
    if type(hex) ~= "string" then
        return nil
    end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then
        return nil
    end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then
        return nil
    end
    return Color3.fromRGB(r, g, b)
end

local function toColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) == "string" then
        return hexToRgb(value) or fallback
    end
    if type(value) == "table" then
        local r = value.R or value.r or value[1]
        local g = value.G or value.g or value[2]
        local b = value.B or value.b or value[3]
        if r and g and b then
            if r <= 1 and g <= 1 and b <= 1 then
                return Color3.new(r, g, b)
            end
            return Color3.fromRGB(r, g, b)
        end
    end
    return fallback
end

local function colorToData(color)
    if typeof(color) ~= "Color3" then
        return color
    end
    return { R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255), Hex = rgbToHex(color) }
end

local function enumName(value)
    if typeof(value) == "EnumItem" then
        return value.Name
    end
    return tostring(value)
end

local function getInputName(input)
    if INPUT_TYPES[input.UserInputType] then
        return INPUT_TYPES[input.UserInputType]
    end
    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end
    return nil
end

local function inputFromName(name)
    if typeof(name) == "EnumItem" then
        return name
    end
    if type(name) ~= "string" then
        return nil
    end
    if INPUT_NAMES[name] then
        return INPUT_NAMES[name]
    end
    local ok, key = pcall(function()
        return Enum.KeyCode[name]
    end)
    if ok then
        return key
    end
    return nil
end

local function isSameInput(input, value)
    if typeof(value) ~= "EnumItem" then
        value = inputFromName(value)
    end
    if not value then
        return false
    end
    if value.EnumType == Enum.KeyCode then
        return input.KeyCode == value
    end
    if value.EnumType == Enum.UserInputType then
        return input.UserInputType == value
    end
    return false
end

local function getMouseLocation()
    local location = UserInputService:GetMouseLocation()
    return Vector2.new(location.X, location.Y)
end

local function isPointInsideGuiObject(object, point)
    if not object or not object.Parent or not object.Visible then
        return false
    end
    local pos = object.AbsolutePosition
    local size = object.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

function Utility:Create(className, properties, children)
    local instance = typeof(className) == "Instance" and className or Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

function Utility:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Library.Connections, connection)
    return connection
end

function Utility:Tween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

function Utility:AddCorner(parent, radius)
    return self:Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 4),
        Parent = parent
    })
end

function Utility:AddStroke(parent, colorKey, thickness)
    local stroke = self:Create("UIStroke", {
        Color = Library.Theme[colorKey or "Outline"],
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
    Library:RegisterTheme(stroke, { Color = colorKey or "Outline" })
    return stroke
end

function Utility:AddPadding(parent, left, top, right, bottom)
    return self:Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        Parent = parent
    })
end

function Utility:AddList(parent, padding, fillDirection, horizontalAlignment)
    return self:Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = fillDirection or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
        Parent = parent
    })
end

function Utility:TextLabel(properties)
    local label = self:Create("TextLabel", merge({
        BackgroundTransparency = 1,
        Font = Library.Theme.Font,
        TextSize = Library.Theme.TextSize,
        TextColor3 = Library.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false
    }, properties))
    Library:RegisterTheme(label, { TextColor3 = "Text" })
    return label
end

function Utility:TextButton(properties)
    local button = self:Create("TextButton", merge({
        AutoButtonColor = false,
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        Font = Library.Theme.Font,
        TextSize = Library.Theme.TextSize,
        TextColor3 = Library.Theme.Text
    }, properties))
    Library:RegisterTheme(button, { BackgroundColor3 = "PanelLight", TextColor3 = "Text" })
    return button
end

function Utility:Frame(properties)
    local frame = self:Create("Frame", merge({
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0
    }, properties))
    Library:RegisterTheme(frame, { BackgroundColor3 = "Panel" })
    return frame
end

function Utility:GetTextBounds(text, size, font, width)
    local bounds = TextService:GetTextSize(tostring(text or ""), size or Library.Theme.TextSize, font or Library.Theme.Font, Vector2.new(width or 1000, 1000))
    return bounds.X, bounds.Y
end

function Utility:AutoCanvas(scrollingFrame, layout, extra)
    local function update()
        scrollingFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extra or 8))
    end
    update()
    self:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), update)
end

function Library:RegisterTheme(instance, properties)
    self.Registry[instance] = properties
end

function Library:UnregisterTheme(instance)
    self.Registry[instance] = nil
end

function Library:UpdateColors()
    for instance, properties in pairs(self.Registry) do
        if instance and instance.Parent then
            for property, themeKey in pairs(properties) do
                if self.Theme[themeKey] ~= nil then
                    pcall(function()
                        instance[property] = self.Theme[themeKey]
                    end)
                end
            end
        else
            self.Registry[instance] = nil
        end
    end
end

function Library:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if self.Theme[key] ~= nil then
            if typeof(self.Theme[key]) == "Color3" then
                self.Theme[key] = toColor(value, self.Theme[key])
            else
                self.Theme[key] = value
            end
        end
    end
    if self.Theme.Accent then
        local h, s, v = Color3.toHSV(self.Theme.Accent)
        self.Theme.AccentDark = Color3.fromHSV(h, s, math.max(0, v * 0.66))
    end
    self:UpdateColors()
end

function Library:GetTheme()
    local data = {}
    for key, value in pairs(self.Theme) do
        if typeof(value) == "Color3" then
            data[key] = colorToData(value)
        else
            data[key] = value
        end
    end
    return data
end

function Library:SafeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    if not self.NotifyOnError then
        return callback(...)
    end
    local ok, result = pcall(callback, ...)
    if not ok then
        self:Notify(tostring(result), 5, "Error")
    end
    return result
end

function Library:CanWriteFiles()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function Library:JSONEncode(value)
    return HttpService:JSONEncode(value)
end

function Library:JSONDecode(value)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(value)
    end)
    if ok then
        return result
    end
    return nil
end

function Library:GetGuiParent()
    if gethui then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end
    if syn and syn.protect_gui then
        return CoreGui
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

function Library:ProtectGui(gui)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    elseif protectgui then
        pcall(protectgui, gui)
    end
end

function Library:CreateScreenGui(name)
    local gui = Utility:Create("ScreenGui", {
        Name = name or "UniversalUILib",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })
    self:ProtectGui(gui)
    gui.Parent = self:GetGuiParent()
    self.ScreenGui = gui
    return gui
end

function Library:GetScreenGui()
    if self.ScreenGui and self.ScreenGui.Parent then
        return self.ScreenGui
    end
    return self:CreateScreenGui("UniversalUILib")
end

function Library:SetWatermark(text)
    if not self.Watermark then
        self:SetWatermarkVisibility(true)
    end
    self.Watermark.Label.Text = tostring(text or "")
    local x = Utility:GetTextBounds(self.Watermark.Label.Text, 13, self.Theme.Font)
    self.Watermark.Container.Size = UDim2.fromOffset(math.max(120, x + 18), 24)
end

function Library:SetWatermarkVisibility(visible)
    local gui = self:GetScreenGui()
    if not self.Watermark then
        local container = Utility:Frame({
            Name = "Watermark",
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.fromOffset(160, 24),
            BackgroundColor3 = self.Theme.Main,
            Parent = gui,
            ZIndex = 1000
        })
        Library:RegisterTheme(container, { BackgroundColor3 = "Main" })
        Utility:AddCorner(container, 4)
        Utility:AddStroke(container, "Accent", 1)
        Utility:AddPadding(container, 8, 0, 8, 0)
        local label = Utility:TextLabel({
            Size = UDim2.fromScale(1, 1),
            Text = self.Name,
            Parent = container,
            ZIndex = 1001
        })
        self.Watermark = { Container = container, Label = label }
    end
    self.Watermark.Container.Visible = visible == true
end

function Library:Notify(message, duration, title)
    duration = duration or 4
    local gui = self:GetScreenGui()
    if not self.NotificationHolder then
        local holder = Utility:Create("Frame", {
            Name = "Notifications",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 12),
            Size = UDim2.fromOffset(300, 600),
            Parent = gui,
            ZIndex = 2000
        })
        local layout = Utility:AddList(holder, 8)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        self.NotificationHolder = holder
    end

    local frame = Utility:Frame({
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(300, 58),
        BackgroundColor3 = self.Theme.Main,
        Parent = self.NotificationHolder,
        ZIndex = 2001
    })
    Library:RegisterTheme(frame, { BackgroundColor3 = "Main" })
    Utility:AddCorner(frame, 4)
    Utility:AddStroke(frame, "Outline", 1)
    Utility:AddPadding(frame, 10, 8, 10, 8)

    local titleLabel = Utility:TextLabel({
        Text = tostring(title or self.Name),
        Size = UDim2.new(1, -4, 0, 16),
        TextColor3 = self.Theme.Accent,
        Parent = frame,
        ZIndex = 2002
    })
    Library:RegisterTheme(titleLabel, { TextColor3 = "Accent" })

    local msg = Utility:TextLabel({
        Text = tostring(message or ""),
        Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, -4, 0, 30),
        TextWrapped = true,
        TextColor3 = self.Theme.Text,
        Parent = frame,
        ZIndex = 2002
    })
    Library:RegisterTheme(msg, { TextColor3 = "Text" })

    frame.Position = UDim2.fromOffset(340, 0)
    frame.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    msg.TextTransparency = 1
    Utility:Tween(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 0
    })
    Utility:Tween(titleLabel, TweenInfo.new(0.18), { TextTransparency = 0 })
    Utility:Tween(msg, TweenInfo.new(0.18), { TextTransparency = 0 })

    task.delay(duration, function()
        if frame.Parent then
            Utility:Tween(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.fromOffset(340, 0),
                BackgroundTransparency = 1
            })
            Utility:Tween(titleLabel, TweenInfo.new(0.18), { TextTransparency = 1 })
            Utility:Tween(msg, TweenInfo.new(0.18), { TextTransparency = 1 })
            task.wait(0.2)
            frame:Destroy()
        end
    end)
    return frame
end

function Library:OnUnload(callback)
    table.insert(self.UnloadCallbacks, callback)
end

function Library:AttemptSave()
    local saveManager = self.SaveManager
    if not saveManager or saveManager.Loading or not saveManager.AutoSave then
        return
    end
    if saveManager.QueueSave then
        saveManager:QueueSave()
    elseif saveManager.Save then
        saveManager:Save(nil, true)
    end
end

function Library:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    for _, callback in ipairs(self.UnloadCallbacks) do
        self:SafeCallback(callback)
    end
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    for index in pairs(self.Connections) do
        self.Connections[index] = nil
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function Library:SetOpen(frame, open, owner)
    if not frame then
        return
    end
    self.OpenFrames[frame] = open and true or nil
    self.OpenFrameOwners[frame] = open and owner or nil
end

function Library:CloseOpenFrames(except)
    for frame in pairs(self.OpenFrames) do
        if frame ~= except and frame.Parent then
            frame.Visible = false
            self.OpenFrames[frame] = nil
            self.OpenFrameOwners[frame] = nil
        end
    end
end

function Library:UpdateDependencyBoxes()
    for _, box in ipairs(self.DependencyBoxes) do
        box:Update()
    end
end

function BaseControl:OnChanged(callback)
    table.insert(self.Callbacks, callback)
    return self
end

function BaseControl:Fire(...)
    for _, callback in ipairs(self.Callbacks) do
        Library:SafeCallback(callback, ...)
    end
    if self.Callback then
        Library:SafeCallback(self.Callback, ...)
    end
    Library:UpdateDependencyBoxes()
    Library:AttemptSave()
end

function BaseControl:SetVisible(visible)
    if self.Container then
        self.Container.Visible = visible == true
    end
    return self
end

function BaseControl:SetDisabled(disabled)
    self.Disabled = disabled == true
    if self.Container then
        self.Container.BackgroundTransparency = self.Disabled and 0.45 or 0
    end
    return self
end

local function newControl(kind, index, info, container)
    local control = setmetatable({
        Kind = kind,
        Index = index,
        Info = info or {},
        Callback = info and info.Callback,
        Callbacks = {},
        Container = container,
        Disabled = false
    }, BaseControl)
    return control
end

local function addTooltip(text, hoverObject)
    if not text or text == "" then
        return
    end
    Utility:Connect(hoverObject.MouseEnter, function()
        local gui = Library:GetScreenGui()
        if Library.Tooltip and Library.Tooltip.Parent then
            Library.Tooltip:Destroy()
        end
        local width, height = Utility:GetTextBounds(text, 12, Library.Theme.Font, 260)
        local tooltip = Utility:Frame({
            Name = "Tooltip",
            Size = UDim2.fromOffset(math.min(280, width + 16), height + 12),
            BackgroundColor3 = Library.Theme.Main,
            Parent = gui,
            ZIndex = 3000
        })
        Library:RegisterTheme(tooltip, { BackgroundColor3 = "Main" })
        Utility:AddCorner(tooltip, 4)
        Utility:AddStroke(tooltip, "Outline", 1)
        Utility:AddPadding(tooltip, 8, 6, 8, 6)
        Utility:TextLabel({
            Text = text,
            TextWrapped = true,
            Size = UDim2.fromScale(1, 1),
            Parent = tooltip,
            ZIndex = 3001
        })
        Library.Tooltip = tooltip
        local function update()
            if tooltip.Parent then
                local mouse = getMouseLocation()
                tooltip.Position = UDim2.fromOffset(mouse.X + 12, mouse.Y + 10)
            end
        end
        update()
        local conn
        conn = RunService.RenderStepped:Connect(update)
        Utility:Connect(tooltip.AncestryChanged, function(_, parent)
            if not parent and conn then
                conn:Disconnect()
                conn = nil
            end
        end)
    end)
    Utility:Connect(hoverObject.MouseLeave, function()
        if Library.Tooltip and Library.Tooltip.Parent then
            Library.Tooltip:Destroy()
            Library.Tooltip = nil
        end
    end)
end

local function createControlContainer(parent, height)
    local container = Utility:Frame({
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 28),
        Parent = parent
    })
    Library:RegisterTheme(container, {})
    return container
end

local GroupMethods = {}
GroupMethods.__index = GroupMethods

local TabMethods = {}
TabMethods.__index = TabMethods

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabBoxMethods = {}
TabBoxMethods.__index = TabBoxMethods

local LabelMethods = {}
LabelMethods.__index = LabelMethods

local DependencyBoxMethods = {}
DependencyBoxMethods.__index = DependencyBoxMethods

local function attachControlMethods(target)
    for key, value in pairs(GroupMethods) do
        if key:sub(1, 3) == "Add" then
            target[key] = value
        end
    end
end

local function makeGroup(parent, title)
    local group = setmetatable({
        Title = title or "Groupbox",
        Controls = {}
    }, GroupMethods)

    local outer = Utility:Frame({
        Name = safeName(title or "Groupbox"),
        Size = UDim2.new(1, 0, 0, 80),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.Theme.Panel,
        Parent = parent
    })
    Library:RegisterTheme(outer, { BackgroundColor3 = "Panel" })
    Utility:AddCorner(outer, 4)
    Utility:AddStroke(outer, "Outline", 1)

    local titleLabel = Utility:TextLabel({
        Text = title or "Groupbox",
        TextColor3 = Library.Theme.Accent,
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.fromOffset(8, 0),
        Parent = outer
    })
    Library:RegisterTheme(titleLabel, { TextColor3 = "Accent" })

    local content = Utility:Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 28),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = outer
    })
    local layout = Utility:AddList(content, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Utility:AddPadding(content, 0, 0, 0, 8)

    group.Container = outer
    group.Content = content
    group.Layout = layout
    return group
end

local function makeColumn(parent)
    local column = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent
    })
    local layout = Utility:AddList(column, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    return column
end

function GroupMethods:AddLabel(text, wrap)
    local height = wrap and math.max(24, select(2, Utility:GetTextBounds(text, 13, Library.Theme.Font, 260)) + 8) or 22
    local container = createControlContainer(self.Content, height)
    local label = Utility:TextLabel({
        Text = tostring(text or ""),
        TextWrapped = wrap == true,
        Size = UDim2.fromScale(1, 1),
        Parent = container
    })
    local object = setmetatable({
        Container = container,
        Label = label,
        Text = text
    }, LabelMethods)
    table.insert(self.Controls, object)
    return object
end

function LabelMethods:SetText(text)
    self.Text = tostring(text or "")
    self.Label.Text = self.Text
    return self
end

function GroupMethods:AddDivider()
    local container = createControlContainer(self.Content, 9)
    local line = Utility:Create("Frame", {
        BackgroundColor3 = Library.Theme.Outline,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = container
    })
    Library:RegisterTheme(line, { BackgroundColor3 = "Outline" })
    return line
end

function GroupMethods:AddButton(textOrInfo, callback)
    local info = type(textOrInfo) == "table" and textOrInfo or { Text = tostring(textOrInfo or "Button"), Func = callback }
    local container = createControlContainer(self.Content, 30)
    local button = Utility:TextButton({
        Text = info.Text or "Button",
        Size = UDim2.fromScale(1, 1),
        Parent = container
    })
    Utility:AddCorner(button, 4)
    Utility:AddStroke(button, "Outline", 1)
    addTooltip(info.Tooltip, button)

    local object = newControl("Button", nil, { Callback = info.Func }, container)
    object.Button = button
    object.SubButtons = {}
    object.LastClick = 0

    function object:AddButton(subInfo)
        subInfo = type(subInfo) == "table" and subInfo or { Text = tostring(subInfo or "Button") }
        local sub = GroupMethods.AddButton(self.__Group, subInfo)
        table.insert(self.SubButtons, sub)
        return sub
    end
    object.__Group = self

    Utility:Connect(button.MouseButton1Click, function()
        if object.Disabled then
            return
        end
        if info.DoubleClick then
            local now = os.clock()
            if now - object.LastClick > 0.45 then
                object.LastClick = now
                button.Text = "Confirm"
                task.delay(0.6, function()
                    if button.Parent then
                        button.Text = info.Text or "Button"
                    end
                end)
                return
            end
        end
        object:Fire()
    end)
    table.insert(self.Controls, object)
    return object
end

function GroupMethods:AddToggle(index, info)
    info = info or {}
    local container = createControlContainer(self.Content, 26)
    local button = Utility:Create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        Parent = container
    })
    local box = Utility:Frame({
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(0, 4),
        BackgroundColor3 = Library.Theme.Background,
        Parent = button
    })
    Library:RegisterTheme(box, { BackgroundColor3 = "Background" })
    Utility:AddCorner(box, 3)
    Utility:AddStroke(box, "Outline", 1)
    local fill = Utility:Create("Frame", {
        Size = UDim2.new(1, -6, 1, -6),
        Position = UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
        BackgroundColor3 = Library.Theme.Accent,
        Visible = false,
        Parent = box
    })
    Library:RegisterTheme(fill, { BackgroundColor3 = "Accent" })
    Utility:AddCorner(fill, 2)
    local label = Utility:TextLabel({
        Text = info.Text or tostring(index),
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -26, 1, 0),
        Parent = button
    })
    addTooltip(info.Tooltip, button)

    local object = newControl("Toggle", index, info, container)
    object.Value = info.Default == true
    object.Button = button
    object.Fill = fill
    object.Label = label
    object.AddColorPicker = LabelMethods.AddColorPicker
    object.AddKeyPicker = LabelMethods.AddKeyPicker

    function object:SetValue(value, silent)
        value = value == true
        if self.Value == value and not silent then
            return self
        end
        self.Value = value
        self.Fill.Visible = value
        if Toggles[index] == self then
            Toggles[index].Value = value
        end
        if not silent then
            self:Fire(value)
        end
        return self
    end

    Utility:Connect(button.MouseButton1Click, function()
        if object.Disabled then
            return
        end
        object:SetValue(not object.Value)
    end)

    Toggles[index] = object
    object:SetValue(object.Value, true)
    table.insert(self.Controls, object)
    return object
end

function GroupMethods:AddSlider(index, info)
    info = info or {}
    local min = tonumber(info.Min) or 0
    local max = tonumber(info.Max) or 100
    local rounding = tonumber(info.Rounding) or 0
    local container = createControlContainer(self.Content, info.Compact and 28 or 42)
    local label
    if not info.Compact then
        label = Utility:TextLabel({
            Text = info.Text or tostring(index),
            Size = UDim2.new(1, -80, 0, 18),
            Parent = container
        })
    end
    local valueLabel = Utility:TextLabel({
        Text = "",
        Size = UDim2.fromOffset(78, 18),
        Position = UDim2.new(1, -78, 0, info.Compact and 0 or 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    local barY = info.Compact and 10 or 26
    local bar = Utility:Frame({
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.fromOffset(0, barY),
        BackgroundColor3 = Library.Theme.Background,
        Parent = container
    })
    Library:RegisterTheme(bar, { BackgroundColor3 = "Background" })
    Utility:AddCorner(bar, 4)
    Utility:AddStroke(bar, "Outline", 1)
    local fill = Utility:Frame({
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Library.Theme.Accent,
        Parent = bar
    })
    Library:RegisterTheme(fill, { BackgroundColor3 = "Accent" })
    Utility:AddCorner(fill, 4)
    addTooltip(info.Tooltip, container)

    local object = newControl("Slider", index, info, container)
    object.Value = clamp(info.Default or min, min, max)
    object.Min = min
    object.Max = max
    object.Rounding = rounding
    object.Suffix = info.Suffix or ""
    object.HideMax = info.HideMax == true
    object.Label = label
    object.ValueLabel = valueLabel
    object.Bar = bar
    object.Fill = fill

    local function valueText(value)
        local rendered = tostring(value) .. object.Suffix
        if not object.HideMax then
            rendered = rendered .. " / " .. tostring(max) .. object.Suffix
        end
        return rendered
    end

    function object:SetValue(value, silent)
        value = roundTo(clamp(value, self.Min, self.Max), self.Rounding)
        self.Value = value
        local pct = (value - self.Min) / (self.Max - self.Min)
        self.Fill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
        self.ValueLabel.Text = valueText(value)
        if not silent then
            self:Fire(value)
        end
        return self
    end

    local dragging = false
    local function setFromMouse()
        local mouse = getMouseLocation()
        local x = math.clamp((mouse.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        object:SetValue(min + (max - min) * x)
    end
    Utility:Connect(bar.InputBegan, function(input)
        if object.Disabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromMouse()
        end
    end)
    Utility:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromMouse()
        end
    end)
    Utility:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Options[index] = object
    object:SetValue(object.Value, true)
    table.insert(self.Controls, object)
    return object
end

function GroupMethods:AddInput(index, info)
    info = info or {}
    local container = createControlContainer(self.Content, 48)
    local label = Utility:TextLabel({
        Text = info.Text or tostring(index),
        Size = UDim2.new(1, 0, 0, 18),
        Parent = container
    })
    local box = Utility:Create("TextBox", {
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Library.Theme.Font,
        TextSize = Library.Theme.TextSize,
        TextColor3 = Library.Theme.Text,
        PlaceholderColor3 = Library.Theme.MutedText,
        PlaceholderText = info.Placeholder or "",
        Text = tostring(info.Default or ""),
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 22),
        Parent = container
    })
    Library:RegisterTheme(box, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "MutedText" })
    Utility:AddCorner(box, 4)
    Utility:AddStroke(box, "Outline", 1)
    addTooltip(info.Tooltip, box)

    local object = newControl("Input", index, info, container)
    object.Value = tostring(info.Default or "")
    object.TextBox = box
    object.Label = label
    object.Numeric = info.Numeric == true
    object.Finished = info.Finished == true
    object.MaxLength = info.MaxLength

    local function sanitize(value)
        value = tostring(value or "")
        if object.Numeric then
            value = value:gsub("[^%d%-%+%.]", "")
        end
        if object.MaxLength and #value > object.MaxLength then
            value = value:sub(1, object.MaxLength)
        end
        return value
    end

    function object:SetValue(value, silent)
        value = sanitize(value)
        self.Value = value
        self.TextBox.Text = value
        if not silent then
            self:Fire(value)
        end
        return self
    end

    Utility:Connect(box:GetPropertyChangedSignal("Text"), function()
        if object.Disabled then
            return
        end
        local sanitized = sanitize(box.Text)
        if sanitized ~= box.Text then
            box.Text = sanitized
            return
        end
        if not object.Finished then
            object:SetValue(box.Text)
        end
    end)
    Utility:Connect(box.FocusLost, function(enterPressed)
        if object.Finished and (enterPressed or info.FinishedOnly ~= true) then
            object:SetValue(box.Text)
        end
    end)

    Options[index] = object
    object:SetValue(object.Value, true)
    table.insert(self.Controls, object)
    return object
end

local function normalizeDropdownValue(info, value)
    local values = info.Values or {}
    if info.Multi then
        local selected = {}
        if type(value) == "table" then
            for key, enabled in pairs(value) do
                if type(key) == "number" and enabled ~= false then
                    selected[tostring(enabled)] = true
                elseif enabled == true then
                    selected[tostring(key)] = true
                end
            end
            return selected
        end
        if value ~= nil then
            selected[tostring(value)] = true
        end
        return selected
    end
    if type(value) == "number" then
        return values[value]
    end
    if value == nil then
        return values[1]
    end
    return value
end

function GroupMethods:AddDropdown(index, info)
    info = info or {}
    info.Values = info.Values or {}
    local container = createControlContainer(self.Content, 48)
    local label = Utility:TextLabel({
        Text = info.Text or tostring(index),
        Size = UDim2.new(1, 0, 0, 18),
        Parent = container
    })
    local button = Utility:TextButton({
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 22),
        BackgroundColor3 = Library.Theme.Background,
        Parent = container
    })
    Library:RegisterTheme(button, { BackgroundColor3 = "Background", TextColor3 = "Text" })
    Utility:AddCorner(button, 4)
    Utility:AddStroke(button, "Outline", 1)
    Utility:AddPadding(button, 8, 0, 24, 0)
    local arrow = Utility:TextLabel({
        Text = "v",
        Size = UDim2.fromOffset(18, 24),
        Position = UDim2.new(1, -20, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = container
    })
    local popup = Utility:Frame({
        Name = safeName(index) .. "_Dropdown",
        Visible = false,
        Size = UDim2.fromOffset(220, 120),
        BackgroundColor3 = Library.Theme.Main,
        Parent = Library:GetScreenGui(),
        ZIndex = 2500
    })
    Library:RegisterTheme(popup, { BackgroundColor3 = "Main" })
    Utility:AddCorner(popup, 4)
    Utility:AddStroke(popup, "Outline", 1)
    local list = Utility:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.Theme.Accent,
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.fromOffset(4, 4),
        CanvasSize = UDim2.fromOffset(0, 0),
        Parent = popup,
        ZIndex = 2501
    })
    Library:RegisterTheme(list, { ScrollBarImageColor3 = "Accent" })
    local listLayout = Utility:AddList(list, 3)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Utility:AutoCanvas(list, listLayout, 4)
    addTooltip(info.Tooltip, button)

    local object = newControl("Dropdown", index, info, container)
    object.Values = info.Values
    object.Multi = info.Multi == true
    object.Value = normalizeDropdownValue(object, info.Default)
    object.Button = button
    object.Popup = popup
    object.List = list
    object.Label = label
    object.OptionButtons = {}

    local function valueSummary(value)
        if object.Multi then
            local selected = {}
            for item, enabled in pairs(value or {}) do
                if enabled then
                    table.insert(selected, tostring(item))
                end
            end
            table.sort(selected)
            if #selected == 0 then
                return info.Placeholder or "None"
            end
            return table.concat(selected, ", ")
        end
        return tostring(value or info.Placeholder or "Select")
    end

    local function refreshButtons()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for key in pairs(object.OptionButtons) do
            object.OptionButtons[key] = nil
        end
        for _, item in ipairs(object.Values) do
            local itemKey = tostring(item)
            local itemButton = Utility:TextButton({
                Text = tostring(item),
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -2, 0, 24),
                BackgroundColor3 = Library.Theme.PanelLight,
                Parent = list,
                ZIndex = 2502
            })
            Library:RegisterTheme(itemButton, { BackgroundColor3 = "PanelLight", TextColor3 = "Text" })
            Utility:AddCorner(itemButton, 3)
            Utility:AddPadding(itemButton, 7, 0, 7, 0)
            object.OptionButtons[itemKey] = itemButton
            Utility:Connect(itemButton.MouseButton1Click, function()
                if object.Multi then
                    local newValue = {}
                    for key, enabled in pairs(object.Value or {}) do
                        newValue[key] = enabled
                    end
                    newValue[itemKey] = not newValue[itemKey]
                    object:SetValue(newValue)
                else
                    object:SetValue(item)
                    popup.Visible = false
                    Library:SetOpen(popup, false)
                end
            end)
        end
    end

    local function refreshSelectedVisuals()
        button.Text = "  " .. valueSummary(object.Value)
        for itemKey, itemButton in pairs(object.OptionButtons) do
            local selected = object.Multi and object.Value and object.Value[itemKey] == true or tostring(object.Value) == itemKey
            itemButton.TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text
        end
    end

    function object:SetValues(values)
        self.Values = values or {}
        refreshButtons()
        refreshSelectedVisuals()
        return self
    end

    function object:SetValue(value, silent)
        value = normalizeDropdownValue(self, value)
        if not self.Multi and not listContains(self.Values, value) and #self.Values > 0 then
            value = self.Values[1]
        end
        self.Value = value
        refreshSelectedVisuals()
        if not silent then
            self:Fire(value)
        end
        return self
    end

    Utility:Connect(button.MouseButton1Click, function()
        if object.Disabled then
            return
        end
        local visible = not popup.Visible
        Library:CloseOpenFrames(popup)
        popup.Visible = visible
        Library:SetOpen(popup, visible, button)
        if visible then
            local abs = button.AbsolutePosition
            popup.Position = UDim2.fromOffset(abs.X, abs.Y + button.AbsoluteSize.Y + 4)
            popup.Size = UDim2.fromOffset(math.max(button.AbsoluteSize.X, 180), math.min(180, 8 + (#object.Values * 27)))
        end
    end)

    refreshButtons()
    Options[index] = object
    object:SetValue(object.Value, true)
    table.insert(self.Controls, object)
    return object
end

function LabelMethods:AddColorPicker(index, info)
    info = info or {}
    local holder = self.Container or self.Button or self
    local pickerButton = Utility:TextButton({
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 18),
        BackgroundColor3 = toColor(info.Default, Library.Theme.Accent),
        Parent = holder
    })
    Utility:AddCorner(pickerButton, 3)
    Utility:AddStroke(pickerButton, "Outline", 1)
    local popup = Utility:Frame({
        Name = safeName(index) .. "_ColorPicker",
        Visible = false,
        Size = UDim2.fromOffset(230, 170),
        BackgroundColor3 = Library.Theme.Main,
        Parent = Library:GetScreenGui(),
        ZIndex = 2600
    })
    Library:RegisterTheme(popup, { BackgroundColor3 = "Main" })
    Utility:AddCorner(popup, 4)
    Utility:AddStroke(popup, "Outline", 1)
    Utility:AddPadding(popup, 10, 8, 10, 8)
    local title = Utility:TextLabel({
        Text = info.Title or "Color",
        Size = UDim2.new(1, 0, 0, 18),
        TextColor3 = Library.Theme.Accent,
        Parent = popup,
        ZIndex = 2601
    })
    Library:RegisterTheme(title, { TextColor3 = "Accent" })

    local object = newControl("ColorPicker", index, info, holder)
    object.Value = toColor(info.Default, Library.Theme.Accent)
    object.Transparency = info.Transparency
    object.Button = pickerButton
    object.Popup = popup
    object.Sliders = {}

    local function addColorSlider(name, y, default, max)
        local lbl = Utility:TextLabel({
            Text = name,
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.fromOffset(22, 20),
            Parent = popup,
            ZIndex = 2601
        })
        local box = Utility:Create("TextBox", {
            BackgroundColor3 = Library.Theme.Background,
            BorderSizePixel = 0,
            Font = Library.Theme.Font,
            TextSize = 12,
            TextColor3 = Library.Theme.Text,
            Text = tostring(default),
            Position = UDim2.fromOffset(28, y),
            Size = UDim2.fromOffset(54, 20),
            Parent = popup,
            ZIndex = 2601
        })
        Library:RegisterTheme(box, { BackgroundColor3 = "Background", TextColor3 = "Text" })
        Utility:AddCorner(box, 3)
        Utility:AddStroke(box, "Outline", 1)
        local bar = Utility:Frame({
            BackgroundColor3 = Library.Theme.Background,
            Position = UDim2.fromOffset(90, y + 6),
            Size = UDim2.new(1, -90, 0, 8),
            Parent = popup,
            ZIndex = 2601
        })
        Library:RegisterTheme(bar, { BackgroundColor3 = "Background" })
        Utility:AddCorner(bar, 4)
        local fill = Utility:Frame({
            BackgroundColor3 = Library.Theme.Accent,
            Size = UDim2.fromScale(default / max, 1),
            Parent = bar,
            ZIndex = 2602
        })
        Library:RegisterTheme(fill, { BackgroundColor3 = "Accent" })
        Utility:AddCorner(fill, 4)
        local data = { Box = box, Bar = bar, Fill = fill, Max = max, Value = default }
        object.Sliders[name] = data
        local function set(v, noObjectUpdate)
            v = math.floor(clamp(v, 0, max))
            data.Value = v
            data.Box.Text = tostring(v)
            data.Fill.Size = UDim2.fromScale(v / max, 1)
            if not noObjectUpdate then
                if name == "A" then
                    object.Transparency = v / 100
                    object:Fire(object.Value)
                else
                    object:SetValue(Color3.fromRGB(object.Sliders.R.Value, object.Sliders.G.Value, object.Sliders.B.Value))
                end
            end
        end
        Utility:Connect(box.FocusLost, function()
            set(tonumber(box.Text) or 0)
        end)
        local dragging = false
        local function fromMouse()
            local mouse = getMouseLocation()
            set(((mouse.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)) * max)
        end
        Utility:Connect(bar.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                fromMouse()
            end
        end)
        Utility:Connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromMouse()
            end
        end)
        Utility:Connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        data.Set = set
        return data
    end

    addColorSlider("R", 32, math.floor(object.Value.R * 255), 255)
    addColorSlider("G", 62, math.floor(object.Value.G * 255), 255)
    addColorSlider("B", 92, math.floor(object.Value.B * 255), 255)
    if info.Transparency ~= nil then
        addColorSlider("A", 122, math.floor((info.Transparency or 0) * 100), 100)
    end

    function object:SetValue(value, silent)
        value = toColor(value, self.Value)
        self.Value = value
        self.Button.BackgroundColor3 = value
        if self.Sliders.R then
            self.Sliders.R.Set(math.floor(value.R * 255), true)
            self.Sliders.G.Set(math.floor(value.G * 255), true)
            self.Sliders.B.Set(math.floor(value.B * 255), true)
        end
        if not silent then
            self:Fire(value)
        end
        return self
    end

    function object:SetValueRGB(value, silent)
        return self:SetValue(value, silent)
    end

    function object:SetTransparency(value, silent)
        self.Transparency = clamp(value, 0, 1)
        if self.Sliders.A then
            self.Sliders.A.Set(math.floor(self.Transparency * 100), true)
        end
        if not silent then
            self:Fire(self.Value)
        end
        return self
    end

    Utility:Connect(pickerButton.MouseButton1Click, function()
        local visible = not popup.Visible
        Library:CloseOpenFrames(popup)
        popup.Visible = visible
        Library:SetOpen(popup, visible, pickerButton)
        if visible then
            local abs = pickerButton.AbsolutePosition
            popup.Position = UDim2.fromOffset(abs.X - popup.AbsoluteSize.X + pickerButton.AbsoluteSize.X, abs.Y + 24)
        end
    end)

    Options[index] = object
    object:SetValue(object.Value, true)
    return object
end

function LabelMethods:AddKeyPicker(index, info)
    info = info or {}
    local holder = self.Container or self.Button or self
    local keyButton = Utility:TextButton({
        Text = tostring(info.Default or "None"),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(76, 20),
        BackgroundColor3 = Library.Theme.Background,
        Parent = holder
    })
    Library:RegisterTheme(keyButton, { BackgroundColor3 = "Background", TextColor3 = "Text" })
    Utility:AddCorner(keyButton, 3)
    Utility:AddStroke(keyButton, "Outline", 1)

    local object = newControl("KeyPicker", index, info, holder)
    object.Value = info.Default or "None"
    object.Mode = info.Mode or "Toggle"
    object.Text = info.Text or tostring(index)
    object.NoUI = info.NoUI == true
    object.SyncToggleState = info.SyncToggleState == true
    object.ParentToggle = self.Kind == "Toggle" and self or nil
    object.State = false
    object.Binding = false
    object.Button = keyButton
    object.ClickCallbacks = {}
    object.ChangedCallback = info.ChangedCallback

    function object:SetValue(value, silent)
        if type(value) == "table" then
            self.Value = value[1] or self.Value
            self.Mode = value[2] or self.Mode
        else
            self.Value = value
        end
        self.Button.Text = tostring(self.Value or "None")
        if not silent then
            if self.ChangedCallback then
                Library:SafeCallback(self.ChangedCallback, inputFromName(self.Value) or self.Value)
            end
            for _, callback in ipairs(self.Callbacks) do
                Library:SafeCallback(callback, self.Value)
            end
            Library:AttemptSave()
        end
        return self
    end

    function object:GetState()
        if self.Mode == "Always" then
            return true
        end
        return self.State == true
    end

    function object:SetState(state, fromInput)
        self.State = state == true
        if self.SyncToggleState and self.ParentToggle and self.ParentToggle.SetValue then
            self.ParentToggle:SetValue(self.State)
        end
        if fromInput then
            for _, callback in ipairs(self.ClickCallbacks) do
                Library:SafeCallback(callback, self.State)
            end
            if self.Callback then
                Library:SafeCallback(self.Callback, self.State)
            end
        end
        return self
    end

    function object:OnClick(callback)
        table.insert(self.ClickCallbacks, callback)
        return self
    end

    Utility:Connect(keyButton.MouseButton1Click, function()
        object.Binding = true
        keyButton.Text = "..."
    end)

    Utility:Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed and not info.IgnoreGameProcessed then
            return
        end
        if object.Binding then
            local newName = getInputName(input)
            if newName then
                object.Binding = false
                object:SetValue(newName)
            end
            return
        end
        if not isSameInput(input, object.Value) then
            return
        end
        if object.Mode == "Hold" then
            object:SetState(true, true)
        elseif object.Mode == "Toggle" then
            object:SetState(not object.State, true)
        elseif object.Mode == "Always" then
            object:SetState(true, true)
        end
    end)

    Utility:Connect(UserInputService.InputEnded, function(input)
        if isSameInput(input, object.Value) and object.Mode == "Hold" then
            object:SetState(false, true)
        end
    end)

    Options[index] = object
    object:SetValue({ object.Value, object.Mode }, true)
    if not object.NoUI then
        Library:AddKeybindToList(object)
    end
    return object
end

function GroupMethods:AddDependencyBox()
    local container = Utility:Frame({
        Name = "DependencyBox",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.Theme.PanelLight,
        Parent = self.Content
    })
    Library:RegisterTheme(container, { BackgroundColor3 = "PanelLight" })
    Utility:AddCorner(container, 4)
    Utility:AddStroke(container, "Outline", 1)
    Utility:AddPadding(container, 8, 8, 8, 8)
    local layout = Utility:AddList(container, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local box = setmetatable({
        Container = container,
        Content = container,
        Layout = layout,
        Controls = {},
        Dependencies = {}
    }, DependencyBoxMethods)
    attachControlMethods(box)
    table.insert(Library.DependencyBoxes, box)
    return box
end

function DependencyBoxMethods:SetupDependencies(dependencies)
    self.Dependencies = dependencies or {}
    self:Update()
    return self
end

function DependencyBoxMethods:Update()
    local visible = true
    for _, dep in ipairs(self.Dependencies or {}) do
        local control = dep[1]
        local expected = dep[2]
        if control and control.Value ~= expected then
            visible = false
            break
        end
    end
    self.Container.Visible = visible
    for _, child in ipairs(self.Controls or {}) do
        if child.Update then
            child:Update()
        end
    end
end

function TabBoxMethods:AddTab(name)
    local tab = setmetatable({
        Name = name,
        Controls = {}
    }, GroupMethods)
    local button = Utility:TextButton({
        Text = name,
        Size = UDim2.new(0, 90, 1, 0),
        BackgroundColor3 = Library.Theme.PanelLight,
        Parent = self.Buttons
    })
    Library:RegisterTheme(button, { BackgroundColor3 = "PanelLight", TextColor3 = "Text" })
    Utility:AddCorner(button, 3)
    local page = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Container
    })
    Utility:AddList(page, 6).HorizontalAlignment = Enum.HorizontalAlignment.Left
    tab.Container = page
    tab.Content = page
    tab.Layout = page:FindFirstChildOfClass("UIListLayout")
    self.Tabs[name] = tab
    Utility:Connect(button.MouseButton1Click, function()
        self:SelectTab(name)
    end)
    if not self.Selected then
        self:SelectTab(name)
    end
    return tab
end

function TabBoxMethods:SelectTab(name)
    self.Selected = name
    for tabName, tab in pairs(self.Tabs) do
        tab.Container.Visible = tabName == name
    end
end

local function addTabBox(tab, side)
    local column = side == "Right" and tab.RightColumn or tab.LeftColumn
    local box = Utility:Frame({
        Name = side .. "Tabbox",
        Size = UDim2.new(1, 0, 0, 160),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.Theme.Panel,
        Parent = column
    })
    Library:RegisterTheme(box, { BackgroundColor3 = "Panel" })
    Utility:AddCorner(box, 4)
    Utility:AddStroke(box, "Outline", 1)
    Utility:AddPadding(box, 8, 8, 8, 8)
    local buttons = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = box
    })
    Utility:AddList(buttons, 4, Enum.FillDirection.Horizontal)
    local tabbox = setmetatable({
        Container = box,
        Buttons = buttons,
        Tabs = {},
        Selected = nil
    }, TabBoxMethods)
    return tabbox
end

function TabMethods:AddLeftGroupbox(title)
    return makeGroup(self.LeftColumn, title)
end

function TabMethods:AddRightGroupbox(title)
    return makeGroup(self.RightColumn, title)
end

function TabMethods:AddLeftTabbox()
    return addTabBox(self, "Left")
end

function TabMethods:AddRightTabbox()
    return addTabBox(self, "Right")
end

function WindowMethods:AddTab(name)
    local tab = setmetatable({
        Name = name,
        Window = self
    }, TabMethods)
    local button = Utility:TextButton({
        Text = name,
        Size = UDim2.new(1, -8, 0, 28),
        BackgroundColor3 = Library.Theme.Panel,
        Parent = self.TabButtonHolder
    })
    Library:RegisterTheme(button, { BackgroundColor3 = "Panel", TextColor3 = "Text" })
    Utility:AddCorner(button, 4)
    Utility:AddPadding(button, 8, 0, 8, 0)

    local page = Utility:Create("ScrollingFrame", {
        Name = safeName(name),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Library.Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHolder
    })
    Library:RegisterTheme(page, { ScrollBarImageColor3 = "Accent" })
    local columns = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = page
    })
    Utility:AddPadding(columns, 2, 2, 2, 8)
    Utility:AddList(columns, 10, Enum.FillDirection.Horizontal)
    local left = makeColumn(columns)
    local right = makeColumn(columns)
    local columnsLayout = columns:FindFirstChildOfClass("UIListLayout")
    Utility:AutoCanvas(page, columnsLayout, 16)
    tab.Page = page
    tab.LeftColumn = left
    tab.RightColumn = right
    tab.Button = button

    self.Tabs[name] = tab
    Utility:Connect(button.MouseButton1Click, function()
        self:SelectTab(name)
    end)
    if not self.SelectedTab then
        self:SelectTab(name)
    end
    return tab
end

function WindowMethods:SelectTab(name)
    self.SelectedTab = name
    for tabName, tab in pairs(self.Tabs) do
        local selected = tabName == name
        tab.Page.Visible = selected
        tab.Button.BackgroundColor3 = selected and Library.Theme.AccentDark or Library.Theme.Panel
    end
end

function WindowMethods:SetVisible(visible)
    self.Visible = visible == true
    self.Frame.Visible = self.Visible
    return self
end

function WindowMethods:Toggle()
    return self:SetVisible(not self.Visible)
end

function WindowMethods:SetTitle(title)
    self.Title = tostring(title or "")
    self.TitleLabel.Text = self.Title
    return self
end

function WindowMethods:Destroy()
    if self.Frame then
        self.Frame:Destroy()
    end
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPos
    Utility:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    Utility:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Utility:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeResizable(frame, handle, minSize)
    minSize = minSize or Vector2.new(420, 320)
    local resizing = false
    local start
    local startSize
    Utility:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            start = input.Position
            startSize = frame.AbsoluteSize
        end
    end)
    Utility:Connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - start
            frame.Size = UDim2.fromOffset(math.max(minSize.X, startSize.X + delta.X), math.max(minSize.Y, startSize.Y + delta.Y))
        end
    end)
    Utility:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
end

function Library:AddKeybindToList(keybind)
    if not self.KeybindFrame then
        local gui = self:GetScreenGui()
        local frame = Utility:Frame({
            Name = "Keybinds",
            Position = UDim2.new(1, -190, 0, 120),
            Size = UDim2.fromOffset(178, 32),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Theme.Main,
            Parent = gui,
            Visible = false,
            ZIndex = 1200
        })
        Library:RegisterTheme(frame, { BackgroundColor3 = "Main" })
        Utility:AddCorner(frame, 4)
        Utility:AddStroke(frame, "Outline", 1)
        Utility:AddPadding(frame, 8, 6, 8, 6)
        local title = Utility:TextLabel({
            Text = "Keybinds",
            Size = UDim2.new(1, 0, 0, 18),
            TextColor3 = self.Theme.Accent,
            Parent = frame,
            ZIndex = 1201
        })
        Library:RegisterTheme(title, { TextColor3 = "Accent" })
        local content = Utility:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = frame,
            ZIndex = 1201
        })
        Utility:AddList(content, 3)
        self.KeybindFrame = frame
        self.KeybindContent = content
    end
    local row = Utility:TextLabel({
        Text = keybind.Text .. " [" .. tostring(keybind.Value) .. "]",
        Size = UDim2.new(1, 0, 0, 18),
        Parent = self.KeybindContent,
        ZIndex = 1202
    })
    keybind.KeybindListLabel = row
    keybind:OnChanged(function()
        if row.Parent then
            row.Text = keybind.Text .. " [" .. tostring(keybind.Value) .. "]"
        end
    end)
end

function Library:CreateWindow(options)
    options = type(options) == "table" and options or { Title = tostring(options or self.Name) }
    local gui = self:GetScreenGui()
    local size = options.Size or DEFAULT_WINDOW_SIZE
    local position = options.Position or DEFAULT_WINDOW_POSITION
    local frame = Utility:Frame({
        Name = safeName(options.Title or self.Name),
        Size = UDim2.fromOffset(size.X, size.Y),
        Position = options.Center and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(position.X, position.Y),
        AnchorPoint = options.Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        BackgroundColor3 = self.Theme.Background,
        Parent = gui,
        Visible = options.AutoShow == true
    })
    Library:RegisterTheme(frame, { BackgroundColor3 = "Background" })
    Utility:AddCorner(frame, 5)
    Utility:AddStroke(frame, "Outline", 1)

    local topbar = Utility:Frame({
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.Theme.Main,
        Parent = frame
    })
    Library:RegisterTheme(topbar, { BackgroundColor3 = "Main" })
    Utility:AddCorner(topbar, 5)

    local title = Utility:TextLabel({
        Text = options.Title or self.Name,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -48, 1, 0),
        TextColor3 = self.Theme.Text,
        Parent = topbar
    })
    Library:RegisterTheme(title, { TextColor3 = "Text" })
    local close = Utility:TextButton({
        Text = "x",
        Size = UDim2.fromOffset(30, 26),
        Position = UDim2.new(1, -34, 0, 5),
        BackgroundColor3 = self.Theme.Panel,
        Parent = topbar
    })
    Library:RegisterTheme(close, { BackgroundColor3 = "Panel", TextColor3 = "Text" })
    Utility:AddCorner(close, 4)

    local body = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 44),
        Size = UDim2.new(1, -16, 1, -52),
        Parent = frame
    })
    local sidebar = Utility:Frame({
        Name = "Tabs",
        Size = UDim2.fromOffset(options.TabWidth or 140, 1),
        BackgroundColor3 = self.Theme.Main,
        Parent = body
    })
    sidebar.Size = UDim2.new(0, options.TabWidth or 140, 1, 0)
    Library:RegisterTheme(sidebar, { BackgroundColor3 = "Main" })
    Utility:AddCorner(sidebar, 4)
    Utility:AddStroke(sidebar, "Outline", 1)
    Utility:AddPadding(sidebar, 6, 6, 6, 6)
    local tabButtons = Utility:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Accent,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.fromOffset(0, 0),
        Parent = sidebar
    })
    Library:RegisterTheme(tabButtons, { ScrollBarImageColor3 = "Accent" })
    local tabButtonLayout = Utility:AddList(tabButtons, options.TabPadding or 6)
    Utility:AutoCanvas(tabButtons, tabButtonLayout, 8)

    local pageHolder = Utility:Frame({
        Name = "Pages",
        Position = UDim2.fromOffset((options.TabWidth or 140) + 8, 0),
        Size = UDim2.new(1, -((options.TabWidth or 140) + 8), 1, 0),
        BackgroundTransparency = 1,
        Parent = body
    })
    Library:RegisterTheme(pageHolder, {})

    local resize = Utility:Create("TextButton", {
        Text = "",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(14, 14),
        Parent = frame
    })
    Library:RegisterTheme(resize, { BackgroundColor3 = "Accent" })
    Utility:AddCorner(resize, 3)

    local window = setmetatable({
        Title = options.Title or self.Name,
        Frame = frame,
        Topbar = topbar,
        TitleLabel = title,
        TabButtonHolder = tabButtons,
        PageHolder = pageHolder,
        Tabs = {},
        Visible = options.AutoShow == true,
        SelectedTab = nil
    }, WindowMethods)

    Utility:Connect(close.MouseButton1Click, function()
        window:SetVisible(false)
    end)
    makeDraggable(frame, topbar)
    makeResizable(frame, resize, Vector2.new(420, 320))

    if options.Keybind then
        self.ToggleKeybind = inputFromName(options.Keybind)
    end
    if not self.ToggleKeybind then
        self.ToggleKeybind = inputFromName("RightControl")
    end

    table.insert(self.Windows, window)
    return window
end

Utility:Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then
        return
    end
    local bind = Library.ToggleKeybind
    if type(bind) == "table" and bind.Value ~= nil then
        bind = bind.Value
    end
    if bind and isSameInput(input, bind) then
        local first = Library.Windows[1]
        if first then
            first:Toggle()
        end
    end
end)

Utility:Connect(UserInputService.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.defer(function()
            local mouse = getMouseLocation()
            for frame in pairs(Library.OpenFrames) do
                if frame.Parent and frame.Visible then
                    local owner = Library.OpenFrameOwners[frame]
                    local inside = isPointInsideGuiObject(frame, mouse) or isPointInsideGuiObject(owner, mouse)
                    if not inside then
                        frame.Visible = false
                        Library:SetOpen(frame, false)
                    end
                end
            end
        end)
    end
end)

Utility:Connect(RunService.RenderStepped, function(delta)
    Library.CurrentRainbowHue = (Library.CurrentRainbowHue + delta / 8) % 1
    Library.CurrentRainbowColor = Color3.fromHSV(Library.CurrentRainbowHue, 0.85, 1)
end)

return Library
