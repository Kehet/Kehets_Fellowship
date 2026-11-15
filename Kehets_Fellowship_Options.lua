-- Settings page in Options > AddOns, with the message settings of LibKehetsVerbosity-2.0 listed under it.
-- Clients with proxy settings get the native list of the game settings; the others get a page of check boxes.
local UI = Fellowship.UI

local DISPLAY_NAME = "Kehet's Fellowship"

local page
local category
-- Native settings, so a change made with a slash command can be shown on the page
local settings = {}

-- Register a check box in the native list. get and set read and write the saved value.
local function AddCheckbox(variable, name, tooltip, get, set)
    local setting = Settings.RegisterProxySetting(category, "KEHETS_FELLOWSHIP_" .. variable,
        Settings.VarType.Boolean, name, true, get, set)
    settings[variable] = setting
    return Settings.CreateCheckbox(category, setting, tooltip)
end

local function RegisterNativePage()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory(DISPLAY_NAME)
    local profile = Fellowship.db.profile

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Join sound"))

    local enabled = AddCheckbox("SOUND_ENABLED", "Play a sound when a rated player joins",
        "Play a sound when a player with a score other than 0 joins your group",
        function() return profile.sound.enabled end,
        function(value) profile.sound.enabled = value end)

    -- The other sound settings have no effect while the join sound is off
    local function IsSoundOn()
        return profile.sound.enabled
    end

    local guild = AddCheckbox("SOUND_GUILD", "Play for guild members",
        "Play the join sound when the rated player is in your guild",
        function() return profile.sound.guild end,
        function(value) profile.sound.guild = value end)
    guild:Indent()
    guild:SetParentInitializer(enabled, IsSoundOn)

    local friends = AddCheckbox("SOUND_FRIENDS", "Play for friends",
        "Play the join sound when the rated player is on your friend list or your Battle.net friend list",
        function() return profile.sound.friends end,
        function(value) profile.sound.friends = value end)
    friends:Indent()
    friends:SetParentInitializer(enabled, IsSoundOn)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Minimap"))

    AddCheckbox("MINIMAP", "Show minimap button",
        "Show the Kehet's Fellowship button on the minimap",
        function() return not profile.minimap.hide end,
        function(value) Fellowship:SetMinimapIconShown(value) end)

    Settings.RegisterAddOnCategory(category)
end

local function BuildPage()
    page.title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    page.title:SetPoint("TOPLEFT", 16, -16)
    page.title:SetText(DISPLAY_NAME)

    local sound = Fellowship.db.profile.sound

    page.soundHeader = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    page.soundHeader:SetPoint("TOPLEFT", 16, -52)
    page.soundHeader:SetText("Join sound")

    page.soundEnabled = UI.CreateCheckbox(page, "Play a sound when a rated player joins",
        "Play a sound when a player with a score other than 0 joins your group",
        function(checked)
            sound.enabled = checked
            page:Refresh()
        end)
    page.soundEnabled:SetPoint("TOPLEFT", 12, -70)

    page.soundGuild = UI.CreateCheckbox(page, "Play for guild members",
        "Play the join sound when the rated player is in your guild",
        function(checked) sound.guild = checked end)
    page.soundGuild:SetPoint("TOPLEFT", 32, -96)

    page.soundFriends = UI.CreateCheckbox(page, "Play for friends",
        "Play the join sound when the rated player is on your friend list or your Battle.net friend list",
        function(checked) sound.friends = checked end)
    page.soundFriends:SetPoint("TOPLEFT", 32, -122)

    page.minimapHeader = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    page.minimapHeader:SetPoint("TOPLEFT", 16, -164)
    page.minimapHeader:SetText("Minimap")

    page.minimap = UI.CreateCheckbox(page, "Show minimap button",
        "Show the Kehet's Fellowship button on the minimap",
        function(checked) Fellowship:SetMinimapIconShown(checked) end)
    page.minimap:SetPoint("TOPLEFT", 12, -182)

    page.messages = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    page.messages:SetPoint("TOPLEFT", 16, -224)
    page.messages:SetText("The chat messages are set on the Messages page under this one.")
end

local function RefreshPage()
    local profile = Fellowship.db.profile
    -- Settings other than the main toggle have no effect while the join sound is off
    local soundOff = not profile.sound.enabled
    UI.SetCheckbox(page.soundEnabled, profile.sound.enabled, false)
    UI.SetCheckbox(page.soundGuild, profile.sound.guild, soundOff)
    UI.SetCheckbox(page.soundFriends, profile.sound.friends, soundOff)
    UI.SetCheckbox(page.minimap, not profile.minimap.hide, false)
end

local function RegisterCanvasPage()
    page = CreateFrame("Frame")
    page.name = DISPLAY_NAME
    page.Refresh = RefreshPage
    page:SetScript("OnShow", function()
        if not page.title then
            BuildPage()
        end
        RefreshPage()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(page, DISPLAY_NAME)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(page)
    end
end

-- Register the settings page in the game's AddOns settings list
function Fellowship:RegisterOptions()
    if Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting then
        RegisterNativePage()
    else
        RegisterCanvasPage()
    end
    self:RegisterMessagePage(category)
end

-- Open the settings page
function Fellowship:OpenOptions()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(page)
    end
end

-- Update an open settings page after a setting is changed with a slash command
function Fellowship:RefreshOptions()
    for _, setting in pairs(settings) do
        setting:NotifyUpdate()
    end
    if page and page.title and page:IsVisible() then
        RefreshPage()
    end
end
