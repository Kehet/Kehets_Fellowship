-- Popup that asks the player to rate the players of the group they just left.
-- The player list opens the same window to edit one known player.
local UI = Fellowship.UI

local WINDOW_WIDTH = 520
local ROW_HEIGHT = 74
local ROW_SPACING = 12
local CONTENT_WIDTH = WINDOW_WIDTH - 44

-- Preset tag buttons, in lines of PRESETS_PER_LINE under the note and tags
local PRESETS_PER_LINE = 5
local PRESET_SPACING = 4
local PRESET_LINE_HEIGHT = 24
local PRESET_WIDTH = (CONTENT_WIDTH - 8 - (PRESETS_PER_LINE - 1) * PRESET_SPACING) / PRESETS_PER_LINE

-- The window is created on first use and kept
local window

-- Parse comma-separated tags, trimming whitespace and dropping empty ones
local function ParseTags(text)
    local tagList = {}
    if text and text ~= "" then
        for tag in string.gmatch(text, "[^,]+") do
            local trimmedTag = string.match(tag, "^%s*(.-)%s*$")
            if trimmedTag ~= "" then
                table.insert(tagList, trimmedTag)
            end
        end
    end
    return tagList
end

-- Parse the preset list, dropping repeats that differ only in case
local function ParsePresets(text)
    local presets = {}
    for _, tag in ipairs(ParseTags(text)) do
        AddTagIfMissing(presets, tag)
    end
    return presets
end

local function GetPresets()
    return Fellowship.db.profile.presetTags
end

