# API Reference

## Loading

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalUILib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
```

## CreateWindow

```lua
local Window = Library:CreateWindow({
    Title = "My Window",
    Center = true,
    AutoShow = true,
    Size = Vector2.new(620, 520),
    Position = Vector2.new(160, 120),
    TabWidth = 140,
    TabPadding = 6,
    Keybind = "RightControl"
})
```

Options:

- `Title`: window title.
- `Center`: centers the window on creation.
- `AutoShow`: shows the window immediately.
- `Size`: initial `Vector2` size.
- `Position`: initial `Vector2` position when `Center` is false.
- `TabWidth`: sidebar width.
- `TabPadding`: spacing between tab buttons.
- `Keybind`: key used to toggle the first window.

## Tabs

```lua
local Main = Window:AddTab("Main")
local Left = Main:AddLeftGroupbox("Left")
local Right = Main:AddRightGroupbox("Right")
```

## Labels and Dividers

```lua
Left:AddLabel("Plain label")
Left:AddLabel("Wrapped label text", true)
Left:AddDivider()
```

## Buttons

```lua
Left:AddButton({
    Text = "Run",
    Tooltip = "Runs a callback",
    DoubleClick = false,
    Func = function()
        print("clicked")
    end
})
```

## Toggles

```lua
Left:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Tooltip = "Example toggle",
    Callback = function(value)
        print(value)
    end
})

Toggles.Enabled:OnChanged(function(value)
    print("changed", value)
end)

Toggles.Enabled:SetValue(true)
```

## Sliders

```lua
Left:AddSlider("Amount", {
    Text = "Amount",
    Default = 10,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Compact = false,
    HideMax = false
})

Options.Amount:SetValue(50)
```

## Text Inputs

```lua
Left:AddInput("Name", {
    Text = "Name",
    Default = "",
    Placeholder = "Type here",
    Numeric = false,
    Finished = true,
    MaxLength = 32
})
```

## Dropdowns

```lua
Left:AddDropdown("Choice", {
    Text = "Choice",
    Values = { "A", "B", "C" },
    Default = 1,
    Multi = false
})

Options.Choice:SetValue("B")
Options.Choice:SetValues({ "A", "B", "C", "D" })
```

Multi dropdown:

```lua
Left:AddDropdown("Choices", {
    Text = "Choices",
    Values = { "A", "B", "C" },
    Multi = true,
    Default = { A = true }
})

Options.Choices:SetValue({ A = true, C = true })
```

## Color Pickers

```lua
Left:AddLabel("Color"):AddColorPicker("AccentColor", {
    Title = "Accent",
    Default = Color3.fromRGB(0, 170, 255),
    Transparency = 0,
    Callback = function(color)
        print(color)
    end
})

Options.AccentColor:SetValueRGB(Color3.fromRGB(255, 100, 100))
Options.AccentColor:SetTransparency(0.25)
```

## Key Pickers

```lua
Left:AddLabel("Bind"):AddKeyPicker("ActionBind", {
    Default = "F",
    Mode = "Toggle",
    Text = "Action",
    NoUI = false,
    SyncToggleState = false,
    Callback = function(state)
        print(state)
    end,
    ChangedCallback = function(key)
        print(key)
    end
})

Options.ActionBind:OnClick(function(state)
    print("clicked", state)
end)

Options.ActionBind:SetValue({ "G", "Hold" })
```

Modes:

- `Toggle`: each press flips state.
- `Hold`: state is true while the key is held.
- `Always`: state is always true.

## Dependency Boxes

```lua
Left:AddToggle("ShowAdvanced", {
    Text = "Show advanced"
})

local DepBox = Left:AddDependencyBox()
DepBox:AddSlider("AdvancedAmount", {
    Text = "Advanced amount",
    Default = 5,
    Min = 0,
    Max = 10,
    Rounding = 0
})

DepBox:SetupDependencies({
    { Toggles.ShowAdvanced, true }
})
```

## Tab Boxes

```lua
local Box = Main:AddRightTabbox()
local A = Box:AddTab("A")
local B = Box:AddTab("B")

A:AddToggle("AEnabled", { Text = "A enabled" })
B:AddToggle("BEnabled", { Text = "B enabled" })
```

## Library Helpers

```lua
Library:Notify("Message", 4, "Title")
Library:SetWatermarkVisibility(true)
Library:SetWatermark("My UI")
Library:OnUnload(function()
    print("unloaded")
end)
Library:Unload()
```

## Theme Table

```lua
Library:SetTheme({
    Accent = Color3.fromRGB(0, 170, 255),
    Background = Color3.fromRGB(17, 18, 22),
    Main = Color3.fromRGB(26, 27, 33),
    Panel = Color3.fromRGB(31, 33, 40),
    PanelLight = Color3.fromRGB(38, 41, 50),
    Outline = Color3.fromRGB(61, 65, 78),
    Text = Color3.fromRGB(240, 244, 248),
    MutedText = Color3.fromRGB(166, 173, 186),
    Risk = Color3.fromRGB(240, 80, 80)
})
```
