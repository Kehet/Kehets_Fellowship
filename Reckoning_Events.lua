-- Event handling for "Do I Know You" addon

-- Slash command handler for showing known players
function Reckoning:ShowKnownPlayers()
    self:Print("List of all known players:")

    if next(self.db.factionrealm.players) == nil then
        self:Print("No players found in the database.")
    else
        for name, info in pairs(self.db.factionrealm.players) do
            local score = info.score
            if score ~= nil then
                self:Print(name .. " - Last seen on " .. info.lastSeen .. " - Shared " .. info.count .. " instances - Score: " .. score)
            else
                self:Print(name .. " - Last seen on " .. info.lastSeen .. " - Shared " .. info.count .. " instances - No score")
            end
        end
    end
end


function Reckoning_OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Reckoning" then
        if not ReckoningDB then
            ReckoningDB = {}
        end
    elseif event == "GROUP_ROSTER_UPDATE"
        or event == "PARTY_LEADER_CHANGED"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "GROUP_JOINED"
        or event == "GROUP_FORMED" then
        UpdatePartyMembers()
    elseif event == "GROUP_LEFT" then
        previousGroupMembers = partyMembers
        partyMembers = {}
        self:ShowPreviousGroupPopup()
    end
end
