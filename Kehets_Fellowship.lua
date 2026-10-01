-- Initialize Ace3 with AceConsole for slash commands, AceEvent for event handling, and AceDB for saved variables
Fellowship = LibStub("AceAddon-3.0"):NewAddon("Kehet's Fellowship", "AceConsole-3.0", "AceEvent-3.0")

-- Default structure for saved variables (faction-realm specific)
local defaultSavedVariables = {
    factionrealm = {
        players = {},
    },
    profile = {
        minimap = {
            hide = false,
        },
        -- Sound played when a rated player joins the group
        sound = {
            enabled = true,
            guild = true,
            friends = true,
        },
    },
}

-- LibDataBroker object for the minimap icon
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Kehet's Fellowship", {
    type = "data source",
    text = "Kehet's Fellowship",
    icon = "Interface\\Icons\\inv_hammer_16",
    OnClick = function(self, button)
        if button == "LeftButton" then
            -- Open the GroupScore player tracking screen or other main functionality
            -- Fellowship:Print("Opening Fellowship...")
            Fellowship:ShowPreviousGroupPopup() -- Example, replace with your main functionality
        elseif button == "RightButton" then
            Fellowship:ShowPlayerList()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Kehet's Fellowship")
        tooltip:AddLine("Left-click to open Kehet's Fellowship.")
        tooltip:AddLine("Right-click to list all known players.")
    end,
})

-- Initialize the minimap icon using LibDBIcon
local icon = LibStub("LibDBIcon-1.0")

-- Initialize the addon and register slash commands
function Fellowship:OnInitialize()
    -- Set up AceDB with factionrealm scope
    self.db = LibStub("AceDB-3.0"):New("FellowshipDB", defaultSavedVariables, true)

    icon:Register("Kehet's Fellowship", ldb, self.db.profile.minimap)

    -- Register slash commands
    self:RegisterChatCommand("fellowship", "HandleSlashCommand")
    self:RegisterChatCommand("fellow", "HandleSlashCommand")
end

-- Register events using AceEvent
function Fellowship:OnEnable()
    self:Print("Enabled - Use /fellow list to open the known players window, /fellow or /fellowship to list all commands")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdatePartyMembers")
    self:RegisterEvent("PARTY_LEADER_CHANGED", "UpdatePartyMembers")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_JOINED", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_FORMED", "UpdatePartyMembers")
    self:RegisterEvent("GROUP_LEFT", "OnGroupLeft")
    self:RegisterEvent("LFG_BOOT_PROPOSAL_UPDATE", "OnBootProposalUpdate")
end

-- Slash command handler
function Fellowship:HandleSlashCommand(input)
    local command, playerName, score, note, tags = self:GetArgs(input:lower(), 5)

    if command == "list" then
        self:ShowPlayerList()
    elseif command == "show" then
        self:ShowKnownPlayers()
    elseif command == "reset" then
        self:ShowResetConfirmation()
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
    elseif command == "sound" then
        self:ToggleJoinSound(playerName)
    elseif command == "add" then
        self:AddScore(playerName, score, note, tags)
    elseif command == "remove" or command == "delete" then
        self:RemoveScore(playerName)
    else
        self:Print("Unknown command.")
        self:Print(" '/fellow list' to open the known players window")
        self:Print(" '/fellow show' to list all known players in chat")
        self:Print(" '/fellow reset' to clear all known players")
        self:Print(" '/fellow reopen' to reopen the previous group popup")
        self:Print(" '/fellow test' to test with fake data")
        self:Print(" '/fellow toggleicon' to show/hide the minimap icon")
        self:Print(" '/fellow sound' to turn the rated player join sound on/off")
        self:Print(" '/fellow sound guild' to turn the join sound on/off for guild members")
        self:Print(" '/fellow sound friends' to turn the join sound on/off for friends")
        self:Print(" '/fellow add <playerName> <score> [note [tags]]' - tags are comma-separated")
        self:Print(" '/fellow remove <playerName>")
    end
end
