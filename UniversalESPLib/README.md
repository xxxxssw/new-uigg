# UniversalESPLib

UniversalESPLib is a standalone Roblox Lua ESP library built around a modular target/provider/feature system.

It is designed for raw GitHub loading:

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalESPLib/main/"
local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()

ESP:Start()
```

This is a visualization library only. It does not include aimbot logic, remote spam, DDoS code, malware, keyloggers, webhooks, token collection, or hidden telemetry.

## Features

- Player ESP provider included by default.
- Manual object/model/part tracking.
- CollectionService tag tracking.
- Folder/descendant tracking.
- Optional NPC provider module for non-player Humanoid models.
- Drawing API renderer with GUI fallback.
- 2D corner/full boxes.
- 3D bounding boxes.
- Names and display names.
- Health bars and health text.
- Distance text.
- Equipped tool text.
- Tracers with bottom/center/top/mouse origins.
- Skeleton ESP for R6/R15 rigs.
- Chams via Roblox `Highlight`.
- Offscreen arrows.
- Head dots.
- Look direction lines.
- Optional radar feature module.
- Per-target setting overrides.
- Feature registry for custom visuals.
- Provider registry for custom target sources.
- Optional config manager.
- Optional bridge for the UniversalUILib menu library.

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

## Full Example

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalESPLib/main/"

local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()
local NPCProvider = loadstring(game:HttpGet(repo .. "modules/NPCProvider.lua"))()(ESP)
local RadarFeature = loadstring(game:HttpGet(repo .. "modules/RadarFeature.lua"))()(ESP)

ESP:SetSettings({
    TeamCheck = false,
    MaxDistance = 4500,
    Box = true,
    Name = true,
    HealthBar = true,
    Distance = true,
    Tool = true,
    OffscreenArrows = true,
    Skeleton = false,
    Chams = false,
    Tracer = false,
    Radar = false
})

ESP:Start()

NPCProvider:Start({
    Root = workspace,
    Type = "NPC",
    Color = Color3.fromRGB(255, 210, 90)
})
```

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

## UI Integration

UniversalESPLib can be controlled from the UniversalUILib menu:

```lua
local uiRepo = "https://raw.githubusercontent.com/OWNER/UniversalUILib/main/"
local Library = loadstring(game:HttpGet(uiRepo .. "Library.lua"))()
local Bridge = loadstring(game:HttpGet(repo .. "addons/UILibBridge.lua"))()

local Window = Library:CreateWindow({
    Title = "ESP",
    Center = true,
    AutoShow = true
})

local Tab = Window:AddTab("ESP")
Bridge:ApplyToTab(Tab, ESP)
```

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
        esp:SetVisual(state.Text, {
            Visible = true,
            Text = target.Type,
            Position = context.Bounds.Center,
            Center = true,
            Color = context.Color,
            Alpha = context.Alpha
        })
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

- Default provider tracks players when `ESP:Start()` is called.
- Drawing API is used when available. GUI fallback is used otherwise.
- Settings can be global through `ESP:SetSettings(...)` or per-target through `ESP:Track(instance, options)`.
- `ESP:Unload()` removes drawings, GUI objects, highlights, targets, and connections.