local function GetRowHeight()
    local lines = math.ceil(#GetPresets() / PRESETS_PER_LINE)
    return ROW_HEIGHT + lines * PRESET_LINE_HEIGHT
end

local function FindTag(tags, tag)
    for i, existing in ipairs(tags) do
        if string.lower(existing) == string.lower(tag) then
            return i
        end
    end
end

local function GetPlayer(playerName)
    local players = Fellowship.db.factionrealm.players
    players[playerName] = players[playerName] or {}
    return players[playerName]
end

local function ShowTags(row, tags)
    row.tags:ClearFocus()
    row.tags:SetText(table.concat(tags, ", "))
    row.tags:SetCursorPosition(0)
end

local function UpdatePresetButtons(row)
    local tags = (Fellowship.db.factionrealm.players[row.playerName] or {}).tags or {}
    for _, button in ipairs(row.presetButtons) do
        if button:IsShown() then
            UI.SetButtonChosen(button, FindTag(tags, button.tag) ~= nil)
        end
    end
end

-- Add the preset tag to the player, or remove it if they have it
local function TogglePresetTag(row, tag)
    local playerData = GetPlayer(row.playerName)
    playerData.tags = playerData.tags or {}
    local index = FindTag(playerData.tags, tag)
    if index then
        table.remove(playerData.tags, index)
    else
        table.insert(playerData.tags, tag)
    end
    ShowTags(row, playerData.tags)
    UpdatePresetButtons(row)
    Fellowship:Print("Tags for " .. row.playerName .. ": " .. table.concat(playerData.tags, ", "))
    Fellowship:RefreshPlayerList()
end

-- Show one button for each preset, making more buttons when the row has too few
local function LayoutPresetButtons(row)
    local presets = GetPresets()
    for i, tag in ipairs(presets) do
        local button = row.presetButtons[i]
        if not button then
            button = UI.CreateButton(row, "", PRESET_WIDTH, function(self)
                TogglePresetTag(row, self.tag)
            end)
            button:SetHeight(20)
            local column = (i - 1) % PRESETS_PER_LINE
            local line = math.floor((i - 1) / PRESETS_PER_LINE)
            button:SetPoint("TOPLEFT", 4 + column * (PRESET_WIDTH + PRESET_SPACING), -ROW_HEIGHT - line * PRESET_LINE_HEIGHT)
            button:GetFontString():SetWidth(PRESET_WIDTH - 8)
            button:GetFontString():SetWordWrap(false)
            row.presetButtons[i] = button
        end
        button.tag = tag
        button:SetText(tag)
        button:Show()
    end
    for i = #presets + 1, #row.presetButtons do
        row.presetButtons[i]:Hide()
    end
end

-- Build the controls of a pooled row once; InitRow fills them for one player
local function BuildRow(row)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", 4, -6)
    row.name:SetWidth(150)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Score slider from -2 to 2. The score is saved at once; the chat line waits until the slider stops,
    -- so a drag across several values prints one line.
    row.score = UI.CreateScoreSlider(row, 220, function(score)
        if row.initializing then
            return
        end
        local playerName = row.playerName
        GetPlayer(playerName).score = score
        Fellowship:RefreshPlayerList()
        if row.printTimer then
            row.printTimer:Cancel()
        end
        row.printTimer = C_Timer.NewTimer(0.5, function()
            Fellowship:Print("Player " .. playerName .. " scored: " .. score)
        end)
    end)
    row.score:SetPoint("LEFT", row, "TOPLEFT", 160, -14)

    local boxWidth = (CONTENT_WIDTH - 24) / 2
    row.note = UI.CreateEditBox(row, "Note:", boxWidth, function(text)
        GetPlayer(row.playerName).note = text
        Fellowship:Print("Note for " .. row.playerName .. ": " .. text)
        Fellowship:RefreshPlayerList()
    end)
    row.note:SetPoint("TOPLEFT", 8, -44)

    row.tags = UI.CreateEditBox(row, "Tags (comma-separated):", boxWidth, function(text)
        local tagList = ParseTags(text)
        GetPlayer(row.playerName).tags = tagList
        UpdatePresetButtons(row)
        Fellowship:Print("Tags for " .. row.playerName .. ": " .. table.concat(tagList, ", "))
        Fellowship:RefreshPlayerList()
    end)
    row.tags:SetPoint("LEFT", row.note, "RIGHT", 12, 0)

    row.presetButtons = {}
end

local function InitRow(row, element)
    if not row.name then
        BuildRow(row)
    end

    local playerData = Fellowship.db.factionrealm.players[element.playerName] or {}
    row.playerName = element.playerName
    row.name:SetText(ColorizeNameByClass(element.playerName, playerData.class))
    row.initializing = true
    row.score:SetValue(tonumber(playerData.score) or 0)
    row.initializing = false
    row.note:ClearFocus()
    row.note:SetText(playerData.note or "")
    row.note:SetCursorPosition(0)
    ShowTags(row, playerData.tags or {})
    LayoutPresetButtons(row)
    UpdatePresetButtons(row)
end

local function SavePresets(dialog)
    local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
    Fellowship.db.profile.presetTags = ParsePresets(editBox:GetText())
    -- Lay the rows out again with the new buttons and row height
    if window and window:IsShown() then
        window.list.scrollBox:SetDataProvider(CreateDataProvider(window.elements), true)
    end
end

StaticPopupDialogs["KEHETS_FELLOWSHIP_PRESET_TAGS"] = {
    text = "Preset tags, comma-separated.\nThe rating window shows a button for each one.",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 350,
    maxLetters = 1000,
    OnShow = function(self)
        local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
        editBox:SetText(table.concat(GetPresets(), ", "))
        editBox:SetFocus()
    end,
    OnAccept = SavePresets,
    EditBoxOnEnterPressed = function(self)
        local dialog = self:GetParent()
        SavePresets(dialog)
        dialog:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Open the dialog that edits the preset tags; the settings page has a button for it
function Fellowship:ShowPresetTagsDialog()
    StaticPopup_Show("KEHETS_FELLOWSHIP_PRESET_TAGS")
end

local LAST_GROUP_TITLE = "Remember Players from Your Last Group"

local function CreateWindow()
    local frame = UI.CreateWindow("KehetsFellowshipLastGroup", LAST_GROUP_TITLE, WINDOW_WIDTH, 340)

    frame.list = UI.CreateScrollList(frame, "Frame", GetRowHeight, InitRow, ROW_SPACING)
    frame.list:SetPoint("TOPLEFT", 10, -30)
    frame.list:SetPoint("BOTTOMRIGHT", -10, 42)

    frame.closeButton = UI.CreateButton(frame, "Close", 100, function()
        frame:Hide()
    end)
    frame.closeButton:SetPoint("BOTTOM", 0, 12)

    return frame
end

-- Show the window with one row for each of the given players
local function ShowPlayers(title, elements)
    if not window then
        window = CreateWindow()
    end
    window.titleText:SetText(title)
    window.elements = elements
    window.list.scrollBox:SetDataProvider(CreateDataProvider(elements))
    window:Show()
    window:Raise()
end

-- Function to show a popup for remembering players from the previous group
function Fellowship:ShowPreviousGroupPopup()
    -- If there are no players in the previous group, show a message
    if not previousGroupMembers or next(previousGroupMembers) == nil then
        self:Print("No previous group to show.")
        return
    end

    local elements = {}
    for playerName, roleTag in pairs(previousGroupMembers) do
        -- Tag the player with the role they had in the group, unless they already have that tag
        local playerData = self.db.factionrealm.players[playerName]
        if playerData and type(roleTag) == "string" then
            playerData.tags = playerData.tags or {}
            AddTagIfMissing(playerData.tags, roleTag)
        end
        table.insert(elements, { playerName = playerName })
    end
    table.sort(elements, function(a, b) return a.playerName < b.playerName end)

    ShowPlayers(LAST_GROUP_TITLE, elements)
end

-- Edit the score, note and tags of one known player
function Fellowship:ShowEditPlayer(playerName)
    ShowPlayers("Edit Player", { { playerName = playerName } })
end

-- Close the previous group popup if it is open, otherwise show it
function Fellowship:TogglePreviousGroupPopup()
    if window and window:IsShown() then
        window:Hide()
    else
        self:ShowPreviousGroupPopup()
    end
end
