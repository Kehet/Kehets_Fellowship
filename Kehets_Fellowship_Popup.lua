-- Popup that asks the player to rate the players of the group they just left
local UI = Fellowship.UI

local WINDOW_WIDTH = 520
local ROW_HEIGHT = 74
local CONTENT_WIDTH = WINDOW_WIDTH - 60

-- The window is created on first use and kept, with one row per player that is reused
local window
local rows = {}

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

local function GetPlayer(playerName)
    local players = Fellowship.db.factionrealm.players
    players[playerName] = players[playerName] or {}
    return players[playerName]
end

local function GetRow(index)
    if rows[index] then
        return rows[index]
    end

    local row = CreateFrame("Frame", nil, window.content)
    row:SetSize(CONTENT_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", 4, -6)
    row.name:SetWidth(150)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    -- Score buttons from -2 to 2
    row.scoreButtons = {}
    for score = -2, 2 do
        local button = UI.CreateButton(row, tostring(score), 44, function()
            GetPlayer(row.playerName).score = score
            Fellowship:Print("Player " .. row.playerName .. " scored: " .. score)
            UI.SetChosen(row.scoreButtons, score)
            Fellowship:RefreshPlayerList()
        end)
        button.label = tostring(score)
        button:SetPoint("TOPLEFT", 160 + (score + 2) * 48, -2)
        row.scoreButtons[score] = button
    end

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
        Fellowship:Print("Tags for " .. row.playerName .. ": " .. table.concat(tagList, ", "))
        Fellowship:RefreshPlayerList()
    end)
    row.tags:SetPoint("LEFT", row.note, "RIGHT", 12, 0)

    rows[index] = row
    return row
end

local function CreateWindow()
    local frame = UI.CreateWindow("KehetsFellowshipLastGroup", "Remember Players from Your Last Group", WINDOW_WIDTH, 340)
    frame:SetScript("OnHide", function()
        for _, row in ipairs(rows) do
            row.note:ClearFocus()
            row.tags:ClearFocus()
        end
    end)

    local inset = CreateFrame("Frame", nil, frame, UI.HasTemplate("InsetFrameTemplate3") and "InsetFrameTemplate3" or nil)
    inset:SetPoint("TOPLEFT", 10, -30)
    inset:SetPoint("BOTTOMRIGHT", -10, 42)

    frame.scroll = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 6, -6)
    frame.scroll:SetPoint("BOTTOMRIGHT", -26, 6)

    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetSize(CONTENT_WIDTH, 1)
    frame.scroll:SetScrollChild(frame.content)

    frame.closeButton = UI.CreateButton(frame, "Close", 100, function()
        frame:Hide()
    end)
    frame.closeButton:SetPoint("BOTTOM", 0, 12)

    return frame
end

-- Function to show a popup for remembering players from the previous group
function Fellowship:ShowPreviousGroupPopup()
    -- If there are no players in the previous group, show a message
    if not previousGroupMembers or next(previousGroupMembers) == nil then
        self:Print("No previous group to show.")
        return
    end

    if not window then
        window = CreateWindow()
    end

    local index = 0
    for playerName, roleTag in pairs(previousGroupMembers) do
        index = index + 1
        local row = GetRow(index)
        local playerData = self.db.factionrealm.players[playerName] or {}

        -- Tag the player with the role they had in the group, unless they already have that tag
        if type(roleTag) == "string" then
            playerData.tags = playerData.tags or {}
            AddTagIfMissing(playerData.tags, roleTag)
        end

        row.playerName = playerName
        row.name:SetText(ColorizeNameByClass(playerName, playerData.class))
        UI.SetChosen(row.scoreButtons, playerData.score)
        row.note:SetText(playerData.note or "")
        row.note:SetCursorPosition(0)
        row.tags:SetText(table.concat(playerData.tags or {}, ", "))
        row.tags:SetCursorPosition(0)
        row:Show()
    end
    for i = index + 1, #rows do
        rows[i]:Hide()
    end

    window.content:SetHeight(math.max(1, index * ROW_HEIGHT))
    window.scroll:SetVerticalScroll(0)
    window:Show()
    window:Raise()
end

-- Close the previous group popup if it is open, otherwise show it
function Fellowship:TogglePreviousGroupPopup()
    if window and window:IsShown() then
        window:Hide()
    else
        self:ShowPreviousGroupPopup()
    end
end
