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

-- Convert a lastSeen value to a unix timestamp, or nil if it can't be read.
-- New entries hold a "YYYY-MM-DD HH:MM:SS" string, older ones a unix timestamp.
local function LastSeenToTime(lastSeen)
    if type(lastSeen) == "number" then
        return lastSeen > 0 and lastSeen or nil
    end
    if type(lastSeen) ~= "string" then
        return nil
    end
    local year, month, day, hour, min, sec = lastSeen:match("^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)$")
    if not year then
        return nil
    end
    return time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
    })
end

-- Format a count with its unit, e.g. "1 day ago" or "3 days ago"
local function Ago(count, unit)
    return count .. " " .. unit .. (count == 1 and "" or "s") .. " ago"
end

-- Describe how long ago a lastSeen value was, e.g. "3 days ago".
-- Returns the value as text if it can't be read.
function FormatTimeAgo(lastSeen)
    local timestamp = LastSeenToTime(lastSeen)
    if not timestamp then
        return tostring(lastSeen or "Unknown")
    end

    local diff = math.max(0, time() - timestamp)
    if diff < 60 then
        return "just now"
    elseif diff < 3600 then
        return Ago(math.floor(diff / 60), "minute")
    elseif diff < 86400 then
        return Ago(math.floor(diff / 3600), "hour")
    elseif diff < 86400 * 30 then
        return Ago(math.floor(diff / 86400), "day")
    elseif diff < 86400 * 365 then
        return Ago(math.floor(diff / (86400 * 30)), "month")
    end
    return Ago(math.floor(diff / (86400 * 365)), "year")
end

-- Tag names for the group roles returned by UnitGroupRolesAssigned
local roleTags = {
    TANK = "Tank",
    HEALER = "Healer",
    DAMAGER = "DPS",
}

-- Get the role tag for a group unit, or nil if the unit has no role assigned
function GetRoleTag(unit)
    return roleTags[UnitGroupRolesAssigned(unit)]
end

-- Add a tag to a tag list unless it is already there (case-insensitive).
-- Returns true if the tag was added.
function AddTagIfMissing(tags, tag)
    for _, existing in ipairs(tags) do
        if string.lower(existing) == string.lower(tag) then
            return false
        end
    end
    table.insert(tags, tag)
    return true
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
        table.insert(details, "last grouped " .. FormatTimeAgo(info.lastSeen))
    end

    local suffix = #details > 0 and (" (" .. table.concat(details, " - ") .. ")") or ""

    if info.score and info.score > 0 then
        self:Print("|cFF33FF33Good player joined:|r " .. name .. suffix)
    else
        self:Print("You have grouped with " .. name .. " before" .. suffix)
    end
end

-- Check if a unit is on the character friend list or the Battle.net friend list
local function IsUnitFriend(unit)
    local guid = UnitGUID(unit)
    if not guid then
        return false
    end
    if C_FriendList.IsFriend(guid) then
        return true
    end
    if C_BattleNet and C_BattleNet.GetAccountInfoByGUID then
        local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid)
        return accountInfo ~= nil and accountInfo.isFriend == true
    end
    return false
end

-- File ID of sound/creature/goblinmalegruffnpc/goblinmalegruffnpcgreeting06.ogg
local GOOD_PLAYER_SOUND_FILE_ID = 550773

-- File ID of sound/creature/nightelfmalestandardnpc/nightelfmalestandardnpcpissed01.ogg
local BAD_PLAYER_SOUND_FILE_ID = 556575

-- Play a sound when a rated player (score other than 0) joins the group,
-- unless the sound is turned off for everyone, guild members or friends
function Fellowship:PlayJoinSound(unit, info)
    local settings = self.db.profile.sound

    if not settings.enabled or not info.score or info.score == 0 then
        return
    end
    if not settings.guild and UnitIsInMyGuild(unit) then
        return
    end
    if not settings.friends and IsUnitFriend(unit) then
        return
    end

    -- Good players get a goblin greeting, bad players an annoyed night elf
    PlaySoundFile(info.score > 0 and GOOD_PLAYER_SOUND_FILE_ID or BAD_PLAYER_SOUND_FILE_ID, "Master")
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

    -- Add new players to the current session's party members (do not remove players who leave).
    -- The value is the player's role tag, kept from an earlier update if no role is assigned now.
    partyMembers[fullName] = GetRoleTag(unit) or partyMembers[fullName] or true

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
        self:PlayJoinSound(unit, info)
    end

    -- Count each instance run together once
    if info.lastInstanceID ~= instanceID and instanceID ~= nil then
        info.lastInstanceID = instanceID
        info.count = (info.count or 0) + 1
        info.lastSeen = GetTimestamp()
    end

    info.class = info.class or classFileName
