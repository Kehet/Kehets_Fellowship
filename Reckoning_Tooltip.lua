-- PlayerScoreAddon.lua

-- Hook the GameTooltip:SetUnit function
local function AddPlayerScore(self)
    local _, unit = self:GetUnit()
    if unit and UnitIsPlayer(unit) then

        local playerName, playerRealm = GetUnitName(unit, true)
        local fullPlayerName = GetFullPlayerName(playerName, playerRealm)

        if not Reckoning.db.factionrealm.players[fullPlayerName] then
            local score = Reckoning.db.factionrealm.players[fullPlayerName]
            if score then
                AddTooltipLine(self, "Score", score)
                self:Show()
            end
        end
    end
end

-- Function to add a formatted line to the tooltip
local function AddTooltipLine(tooltip, leftText, rightText)
    local leftTextFormatted = leftText
    local rightTextFormatted = format("%-10s", tostring(rightText))
    tooltip:AddDoubleLine(leftTextFormatted, rightTextFormatted, 1, 1, 1, 1, 1, 1)
end

-- Hook the GameTooltip
GameTooltip:HookScript("OnTooltipSetUnit", AddPlayerScore)
