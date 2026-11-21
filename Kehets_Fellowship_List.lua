-- Player list window: every known player in a scrolling table with sorting and filtering
local UI = Fellowship.UI

local ROW_HEIGHT = 16

local SORT_ASC_ICON = " |TInterface\\Buttons\\Arrow-Up-Up:0|t"
local SORT_DESC_ICON = " |TInterface\\Buttons\\Arrow-Down-Up:0|t"

-- Normalize lastSeen to a sortable "YYYY-MM-DD HH:MM:SS" string, or "" if never seen.
-- Older entries may hold a unix timestamp instead of a string.
local function NormalizeLastSeen(lastSeen)
    if type(lastSeen) == "number" and lastSeen > 0 then
        return date("%Y-%m-%d %H:%M:%S", lastSeen)
    elseif type(lastSeen) == "string" then
        return lastSeen
    end
    return ""
end

local function GetClassName(classFileName)
    return classFileName and LOCALIZED_CLASS_NAMES_MALE[classFileName] or ""
end

local function GetTagsText(info)
    return info.tags and table.concat(info.tags, ", ") or ""
end

local function FormatScore(score)
    if type(score) ~= "number" then
        return "-"
    elseif score > 0 then
        return "|cFF33FF33+" .. score .. "|r"
    elseif score < 0 then
        return "|cFFFF4D4D" .. score .. "|r"
    end
    return "0"
end

-- Table columns, widths in pixels. sortValue returns the value a column sorts by;
-- "" always sorts last. display returns the cell text. Text columns sort ascending
-- on first click, numbers and dates descending.
local columns = {
    { key = "name", title = "Name", width = 150, ascending = true,
      sortValue = function(entry) return entry.name end,
      display = function(entry) return ColorizeNameByClass(entry.name, entry.info.class) end },
    { key = "class", title = "Class", width = 80, ascending = true,
      sortValue = function(entry) return GetClassName(entry.info.class) end,
      display = function(entry) return GetClassName(entry.info.class) end },
    { key = "score", title = "Score", width = 50, ascending = false, align = "CENTER",
      sortValue = function(entry) return entry.info.score or 0 end,
      display = function(entry) return FormatScore(entry.info.score) end },
    { key = "count", title = "Seen", width = 45, ascending = false, align = "CENTER",
      sortValue = function(entry) return entry.info.count or 0 end,
      display = function(entry) return tostring(entry.info.count or 0) end },
    { key = "lastSeen", title = "Last seen", width = 110, ascending = false,
      sortValue = function(entry) return NormalizeLastSeen(entry.info.lastSeen) end,
      display = function(entry)
          local lastSeen = NormalizeLastSeen(entry.info.lastSeen)
          return lastSeen ~= "" and lastSeen:sub(1, 16) or "Never"
      end },
    { key = "tags", title = "Tags", width = 140, ascending = true,
      sortValue = function(entry) return string.lower(GetTagsText(entry.info)) end,
      display = function(entry) return GetTagsText(entry.info) end },
    { key = "note", title = "Note", width = 255, ascending = true,
      sortValue = function(entry) return string.lower(entry.info.note or "") end,
      display = function(entry) return entry.info.note or "" end },
}

local columnsByKey = {}
for _, column in ipairs(columns) do
    columnsByKey[column.key] = column
end

local scoreFilters = {
    all = "All scores",
    positive = "Positive",
    neutral = "Neutral",
    negative = "Negative",
}
local scoreFilterOrder = { "all", "positive", "neutral", "negative" }

-- Window state, kept for the session so the list reopens the way it was left
local sortKey = "lastSeen"
local sortAscending = false
local filterText = ""
local scoreFilter = "all"

local function MatchesScoreFilter(score)
    score = score or 0
    if scoreFilter == "positive" then
        return score > 0
    elseif scoreFilter == "negative" then
        return score < 0
    elseif scoreFilter == "neutral" then
        return score == 0
    end
    return true
end

-- Match the search text against name, class, tags and note (case-insensitive)
local function MatchesText(entry, needle)
    if needle == "" then
        return true
    end
    local haystack = string.lower(table.concat({
        entry.name,
        GetClassName(entry.info.class),
        GetTagsText(entry.info),
        entry.info.note or "",
    }, "\n"))
    return string.find(haystack, needle, 1, true) ~= nil
end

local function GetFilteredSortedPlayers(players)
    local needle = string.lower(strtrim(filterText))
    local entries = {}

    for name, info in pairs(players) do
        local entry = { name = name, info = info }
        if MatchesScoreFilter(info.score) and MatchesText(entry, needle) then
            entry.sortValue = columnsByKey[sortKey].sortValue(entry)
            table.insert(entries, entry)
        end
    end

    table.sort(entries, function(a, b)
        local va, vb = a.sortValue, b.sortValue
        if va == vb then
            return a.name < b.name
        end
        if va == "" or vb == "" then
            return vb == ""
        end
        if sortAscending then
            return va < vb
        end
        return va > vb
    end)

    return entries
