-- PlayerScoreAddon.lua

local function FormatLastSeen(lastSeen)
    if type(lastSeen) == "number" and lastSeen > 0 then
        local now = time()
        local diff = math.max(0, now - lastSeen)
        if diff < 60 then
            return "just now"
        elseif diff < 3600 then
            local m = math.floor(diff / 60)
            return m .. " minute" .. (m == 1 and "" or "s") .. " ago"
        elseif diff < 86400 then
            local h = math.floor(diff / 3600)
            return h .. " hour" .. (h == 1 and "" or "s") .. " ago"
        elseif diff < 86400 * 7 then
            local d = math.floor(diff / 86400)
            return d .. " day" .. (d == 1 and "" or "s") .. " ago"
        else
            -- Fallback to a readable date
            return date("%Y-%m-%d %H:%M", lastSeen)
        end
    end
    return tostring(lastSeen or "Unknown")
end

local function AddPlayerScore(self)
    local _, unit = self:GetUnit()

    if unit and UnitIsPlayer(unit) then

        local playerName, playerRealm = GetUnitName(unit, true)
        local fullName = GetFullPlayerName(playerName, playerRealm)


        if Reckoning.db.factionrealm.players[fullName] then

            local score = Reckoning.db.factionrealm.players[fullName].score
            local note = Reckoning.db.factionrealm.players[fullName].note
            local lastSeen = Reckoning.db.factionrealm.players[fullName].lastSeen

            if score then
                local sr, sg, sb = 1, 1, 1
                if type(score) == "number" then
                    if score > 0 then
                        sr, sg, sb = 0.2, 1.0, 0.2
                    elseif score < 0 then
                        sr, sg, sb = 1.0, 0.3, 0.3
                    end
                end

                self:AddLine("Reckoning score " .. tostring(score ~= nil and score or "-"), sr, sg, sb, true)

                if note and note ~= nil and note ~= "" then
                    self:AddLine("Note: " .. note)
                end

                if lastSeen ~= nil then
                    self:AddLine("Last seen ", FormatLastSeen(lastSeen))
                end

                self:Show()
            end
        end
    end
end

-- Hook the GameTooltip
GameTooltip:HookScript("OnTooltipSetUnit", AddPlayerScore)
