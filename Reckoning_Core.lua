-- Declare global tables for party and previous group members
partyMembers = {}
previousGroupMembers = {}

-- Get a player's full name in "CharacterName-RealmName" format
function GetFullPlayerName(name, realm)
    if not name or name == "" or name == "Unknown" then
        name = UnitName("player")
    end
    if not realm or realm == "" then
        return name
    end
    return name .. "-" .. realm
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

-- Update the party members table when the group changes, but do not remove players who leave
function Reckoning:UpdatePartyMembers()
    local instanceID = GetCurrentInstanceID()
    local numGroupMembers = GetNumGroupMembers()

    -- Get the current player's name and realm
    local playerName, playerRealm = UnitName("player")
    local fullPlayerName = GetFullPlayerName(playerName, playerRealm)

    -- Process raid members
    if IsInRaid() then
        self:Print("Updating raid members...")
        for i = 1, numGroupMembers do
            local name, realm = UnitName("raid" .. i)
            if name then
                local fullName = GetFullPlayerName(name, realm)
                if fullName ~= fullPlayerName then
                    local timestamp = GetTimestamp()

                    -- Add new players to the current session's party members (do not remove players who leave)
                    if not partyMembers[fullName] then
                        partyMembers[fullName] = true
                        self:Print("New player joined your raid: " .. fullName)
                    end

                    -- Update ReckoningDB
                    if self.db.factionrealm.players[fullName] then
                        if self.db.factionrealm.players[fullName].lastInstanceID ~= instanceID then
                            self.db.factionrealm.players[fullName].lastInstanceID = instanceID
                            self.db.factionrealm.players[fullName].count = self.db.factionrealm.players[fullName].count + 1

                            -- Display player's score when they join
                            local score = self.db.factionrealm.players[fullName].score
                            local note = self.db.factionrealm.players[fullName].note
                            if score ~= 0 or (note ~= nil and note ~= "") then
                                self:Print(fullName .. " has a score of " .. score)
                                if note ~= nil and note ~= "" then
                                    self:Print("Note: " .. note);
                                end
                            end
                        end
                    else
                        self.db.factionrealm.players[fullName] = {
                            lastSeen = timestamp,
                            count = 1,
                            lastInstanceID = instanceID,
                            score = 0,
                            note = nil
                        }
                        self:Print("Added new player to ReckoningDB: " .. fullName)
                    end
                end
            end
        end
    elseif IsInGroup() then
        self:Print("Updating party members...")
        for i = 1, numGroupMembers - 1 do  -- We subtract 1 because "party" doesn't include the player themselves
            local name, realm = UnitName("party" .. i)
            if name then
                local fullName = GetFullPlayerName(name, realm)
                if fullName ~= fullPlayerName then
                    local timestamp = GetTimestamp()

                    if not partyMembers[fullName] then
                        partyMembers[fullName] = true
                        self:Print("New player joined your party: " .. fullName)
                    end

                    -- Update ReckoningDB
                    if self.db.factionrealm.players[fullName] then
                        if self.db.factionrealm.players[fullName].lastInstanceID ~= instanceID then
                            self.db.factionrealm.players[fullName].lastInstanceID = instanceID
                            self.db.factionrealm.players[fullName].count = self.db.factionrealm.players[fullName].count + 1

                            -- Display player's score when they join
                            local score = self.db.factionrealm.players[fullName].score
                            local note = self.db.factionrealm.players[fullName].note
                            if score ~= 0 or (note ~= nil and note ~= "") then
                                self:Print(fullName .. " has a score of " .. score)
                                if note ~= nil and note ~= "" then
                                    self:Print("Note: " .. note);
                                end
                            end
                        end
                    else
                        self.db.factionrealm.players[fullName] = {
                            lastSeen = timestamp,
                            count = 1,
                            lastInstanceID = instanceID,
                            score = 0,
                            note = nil
                        }
                        self:Print("Added new player to ReckoningDB: " .. fullName)
                    end
                end
            end
        end
    else
        self:Print("You are not in a party or raid.")
    end
end