end

local function ShowPlayerTooltip(owner, entry)
    local info = entry.info
    GameTooltip:SetOwner(owner, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine(ColorizeNameByClass(entry.name, info.class))
    GameTooltip:AddDoubleLine("Score", FormatScore(info.score), 1, 1, 1)
    GameTooltip:AddDoubleLine("Grouped", (info.count or 0) .. " times", 1, 1, 1, 1, 1, 1)
    local lastSeen = NormalizeLastSeen(info.lastSeen)
    GameTooltip:AddDoubleLine("Last seen", lastSeen ~= "" and lastSeen or "Never", 1, 1, 1, 1, 1, 1)
    if info.tags and #info.tags > 0 then
        GameTooltip:AddLine("Tags: " .. GetTagsText(info), 0.8, 0.8, 0.8, true)
    end
    if info.note and info.note ~= "" then
        GameTooltip:AddLine(info.note, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

-- Names are stored in lower case. Capitalize the name and realm for display and copying.
local function GetDisplayName(name)
    return (name:gsub("^%l", string.upper):gsub("[ %-]%l", string.upper))
end

local function Whisper(name)
    if ChatFrameUtil and ChatFrameUtil.SendTell then
        ChatFrameUtil.SendTell(name)
    else
        ChatFrame_SendTell(name)
    end
end

local function Invite(name)
    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(name)
    else
        InviteUnit(name)
    end
end

-- The game does not let addons write to the clipboard, so show the name selected in a text box
StaticPopupDialogs["KEHETS_FELLOWSHIP_COPY_NAME"] = {
    text = "Press Ctrl+C to copy the name.",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 250,
    OnShow = function(self, data)
        local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
        editBox:SetText(data or self.data or "")
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["KEHETS_FELLOWSHIP_REMOVE_PLAYER"] = {
    text = "Remove %s from the known players?\n\nThe score, note and tags are deleted.",
    button1 = "Remove",
    button2 = "Cancel",
    OnAccept = function(self, data)
        Fellowship:RemoveScore(data or self.data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
}

-- Right-click menu with the actions of the guild roster menu. Clients without the menu system get no menu.
local function ShowPlayerMenu(owner, entry)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        return
    end
    GameTooltip:Hide()

    local name = entry.name
    local displayName = GetDisplayName(name)
    MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
        rootDescription:CreateTitle(ColorizeNameByClass(displayName, entry.info.class))
        rootDescription:CreateButton("Edit", function() Fellowship:ShowEditPlayer(name) end)
        rootDescription:CreateDivider()
        rootDescription:CreateButton("Whisper", function() Whisper(name) end)
        rootDescription:CreateButton("Invite", function() Invite(name) end)
        rootDescription:CreateButton("Add Friend", function() C_FriendList.AddFriend(name) end)
        rootDescription:CreateButton("Ignore", function() C_FriendList.AddIgnore(name) end)
        rootDescription:CreateButton("Copy Character Name", function()
            StaticPopup_Show("KEHETS_FELLOWSHIP_COPY_NAME", nil, nil, displayName)
        end)
        rootDescription:CreateDivider()
        rootDescription:CreateButton("Remove from Known Players", function()
            StaticPopup_Show("KEHETS_FELLOWSHIP_REMOVE_PLAYER", displayName, nil, name)
        end)
    end)
end

local CELL_PADDING = 3
local ROW_HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

-- The window is created on first use and kept, since frames cannot be destroyed
local window

local function GetTableWidth()
    local width = 0
    for _, column in ipairs(columns) do
        width = width + column.width
    end
    return width
end

-- Create one font string per column across a row
local function CreateCells(parent, fontObject)
    local cells = {}
    local x = 0
    for i, column in ipairs(columns) do
        local cell = parent:CreateFontString(nil, "OVERLAY", fontObject)
        cell:SetPoint("LEFT", parent, "LEFT", x + CELL_PADDING, 0)
        cell:SetWidth(column.width - 2 * CELL_PADDING)
        cell:SetJustifyH(column.align or "LEFT")
        -- Keep every cell on one line; text that does not fit ends in "..."
        cell:SetWordWrap(false)
        cells[i] = cell
        x = x + column.width
    end
    return cells
end

-- Fill a pooled row of the scrolling list with one player
local function InitRow(row, entry)
    if not row.cells then
        row:SetHighlightTexture(ROW_HIGHLIGHT, "ADD")
        row.stripe = row:CreateTexture(nil, "BACKGROUND")
        row.stripe:SetAllPoints()
        row.stripe:SetColorTexture(1, 1, 1, 0.04)
        row.cells = CreateCells(row, "GameFontHighlightSmall")
        row:SetScript("OnEnter", function(self)
            ShowPlayerTooltip(self, self.entry)
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:RegisterForClicks("RightButtonUp")
        row:SetScript("OnClick", function(self)
            ShowPlayerMenu(self, self.entry)
        end)
    end

    row.entry = entry
    row.stripe:SetShown(entry.index % 2 == 0)
    for i, column in ipairs(columns) do
        row.cells[i]:SetText(column.display(entry))
    end
end

local function SetSort(column)
    if sortKey == column.key then
        sortAscending = not sortAscending
    else
        sortKey = column.key
        sortAscending = column.ascending
    end
    Fellowship:RefreshPlayerList(true)
end

local function SetScoreFilter(key)
    scoreFilter = key
    Fellowship:RefreshPlayerList(true)
end

-- The score filter is a dropdown where the client has the menu system, otherwise a row of buttons
local function CreateScoreFilter(frame, anchor)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", anchor, "RIGHT", 24, 0)
    label:SetText("Score:")

    if UI.HasTemplate("WowStyle1DropdownTemplate") then
        local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(150)
        dropdown:SetPoint("LEFT", label, "RIGHT", 8, 0)
        dropdown:SetupMenu(function(_, rootDescription)
            for _, key in ipairs(scoreFilterOrder) do
                rootDescription:CreateRadio(scoreFilters[key],
                    function() return scoreFilter == key end,
                    function() SetScoreFilter(key) end)
            end
        end)
        frame.scoreDropdown = dropdown
        return
    end

    frame.scoreButtons = {}
    local previous = label
    for _, key in ipairs(scoreFilterOrder) do
        local button = UI.CreateButton(frame, scoreFilters[key], 90, function()
            SetScoreFilter(key)
        end)
        button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        frame.scoreButtons[key] = button
        previous = button
    end
end

local function CreateWindow()
    local tableWidth = GetTableWidth()
    local frame = UI.CreateWindow("KehetsFellowshipPlayerList", "Kehet's Fellowship - Known Players", tableWidth + 60, 560)
    frame:SetScript("OnHide", function()
        GameTooltip:Hide()
        frame.search:ClearFocus()
    end)

    -- Filters
    local search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetPoint("TOPLEFT", 26, -36)
    search:SetSize(300, 20)
    search:SetAutoFocus(false)
    if search.Instructions then
        search.Instructions:SetText("Search name, class, tags or note")
    end
    search:SetText(filterText)
    search:HookScript("OnTextChanged", function(self)
        if self:GetText() ~= filterText then
            filterText = self:GetText()
            Fellowship:RefreshPlayerList(true)
        end
    end)
    frame.search = search

    CreateScoreFilter(frame, search)

    -- Column headers, click to sort the whole list. They overlap by 2 pixels, as the native ones do.
    frame.headers = {}
    local x = 0
    for i, column in ipairs(columns) do
        local header = UI.CreateColumnHeader(frame, column.width + 2, function()
            SetSort(column)
        end)
        header:SetPoint("TOPLEFT", 18 + x, -66)
        frame.headers[i] = header
        x = x + column.width
    end

    -- Rows are as wide as the headers; the scroll bar sits right of them
    frame.list = UI.CreateScrollList(frame, "Button", ROW_HEIGHT, InitRow)
    frame.list:SetPoint("TOPLEFT", 16, -92)
    frame.list:SetPoint("BOTTOMRIGHT", -16, 40)

    frame.emptyText = frame.list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.emptyText:SetPoint("CENTER")

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("BOTTOMLEFT", 24, 16)

    return frame
end

-- Show the player list window, or refresh it if it is already open
function Fellowship:ShowPlayerList()
    if not window then
        window = CreateWindow()
    end
    window:Show()
    self:RefreshPlayerList()
end

-- Rebuild the table from the database. Does nothing if the window is closed.
-- The list keeps its scroll position unless scrollToTop is set, as after a new sort or filter.
function Fellowship:RefreshPlayerList(scrollToTop)
    if not window or not window:IsShown() then
        return
    end

    local players = self.db.factionrealm.players
    local entries = GetFilteredSortedPlayers(players)
    for i, entry in ipairs(entries) do
        entry.index = i
    end

    for i, column in ipairs(columns) do
        local text = column.title
        if column.key == sortKey then
            text = text .. (sortAscending and SORT_ASC_ICON or SORT_DESC_ICON)
        end
        window.headers[i]:SetText(text)
    end

    window.list.scrollBox:SetDataProvider(CreateDataProvider(entries), not scrollToTop)

    if #entries == 0 then
        window.emptyText:SetText(next(players) and "No players match the filter." or "No players found in the database.")
        window.emptyText:Show()
    else
        window.emptyText:Hide()
    end

    if window.scoreDropdown then
        window.scoreDropdown:GenerateMenu()
    else
        UI.SetChosen(window.scoreButtons, scoreFilter)
    end

    local total = 0
    for _ in pairs(players) do
        total = total + 1
    end
    window.status:SetText(#entries .. " of " .. total .. " known players shown")
end
