-- Optional 2D radar feature. Register it, then enable ESP.Settings.Radar.
return function(ESP)
    ESP.Settings.Radar = ESP.Settings.Radar or false
    ESP.Settings.RadarPosition = ESP.Settings.RadarPosition or Vector2.new(20, 250)
    ESP.Settings.RadarSize = ESP.Settings.RadarSize or 160
    ESP.Settings.RadarRange = ESP.Settings.RadarRange or 350
    ESP.Settings.RadarUseCameraRotation = ESP.Settings.RadarUseCameraRotation ~= false

    local RadarFeature = {
        Panel = nil,
        Stroke = nil,
        CenterDot = nil
    }

    local function getLocalRoot()
        local player = game:GetService("Players").LocalPlayer
        local character = player and player.Character
        if not character then
            return nil
        end
        return character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
    end

    function RadarFeature:EnsurePanel(esp)
        if self.Panel and self.Panel.Parent then
            return
        end
        local panel = Instance.new("Frame")
        panel.Name = "Radar"
        panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        panel.BackgroundTransparency = 0.25
        panel.BorderSizePixel = 0
        panel.Position = UDim2.fromOffset(ESP.Settings.RadarPosition.X, ESP.Settings.RadarPosition.Y)
        panel.Size = UDim2.fromOffset(ESP.Settings.RadarSize, ESP.Settings.RadarSize)
        panel.Parent = esp:GetScreenGui()

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(80, 85, 100)
        stroke.Thickness = 1
        stroke.Parent = panel

        local center = Instance.new("Frame")
        center.Name = "Center"
        center.AnchorPoint = Vector2.new(0.5, 0.5)
        center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        center.BorderSizePixel = 0
        center.Position = UDim2.fromScale(0.5, 0.5)
        center.Size = UDim2.fromOffset(4, 4)
        center.Parent = panel

        local centerCorner = Instance.new("UICorner")
        centerCorner.CornerRadius = UDim.new(1, 0)
        centerCorner.Parent = center

        self.Panel = panel
        self.Stroke = stroke
        self.CenterDot = center
    end

    function RadarFeature:SetPanelVisible(visible)
        if self.Panel then
            self.Panel.Visible = visible
        end
    end

    ESP:RegisterFeature("Radar", {
        Order = 95,
        Create = function(_, _, state, esp)
            state.Dot = esp:CreateVisual("Circle")
        end,
        Update = function(_, target, state, context, esp)
            if not esp.Settings.Radar then
                esp:HideVisual(state.Dot)
                RadarFeature:SetPanelVisible(false)
                return
            end

            RadarFeature:EnsurePanel(esp)
            RadarFeature:SetPanelVisible(true)

            local localRoot = getLocalRoot()
            if not localRoot or not context.Visible or not context.Info.Root then
                esp:HideVisual(state.Dot)
                return
            end

            local size = esp.Settings.RadarSize
            local range = math.max(1, esp.Settings.RadarRange)
            local relative = context.Info.Root.Position - localRoot.Position
            local x = relative.X
            local z = relative.Z

            if esp.Settings.RadarUseCameraRotation and context.Camera then
                local look = context.Camera.CFrame.LookVector
                local yaw = math.atan2 and math.atan2(look.X, look.Z) or math.atan(look.X, look.Z)
                local cos = math.cos(yaw)
                local sin = math.sin(yaw)
                local rx = x * cos - z * sin
                local rz = x * sin + z * cos
                x = rx
                z = rz
            end

            local px = math.clamp(x / range, -1, 1) * (size / 2 - 8)
            local py = math.clamp(z / range, -1, 1) * (size / 2 - 8)
            local panelPosition = esp.Settings.RadarPosition
            local position = Vector2.new(panelPosition.X + size / 2 + px, panelPosition.Y + size / 2 + py)

            esp:SetVisual(state.Dot, {
                Visible = true,
                Position = position,
                Radius = 3,
                Color = context.Color,
                Alpha = context.Alpha,
                Filled = true,
                Thickness = 1
            })
        end
    })

    return RadarFeature
end
