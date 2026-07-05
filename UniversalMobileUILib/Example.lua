local repo = "https://raw.githubusercontent.com/OWNER/UniversalMobileUILib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Mobile UI Demo",
    Center = true,
    AutoShow = true,
    TabPadding = 4,
    Keybind = "RightControl"
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings")
}

local MainLeft = Tabs.Main:AddLeftGroupbox("Controls")

MainLeft:AddToggle("DemoToggle", {
    Text = "Demo toggle",
    Default = true,
    Tooltip = "Toggles can be read from Toggles.DemoToggle.Value",
    Callback = function(value)
        print("DemoToggle:", value)
    end
})

Toggles.DemoToggle:OnChanged(function(value)
    print("OnChanged DemoToggle:", value)
end)

MainLeft:AddSlider("DemoSlider", {
    Text = "Demo slider",
    Default = 25,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        print("DemoSlider:", value)
    end
})

MainLeft:AddInput("DemoInput", {
    Text = "Text input",
    Default = "hello",
    Placeholder = "Type here",
    Finished = true,
    Callback = function(value)
        print("DemoInput:", value)
    end
})

MainLeft:AddDropdown("DemoDropdown", {
    Text = "Dropdown",
    Values = { "Alpha", "Bravo", "Charlie" },
    Default = 1,
    Callback = function(value)
        print("DemoDropdown:", value)
    end
})

MainLeft:AddDropdown("DemoMultiDropdown", {
    Text = "Multi dropdown",
    Values = { "One", "Two", "Three" },
    Multi = true,
    Default = { One = true },
    Callback = function(value)
        print("DemoMultiDropdown:", value)
    end
})

MainLeft:AddButton({
    Text = "Notify",
    Func = function()
        Library:Notify("Button clicked.", 3, "Example")
    end
})

local MainRight = Tabs.Main:AddRightGroupbox("Pickers")

MainRight:AddLabel("Accent color"):AddColorPicker("DemoColor", {
    Title = "Demo color",
    Default = Color3.fromRGB(0, 170, 255),
    Callback = function(color)
        print("DemoColor:", color)
    end
})

MainRight:AddLabel("Action bind"):AddKeyPicker("DemoKeybind", {
    Default = "F",
    Mode = "Toggle",
    Text = "Example bind",
    Callback = function(state)
        print("DemoKeybind state:", state)
    end,
    ChangedCallback = function(key)
        print("DemoKeybind changed:", key)
    end
})

local DepGroup = Tabs.Visuals:AddLeftGroupbox("Dependency Boxes")
DepGroup:AddToggle("ShowExtraControls", {
    Text = "Show extra controls",
    Default = false
})

local DepBox = DepGroup:AddDependencyBox()
DepBox:AddSlider("DependentSlider", {
    Text = "Only visible when enabled",
    Default = 10,
    Min = 0,
    Max = 20,
    Rounding = 0
})
DepBox:AddDropdown("DependentDropdown", {
    Text = "Dependent dropdown",
    Values = { "Visible", "Hidden" },
    Default = 1
})
DepBox:SetupDependencies({
    { Toggles.ShowExtraControls, true }
})

local TabBox = Tabs.Visuals:AddRightTabbox()
local TabA = TabBox:AddTab("Tab A")
TabA:AddToggle("TabAToggle", { Text = "Toggle A" })
local TabB = TabBox:AddTab("Tab B")
TabB:AddToggle("TabBToggle", { Text = "Toggle B" })

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton({
    Text = "Unload",
    DoubleClick = true,
    Func = function()
        Library:Unload()
    end
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu bind"
})

Library.ToggleKeybind = Options.MenuKeybind
Library:SetWatermarkVisibility(true)
Library:SetWatermark("UniversalMobileUILib demo")
Library.KeybindFrame.Visible = true

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("UniversalMobileUILib")
SaveManager:SetFolder("UniversalMobileUILib")

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
