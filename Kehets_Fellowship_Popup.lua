-- Popup that asks the player to rate the players of the group they just left
local UI = Fellowship.UI

local WINDOW_WIDTH = 520
local ROW_HEIGHT = 74
local ROW_SPACING = 12
local CONTENT_WIDTH = WINDOW_WIDTH - 44

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

local function GetPlayer(playerName)
    local players = Fellowship.db.factionrealm.players
    players[playerName] = players[playerName] or {}
    return players[playerName]
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
        Fellowship:Print("Tags for " .. row.playerName .. ": " .. table.concat(tagList, ", "))
        Fellowship:RefreshPlayerList()
    end)
    row.tags:SetPoint("LEFT", row.note, "RIGHT", 12, 0)
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
    row.tags:ClearFocus()
    row.tags:SetText(table.concat(playerData.tags or {}, ", "))
    row.tags:SetCursorPosition(0)
end

local function CreateWindow()
    local frame = UI.CreateWindow("KehetsFellowshipLastGroup", "Remember Players from Your Last Group", WINDOW_WIDTH, 340)

    frame.list = UI.CreateScrollList(frame, "Frame", ROW_HEIGHT, InitRow, ROW_SPACING)
    frame.list:SetPoint("TOPLEFT", 10, -30)
    frame.list:SetPoint("BOTTOMRIGHT", -10, 42)

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

    window.list.scrollBox:SetDataProvider(CreateDataProvider(elements))
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