end

-- Get the unit IDs of all group members
local function GetGroupUnits()
    local units = {}
    local numGroupMembers = GetNumGroupMembers()

    if IsInRaid() then
        for i = 1, numGroupMembers do
            table.insert(units, "raid" .. i)
        end
    elseif IsInGroup() then
        -- "party" units don't include the player themselves
        for i = 1, numGroupMembers - 1 do
            table.insert(units, "party" .. i)
        end
    end

    return units
end

-- Tag for players who were removed from the group by a vote kick
local VOTE_KICKED_TAG = "Vote-kicked"

-- Seconds after a kick vote ends that the target can still leave the group and count as kicked
local KICK_GRACE_SECONDS = 10

-- Update the party members table when the group changes, but do not remove players who leave
function Fellowship:UpdatePartyMembers()
    local instanceID = GetCurrentInstanceID()

    local playerName, playerRealm = UnitName("player")
    local fullPlayerName = GetFullPlayerName(playerName, playerRealm)

    for _, unit in ipairs(GetGroupUnits()) do
        self:ProcessGroupUnit(unit, fullPlayerName, instanceID)
    end

    self:CheckPendingKick()
end

-- Find the full name of the group member a kick vote is against.
-- The vote may give the name without a realm, so compare names only.
local function FindKickTargetFullName(targetName)
    local targetBaseName = string.lower(string.match(targetName, "^[^-]+"))

    for _, unit in ipairs(GetGroupUnits()) do
        local name, realm = UnitName(unit)
        if name and not UnitIsUnit(unit, "player") and string.lower(name) == targetBaseName then
            return GetFullPlayerName(name, realm)
        end
    end
end

-- Remember the target and reason of a kick vote, so they can be tagged if they leave the group
function Fellowship:OnBootProposalUpdate()
    local inProgress, _, _, targetName, _, _, _, reason = GetLFGBootProposal()

    if inProgress and targetName then
        local fullName = FindKickTargetFullName(targetName)
        if fullName then
            self.pendingKick = { fullName = fullName, reason = reason }
        end
    elseif self.pendingKick and not self.pendingKick.endedAt then
        -- The vote is over. If it passed, the target leaves the group in the next roster update.
        self.pendingKick.endedAt = GetTime()
    end
end

-- Tag the target of a kick vote if they are no longer in the group
function Fellowship:CheckPendingKick()
    local kick = self.pendingKick
    if not kick or not IsInGroup() then
        return
    end

    -- The target is still in the group long after the vote ended, so the vote failed
    if kick.endedAt and GetTime() - kick.endedAt > KICK_GRACE_SECONDS then
        self.pendingKick = nil
        return
    end

    for _, unit in ipairs(GetGroupUnits()) do
        local name, realm = UnitName(unit)
        if name and GetFullPlayerName(name, realm) == kick.fullName then
            return
        end
    end

    self.pendingKick = nil
    self:MarkVoteKicked(kick.fullName, kick.reason)
end

-- Add the vote kick tag to a player and add the kick reason to their note
function Fellowship:MarkVoteKicked(fullName, reason)
    local info = self.db.factionrealm.players[fullName]
    if not info then
        return
    end

    info.tags = info.tags or {}
    AddTagIfMissing(info.tags, VOTE_KICKED_TAG)

    local message = ColorizeNameByClass(fullName, info.class) .. " was vote-kicked"

    if reason and reason ~= "" then
        if info.note and info.note ~= "" then
            info.note = info.note .. " - " .. reason
        else
            info.note = reason
        end
        message = message .. ": " .. reason
    end

    self:Print(message)
    self:RefreshPlayerList()
end
