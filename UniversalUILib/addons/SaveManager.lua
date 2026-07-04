local SaveManager = {
    Library = nil,
    Folder = "UniversalUILib",
    IgnoreIndexes = {},
    MemoryConfigs = {},
    CurrentConfig = nil
}

local function safeName(value)
    local text = tostring(value or "config"):gsub("[^%w_%-]", "_")
    if text == "" then
        return "config"
    end
    return text
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
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

local function colorToData(color)
    if typeof(color) ~= "Color3" then
        return color
    end
    return {
        R = math.floor(color.R * 255),
        G = math.floor(color.G * 255),
        B = math.floor(color.B * 255)
    }
end

local function dataToColor(value)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) ~= "table" then
        return nil
    end
    local r = value.R or value.r or value[1]
    local g = value.G or value.g or value[2]
    local b = value.B or value.b or value[3]
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

function SaveManager:SetLibrary(library)
    self.Library = library
    library.SaveManager = self
    return self
end

function SaveManager:SetFolder(folder)
    self.Folder = tostring(folder or self.Folder)
    return self
end

function SaveManager:GetConfigFolder()
    return self.Folder .. "/configs"
end

function SaveManager:GetConfigPath(name)
    return self:GetConfigFolder() .. "/" .. safeName(name) .. ".json"
end

function SaveManager:SetIgnoreIndexes(indexes)
    self.IgnoreIndexes = self.IgnoreIndexes or {}
    for _, index in ipairs(indexes or {}) do
        self.IgnoreIndexes[index] = true
    end
    return self
end

function SaveManager:IgnoreThemeSettings()
    local ignored = {
        "ThemeManager_SelectedTheme",
        "ThemeManager_CustomName"
    }
    for _, key in ipairs({
        "Background",
        "Main",
        "Panel",
        "PanelLight",
        "Outline",
        "Accent",
        "Text",
        "MutedText",
        "Risk"
    }) do
        table.insert(ignored, "ThemeManager_Color_" .. key)
    end
    return self:SetIgnoreIndexes(ignored)
end

function SaveManager:ShouldIgnore(index)
    return self.IgnoreIndexes and self.IgnoreIndexes[index] == true
end

function SaveManager:GetConfigNames()
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
                if name and not contains(names, name) then
                    table.insert(names, name)
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

function SaveManager:Serialize()
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    local data = {
        Toggles = {},
        Options = {}
    }
    for index, toggle in pairs(self.Library.Toggles) do
        if not self:ShouldIgnore(index) then
            data.Toggles[index] = toggle.Value == true
        end
    end
    for index, option in pairs(self.Library.Options) do
        if not self:ShouldIgnore(index) then
            if option.Kind == "ColorPicker" then
                data.Options[index] = {
                    Kind = option.Kind,
                    Value = colorToData(option.Value),
                    Transparency = option.Transparency
                }
            elseif option.Kind == "KeyPicker" then
                data.Options[index] = {
                    Kind = option.Kind,
                    Value = option.Value,
                    Mode = option.Mode,
                    State = option.State
                }
            else
                data.Options[index] = {
                    Kind = option.Kind,
                    Value = option.Value
                }
            end
        end
    end
    return data
end

function SaveManager:ApplyData(data)
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    if type(data) ~= "table" then
        return false
    end
    for index, value in pairs(data.Toggles or {}) do
        local toggle = self.Library.Toggles[index]
        if toggle and toggle.SetValue and not self:ShouldIgnore(index) then
            toggle:SetValue(value)
        end
    end
    for index, entry in pairs(data.Options or {}) do
        local option = self.Library.Options[index]
        if option and not self:ShouldIgnore(index) then
            local value = type(entry) == "table" and entry.Value or entry
            if option.Kind == "ColorPicker" then
                local color = dataToColor(value)
                if color and option.SetValue then
                    option:SetValue(color)
                end
                if entry.Transparency ~= nil and option.SetTransparency then
                    option:SetTransparency(entry.Transparency)
                end
            elseif option.Kind == "KeyPicker" then
                if option.SetValue then
                    option:SetValue({ value, entry.Mode or option.Mode })
                end
                if entry.State ~= nil and option.SetState then
                    option:SetState(entry.State)
                end
            elseif option.SetValue then
                option:SetValue(value)
            end
        end
    end
    return true
