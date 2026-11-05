-- PlayerScoreAddon.lua

-- WoW: Forever hands out secret values that addons cannot compare, and has no issecretvalue on the other clients
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- Returns the unit the tooltip shows, or nil when the client keeps it secret
local function GetTooltipUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit and not IsSecret(unit) then
        return unit
    end
    -- The world cursor tooltip is the mouseover unit, and a literal token is never secret
    if UnitExists("mouseover") then
        return "mouseover"
    end
    return nil
end

local function AddPlayerScore(self)
    local unit = GetTooltipUnit(self)
    if not unit then
        return
    end

    local isPlayer = UnitIsPlayer(unit)
    if not IsSecret(isPlayer) and isPlayer then

        local playerName, playerRealm = GetUnitName(unit, true)
        if IsSecret(playerName) or IsSecret(playerRealm) then
            return
        end
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

-- WoW: Forever has no OnTooltipSetUnit script, so its unit tooltips are hooked through TooltipDataProcessor
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip == GameTooltip then
            AddPlayerScore(tooltip)
        end
    end)
else
    GameTooltip:HookScript("OnTooltipSetUnit", AddPlayerScore)
end
