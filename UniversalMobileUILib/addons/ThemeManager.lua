local ThemeManager = {
    Library = nil,
    Folder = "UniversalMobileUILib",
    ActiveTheme = "Default",
    BuiltInThemes = {
        Default = {
            Background = "#111216",
            Main = "#1A1B21",
            Panel = "#1F2128",
            PanelLight = "#262932",
            Outline = "#3D414E",
            Accent = "#00AAFF",
            Text = "#F0F4F8",
            MutedText = "#A6ADBA",
            Risk = "#F05050"
        },
        Midnight = {
            Background = "#101114",
            Main = "#181A20",
            Panel = "#20232B",
            PanelLight = "#2A2E39",
            Outline = "#464B5A",
            Accent = "#7DD3FC",
            Text = "#EEF2F7",
            MutedText = "#9AA3B2",
            Risk = "#FB7185"
        },
        Ember = {
            Background = "#171412",
            Main = "#231E1A",
            Panel = "#2C251F",
            PanelLight = "#362D25",
            Outline = "#5A4A3D",
            Accent = "#F97316",
            Text = "#FFF7ED",
            MutedText = "#D6C2B2",
            Risk = "#EF4444"
        },
        Forest = {
            Background = "#101513",
            Main = "#18211D",
            Panel = "#202B26",
            PanelLight = "#2A3932",
            Outline = "#43564E",
            Accent = "#34D399",
            Text = "#ECFDF5",
            MutedText = "#A7BFB4",
            Risk = "#F87171"
        },
        Rose = {
            Background = "#171216",
            Main = "#221A21",
            Panel = "#2C222A",
            PanelLight = "#382B35",
            Outline = "#594653",
            Accent = "#F472B6",
            Text = "#FFF1F8",
            MutedText = "#D8B8CA",
            Risk = "#FB7185"
        }
    }
}

local COLOR_KEYS = {
    "Background",
    "Main",
    "Panel",
    "PanelLight",
    "Outline",
    "Accent",
    "Text",
    "MutedText",
    "Risk"
}

local function safeName(value)
    return tostring(value or "theme"):gsub("[^%w_%-]", "_")
end

local function find(list, value)
    for index, item in ipairs(list or {}) do
        if item == value then
            return index
        end
    end
    return nil
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

local function colorToHex(color)
    if typeof(color) ~= "Color3" then
        return color
    end
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function normalizeTheme(library, theme)
    local normalized = {}
    for key, value in pairs(theme or {}) do
        normalized[key] = value
    end
    if library and library.Theme then
        for _, key in ipairs(COLOR_KEYS) do
            if normalized[key] == nil and library.Theme[key] ~= nil then
                normalized[key] = library.Theme[key]
            end
        end
    end
    return normalized
end

function ThemeManager:SetLibrary(library)
    self.Library = library
    library.ThemeManager = self
    return self
end

function ThemeManager:SetFolder(folder)
    self.Folder = tostring(folder or self.Folder)
    return self
end

function ThemeManager:GetThemeFolder()
    return self.Folder .. "/themes"
end

function ThemeManager:GetThemePath(name)
    return self:GetThemeFolder() .. "/" .. safeName(name) .. ".json"
end

function ThemeManager:GetThemeNames()
    local names = {}
    for name in pairs(self.BuiltInThemes) do
        table.insert(names, name)
    end
    if canUseFiles() and type(listfiles) == "function" then
        ensureFolder(self.Folder)
        ensureFolder(self:GetThemeFolder())
        local ok, files = pcall(listfiles, self:GetThemeFolder())
        if ok then
            for _, path in ipairs(files) do
                local name = tostring(path):match("([^/\\]+)%.json$")
                if name and not self.BuiltInThemes[name] then
                    table.insert(names, name)
                end
            end
        end
    end
    table.sort(names)
    return names
end

function ThemeManager:ApplyTheme(themeOrName)
    assert(self.Library, "ThemeManager:SetLibrary must be called first")
    local theme = themeOrName
    if type(themeOrName) == "string" then
        self.ActiveTheme = themeOrName
        theme = self.BuiltInThemes[themeOrName] or self:LoadThemeData(themeOrName)
    end
    if type(theme) ~= "table" then
        self.Library:Notify("Theme not found: " .. tostring(themeOrName), 4, "Theme Manager")
        return self
    end
    self.Library:SetTheme(normalizeTheme(self.Library, theme))
    return self
end

function ThemeManager:LoadThemeData(name)
    if not canUseFiles() then
        return nil
    end
    local path = self:GetThemePath(name)
    if not isfile(path) then
        return nil
    end
    local ok, content = pcall(readfile, path)
    if not ok then
        return nil
    end
    return self.Library:JSONDecode(content)
end

function ThemeManager:SaveTheme(name)
    assert(self.Library, "ThemeManager:SetLibrary must be called first")
    name = safeName(name or self.ActiveTheme or "Custom")
    if not canUseFiles() then
        self.Library:Notify("File saving is not available in this environment.", 4, "Theme Manager")
        return false
    end
    ensureFolder(self.Folder)
    ensureFolder(self:GetThemeFolder())
    local data = {}
    for _, key in ipairs(COLOR_KEYS) do
        data[key] = colorToHex(self.Library.Theme[key])
    end
    writefile(self:GetThemePath(name), self.Library:JSONEncode(data))
    self.Library:Notify("Saved theme: " .. name, 3, "Theme Manager")
    return true
end

function ThemeManager:DeleteTheme(name)
    name = safeName(name)
    if not canUseFiles() or type(delfile) ~= "function" then
        return false
    end
    local path = self:GetThemePath(name)
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

function ThemeManager:ApplyToGroupbox(groupbox)
    assert(self.Library, "ThemeManager:SetLibrary must be called first")
    local themeNames = self:GetThemeNames()
    if #themeNames == 0 then
        themeNames = { "Default" }
    end
    local themeDropdown = groupbox:AddDropdown("ThemeManager_SelectedTheme", {
        Text = "Theme",
        Values = themeNames,
        Default = find(themeNames, self.ActiveTheme) or 1,
        Callback = function(value)
            self:ApplyTheme(value)
        end
    })

    groupbox:AddInput("ThemeManager_CustomName", {
        Text = "Theme name",
        Default = "Custom",
        Placeholder = "Theme name"
    })

    groupbox:AddButton({
        Text = "Save theme",
        Func = function()
            local name = self.Library.Options.ThemeManager_CustomName.Value
            if self:SaveTheme(name) then
                themeDropdown:SetValues(self:GetThemeNames())
            end
        end
    })

    groupbox:AddDivider()

    for _, key in ipairs(COLOR_KEYS) do
        local label = groupbox:AddLabel(key)
        label:AddColorPicker("ThemeManager_Color_" .. key, {
            Title = key,
            Default = self.Library.Theme[key],
            Callback = function(color)
                self.Library:SetTheme({ [key] = color })
            end
        })
    end
    return self
end

function ThemeManager:ApplyToTab(tab)
    local groupbox
    if tab.AddLeftGroupbox then
        groupbox = tab:AddLeftGroupbox("Themes")
    else
        groupbox = tab
    end
    return self:ApplyToGroupbox(groupbox)
end

return ThemeManager
