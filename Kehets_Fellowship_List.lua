-- Player list window: every known player in a table with sorting, filtering and pagination
local AceGUI = LibStub("AceGUI-3.0")

local PAGE_SIZE = 25
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
local currentPage = 1

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

local CELL_PADDING = 3
local ROW_HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

-- Frames cannot be destroyed, so the table is created on first use and moved
-- into each new window
local playerTable

-- Create one font string per column across a row or header frame
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

local function GetPlayerTable()
    if playerTable then
        return playerTable
    end

    local width = 0
    for _, column in ipairs(columns) do
        width = width + column.width
    end

    local tableFrame = CreateFrame("Frame", nil, UIParent)
    tableFrame:SetSize(width, ROW_HEIGHT * (PAGE_SIZE + 1) + 2)

    local background = tableFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.3)

    -- Header: one button per column, click to sort the whole list
    local header = CreateFrame("Frame", nil, tableFrame)
    header:SetPoint("TOPLEFT")
    header:SetSize(width, ROW_HEIGHT)
    tableFrame.headerCells = CreateCells(header, "GameFontNormalSmall")

    local x = 0
    for _, column in ipairs(columns) do
        local button = CreateFrame("Button", nil, header)
        button:SetPoint("TOPLEFT", header, "TOPLEFT", x, 0)
        button:SetSize(column.width, ROW_HEIGHT)
        button:SetHighlightTexture(ROW_HIGHLIGHT, "ADD")
        button:SetScript("OnClick", function()
            if sortKey == column.key then
                sortAscending = not sortAscending
            else
                sortKey = column.key
                sortAscending = column.ascending
            end
            currentPage = 1
            Fellowship:RefreshPlayerList()
        end)
        x = x + column.width
    end

    local divider = tableFrame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    divider:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
    divider:SetHeight(1)
    divider:SetColorTexture(1, 0.82, 0, 0.5)

    -- Rows, striped, with the full player details as a tooltip
    tableFrame.rows = {}
    for i = 1, PAGE_SIZE do
        local row = CreateFrame("Button", nil, tableFrame)
        row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2 - (i - 1) * ROW_HEIGHT)
        row:SetSize(width, ROW_HEIGHT)
        row:SetHighlightTexture(ROW_HIGHLIGHT, "ADD")
        if i % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.04)
        end
        row.cells = CreateCells(row, "GameFontHighlightSmall")
        row:SetScript("OnEnter", function(self)
            if self.entry then
                ShowPlayerTooltip(self, self.entry)
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        tableFrame.rows[i] = row
    end

    tableFrame.emptyText = tableFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    tableFrame.emptyText:SetPoint("CENTER")

    playerTable = tableFrame
    return playerTable
end

-- Show the player list window, or refresh it if it is already open
function Fellowship:ShowPlayerList()
    if self.playerListWidgets then
        self:RefreshPlayerList()
        return
    end

    local widgets = {}
    local st = GetPlayerTable()
    widgets.table = st

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Kehet's Fellowship - Known Players")
    frame:SetLayout("Flow")
    frame:SetWidth(900)
    frame:SetHeight(600)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        -- Detach the table before AceGUI recycles its container for another window
        GameTooltip:Hide()
        st:Hide()
        st:ClearAllPoints()
        st:SetParent(UIParent)
        AceGUI:Release(widget)
        self.playerListWidgets = nil
    end)
    widgets.frame = frame

    -- Filters
    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetLabel("Search name, class, tags or note")
    searchBox:SetText(filterText)
    searchBox:SetWidth(300)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(widget, event, text)
        filterText = text
        currentPage = 1
        self:RefreshPlayerList()
    end)
    frame:AddChild(searchBox)

    local scoreDropdown = AceGUI:Create("Dropdown")
    scoreDropdown:SetLabel("Score")
    scoreDropdown:SetList(scoreFilters, scoreFilterOrder)
    scoreDropdown:SetValue(scoreFilter)
    scoreDropdown:SetWidth(150)
    scoreDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        scoreFilter = key
        currentPage = 1
        self:RefreshPlayerList()
    end)
    frame:AddChild(scoreDropdown)

    -- Placeholder that reserves space for the table
    local tableHolder = AceGUI:Create("SimpleGroup")
    tableHolder:SetFullWidth(true)
    tableHolder:SetAutoAdjustHeight(false) -- It has no AceGUI children to size it
    tableHolder:SetHeight(st:GetHeight() + 8)
    frame:AddChild(tableHolder)

    st:SetParent(tableHolder.frame)
    st:ClearAllPoints()
    st:SetPoint("TOPLEFT", tableHolder.frame, "TOPLEFT", 0, -4)
    st:Show()

    -- Pagination
    local footer = AceGUI:Create("SimpleGroup")
    footer:SetFullWidth(true)
    footer:SetLayout("Flow")
    frame:AddChild(footer)

    local prevButton = AceGUI:Create("Button")
    prevButton:SetText("< Previous")
    prevButton:SetWidth(110)
    prevButton:SetCallback("OnClick", function()
        currentPage = currentPage - 1
        self:RefreshPlayerList()
    end)
    footer:AddChild(prevButton)
    widgets.prevButton = prevButton

    local pageLabel = AceGUI:Create("Label")
    pageLabel:SetWidth(200)
    pageLabel:SetJustifyH("CENTER")
    footer:AddChild(pageLabel)
    widgets.pageLabel = pageLabel

    local nextButton = AceGUI:Create("Button")
    nextButton:SetText("Next >")
    nextButton:SetWidth(110)
    nextButton:SetCallback("OnClick", function()
        currentPage = currentPage + 1
        self:RefreshPlayerList()
    end)
    footer:AddChild(nextButton)
    widgets.nextButton = nextButton

    self.playerListWidgets = widgets
    self:RefreshPlayerList()
    frame:Show()
end

-- Rebuild the table from the database. Does nothing if the window is closed.
function Fellowship:RefreshPlayerList()
    local widgets = self.playerListWidgets
    if not widgets then
        return
    end

    local players = self.db.factionrealm.players
    local entries = GetFilteredSortedPlayers(players)

    local pageCount = math.max(1, math.ceil(#entries / PAGE_SIZE))
    currentPage = math.min(math.max(currentPage, 1), pageCount)

    local st = widgets.table
    for i, column in ipairs(columns) do
        local text = column.title
        if column.key == sortKey then
            text = text .. (sortAscending and SORT_ASC_ICON or SORT_DESC_ICON)
        end
        st.headerCells[i]:SetText(text)
    end

    local first = (currentPage - 1) * PAGE_SIZE
    for i, row in ipairs(st.rows) do
        local entry = entries[first + i]
        row.entry = entry
        if entry then
            for j, column in ipairs(columns) do
                row.cells[j]:SetText(column.display(entry))
            end
            row:Show()
        else
            row:Hide()
        end
    end

    if #entries == 0 then
        st.emptyText:SetText(next(players) and "No players match the filter." or "No players found in the database.")
        st.emptyText:Show()
    else
        st.emptyText:Hide()
    end

    widgets.pageLabel:SetText("Page " .. currentPage .. " of " .. pageCount)
    widgets.prevButton:SetDisabled(currentPage <= 1)
    widgets.nextButton:SetDisabled(currentPage >= pageCount)

    local total = 0
    for _ in pairs(players) do
        total = total + 1
    end
    widgets.frame:SetStatusText(#entries .. " of " .. total .. " known players shown")
end
