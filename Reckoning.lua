-- Initialize Ace3 with AceConsole for slash commands, AceEvent for event handling, and AceDB for saved variables
Reckoning = LibStub("AceAddon-3.0"):NewAddon("Reckoning", "AceConsole-3.0", "AceEvent-3.0")

-- Default structure for saved variables (faction-realm specific)
local defaultSavedVariables = {
    factionrealm = {
        players = {},
    },
    profile = {
        minimap = {
            hide = false,
        },
    },
}

-- LibDataBroker object for the minimap icon
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Reckoning", {
    type = "data source",
    text = "Reckoning",
    icon = "Interface\\Icons\\inv_hammer_16",
    OnClick = function(self, button)
        if button == "LeftButton" then
            -- Open the GroupScore player tracking screen or other main functionality
            -- Reckoning:Print("Opening Reckoning...")
            Reckoning:ShowPreviousGroupPopup() -- Example, replace with your main functionality
        elseif button == "RightButton" then
            -- Show some additional options or a menu, if you want
            Reckoning:Print("Reckoning menu or options can go here.")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Reckoning")
        tooltip:AddLine("Left-click to open Reckoning.")
        tooltip:AddLine("Right-click for options.")
    end,
})

-- Initialize the minimap icon using LibDBIcon
local icon = LibStub("LibDBIcon-1.0")

-- Initialize the addon and register slash commands
function Reckoning:OnInitialize()
    -- Set up AceDB with factionrealm scope
    self.db = LibStub("AceDB-3.0"):New("ReckoningDB", defaultSavedVariables, true)

    icon:Register("Reckoning", ldb, self.db.profile.minimap)

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
    local command, playerName, score, note = self:GetArgs(input:lower(), 4)

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
    elseif command == "toggleicon" then
        self:ToggleMinimapIcon()
        self:Print("Toggled minimap icon.")
    elseif command == "add" then
        self:AddScore(playerName, score, note)
    else
        self:Print("Unknown command.")
        self:Print(" '/rec show' to list all known players")
        self:Print(" '/rec reset' to clear all known players")
        self:Print(" '/rec reopen' to reopen the previous group popup")
        self:Print(" '/rec test' to test with fake data")
        self:Print(" '/rec toggleicon' to show/hide the minimap icon")
        self:Print(" '/rec add <playerName> <score> [note]")
    end
end
