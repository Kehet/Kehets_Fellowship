-- AceGUI is part of the Ace3 library, so we use it to create the prettier UI.
local AceGUI = LibStub("AceGUI-3.0")

-- Function to show a popup for rating all players in the previous group
function Reckoning:ShowPreviousGroupPopup()
    -- If there are no players in the previous group, show a message
    if not previousGroupMembers or next(previousGroupMembers) == nil then
        self:Print("No previous group to show.")
        return
    end

    -- Create a frame for the AceGUI popup (increased width)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Rate Players in Your Previous Group")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Flow")
    frame:SetWidth(500)  -- Increased width to prevent wrapping
    frame:SetHeight(300)

    -- Create an AceGUI scroll container to handle large lists
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")
    frame:AddChild(scrollContainer)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollContainer:AddChild(scroll)

    -- Function to create score buttons for each player
    local function CreateScoreButtons(playerName)
        local group = AceGUI:Create("SimpleGroup")
        group:SetFullWidth(true)
        group:SetLayout("Flow")

        -- Add player name label
        local nameLabel = AceGUI:Create("Label")
        nameLabel:SetText(playerName)
        nameLabel:SetWidth(150)
        group:AddChild(nameLabel)

        -- Get current score for the player if it exists
        local currentScore = self.db.factionrealm.players[playerName] and self.db.factionrealm.players[playerName].score or nil

        -- Store the button that matches the current score, if any
        local currentScoreButton = nil

        -- Create score buttons from -2 to 2
        for score = -2, 2 do
            local button = AceGUI:Create("Button")
            button:SetText(tostring(score))  -- Convert score to string to ensure text appears
            button:SetWidth(50)  -- Adjust button width slightly for better alignment
            button:SetHeight(30)  -- Ensure the button height is set
            button.score = score  -- Store the button's score directly in the button object

            -- Disable the button if the current score matches
            if currentScore ~= nil and currentScore == score then
                button:SetDisabled(true)
                button:SetText("|cFF00FF00" .. tostring(score) .. "|r")  -- Highlight the current score in green
                currentScoreButton = button  -- Keep track of the button corresponding to the current score
            end

            button:SetCallback("OnClick", function()
                -- Update the player's score in the factionrealm-specific database
                self.db.factionrealm.players[playerName].score = score
                self:Print("Player " .. playerName .. " scored: " .. score)

                -- Re-enable the previously disabled button (if any)
                if currentScoreButton then
                    currentScoreButton:SetDisabled(false)
                    currentScoreButton:SetText(tostring(currentScoreButton.score))  -- Reset text color using stored score
                end

                -- Disable and highlight the newly clicked button
                button:SetDisabled(true)
                button:SetText("|cFF00FF00" .. tostring(score) .. "|r")  -- Highlight selected score

                -- Update current score button reference
                currentScoreButton = button
            end)

            group:AddChild(button)
        end

        scroll:AddChild(group)
    end

    -- Create a group with buttons for each player
    for playerName in pairs(previousGroupMembers) do
        CreateScoreButtons(playerName)
    end

    -- Close button at the bottom
    local closeButton = AceGUI:Create("Button")
    closeButton:SetText("Close")
    closeButton:SetWidth(100)
    closeButton:SetCallback("OnClick", function() frame:Hide() end)
    frame:AddChild(closeButton)

    -- Show the frame
    frame:Show()
end
