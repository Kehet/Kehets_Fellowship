-- PlayerScoreAddon.lua

local function AddPlayerScore(self)
    local _, unit = self:GetUnit()

    if unit and UnitIsPlayer(unit) then

        local playerName, playerRealm = GetUnitName(unit, true)
        local fullName = GetFullPlayerName(playerName, playerRealm)


        if Fellowship.db.factionrealm.players[fullName] then

            local score = Fellowship.db.factionrealm.players[fullName].score
            local note = Fellowship.db.factionrealm.players[fullName].note
            local lastSeen = Fellowship.db.factionrealm.players[fullName].lastSeen

            if score then
                local sr, sg, sb = 1, 1, 1
                if type(score) == "number" then
                    if score > 0 then
                        sr, sg, sb = 0.2, 1.0, 0.2
                    elseif score < 0 then
                        sr, sg, sb = 1.0, 0.3, 0.3
                    end
                end

                self:AddLine("Kehet's Fellowship score " .. tostring(score ~= nil and score or "-"), sr, sg, sb, true)

                if note and note ~= nil and note ~= "" then
                    self:AddLine("Note: " .. note)
                end

                if lastSeen ~= nil then
                    self:AddLine("Last seen ", FormatTimeAgo(lastSeen))
                end

                self:Show()
            end
        end
    end
end

-- Hook the GameTooltip
GameTooltip:HookScript("OnTooltipSetUnit", AddPlayerScore)
