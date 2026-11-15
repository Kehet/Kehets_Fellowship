local ADDON_NAME = ...

-- The addon table. Fellowship.db is set when the saved variables are loaded.
-- Chat lines start with a short name, coloured like "Kehet's" in the addon title.
Fellowship = { name = "Kehet's Fellowship", chatPrefix = "|cFF009900Fellowship|r: " }
LibStub("LibKehetsVerbosity-2.0"):Embed(Fellowship, function() return Fellowship.db and Fellowship.db.profile end)

-- Messages the player can turn off or move in the Messages settings
Fellowship:RegisterMessageTypes({
    banner = {
        name = "Login message",
        desc = "The line that says the addon is enabled.",
        order = 1,
    },
    join = {
        name = "Known player joined",
        desc = "The line that says a player you grouped with before joined your group.",
        order = 2,
    },
    voteKick = {
        name = "Vote kick",
        desc = "The line that says a player was vote-kicked.",
        order = 3,
    },
})

-- LibDataBroker object for the minimap icon
local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Kehet's Fellowship", {
    type = "data source",
    text = "Kehet's Fellowship",
    icon = "Interface\\Icons\\inv_hammer_16",
    OnClick = function(self, button)
        if button == "LeftButton" then
            -- Open the previous group popup, or close it if it is already open
            Fellowship:TogglePreviousGroupPopup()
        elseif button == "RightButton" then
            Fellowship:ShowPlayerList()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Kehet's Fellowship")
        tooltip:AddLine("Left-click to open or close the last group window.")
        tooltip:AddLine("Right-click to list all known players.")
        tooltip:AddLine("Use /fellow config to open the settings.")
    end,
})

-- Initialize the minimap icon using LibDBIcon
local icon = LibStub("LibDBIcon-1.0")

-- List the addon in the addon drawer by the minimap, on clients that have one, with the clicks and
-- tooltip of the minimap button. It stays there when the minimap button is hidden. The name is
-- coloured like the title in the addon list.
local function AddToAddonDrawer()
    if not AddonCompartmentFrame or not AddonCompartmentFrame.RegisterAddon then
        return
    end
    AddonCompartmentFrame:RegisterAddon({
        text = "|cFF009900Kehet's|r Fellowship",
        icon = ldb.icon,
        notCheckable = true,
        registerForAnyClick = true,
        func = function(_, menuInputData, menu)
            ldb.OnClick(menu, menuInputData.buttonName)
        end,
        funcOnEnter = function(button)
            GameTooltip:SetOwner(button, "ANCHOR_LEFT")
            ldb.OnTooltipShow(GameTooltip)
            GameTooltip:Show()
        end,
        funcOnLeave = GameTooltip_Hide,
    })
end

-- Game events and the methods that handle them
local eventHandlers = {
    GROUP_ROSTER_UPDATE = "UpdatePartyMembers",
    PARTY_LEADER_CHANGED = "UpdatePartyMembers",
    PLAYER_ENTERING_WORLD = "UpdatePartyMembers",
    GROUP_JOINED = "UpdatePartyMembers",
    GROUP_FORMED = "UpdatePartyMembers",
    GROUP_LEFT = "OnGroupLeft",
    LFG_BOOT_PROPOSAL_UPDATE = "OnBootProposalUpdate",
    LFG_PROPOSAL_SUCCEEDED = "OnLFGProposalSucceeded",
    LOADING_SCREEN_ENABLED = "OnLoadingScreenEnabled",
    LOADING_SCREEN_DISABLED = "OnLoadingScreenDisabled",
}

-- Runs once the saved variables are loaded
local function OnAddonLoaded()
    FellowshipDB = FellowshipDB or {}
    Fellowship.db = Fellowship.LoadDatabase(FellowshipDB)

    -- An earlier test build listed the drawer entry through LibDBIcon, which saved this flag and would add a second entry
    Fellowship.db.profile.minimap.showInCompartment = nil
    icon:Register("Kehet's Fellowship", ldb, Fellowship.db.profile.minimap)
    AddToAddonDrawer()

    Fellowship:RegisterOptions()
end

-- Runs when the player is in the world, where AceAddon used to call OnEnable
local function OnPlayerLogin(frame)
    Fellowship:Notify("banner", "Enabled - Use /fellow list to open the known players window, /fellow or /fellowship to list all commands")
    for event in pairs(eventHandlers) do
        frame:RegisterEvent(event)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... == ADDON_NAME then
            self:UnregisterEvent("ADDON_LOADED")
            OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        OnPlayerLogin(self)
    else
        Fellowship[eventHandlers[event]](Fellowship, event, ...)
    end
end)

-- Split a slash command into words. Text in double or single quotes is one word, as with AceConsole's GetArgs.
local function GetArgs(input, count)
    local args = {}
    local pos = 1
    while #args < count do
        local start = input:find("[^ ]", pos)
        if not start then
            break
        end
        local quote = input:sub(start, start)
        local finish
        if quote == '"' or quote == "'" then
            finish = input:find(quote, start + 1, true)
            table.insert(args, input:sub(start + 1, (finish or #input + 1) - 1))
        else
            finish = input:find(" ", start, true)
            table.insert(args, input:sub(start, (finish or #input + 1) - 1))
        end
        if not finish then
            break
        end
        pos = finish + 1
    end
    return unpack(args, 1, count)
end

-- Slash command handler
function Fellowship:HandleSlashCommand(input)
    local command, playerName, score, note, tags = GetArgs(input:lower(), 5)

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
    elseif command == "config" or command == "options" or command == "settings" then
        self:OpenOptions()
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
        self:Print(" '/fellow config' to open the settings")
        self:Print(" '/fellow toggleicon' to show/hide the minimap icon")
        self:Print(" '/fellow sound' to turn the rated player join sound on/off")
        self:Print(" '/fellow sound guild' to turn the join sound on/off for guild members")
        self:Print(" '/fellow sound friends' to turn the join sound on/off for friends")
        self:Print(" '/fellow add <playerName> <score> [note [tags]]' - tags are comma-separated")
        self:Print(" '/fellow remove <playerName>")
    end
end

SLASH_KEHETSFELLOWSHIP1 = "/fellowship"
SLASH_KEHETSFELLOWSHIP2 = "/fellow"
SlashCmdList.KEHETSFELLOWSHIP = function(input)
    Fellowship:HandleSlashCommand(input)
end
