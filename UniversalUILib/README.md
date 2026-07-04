# UniversalUILib

UniversalUILib is a standalone Roblox Lua UI library with a Linoria-style workflow:

- `Library.lua` is the only required file.
- `addons/ThemeManager.lua` and `addons/SaveManager.lua` are optional.
- Designed for direct raw GitHub loading with `loadstring(game:HttpGet(...))()`.
- Works in exploit executors that expose `game:HttpGet`; it also avoids hard dependencies on executor-only file APIs.

This is an original implementation, not a fork or copy of LinoriaLib.

## Install

Upload this folder to a GitHub repository, then replace `OWNER` and `UniversalUILib` in the example URLs:

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalUILib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

If your repo is named differently, update the repo URL accordingly.

## Minimal Example

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalUILib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "My UI",
    Center = true,
    AutoShow = true,
    Keybind = "RightControl"
})

local Main = Window:AddTab("Main")
local Group = Main:AddLeftGroupbox("Controls")

Group:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end
})

Group:AddSlider("Speed", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0
})

Toggles.Enabled:OnChanged(function(value)
    print("Toggle value:", value)
end)

Options.Speed:OnChanged(function(value)
    print("Slider value:", value)
end)
```

## Core API

### Library

- `Library:CreateWindow(options)`
- `Library:Notify(message, duration, title)`
- `Library:SetWatermark(text)`
- `Library:SetWatermarkVisibility(visible)`
- `Library:SetTheme(themeTable)`
- `Library:GetTheme()`
- `Library:OnUnload(callback)`
- `Library:Unload()`

### Window

- `Window:AddTab(name)`
- `Window:SelectTab(name)`
- `Window:SetVisible(visible)`
- `Window:Toggle()`
- `Window:SetTitle(title)`
- `Window:Destroy()`

### Tab

- `Tab:AddLeftGroupbox(title)`
- `Tab:AddRightGroupbox(title)`
- `Tab:AddLeftTabbox()`
- `Tab:AddRightTabbox()`

### Groupbox and Tabbox Tabs

- `Groupbox:AddLabel(text, wrap)`
- `Groupbox:AddDivider()`
- `Groupbox:AddButton(info)`
- `Groupbox:AddToggle(index, info)`
- `Groupbox:AddSlider(index, info)`
- `Groupbox:AddInput(index, info)`
- `Groupbox:AddDropdown(index, info)`
- `Groupbox:AddDependencyBox()`

### Pickers

Labels and toggles can attach pickers:

```lua
Groupbox:AddLabel("Color"):AddColorPicker("AccentPicker", {
    Default = Color3.fromRGB(0, 170, 255),
    Callback = function(color) end
})

Groupbox:AddLabel("Bind"):AddKeyPicker("ActionBind", {
    Default = "F",
    Mode = "Toggle",
    Text = "Action"
})
```

### Globals

For Linoria-style ergonomics, controls are registered globally:

- `Toggles.MyToggle.Value`
- `Toggles.MyToggle:SetValue(true)`
- `Options.MySlider.Value`
- `Options.MySlider:SetValue(50)`
- `Options.MyDropdown:SetValues({ "A", "B", "C" })`
- `Options.MyKeybind:GetState()`

## Theme Manager

```lua
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("UniversalUILib")
ThemeManager:ApplyToTab(SettingsTab)
```

The theme manager includes built-in themes and can save custom themes when `writefile`, `readfile`, and `isfile` are available.

## Save Manager

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("UniversalUILib")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()
```

The save manager serializes toggles, options, dropdowns, text boxes, color pickers, and keybinds. If file APIs are unavailable, configs work in memory for the current session.

## Files

```text
Library.lua
Example.lua
addons/
  SaveManager.lua
  ThemeManager.lua
docs/
  API.md
LICENSE
README.md
```

## Notes

- This library only creates UI. It does not include game automation, bypasses, malware, DDoS code, keyloggers, or hidden telemetry.
- `RightControl` is the default menu toggle keybind.
- For production use, host from your own GitHub repo instead of a third-party raw URL.
