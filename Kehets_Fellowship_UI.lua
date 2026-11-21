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
    -- The native close button calls HideUIPanel, which does nothing for an addon in combat
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    table.insert(UISpecialFrames, name)

    if frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.titleText = frame.TitleContainer.TitleText
    else
        frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.titleText:SetPoint("TOP", 0, -5)
    end
    frame.titleText:SetText(title)

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

-- A row of buttons where one is chosen: the chosen one stays lit with gold text, like a selected tab,
-- and the others have grey text
function UI.SetButtonChosen(button, chosen)
    if chosen then
        button:LockHighlight()
        button:SetNormalFontObject("GameFontNormal")
        button:SetHighlightFontObject("GameFontNormal")
    else
        button:UnlockHighlight()
        button:SetNormalFontObject("GameFontDisable")
        button:SetHighlightFontObject("GameFontHighlight")
    end
end

function UI.SetChosen(buttons, chosen)
    for value, button in pairs(buttons) do
        UI.SetButtonChosen(button, value == chosen)
    end
end

-- Score colours: red for bad, white for neutral, green for good
local function FormatScore(value)
    value = math.floor(value + 0.5)
    if value < 0 then
        return RED_FONT_COLOR:WrapTextInColorCode(tostring(value))
    elseif value > 0 then
        return GREEN_FONT_COLOR:WrapTextInColorCode("+" .. value)
    end
    return HIGHLIGHT_FONT_COLOR:WrapTextInColorCode("0")
end

-- A slider with step buttons, as in the game settings, for a score from -2 to 2.
-- The score is shown on the right. onChange gets the new score as a whole number.
function UI.CreateScoreSlider(parent, width, onChange)
    local slider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    slider:SetSize(width, 24)
    slider:Init(0, -2, 2, 4, {
        [MinimalSliderWithSteppersMixin.Label.Right] = FormatScore,
    })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        onChange(math.floor(value + 0.5))
    end)
    return slider
end

-- A recessed box with a scrolling list inside: a ScrollBox with the thin scroll bar, as the native lists have.
-- initializer(frame, elementData) fills a pooled row of the given frame type and height.
-- rowHeight is a number, or a function that returns the height of every row when the list is laid out.
-- spacing is the optional gap between rows.
function UI.CreateScrollList(parent, frameType, rowHeight, initializer, spacing)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")

    local scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 4, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", -20, 4)

    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, spacing or 0)
    if type(rowHeight) == "function" then
        view:SetElementExtentCalculator(function() return rowHeight() end)
    else
        view:SetElementExtent(rowHeight)
    end
    view:SetElementInitializer(frameType, initializer)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    inset.scrollBox = scrollBox
    return inset
end

-- A column header drawn like the Who list headers: a tab with the text on the left
local HEADER_TEXTURE = "Interface\\FriendsFrame\\WhoFrame-ColumnTabs"

function UI.CreateColumnHeader(parent, width, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 24)

    local left = button:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(HEADER_TEXTURE)
    left:SetTexCoord(0, 0.078125, 0, 0.75)
    left:SetSize(5, 24)
    left:SetPoint("TOPLEFT")

    local right = button:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(HEADER_TEXTURE)
    right:SetTexCoord(0.90625, 0.96875, 0, 0.75)
    right:SetSize(4, 24)
    right:SetPoint("TOPRIGHT")

    local middle = button:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(HEADER_TEXTURE)
    middle:SetTexCoord(0.078125, 0.90625, 0, 0.75)
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")

    button:SetNormalFontObject("GameFontHighlightSmall")
    button:SetHighlightFontObject("GameFontHighlightSmall")
    button:SetText(" ")
    local text = button:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetPoint("TOPLEFT", left, "TOPLEFT", -2, 5)
    highlight:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", 2, -7)

    button:SetScript("OnClick", onClick)
    return button
end
