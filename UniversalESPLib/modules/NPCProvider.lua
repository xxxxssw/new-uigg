-- Tracks non-player Humanoid models as ESP targets.
return function(ESP)
    local Players = game:GetService("Players")

    local NPCProvider = {
        Connections = {},
        Targets = {},
        Started = false
    }

    local function isModel(value)
        return typeof(value) == "Instance" and value:IsA("Model")
    end

    local function hasHumanoid(model)
        return model:FindFirstChildOfClass("Humanoid") ~= nil
    end

    function NPCProvider:ShouldTrack(model)
        if not isModel(model) or not hasHumanoid(model) then
            return false
        end
        if not self.Options.TrackPlayerCharacters and Players:GetPlayerFromCharacter(model) then
            return false
        end
        local filter = self.Options.TrackFilter or self.Options.Filter
        if type(filter) == "function" then
            local ok, allowed = pcall(filter, model)
            return ok and allowed ~= false
        end
        return true
    end

    function NPCProvider:Add(model)
        if self.Targets[model] or not self:ShouldTrack(model) then
            return
        end
        local options = {}
        for key, value in pairs(self.Options) do
            if key ~= "Key" and key ~= "TrackFilter" and key ~= "Filter" and key ~= "TargetFilter" then
                options[key] = value
            end
        end
        if self.Options.TargetFilter then
            options.Filter = self.Options.TargetFilter
        end
        options.Type = options.Type or "NPC"
        options.Name = options.Name or model.Name
        self.Targets[model] = ESP:Track(model, options)
    end

    function NPCProvider:Remove(model)
        local target = self.Targets[model]
        if target then
            ESP:Untrack(target)
            self.Targets[model] = nil
        end
    end

    function NPCProvider:Start(options)
        if self.Started then
            return self
        end
        self.Started = true
        self.Options = options or {}
        self.Root = self.Options.Root or workspace

        for _, descendant in ipairs(self.Root:GetDescendants()) do
            if isModel(descendant) then
                self:Add(descendant)
            end
        end

        table.insert(self.Connections, self.Root.DescendantAdded:Connect(function(descendant)
            if isModel(descendant) then
                task.defer(function()
                    self:Add(descendant)
                end)
            end
        end))

        table.insert(self.Connections, self.Root.DescendantRemoving:Connect(function(descendant)
            self:Remove(descendant)
        end))

        return self
    end

    function NPCProvider:Stop()
        for _, connection in ipairs(self.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        for model in pairs(self.Targets) do
            self:Remove(model)
        end
        self.Connections = {}
        self.Started = false
        return self
    end

    ESP:RegisterProvider("NPCs", NPCProvider)
    return NPCProvider
end
