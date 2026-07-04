-- Wraps ESP:TrackTag as a provider module.
return function(ESP)
    local TagProvider = {
        Trackers = {},
        Started = false
    }

    function TagProvider:Start(options)
        options = options or {}
        local tag = options.Tag
        assert(type(tag) == "string" and tag ~= "", "TagProvider requires options.Tag")

        local targetOptions = {}
        for key, value in pairs(options) do
            if key ~= "Tag" then
                targetOptions[key] = value
            end
        end
        targetOptions.Type = targetOptions.Type or tag

        self.Trackers[tag] = ESP:TrackTag(tag, targetOptions)
        self.Started = true
        return self.Trackers[tag]
    end

    function TagProvider:Stop(tag)
        if tag then
            ESP:UntrackTag(tag)
            self.Trackers[tag] = nil
            return self
        end
        for trackedTag in pairs(self.Trackers) do
            ESP:UntrackTag(trackedTag)
        end
        self.Trackers = {}
        self.Started = false
        return self
    end

    ESP:RegisterProvider("Tags", TagProvider)
    return TagProvider
end
