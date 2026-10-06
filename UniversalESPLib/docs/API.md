# API Reference

## Loading

```lua
local repo = "https://raw.githubusercontent.com/xxxxssw/new-uigg/main/UniversalESPLib/"
local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()
```

## Lifecycle

```lua
ESP:Start()          -- starts the player provider and render loop
ESP:Enable()         -- enables rendering
ESP:Disable()        -- disables rendering and hides visuals
ESP:Toggle()
ESP:SetEnabled(true)
ESP:Unload()         -- disconnects and removes all ESP visuals
```

## Settings

```lua
ESP:SetSetting("Box", true)

ESP:SetSettings({
    TeamCheck = true,
    MaxDistance = 2500,
    Box = true,
    BoxStyle = "Corner",
    Name = true,
    HealthBar = true,
    Distance = true
})
```

### General

| Setting | Default | Description |
| --- | --- | --- |
| `Enabled` | `true` | Master switch. |
| `RenderMode` | `"Auto"` | `Auto`, `Drawing` or `Gui`. |
| `RefreshInterval` | `0` | Seconds between updates. `0` updates every frame. |
| `ShowLocalPlayer` | `false` | Draw the local player. |
| `ShowDead` | `false` | Keep drawing targets with 0 health. |
| `TeamCheck` | `false` | Hide players on the local team. |
| `UseTeamColor` | `false` | Color players by `TeamColor` instead of enemy / friendly colors. |
| `MaxDistance` | `2500` | Targets further than this are hidden. |
| `DistanceOrigin` | `"Character"` | Measure distance from `Character` or `Camera`. |
| `FadeDistance` | `true` | Far targets become more transparent. |
| `FadeSpeed` | `10` | Fade in / out speed (per second). |
| `Transparency` | `1` | Global opacity (1 = opaque). |
| `VisibleCheck` | `false` | Raycast from the camera and use `VisibleColor` when nothing is in the way. |
| `VisibleCheckInterval` | `0.08` | Seconds between raycasts per target. |

### Text

| Setting | Default | Description |
| --- | --- | --- |
| `TextSize` | `13` | Base text size. |
| `TextFont` | `2` | Drawing font id: `0` UI, `1` System, `2` Plex, `3` Monospace. |
| `TextOutline` | `true` | Outline text. |
| `TextUseTargetColor` | `false` | Color text like the target instead of `TextColor`. |
| `ScaleWithDistance` | `true` | Shrink text up to 30% for far targets. |

### Colors

| Setting | Default |
| --- | --- |
| `EnemyColor` | `255, 86, 86` |
| `FriendlyColor` | `96, 165, 250` |
| `NeutralColor` | `240, 240, 245` |
| `VisibleColor` | `120, 255, 170` |
| `TextColor` | `255, 255, 255` |
| `OutlineColor` | `0, 0, 0` |
| `Outline` | `true` (draw outlines under every shape) |
| `Rainbow` / `RainbowSpeed` | `false` / `1` |

### Box

| Setting | Default | Description |
| --- | --- | --- |
| `Box` | `true` | 2D box. |
| `BoxStyle` | `"Corner"` | `Corner` or `Full`. |
| `BoxMode` | `"Precise"` | `Precise` fits body parts; `Fast` uses a fixed box around the root part. |
| `BoxThickness` | `1` | Line thickness. |
| `BoxFill` | `true` | Translucent fill inside the box. |
| `BoxFillTransparency` | `0.9` | Fill transparency. |
| `Box3D` | `false` | Oriented 3D bounding box. |

### Labels

| Setting | Default | Description |
| --- | --- | --- |
| `Name` | `true` | Name above the box. |
| `DisplayName` | `true` | Show `DisplayName (@Name)`. |
| `HealthBar` | `true` | Vertical health bar. |
| `HealthBarSide` | `"Left"` | `Left` or `Right`. |
| `HealthBarWidth` | `2` | Bar width in pixels. |
| `HealthText` | `true` | Health number beside the bar when damaged. |
| `HealthTextAlways` | `false` | Always show the health number. |
| `Distance` | `true` | Distance below the box. |
| `DistanceUnit` | `"m"` | Suffix for the distance label. |
| `Tool` | `true` | Equipped tool name below the box. |

### Extras

| Setting | Default | Description |
| --- | --- | --- |
| `Tracer` | `false` | Line from `TracerOrigin` to the box. |
| `TracerOrigin` | `"Bottom"` | `Bottom`, `Center`, `Top` or `Mouse`. |
| `TracerThickness` | `1` | |
| `Skeleton` | `false` | Bone lines for R6 / R15. |
| `SkeletonThickness` | `1` | |
| `Chams` | `false` | `Highlight` through walls. |
| `ChamsOutline` | `true` | |
| `ChamsFillTransparency` | `0.6` | |
| `ChamsOutlineTransparency` | `0` | |
| `ChamsFillColor` / `ChamsOutlineColor` | `nil` | `nil` uses the target color. |
| `OffscreenArrows` | `true` | Arrows for targets outside the viewport. |
| `ArrowRadius` | `300` | Distance from the screen center. |
| `ArrowSize` | `14` | |
| `HeadDot` | `false` | Dot on the head. |
| `HeadDotRadius` | `3` | |
| `LookLine` | `false` | Line showing head direction. |
| `LookLineLength` | `8` | |

## Tracking

```lua
local target = ESP:Track(workspace.Part, {
    Type = "Objective",
    Name = "Objective",
    Color = Color3.fromRGB(255, 120, 255),
    Box = true,
    Distance = true,
    Tracer = true
})

ESP:Untrack(target)
```

Track a player:

