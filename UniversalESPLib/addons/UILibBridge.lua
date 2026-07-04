local Bridge = {}

local function addToggle(group, index, text, default, callback)
    return group:AddToggle(index, {
        Text = text,
        Default = default == true,
        Callback = callback
    })
end

local function addSlider(group, index, text, default, min, max, rounding, callback)
    return group:AddSlider(index, {
        Text = text,
        Default = default,
        Min = min,
        Max = max,
        Rounding = rounding or 0,
        Callback = callback
    })
end

function Bridge:ApplyToTab(tab, ESP)
    local main = tab:AddLeftGroupbox("ESP")
    local visuals = tab:AddRightGroupbox("Visuals")
    local advanced = tab:AddRightGroupbox("Advanced")

    addToggle(main, "ESP_Enabled", "Enabled", ESP.Settings.Enabled, function(value)
        ESP:SetEnabled(value)
    end)

    addToggle(main, "ESP_TeamCheck", "Team check", ESP.Settings.TeamCheck, function(value)
        ESP:SetSetting("TeamCheck", value)
    end)

    addToggle(main, "ESP_UseTeamColor", "Use team color", ESP.Settings.UseTeamColor, function(value)
        ESP:SetSetting("UseTeamColor", value)
    end)

    addSlider(main, "ESP_MaxDistance", "Max distance", ESP.Settings.MaxDistance, 100, 10000, 0, function(value)
        ESP:SetSetting("MaxDistance", value)
    end)

    addToggle(visuals, "ESP_Box", "Box", ESP.Settings.Box, function(value)
        ESP:SetSetting("Box", value)
    end)

    visuals:AddDropdown("ESP_BoxStyle", {
        Text = "Box style",
        Values = { "Corner", "Full" },
        Default = ESP.Settings.BoxStyle == "Full" and 2 or 1,
        Callback = function(value)
            ESP:SetSetting("BoxStyle", value)
        end
    })

    addToggle(visuals, "ESP_Box3D", "3D box", ESP.Settings.Box3D, function(value)
        ESP:SetSetting("Box3D", value)
    end)

    addToggle(visuals, "ESP_Name", "Name", ESP.Settings.Name, function(value)
        ESP:SetSetting("Name", value)
    end)

    addToggle(visuals, "ESP_HealthBar", "Health bar", ESP.Settings.HealthBar, function(value)
        ESP:SetSetting("HealthBar", value)
    end)

    addToggle(visuals, "ESP_HealthText", "Health text", ESP.Settings.HealthText, function(value)
        ESP:SetSetting("HealthText", value)
    end)

    addToggle(visuals, "ESP_Distance", "Distance", ESP.Settings.Distance, function(value)
        ESP:SetSetting("Distance", value)
    end)

    addToggle(visuals, "ESP_Tool", "Tool", ESP.Settings.Tool, function(value)
        ESP:SetSetting("Tool", value)
    end)

    addToggle(visuals, "ESP_Tracer", "Tracer", ESP.Settings.Tracer, function(value)
        ESP:SetSetting("Tracer", value)
    end)

    visuals:AddDropdown("ESP_TracerOrigin", {
        Text = "Tracer origin",
        Values = { "Bottom", "Center", "Top", "Mouse" },
        Default = 1,
        Callback = function(value)
            ESP:SetSetting("TracerOrigin", value)
        end
    })

    addToggle(advanced, "ESP_Skeleton", "Skeleton", ESP.Settings.Skeleton, function(value)
        ESP:SetSetting("Skeleton", value)
    end)

    addToggle(advanced, "ESP_Chams", "Chams", ESP.Settings.Chams, function(value)
        ESP:SetSetting("Chams", value)
    end)

    addToggle(advanced, "ESP_OffscreenArrows", "Offscreen arrows", ESP.Settings.OffscreenArrows, function(value)
        ESP:SetSetting("OffscreenArrows", value)
    end)

    addToggle(advanced, "ESP_HeadDot", "Head dot", ESP.Settings.HeadDot, function(value)
        ESP:SetSetting("HeadDot", value)
    end)

    addToggle(advanced, "ESP_LookLine", "Look line", ESP.Settings.LookLine, function(value)
        ESP:SetSetting("LookLine", value)
    end)

    addToggle(advanced, "ESP_Rainbow", "Rainbow", ESP.Settings.Rainbow, function(value)
        ESP:SetSetting("Rainbow", value)
    end)

    addSlider(advanced, "ESP_ArrowRadius", "Arrow radius", ESP.Settings.ArrowRadius, 120, 600, 0, function(value)
        ESP:SetSetting("ArrowRadius", value)
    end)

    local enemyLabel = advanced:AddLabel("Enemy color")
    enemyLabel:AddColorPicker("ESP_EnemyColor", {
        Default = ESP.Settings.EnemyColor,
        Callback = function(color)
            ESP:SetSetting("EnemyColor", color)
            ESP:SetSetting("UseTeamColor", false)
        end
    })

    return self
end

return Bridge
