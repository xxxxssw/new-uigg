# API Reference

## Loading

```lua
local repo = "https://raw.githubusercontent.com/OWNER/UniversalESPLib/main/"
local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()
```

## Lifecycle

```lua
ESP:Start()          -- starts player provider and render loop
ESP:Enable()         -- enables rendering
ESP:Disable()        -- disables rendering and hides visuals
ESP:SetEnabled(true)
ESP:Unload()         -- disconnects and removes all ESP visuals
```

## Settings

```lua
ESP:SetSetting("Box", true)

ESP:SetSettings({
    TeamCheck = true,
    MaxDistance = 5000,
    Box = true,
    BoxStyle = "Corner",
    Box3D = false,
    Name = true,
    HealthBar = true,
    HealthText = false,
    Distance = true,
    Tool = true,
    Tracer = false,
    Skeleton = false,
    Chams = false,
    OffscreenArrows = true,
    HeadDot = false,
    LookLine = false,
    Rainbow = false
})
```

Common settings:

- `Enabled`
- `RenderMode`: `Auto`, `Drawing`, or `Gui`
- `RefreshInterval`
- `ShowLocalPlayer`
- `TeamCheck`
- `UseTeamColor`
- `MaxDistance`
- `TextSize`
- `ScaleWithDistance`
- `FadeDistance`
- `Transparency`
- `EnemyColor`
- `FriendlyColor`
- `NeutralColor`
- `TargetColor`
- `OutlineColor`
- `Box`
- `BoxStyle`: `Corner` or `Full`
- `BoxThickness`
- `Box3D`
- `Name`
- `DisplayName`
- `HealthBar`
- `HealthText`
- `Distance`
- `DistanceUnit`
- `Tool`
- `Tracer`
- `TracerOrigin`: `Bottom`, `Center`, `Top`, or `Mouse`
- `Skeleton`
- `Chams`
- `OffscreenArrows`
- `ArrowRadius`
- `ArrowSize`
- `HeadDot`
- `LookLine`
- `Rainbow`

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
        state.Line = esp:CreateVisual("Line")
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

Built-in features:

- `Box`
- `Box3D`
- `Name`
- `HealthBar`
- `HealthText`
- `Distance`
- `Tool`
- `Tracer`
- `Skeleton`
- `HeadDot`
- `LookLine`
- `OffscreenArrows`
- `Chams`

Optional feature modules:

- `modules/RadarFeature.lua`

## Visual API

```lua
local text = ESP:CreateVisual("Text")
ESP:SetVisual(text, {
    Visible = true,
    Text = "Example",
    Position = Vector2.new(100, 100),
    Center = true,
    Color = Color3.fromRGB(255, 255, 255),
    Alpha = 1
})

ESP:HideVisual(text)
ESP:RemoveVisual(text)
```

Supported visual kinds:

- `Text`
- `Line`
- `Square`
- `Circle`
- `Triangle`

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
Bridge:ApplyToTab(SettingsTab, ESP)
```