```lua
ESP:TrackPlayer(game:GetService("Players").SomePlayer, {
    Color = Color3.fromRGB(255, 255, 0)
})
```

Track a folder:

```lua
ESP:TrackFolder(workspace.Items, {
    Type = "Item",
    Color = Color3.fromRGB(120, 255, 160),
    TrackFilter = function(instance)
        return instance:IsA("BasePart")
    end
})
```

Track a CollectionService tag:

```lua
ESP:TrackTag("Loot", {
    Type = "Loot",
    Name = "Loot",
    Color = Color3.fromRGB(120, 255, 160)
})
```

## Target Options

Per-target options override global settings:

```lua
ESP:Track(workspace.Boss, {
    Name = "Boss",
    Color = Color3.fromRGB(255, 80, 80),
    Chams = true,
    Skeleton = true,
    MaxDistance = 10000,
    Filter = function(target, info)
        return info.Health == nil or info.Health > 0
    end,
    GetName = function(target, info)
        return "Custom " .. target.Type
    end,
    GetColor = function(target)
        return Color3.fromRGB(255, 255, 0)
    end,
    GetHealth = function(target)
        return 50, 100
    end,
    GetAdornee = function(target)
        return target.Instance
    end
})
```

Provider selection uses `TrackFilter`; per-target render visibility uses `Filter`.

## Providers

```lua
ESP:RegisterProvider("MyProvider", {
    Start = function(provider, options)
        provider.Target = ESP:Track(workspace.Part, options)
    end,
    Stop = function(provider)
        ESP:Untrack(provider.Target)
    end
})

ESP:StartProvider("MyProvider", {
    Name = "Part",
    Color = Color3.fromRGB(255, 255, 0)
})

ESP:StopProvider("MyProvider")
```

Built-in provider:

- `Players`: starts automatically from `ESP:Start()`.

Optional provider modules:

- `modules/NPCProvider.lua`
- `modules/TagProvider.lua`

## Features

Feature modules get a per-target `state` table and a `context` table every frame.

```lua
ESP:RegisterFeature("MyFeature", {
    Order = 120,
    Create = function(feature, target, state, esp)
        state.Line = esp:CreateVisual("Line", true) -- true = outlined
    end,
    Update = function(feature, target, state, context, esp)
        if not context.Draw then
            esp:HideVisual(state.Line)
            return
        end

        esp:SetVisual(state.Line, {
            Visible = true,
            From = context.Bounds.Top,
            To = context.Bounds.Bottom,
            Color = context.Color,
            Alpha = context.Alpha,
            Thickness = 1
        })
    end,
    Destroy = function(feature, target, state, esp)
        esp:DestroyVisuals(state)
    end
})
```

### Context

| Field | Description |
| --- | --- |
| `Exists` | Target resolved to a part. |
| `Visible` | Passed distance / team / filter checks (or is still fading out). |
| `OnScreen` | Bounds are inside the viewport. |
| `Draw` | `Visible and OnScreen` — use this before drawing. |
| `Fade` | 0..1 fade progress. |
| `Camera`, `Distance`, `Info` | Camera, distance from `DistanceOrigin`, resolved target info. |
| `Bounds` | `Position`, `Size`, `Center`, `Top`, `Bottom`, `Root`, `RootDepth`, `Corners` (3D, when `Box3D`). |
| `Color`, `TextColor`, `Alpha` | Colors and opacity for this frame. |
| `TextSize`, `TextHeight` | Text size after distance scaling. |
| `VisibleToCamera` | Result of the visible check (`nil` when disabled). |
| `TopOffset`, `BottomOffset`, `LeftOffset`, `RightOffset` | Stacking offsets for labels around the box. |

Helpers for stacking labels:

```lua
esp:DrawTopText(state.Text, context, "above the box")
esp:DrawBottomText(state.Text, context, "below the box")
```

Built-in features (in draw order): `Box`, `Box3D`, `Name`, `HealthBar`, `Distance`, `Tool`, `Tracer`, `Skeleton`, `HeadDot`, `LookLine`, `OffscreenArrows`, `Chams`.

Optional feature modules:

- `modules/RadarFeature.lua`

## Visual API

```lua
local line = ESP:CreateVisual("Line", true)   -- outlined
local text = ESP:CreateVisual("Text")         -- text outlines itself

ESP:SetVisual(text, {
    Visible = true,
    Text = "Example",
    Position = Vector2.new(100, 100),
    Center = true,
    Color = Color3.fromRGB(255, 255, 255),
    Alpha = 1,
    Size = 13,
    ZIndex = 8
})

ESP:HideVisual(text)
ESP:RemoveVisual(text)
```

Supported visual kinds: `Text`, `Line`, `Square`, `Circle`, `Triangle`.

Properties: `Visible`, `Color`, `Alpha`, `ZIndex`, `Thickness`, `Filled`, `Position`, `Size`, `From`, `To`, `Radius`, `PointA/B/C`, `Text`, `Center`, `Font`, `Outline` (set `false` to skip the outline layer), `OutlineColor`.

## Config Manager

```lua
local ConfigManager = loadstring(game:HttpGet(repo .. "addons/ConfigManager.lua"))()

ConfigManager:SetLibrary(ESP)
ConfigManager:SetFolder("UniversalESPLib")
ConfigManager:Save("default")
ConfigManager:Load("default")
ConfigManager:SetAutoload("default")
ConfigManager:LoadAutoload()
```

## UI Bridge

```lua
local Bridge = loadstring(game:HttpGet(repo .. "addons/UILibBridge.lua"))()
Bridge:ApplyToTab(Tab, ESP, { ToggleKey = "F2" })
-- or
Bridge:ApplyToWindow(Window, ESP, { TabName = "ESP", ToggleKey = "F2" })
```
