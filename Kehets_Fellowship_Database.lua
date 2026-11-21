-- Saved variables, in the layout AceDB-3.0 used up to 2.7:
--   FellowshipDB.factionrealm["<faction> - <realm>"].players  known players of one faction and realm
--   FellowshipDB.profiles["Default"]                          settings, shared by all characters
--   FellowshipDB.profileKeys["<character key>"]               profile of each character
-- The addon reads and writes the same tables in place, so nothing is moved or removed,
-- and an older version of the addon still reads the file.

local defaultProfile = {
    minimap = {
        hide = false,
    },
    -- Sound played when a rated player joins the group
    sound = {
        enabled = true,
        guild = true,
        friends = true,
    },
}

-- Realm and character keys made the way AceDB-3.0 (minor 40) makes them, so the saved tables are found again.
-- Clients with regional unique names, such as WoW: Forever, key by realm rule set, not by realm name.
local function GetKeys()
    local realmKey, charKey
    if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        if C_GameRules.IsGameRuleActive(Enum.GameRule.HardcoreRuleset) then
            realmKey = "Hardcore"
        elseif C_GameRules.IsGameRuleActive(Enum.GameRule.RPRuleset) then
            realmKey = "RP"
        elseif C_GameRules.IsGameRuleActive(Enum.GameRule.PvPRuleset) then
            realmKey = "PvP"
        else
            realmKey = "PvE"
        end
        local name, surname = UnitNameUnmodified("player")
        charKey = surname and (name .. " " .. tostring(surname)) or name
    else
        realmKey = GetRealmName()
        charKey = UnitNameUnmodified("player") .. " - " .. realmKey
    end
    local factionrealmKey = tostring(UnitFactionGroup("player")) .. " - " .. realmKey
    return factionrealmKey, charKey
end

-- Fill in what the saved table lacks, without changing what is there
local function CopyDefaults(saved, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(saved[key]) ~= "table" then
                saved[key] = {}
            end
            CopyDefaults(saved[key], value)
        elseif saved[key] == nil then
            saved[key] = value
        end
    end
end

local function GetTable(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

-- Returns { factionrealm = <table with players>, profile = <settings table> }, which are the tables
-- inside the saved variables, so a change to them is saved.
function Fellowship.LoadDatabase(saved)
    local factionrealmKey, charKey = GetKeys()

    local realms = GetTable(saved, "factionrealm")
    local realm = GetTable(realms, factionrealmKey)
    if type(realm.players) ~= "table" then
        realm.players = {}
    end

    local profiles = GetTable(saved, "profiles")
    local profileKeys = GetTable(saved, "profileKeys")
    local profileName = profileKeys[charKey]
    if type(profileName) ~= "string" or type(profiles[profileName]) ~= "table" then
        profileName = "Default"
    end
    profileKeys[charKey] = profileName
    local profile = GetTable(profiles, profileName)
    CopyDefaults(profile, defaultProfile)
    -- Not in defaultProfile: CopyDefaults would put back the presets the player removed
    if type(profile.presetTags) ~= "table" then
        profile.presetTags = { "Friendly", "Helpful", "Skilled", "New player", "AFK", "Leaver", "Rude", "Ninja looter" }
    end

    return {
        factionrealm = realm,
        profile = profile,
    }
end
