--[[
    UILibBridge
    Builds a complete, organised ESP menu inside a UniversalUILib tab.

    local Bridge = loadstring(game:HttpGet(repo .. "addons/UILibBridge.lua"))()
    Bridge:ApplyToTab(Window:AddTab("ESP"), ESP)

    Every control index is prefixed with "ESP_" so UniversalUILib's SaveManager
    can persist the whole ESP configuration alongside the UI settings.
]]

local Bridge = {}

local function setting(ESP, key)
    return function(value)
        ESP:SetSetting(key, value)
    end
end

local function addToggle(group, ESP, key, text, tooltip)
    return group:AddToggle("ESP_" .. key, {
        Text = text,
        Default = ESP.Settings[key] == true,
        Tooltip = tooltip,
        Callback = setting(ESP, key)
    })
end

local function addSlider(group, ESP, key, text, min, max, rounding, suffix)
    return group:AddSlider("ESP_" .. key, {
        Text = text,
        Default = ESP.Settings[key] or min,
        Min = min,
        Max = max,
        Rounding = rounding or 0,
        Suffix = suffix or "",
        Callback = setting(ESP, key)
    })
end

local function addDropdown(group, ESP, key, text, values)
    local default = 1
    for index, value in ipairs(values) do
        if value == ESP.Settings[key] then
            default = index
            break
        end
    end
    return group:AddDropdown("ESP_" .. key, {
        Text = text,
        Values = values,
        Default = default,
        Callback = setting(ESP, key)
    })
end

local function addColor(group, ESP, key, text)
    return group:AddLabel(text):AddColorPicker("ESP_" .. key, {
        Title = text,
        Default = ESP.Settings[key] or Color3.fromRGB(255, 255, 255),
        Callback = setting(ESP, key)
    })
end

local function dependsOn(group, toggle)
    local box = group:AddDependencyBox()
    box:SetupDependencies({ { toggle, true } })
    return box
end