end

function SaveManager:Save(name)
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig or "default")
    self.CurrentConfig = name
    local data = self:Serialize()
    self.MemoryConfigs[name] = data
    if canUseFiles() then
        ensureFolder(self.Folder)
        ensureFolder(self:GetConfigFolder())
        writefile(self:GetConfigPath(name), self.Library:JSONEncode(data))
    end
    self.Library:Notify("Saved config: " .. name, 3, "Save Manager")
    if self.ConfigDropdown then
        self.ConfigDropdown:SetValues(self:GetConfigNames())
        self.ConfigDropdown:SetValue(name, true)
    end
    return true
end

function SaveManager:Load(name)
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig or "default")
    local data = self.MemoryConfigs[name]
    if not data and canUseFiles() then
        local path = self:GetConfigPath(name)
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok then
                data = self.Library:JSONDecode(content)
            end
        end
    end
    if not data then
        self.Library:Notify("Config not found: " .. name, 4, "Save Manager")
        return false
    end
    self.CurrentConfig = name
    self:ApplyData(data)
    self.Library:Notify("Loaded config: " .. name, 3, "Save Manager")
    return true
end

function SaveManager:Delete(name)
    name = safeName(name or self.CurrentConfig or "default")
    self.MemoryConfigs[name] = nil
    if canUseFiles() and type(delfile) == "function" then
        local path = self:GetConfigPath(name)
        if isfile(path) then
            delfile(path)
        end
    end
    if self.ConfigDropdown then
        self.ConfigDropdown:SetValues(self:GetConfigNames())
    end
    return true
end

function SaveManager:SetAutoloadConfig(name)
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    name = safeName(name or self.CurrentConfig or "default")
    self.AutoloadConfig = name
    if canUseFiles() then
        ensureFolder(self.Folder)
        writefile(self.Folder .. "/autoload.txt", name)
    end
    self.Library:Notify("Autoload set: " .. name, 3, "Save Manager")
    return true
end

function SaveManager:LoadAutoloadConfig()
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    local name = self.AutoloadConfig
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

function SaveManager:BuildConfigSection(tabOrGroupbox)
    assert(self.Library, "SaveManager:SetLibrary must be called first")
    local groupbox
    if tabOrGroupbox.AddRightGroupbox then
        groupbox = tabOrGroupbox:AddRightGroupbox("Configs")
    else
        groupbox = tabOrGroupbox
    end

    groupbox:AddInput("SaveManager_ConfigName", {
        Text = "Config name",
        Default = self.CurrentConfig or "default",
        Placeholder = "Config name"
    })
    self:SetIgnoreIndexes({ "SaveManager_ConfigName", "SaveManager_ConfigList" })

    self.ConfigDropdown = groupbox:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved configs",
        Values = self:GetConfigNames(),
        Default = 1,
        Callback = function(value)
            if value and value ~= "None" then
                self.CurrentConfig = value
                if self.Library.Options.SaveManager_ConfigName then
                    self.Library.Options.SaveManager_ConfigName:SetValue(value, true)
                end
            end
        end
    })

    groupbox:AddButton({
        Text = "Save",
        Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            self:Save(name)
        end
    })

    groupbox:AddButton({
        Text = "Load",
        Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            self:Load(name)
        end
    })

    groupbox:AddButton({
        Text = "Delete",
        DoubleClick = true,
        Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            self:Delete(name)
            self.Library:Notify("Deleted config: " .. tostring(name), 3, "Save Manager")
        end
    })

    groupbox:AddButton({
        Text = "Set autoload",
        Func = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            self:SetAutoloadConfig(name)
        end
    })

    return self
end

return SaveManager
