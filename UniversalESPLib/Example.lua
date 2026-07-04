local repo = "https://github.com/xxxxssw/new-uigg/blob/main/UniversalESPLib/"

local ESP = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- Optional modules.
local NPCProvider = loadstring(game:HttpGet(repo .. "modules/NPCProvider.lua"))()(ESP)
local TagProvider = loadstring(game:HttpGet(repo .. "modules/TagProvider.lua"))()(ESP)
local RadarFeature = loadstring(game:HttpGet(repo .. "modules/RadarFeature.lua"))()(ESP)
local ConfigManager = loadstring(game:HttpGet(repo .. "addons/ConfigManager.lua"))()

ConfigManager:SetLibrary(ESP)
ConfigManager:SetFolder("UniversalESPLib")

ESP:SetSettings({
    Enabled = true,
    TeamCheck = false,
    MaxDistance = 4500,
    Box = true,
    BoxStyle = "Corner",
    Name = true,
    HealthBar = true,
    Distance = true,
    Tool = true,
    OffscreenArrows = true,
    Chams = false,
    Skeleton = false,
    Tracer = false
})

-- Starts player ESP by default.
ESP:Start()

-- Optional: NPC ESP for non-player Humanoid models.
NPCProvider:Start({
    Root = workspace,
    Type = "NPC",
    Color = Color3.fromRGB(255, 210, 90),
    TrackFilter = function(model)
        return model.Name ~= "IgnoreMe"
    end
})

-- Optional: track anything tagged with CollectionService tag "Loot".
TagProvider:Start({
    Tag = "Loot",
    Type = "Loot",
    Color = Color3.fromRGB(120, 255, 160),
    Name = "Loot"
})

-- Optional: manual custom target.
local importantPart = workspace:FindFirstChild("ImportantPart")
if importantPart then
    ESP:Track(importantPart, {
        Type = "Objective",
        Name = "Objective",
        Color = Color3.fromRGB(255, 120, 255),
        Box = true,
        Distance = true,
        Tracer = true
    })
end

-- Optional: integrate with UniversalUILib.
--[[
local uiRepo = "https://raw.githubusercontent.com/OWNER/UniversalUILib/main/"
local Library = loadstring(game:HttpGet(uiRepo .. "Library.lua"))()
local Bridge = loadstring(game:HttpGet(repo .. "addons/UILibBridge.lua"))()

local Window = Library:CreateWindow({
    Title = "ESP",
    Center = true,
    AutoShow = true
})

local Settings = Window:AddTab("ESP")
Bridge:ApplyToTab(Settings, ESP)
]]

ConfigManager:LoadAutoload()
