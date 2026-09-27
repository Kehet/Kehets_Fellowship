-- Declare global tables for party and previous group members
partyMembers = {}
previousGroupMembers = {}

-- Get a player's full name in "CharacterName-RealmName" format
function GetFullPlayerName(name, realm)
    if not name or name == "" or name == "Unknown" then
        name = UnitName("player")
    end
    if not realm or realm == "" then
        return string.lower(name)
    end
    return string.lower(name .. "-" .. realm)
end

-- Function to colorize text by class
function ColorizeNameByClass(playerName, classFileName)
    if classFileName and RAID_CLASS_COLORS[classFileName] then
        local classColor = RAID_CLASS_COLORS[classFileName]
        return format("|cFF%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, playerName)
    else
        return playerName -- Fallback if class is not found
    end
end

-- Get the current timestamp
function GetTimestamp()
    return date("%Y-%m-%d %H:%M:%S")
end

-- Get the current instance ID
function GetCurrentInstanceID()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    return instanceID
end

-- Announce a known player in chat when they join the group. Players with a
-- positive score get a highlighted line, everyone else a plain reminder.
function Fellowship:AnnounceKnownPlayer(fullName, info)
    local name = ColorizeNameByClass(fullName, info.class)
    local details = {}

    if info.score and info.score ~= 0 then
        table.insert(details, "score " .. (info.score > 0 and "+" or "") .. info.score)
    end
    if info.note and info.note ~= "" then
        table.insert(details, info.note)
    end
    if info.lastSeen then
        table.insert(details, "last grouped " .. info.lastSeen)
    end

    local suffix = #details > 0 and (" (" .. table.concat(details, " - ") .. ")") or ""

    if info.score and info.score > 0 then
        self:Print("|cFF33FF33Good player joined:|r " .. name .. suffix)
    else
        self:Print("You have grouped with " .. name .. " before" .. suffix)
    end
end

-- Record one group member and announce them the first time they appear in this group
function Fellowship:ProcessGroupUnit(unit, fullPlayerName, instanceID)
    local name, realm = UnitName(unit)
    if not name then
        return
    end

    local fullName = GetFullPlayerName(name, realm)
    if fullName == fullPlayerName then
        return
    end

    local _, classFileName = UnitClass(unit)
    local info = self.db.factionrealm.players[fullName]
    local isNewToGroup = not partyMembers[fullName]

    -- Add new players to the current session's party members (do not remove players who leave)
    partyMembers[fullName] = true

    if not info then
        self.db.factionrealm.players[fullName] = {
            lastSeen = GetTimestamp(),
            count = 1,
            lastInstanceID = instanceID,
            score = 0,
            note = nil,
            tags = {},
            class = classFileName
        }
        return
    end

    if isNewToGroup then
        self:AnnounceKnownPlayer(fullName, info)
    end

    -- Count each instance run together once
    if info.lastInstanceID ~= instanceID and instanceID ~= nil then
        info.lastInstanceID = instanceID
        info.count = (info.count or 0) + 1
        info.lastSeen = GetTimestamp()
    end

    info.class = info.class or classFileName
end

-- Update the party members table when the group changes, but do not remove players who leave
function Fellowship:UpdatePartyMembers()
    local instanceID = GetCurrentInstanceID()
    local numGroupMembers = GetNumGroupMembers()

    local playerName, playerRealm = UnitName("player")
    local fullPlayerName = GetFullPlayerName(playerName, playerRealm)

    if IsInRaid() then
        for i = 1, numGroupMembers do
            self:ProcessGroupUnit("raid" .. i, fullPlayerName, instanceID)
        end
    elseif IsInGroup() then
        -- "party" units don't include the player themselves
        for i = 1, numGroupMembers - 1 do
            self:ProcessGroupUnit("party" .. i, fullPlayerName, instanceID)
        end
    end
end