function Bridge:ApplyToTab(tab, ESP, options)
    options = options or {}

    ------------------------------------------------------------------ Left
    local main = tab:AddLeftGroupbox("ESP")

    local enabled = addToggle(main, ESP, "Enabled", "Enabled", "Master switch for every ESP visual")
    enabled:AddKeyPicker("ESP_ToggleKey", {
        Default = options.ToggleKey or "None",
        Mode = "Toggle",
        Text = "ESP",
        SyncToggleState = true
    })
    enabled:OnChanged(function(value)
        ESP:SetEnabled(value)
    end)

    addToggle(main, ESP, "TeamCheck", "Team check", "Hide players on your team")
    addToggle(main, ESP, "UseTeamColor", "Use team colors", "Color players by their team instead of enemy/friendly colors")
    addToggle(main, ESP, "VisibleCheck", "Visible check", "Use the visible color when nothing is between you and the target")
    addToggle(main, ESP, "ShowLocalPlayer", "Show local player")
    addToggle(main, ESP, "ShowDead", "Show dead targets")
    addSlider(main, ESP, "MaxDistance", "Max distance", 50, 10000, 0, "m")
    addToggle(main, ESP, "FadeDistance", "Fade with distance", "Far targets become more transparent")
    addDropdown(main, ESP, "DistanceOrigin", "Measure distance from", { "Character", "Camera" })

    local box = tab:AddLeftGroupbox("Box")
    local boxToggle = addToggle(box, ESP, "Box", "Box")
    local boxDeps = dependsOn(box, boxToggle)
    addDropdown(boxDeps, ESP, "BoxStyle", "Style", { "Corner", "Full" })
    addDropdown(boxDeps, ESP, "BoxMode", "Fit", { "Precise", "Fast" })
    addSlider(boxDeps, ESP, "BoxThickness", "Thickness", 1, 3, 0, "px")
    local fillToggle = addToggle(boxDeps, ESP, "BoxFill", "Fill")
    local fillDeps = dependsOn(boxDeps, fillToggle)
    addSlider(fillDeps, ESP, "BoxFillTransparency", "Fill transparency", 0.5, 1, 2)
    addToggle(box, ESP, "Box3D", "3D box")

    local labels = tab:AddLeftGroupbox("Labels")
    local nameToggle = addToggle(labels, ESP, "Name", "Name")
    local nameDeps = dependsOn(labels, nameToggle)
    addToggle(nameDeps, ESP, "DisplayName", "Show display name")
    local healthToggle = addToggle(labels, ESP, "HealthBar", "Health bar")
    local healthDeps = dependsOn(labels, healthToggle)
    addDropdown(healthDeps, ESP, "HealthBarSide", "Side", { "Left", "Right" })
    addSlider(healthDeps, ESP, "HealthBarWidth", "Width", 1, 5, 0, "px")
    addToggle(healthDeps, ESP, "HealthText", "Health number")
    addToggle(healthDeps, ESP, "HealthTextAlways", "Always show number")
    addToggle(labels, ESP, "Distance", "Distance")
    addToggle(labels, ESP, "Tool", "Equipped tool")
    labels:AddDivider()
    addSlider(labels, ESP, "TextSize", "Text size", 9, 24, 0, "px")
    labels:AddDropdown("ESP_TextFont", {
        Text = "Font",
        Values = { "UI", "System", "Plex", "Monospace" },
        Default = (ESP.Settings.TextFont or 2) + 1,
        Callback = function(value)
            local fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 }
            ESP:SetSetting("TextFont", fonts[value] or 2)
        end
    })
    addToggle(labels, ESP, "ScaleWithDistance", "Scale text with distance")
    addToggle(labels, ESP, "TextUseTargetColor", "Color text like target")

    ----------------------------------------------------------------- Right
    local extras = tab:AddRightGroupbox("Extras")
    local tracerToggle = addToggle(extras, ESP, "Tracer", "Tracers")
    local tracerDeps = dependsOn(extras, tracerToggle)
    addDropdown(tracerDeps, ESP, "TracerOrigin", "Origin", { "Bottom", "Center", "Top", "Mouse" })
    addSlider(tracerDeps, ESP, "TracerThickness", "Thickness", 1, 3, 0, "px")

    local skeletonToggle = addToggle(extras, ESP, "Skeleton", "Skeleton")
    local skeletonDeps = dependsOn(extras, skeletonToggle)
    addSlider(skeletonDeps, ESP, "SkeletonThickness", "Thickness", 1, 3, 0, "px")

    local chamsToggle = addToggle(extras, ESP, "Chams", "Chams", "Highlight targets through walls")
    local chamsDeps = dependsOn(extras, chamsToggle)
    addSlider(chamsDeps, ESP, "ChamsFillTransparency", "Fill transparency", 0, 1, 2)
    addToggle(chamsDeps, ESP, "ChamsOutline", "Outline")

    local arrowToggle = addToggle(extras, ESP, "OffscreenArrows", "Off-screen arrows")
    local arrowDeps = dependsOn(extras, arrowToggle)
    addSlider(arrowDeps, ESP, "ArrowRadius", "Radius", 100, 800, 0, "px")
    addSlider(arrowDeps, ESP, "ArrowSize", "Size", 8, 30, 0, "px")

    local headToggle = addToggle(extras, ESP, "HeadDot", "Head dot")
    local headDeps = dependsOn(extras, headToggle)
    addSlider(headDeps, ESP, "HeadDotRadius", "Radius", 1, 10, 0, "px")

    local lookToggle = addToggle(extras, ESP, "LookLine", "Look direction")
    local lookDeps = dependsOn(extras, lookToggle)
    addSlider(lookDeps, ESP, "LookLineLength", "Length", 2, 30, 0)

    local colors = tab:AddRightGroupbox("Colors")
    addColor(colors, ESP, "EnemyColor", "Enemy")
    addColor(colors, ESP, "FriendlyColor", "Friendly")
    addColor(colors, ESP, "NeutralColor", "Neutral / objects")
    addColor(colors, ESP, "VisibleColor", "Visible")
    addColor(colors, ESP, "TextColor", "Text")
    addColor(colors, ESP, "OutlineColor", "Outline")
    colors:AddDivider()
    addToggle(colors, ESP, "Outline", "Outlines", "Draw a dark outline under every shape")
    local rainbowToggle = addToggle(colors, ESP, "Rainbow", "Rainbow")
    local rainbowDeps = dependsOn(colors, rainbowToggle)
    addSlider(rainbowDeps, ESP, "RainbowSpeed", "Speed", 0.2, 5, 1)
    addSlider(colors, ESP, "Transparency", "Opacity", 0.1, 1, 2)

    return self
end

-- Convenience: creates a tab on the window and fills it.
function Bridge:ApplyToWindow(window, ESP, options)
    options = options or {}
    local tab = window:AddTab(options.TabName or "ESP")
    self:ApplyToTab(tab, ESP, options)
    return tab
end

return Bridge
