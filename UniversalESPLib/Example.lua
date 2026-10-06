--[[
    UniversalESPLib - full example
    Loads the ESP, the UniversalUILib menu, the ESP menu bridge and config saving.

    Press RightControl to open the menu. Press the ESP keybind set in the menu to
    toggle visuals without opening it.
]]

local base = "https://raw.githubusercontent.com/xxxxssw/new-uigg/main/"
local espRepo = base .. "UniversalESPLib/"
local uiRepo = base .. "UniversalUILib/"

local function load(url)
    return loadstring(game:HttpGet(url))()
end

-- ESP ----------------------------------------------------------------------
local ESP = load(espRepo .. "Library.lua")
local NPCProvider = load(espRepo .. "modules/NPCProvider.lua")(ESP)

ESP:SetSettings({
    TeamCheck = false,
    MaxDistance = 2500,
    Box = true,
    BoxStyle = "Corner",
    BoxFill = true,
    Name = true,
    HealthBar = true,
    HealthText = true,
    Distance = true,
    Tool = true,
    OffscreenArrows = true,
    Chams = false,
    Skeleton = false,
    Tracer = false
})

ESP:Start()

-- Optional: NPC ESP for non-player Humanoid models (yellow, no health bar spam).
NPCProvider:Start({
    Root = workspace,
    Type = "NPC",
    Color = Color3.fromRGB(255, 210, 90),
    OffscreenArrows = false,
    Tool = false
})

-- Menu ---------------------------------------------------------------------
local Library = load(uiRepo .. "Library.lua")
local ThemeManager = load(uiRepo .. "addons/ThemeManager.lua")
local SaveManager = load(uiRepo .. "addons/SaveManager.lua")
local Bridge = load(espRepo .. "addons/UILibBridge.lua")

local Window = Library:CreateWindow({
    Title = "Universal ESP",
    Center = true,
    AutoShow = true,
    Size = Vector2.new(640, 560),
    Keybind = "RightControl"
})

local Tabs = {
    ESP = Window:AddTab("ESP"),
    Settings = Window:AddTab("Settings")
}

Bridge:ApplyToTab(Tabs.ESP, ESP, { ToggleKey = "F2" })

-- Settings tab: menu bind, unload, theme and configs.
local Menu = Tabs.Settings:AddLeftGroupbox("Menu")
Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu"
})
Menu:AddButton({
    Text = "Unload",
    DoubleClick = true,
    Func = function()
        ESP:Unload()
        Library:Unload()
    end
})

Library.ToggleKeybind = Options.MenuKeybind
Library:SetWatermark("Universal ESP")
Library:SetWatermarkVisibility(true)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("UniversalESP")
SaveManager:SetFolder("UniversalESP")
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    ESP:Unload()
end)

Library:Notify("Loaded. RightControl opens the menu, F2 toggles ESP.", 5, "Universal ESP")
