local ConfigManager = {
    ESP = nil,
    Folder = "UniversalESPLib",
    CurrentConfig = "default",
    MemoryConfigs = {}
}

local function safeName(value)
    local text = tostring(value or "default"):gsub("[^%w_%-]", "_")
    if text == "" then
        return "default"
    end
    return text
end

local function canUseFiles()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
    if type(makefolder) ~= "function" then
        return
    end
    if type(isfolder) == "function" and isfolder(path) then
        return
    end
    pcall(makefolder, path)
end

function ConfigManager:SetLibrary(esp)
    self.ESP = esp
    esp.ConfigManager = self
    return self
end

function ConfigManager:SetFolder(folder)
    self.Folder = tostring(folder or self.Folder)
    return self
end

function ConfigManager:GetConfigFolder()
    return self.Folder .. "/configs"
end

function ConfigManager:GetConfigPath(name)
    return self:GetConfigFolder() .. "/" .. safeName(name) .. ".json"
end

function ConfigManager:GetConfigNames()
    local names = {}
    for name in pairs(self.MemoryConfigs) do
        table.insert(names, name)
    end
    if canUseFiles() and type(listfiles) == "function" then
        ensureFolder(self.Folder)
        ensureFolder(self:GetConfigFolder())
        local ok, files = pcall(listfiles, self:GetConfigFolder())
        if ok then
            for _, path in ipairs(files) do
                local name = tostring(path):match("([^/\\]+)%.json$")
                if name then
                    local exists = false
                    for _, current in ipairs(names) do
                        if current == name then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(names, name)
                    end
                end
            end
        end
    end
    table.sort(names)
    if #names == 0 then
        return { "None" }
    end
    return names
end

function ConfigManager:Serialize()
    assert(self.ESP, "ConfigManager:SetLibrary must be called first")
    return {
        Version = self.ESP.Version,
        Settings = self.ESP:GetSettings()
    }
end

function ConfigManager:Apply(data)
    assert(self.ESP, "ConfigManager:SetLibrary must be called first")
    if type(data) ~= "table" or type(data.Settings) ~= "table" then
        return false
    end
    self.ESP:SetSettings(data.Settings)
    return true
end

function ConfigManager:Save(name)
    assert(self.ESP, "ConfigManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig)
    self.CurrentConfig = name
    local data = self:Serialize()
    self.MemoryConfigs[name] = data
    if canUseFiles() then
        ensureFolder(self.Folder)
        ensureFolder(self:GetConfigFolder())
        writefile(self:GetConfigPath(name), self.ESP:JSONEncode(data))
    end
    return true
end

function ConfigManager:Load(name)
    assert(self.ESP, "ConfigManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig)
    local data = self.MemoryConfigs[name]
    if not data and canUseFiles() then
        local path = self:GetConfigPath(name)
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok then
                data = self.ESP:JSONDecode(content)
            end
        end
    end
    if not data then
        return false
    end
    self.CurrentConfig = name
    return self:Apply(data)
end

function ConfigManager:Delete(name)
    name = safeName(name or self.CurrentConfig)
    self.MemoryConfigs[name] = nil
    if canUseFiles() and type(delfile) == "function" then
        local path = self:GetConfigPath(name)
        if isfile(path) then
            delfile(path)
        end
    end
    return true
end

function ConfigManager:SetAutoload(name)
    assert(self.ESP, "ConfigManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig)
    self.Autoload = name
    if canUseFiles() then
        ensureFolder(self.Folder)
        writefile(self.Folder .. "/autoload.txt", name)
    end
    return true
end

function ConfigManager:LoadAutoload()
    local name = self.Autoload
    if not name and canUseFiles() and isfile(self.Folder .. "/autoload.txt") then
        local ok, content = pcall(readfile, self.Folder .. "/autoload.txt")
        if ok then
            name = content
        end
    end
    if name and name ~= "" then
        return self:Load(name)
    end
    return false
end

return ConfigManager
