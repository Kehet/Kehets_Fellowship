-- Initialize Ace3 with AceConsole for slash commands, AceEvent for event handling, and AceDB for saved variables
Reckoning = LibStub("AceAddon-3.0"):NewAddon("Reckoning", "AceConsole-3.0", "AceEvent-3.0")

-- Default structure for saved variables (faction-realm specific)
local defaultSavedVariables = {
    factionrealm = {
        players = {},
    },
}

-- Initialize the addon and register slash commands
function Reckoning:OnInitialize()
    -- Set up AceDB with factionrealm scope
    self.db = LibStub("AceDB-3.0"):New("ReckoningDB", defaultSavedVariables, true)

    -- Register slash commands
    self:RegisterChatCommand("reckoning", "HandleSlashCommand")
    self:RegisterChatCommand("rec", "HandleSlashCommand")
end

-- Register events using AceEvent
function Reckoning:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdatePartyMembers")
    self:RegisterEvent("PARTY_LEADER_CHANGED", "UpdatePartyMembers")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_JOINED", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_FORMED", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_LEFT", "OnGroupLeft")
end

-- Slash command handler
function Reckoning:HandleSlashCommand(input)
    local command = input:lower()

    if command == "show" then
        self:ShowKnownPlayers()
    elseif command == "reset" then
        self.db.factionrealm.players = {}  -- Reset the factionrealm-specific players database
        self:Print("All known players have been reset.")
    elseif command == "reopen" then
        -- Reopen the previous group popup
        self:ShowPreviousGroupPopup()
    elseif command == "test" then
        -- Populate fake data and show the score screen
        self:PopulateFakeData()
        self:ShowPreviousGroupPopup()
    else
        self:Print("Unknown command.")
        self:Print(" '/reckoning show' to list all known players")
        self:Print(" '/reckoning reset' to clear all known players")
        self:Print(" '/reckoning reopen' to reopen the previous group popup")
        self:Print(" '/reckoning test' to test with fake data")
    end
end

-- Function to populate fake data for testing
function Reckoning:PopulateFakeData()
    -- Add some fake player names to previousGroupMembers
    previousGroupMembers = {
        ["Thrall-AzjolNerub"] = true,
        ["Jaina-Proudmoore"] = true,
        ["Sylvanas-Windrunner"] = true,
        ["Anduin-Wrynn"] = true,
        ["Illidan-Stormrage"] = true
    }

    -- Add some initial fake scores to the factionrealm-specific database
    self.db.factionrealm.players["Thrall-AzjolNerub"] = { score = -1, lastSeen = "2024-10-05 12:00", count = 1, lastInstanceID = 1 }
    self.db.factionrealm.players["Jaina-Proudmoore"] = { score = 2, lastSeen = "2024-10-05 12:00", count = 1, lastInstanceID = 1 }
    self.db.factionrealm.players["Sylvanas-Windrunner"] = { score = nil, lastSeen = "2024-10-05 12:00", count = 1, lastInstanceID = 1 }
    self.db.factionrealm.players["Anduin-Wrynn"] = { score = 1, lastSeen = "2024-10-05 12:00", count = 1, lastInstanceID = 1 }
    self.db.factionrealm.players["Illidan-Stormrage"] = { score = nil, lastSeen = "2024-10-05 12:00", count = 1, lastInstanceID = 1 }

    self:Print("Fake test data loaded. Opening score popup...")
end
