# UniversalESPLib

UniversalESPLib is a standalone Roblox Luau ESP library built around a modular target / provider / feature system, with a clean outlined visual style that stays readable on any background.

```lua
local repo = "https://raw.githubusercontent.com/xxxxssw/new-uigg/main/UniversalESPLib/"
local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()

ESP:Start()
```

For the full experience (menu, keybinds, saved configs) run `Example.lua`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xxxxssw/new-uigg/main/UniversalESPLib/Example.lua"))()
```

This is a visualization library only. It does not include aimbot logic, remote spam, DDoS code, malware, keyloggers, webhooks, token collection, or hidden telemetry.

## What it looks like

- Every shape is drawn twice: a dark outline underneath and the colored shape on top, so boxes, tracers and skeletons never disappear against bright or dark scenes.
- Corner boxes fit the rig precisely (body parts only, accessories ignored) and snap to whole pixels so 1px lines stay crisp.
- Translucent box fill, outlined health bar with a red → yellow → green gradient and a health number that follows the bar.
- White outlined text for names, distance and tools; text can optionally scale down with distance.
- Targets fade in on spawn and fade out when they die, leave range or get filtered, instead of popping.
- Optional visible check turns the target green when there is line of sight.
- Off-screen arrows, chams (`Highlight`), skeletons, head dots, look lines, 3D boxes, tracers and a radar module.

## Features

- Player ESP provider included by default.
- Manual object / model / part tracking.
- CollectionService tag tracking and folder / descendant tracking.
- Optional NPC provider module for non-player Humanoid models.
- Drawing API renderer with a ScreenGui fallback.
- Corner / full 2D boxes, oriented 3D boxes, box fill.
- Names, display names, health bars, health numbers, distance and equipped tool.
- Tracers with bottom / center / top / mouse origins.
- Skeleton ESP for R6 and R15 rigs.
- Chams via Roblox `Highlight`.
- Off-screen arrows, head dots, look direction lines.
- Visible check with its own color, team check, team colors, dead-target hiding.
- Smooth fade in / out and distance fade.
- Per-target setting overrides, feature registry, provider registry.
- Optional config manager and a complete menu for UniversalUILib.

## Files

```text
Library.lua
Example.lua
modules/
  NPCProvider.lua
  RadarFeature.lua
  TagProvider.lua
addons/
  ConfigManager.lua
  UILibBridge.lua
docs/
  API.md
LICENSE
README.md
```

## Quick Settings

```lua
ESP:SetSettings({
    TeamCheck = false,
    VisibleCheck = true,
    MaxDistance = 2500,

    Box = true,
    BoxStyle = "Corner",      -- Corner | Full
    BoxFill = true,
    Box3D = false,

    Name = true,
    HealthBar = true,
    HealthText = true,
    Distance = true,
    Tool = true,

    Tracer = false,
    Skeleton = false,
    Chams = false,
    OffscreenArrows = true
})
```

See `docs/API.md` for every setting.

## Track Custom Objects

```lua
ESP:Track(workspace.ObjectivePart, {
    Type = "Objective",
    Name = "Objective",
    Color = Color3.fromRGB(255, 120, 255),
    Box = true,
    Distance = true,
    Tracer = true
})
```

## Track Tagged Objects

```lua
local TagProvider = loadstring(game:HttpGet(repo .. "modules/TagProvider.lua"))()(ESP)

TagProvider:Start({
    Tag = "Loot",
    Type = "Loot",
    Color = Color3.fromRGB(120, 255, 160),
    Name = "Loot"
})
```

## NPC ESP

```lua
local NPCProvider = loadstring(game:HttpGet(repo .. "modules/NPCProvider.lua"))()(ESP)

NPCProvider:Start({
    Root = workspace,
    Type = "NPC",
    Color = Color3.fromRGB(255, 210, 90),
    OffscreenArrows = false
})
```

## Menu Integration

UniversalESPLib ships with a complete menu for the UniversalUILib in this repository:

```lua
local uiRepo = "https://raw.githubusercontent.com/xxxxssw/new-uigg/main/UniversalUILib/"
local Library = loadstring(game:HttpGet(uiRepo .. "Library.lua"))()
local Bridge = loadstring(game:HttpGet(repo .. "addons/UILibBridge.lua"))()

local Window = Library:CreateWindow({
    Title = "ESP",
    Center = true,
    AutoShow = true
})

Bridge:ApplyToTab(Window:AddTab("ESP"), ESP, { ToggleKey = "F2" })
```

Every control is registered with an `ESP_` prefix, so UniversalUILib's `SaveManager` saves and restores the whole ESP configuration. `Example.lua` wires all of it together.

## Custom Feature

```lua
ESP:RegisterFeature("MyFeature", {
    Order = 120,
    Create = function(feature, target, state, esp)
        state.Text = esp:CreateVisual("Text")
    end,
    Update = function(feature, target, state, context, esp)
        if not context.Draw then
            esp:HideVisual(state.Text)
            return
        end
        esp:DrawBottomText(state.Text, context, target.Type)
    end
})
```

## Custom Provider

```lua
ESP:RegisterProvider("MyProvider", {
    Start = function(provider, options)
        provider.Target = ESP:Track(workspace.SomePart, {
            Name = "Some Part",
            Color = Color3.fromRGB(255, 255, 0)
        })
    end,
    Stop = function(provider)
        if provider.Target then
            ESP:Untrack(provider.Target)
        end
    end
})

ESP:StartProvider("MyProvider")
```

## Notes

- The default provider tracks players when `ESP:Start()` is called.
- The Drawing API is used when available; otherwise ScreenGui objects are used.
- Settings can be global through `ESP:SetSettings(...)` or per-target through `ESP:Track(instance, options)`.
- `ESP:Unload()` removes drawings, GUI objects, highlights, targets and connections.
