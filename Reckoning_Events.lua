
-- Slash command handler for showing known players
function Reckoning:ShowKnownPlayers()
    self:Print("List of all known players:")

    if next(self.db.factionrealm.players) == nil then
        self:Print("No players found in the database.")
    else
        for name, info in pairs(self.db.factionrealm.players) do
            local lastSeenText = info.lastSeen and info.lastSeen or "Never"
            local class = info.class and info.class or "Unknown"

            if info.note ~= nil and info.note ~= "" then
                self:Print(name .. " - " .. class .. " - Last seen on " .. lastSeenText .. " - Seen " .. info.count .. " times - Score: " .. info.score .. " - Note: " .. info.note)
            else
                self:Print(name .. " - " .. class .. " - Last seen on " .. lastSeenText .. " - Seen " .. info.count .. " times - Score: " .. info.score)
            end
        end
    end
end

-- Function to add a score and optional note for a player
function Reckoning:AddScore(playerName, score, note)
    local fullPlayerName = playerName

    -- Validate score input
    local numericScore = tonumber(score)
    if not numericScore or numericScore < -2 or numericScore > 2 then
        self:Print("Error: Score must be between -2 and 2.")
        return
    end

    -- Ensure the player exists in the database
    if not self.db.factionrealm.players[fullPlayerName] then
        self.db.factionrealm.players[fullPlayerName] = {
            lastSeen = nil,
            count = 0,
            lastInstanceID = nil,
            score = numericScore,
            note = note or nil,
            class = nil
        }
        self:Print("Player " .. fullPlayerName .. " added with score: " .. numericScore)
    else
        -- Update score and note
        self.db.factionrealm.players[fullPlayerName].score = numericScore
        if note then
            self.db.factionrealm.players[fullPlayerName].note = note
        end
        self:Print("Player " .. fullPlayerName .. " updated with score: " .. numericScore)
    end

    -- If a note was provided, display it
    if note then
        self:Print("Note added: " .. note)
    end
end

-- Function to remove all data for a player from the database
function Reckoning:RemoveScore(playerName)
    local fullPlayerName = playerName

    -- Check if the player exists in the database
    if not self.db.factionrealm.players[fullPlayerName] then
        self:Print("Error: Player " .. fullPlayerName .. " not found in database.")
        return
    end

    -- Remove the player from the database
    self.db.factionrealm.players[fullPlayerName] = nil
    self:Print("Player " .. fullPlayerName .. " has been removed from the database.")
end

function Reckoning:ShowResetConfirmation()
    local AceGUI = LibStub("AceGUI-3.0")

    -- Count total entries in database
    local totalEntries = 0
    for _ in pairs(self.db.factionrealm.players) do
        totalEntries = totalEntries + 1
    end

    -- Create confirmation frame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Reset Database Confirmation")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Flow")
    frame:SetWidth(400)
    frame:SetHeight(200)

    -- Warning message
    local warningLabel = AceGUI:Create("Label")
    warningLabel:SetText("|cFFFF0000WARNING:|r You are about to reset the entire player database!")
    warningLabel:SetFullWidth(true)
    frame:AddChild(warningLabel)

    -- Count information
    local countLabel = AceGUI:Create("Label")
    countLabel:SetText("This will permanently delete " .. totalEntries .. " player entries from your database.")
    countLabel:SetFullWidth(true)
    frame:AddChild(countLabel)

    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)

    -- Confirmation question
    local confirmLabel = AceGUI:Create("Label")
    confirmLabel:SetText("Are you sure you want to continue?")
    confirmLabel:SetFullWidth(true)
    frame:AddChild(confirmLabel)

    -- Button container
    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    buttonGroup:SetLayout("Flow")
    frame:AddChild(buttonGroup)

    -- Confirm button (red)
    local confirmButton = AceGUI:Create("Button")
    confirmButton:SetText("|cFFFF0000Yes, Reset All|r")
    confirmButton:SetWidth(150)
    confirmButton:SetCallback("OnClick", function()
        self.db.factionrealm.players = {}  -- Reset the factionrealm-specific players database
        self:Print("All " .. totalEntries .. " known players have been reset.")
        frame:Hide()
    end)
    buttonGroup:AddChild(confirmButton)

    -- Cancel button (green)
    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("|cFF00FF00Cancel|r")
    cancelButton:SetWidth(100)
    cancelButton:SetCallback("OnClick", function()
        self:Print("Reset operation cancelled.")
        frame:Hide()
    end)
    buttonGroup:AddChild(cancelButton)

    -- Show the frame
    frame:Show()
end

-- Handle when the group is left
function Reckoning:OnGroupLeft()
    -- Store the players in the previous group
    previousGroupMembers = partyMembers

    -- Clear the current party members table
    partyMembers = {}

    -- Show the popup with the players
    self:ShowPreviousGroupPopup()
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
    if not self.db.factionrealm.players["Thrall-AzjolNerub"] then
        self.db.factionrealm.players["Thrall-AzjolNerub"] = {
            score = -1,
            lastSeen = "2024-10-05 12:00",
            count = 1,
            lastInstanceID = 1,
            note = "\“Dad who left for cigarettes\” and only comes back to give an awkward pep talk before disappearing again",
            class = "SHAMAN"
        }
    end

    if not self.db.factionrealm.players["Jaina-Proudmoore"] then
        self.db.factionrealm.players["Jaina-Proudmoore"] = {
            score = 2,
            lastSeen = "2024-10-05 12:00",
            count = 1, lastInstanceID = 1,
            note = "The living embodiment of \"daddy issues\" in human form",
            class = "MAGE"
        }
    end

    if not self.db.factionrealm.players["Sylvanas-Windrunner"] then
        self.db.factionrealm.players["Sylvanas-Windrunner"] = {
            score = 0,
            lastSeen = "2024-10-05 12:00",
            count = 1,
            lastInstanceID = 1,
            note = "The edgiest, most melodramatic \"tragic villain\" Azeroth has ever seen",
            class = "HUNTER"
        }
    end

    if not self.db.factionrealm.players["Anduin-Wrynn"] then
        self.db.factionrealm.players["Anduin-Wrynn"] = {
            score = 1,
            lastSeen = "2024-10-05 12:00",
            count = 1,
            lastInstanceID = 1,
            note = "The king with the softest hands in Azeroth",
            class = "PRIEST"
        }
    end

    if not self.db.factionrealm.players["Illidan-Stormrage"] then
        self.db.factionrealm.players["Illidan-Stormrage"] = {
            score = -2,
            lastSeen = "2024-10-05 12:00",
            count = 1,
            lastInstanceID = 1,
            note = "A guy who can’t take no for an answer, obsessed with power, and constantly trying to convince everyone (and himself) that he’s not the bad guy",
            class = "WARRIOR"
        }
    end

    self:Print("Fake test data loaded. Opening score popup...")
end


function Reckoning:ToggleMinimapIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.db.profile.minimap.hide then
        icon:Hide("Reckoning")
    else
        icon:Show("Reckoning")
    end
end
