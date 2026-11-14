-- Window parts built from the native frame templates, shared by the addon's windows and settings page
local UI = {}
Fellowship.UI = UI

function UI.HasTemplate(name)
    return C_XMLUtil ~= nil and C_XMLUtil.GetTemplateInfo ~= nil and C_XMLUtil.GetTemplateInfo(name) ~= nil
end

-- A movable window that closes with Escape. The flat panel is the native look on clients that have it.
function UI.CreateWindow(name, title, width, height)
    local flat = UI.HasTemplate("DefaultPanelFlatTemplate")
    local frame = CreateFrame("Frame", name, UIParent, flat and "DefaultPanelFlatTemplate" or "BasicFrameTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    if not frame.CloseButton then
        frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")
    end

    table.insert(UISpecialFrames, name)

    if frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.TitleContainer.TitleText:SetText(title)
    else
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("TOP", 0, -5)
        frame.title:SetText(title)
    end

    return frame
end

function UI.CreateButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

-- A one-line text box with a label above it. onEnter gets the text when Enter is pressed.
function UI.CreateEditBox(parent, label, width, onEnter)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    box:SetFontObject("ChatFontNormal")

    box.label = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    box.label:SetPoint("BOTTOMLEFT", box, "TOPLEFT", -4, 2)
    box.label:SetText(label)

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if onEnter then
            onEnter(self:GetText())
        end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return box
end

-- A check box with a label on the right and a tooltip
function UI.CreateCheckbox(parent, label, tooltip, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check.label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.label:SetText(label)
    check:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
    end)
    check:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", GameTooltip_Hide)
    return check
end

function UI.SetCheckbox(check, checked, disabled)
    check:SetChecked(checked and true or false)
    check:SetEnabled(not disabled)
    if disabled then
        check.label:SetTextColor(0.5, 0.5, 0.5)
    else
        check.label:SetTextColor(1, 1, 1)
    end
end

-- A row of buttons where one is chosen: the chosen one is greyed out and shows its text in green
function UI.SetChosen(buttons, chosen)
    for value, button in pairs(buttons) do
        local isChosen = value == chosen
        button:SetEnabled(not isChosen)
        button:SetText(isChosen and ("|cFF00FF00" .. button.label .. "|r") or button.label)
    end
end
