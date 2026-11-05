local _, FD = ...
FD = _G.ForeverDungeon or FD

local function backdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 7, right = 7, top = 7, bottom = 7 },
        })
    end
end

local function createButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 100, 22)
    b:SetText(text)
    return b
end

local toast = CreateFrame("Frame", "ForeverDungeonToast", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
toast:SetSize(390, 92)
toast:SetPoint("TOP", UIParent, "TOP", 0, -115)
toast:SetFrameStrata("DIALOG")
backdrop(toast)
toast:Hide()

local toastTitle = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
toastTitle:SetPoint("TOP", 0, -15)
toastTitle:SetText("Forever Dungeon")

local toastText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
toastText:SetPoint("TOP", toastTitle, "BOTTOM", 0, -7)
toastText:SetWidth(350)
toastText:SetJustifyH("CENTER")

local viewButton = createButton(toast, "View Upgrades", 112)
viewButton:SetPoint("BOTTOM", toast, "BOTTOM", -62, 12)
viewButton:SetScript("OnClick", function()
    toast:Hide()
    FD:ShowDetails()
end)

local dismissButton = createButton(toast, "Dismiss", 82)
dismissButton:SetPoint("LEFT", viewButton, "RIGHT", 8, 0)
dismissButton:SetScript("OnClick", function() toast:Hide() end)

local toastToken = 0
function FD:ShowToast(title, text, hasUpgrades, seconds)
    toastToken = toastToken + 1
    local token = toastToken
    toastTitle:SetText(title or "Forever Dungeon")
    toastText:SetText(text or "")
    viewButton:SetShown(hasUpgrades and true or false)
    if hasUpgrades then
        viewButton:SetPoint("BOTTOM", toast, "BOTTOM", -62, 12)
        dismissButton:ClearAllPoints()
        dismissButton:SetPoint("LEFT", viewButton, "RIGHT", 8, 0)
    else
        dismissButton:ClearAllPoints()
        dismissButton:SetPoint("BOTTOM", toast, "BOTTOM", 0, 12)
    end
    toast:Show()

    seconds = tonumber(seconds) or 8
    if seconds > 0 and C_Timer and C_Timer.After then
        C_Timer.After(seconds, function()
            if token == toastToken and toast:IsShown() then toast:Hide() end
        end)
    end
end

local panel = CreateFrame("Frame", "ForeverDungeonPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
panel:SetSize(470, 390)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
backdrop(panel)
panel:Hide()

local panelTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
panelTitle:SetPoint("TOPLEFT", 18, -16)
panelTitle:SetText("Forever Dungeon")

local panelSub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
panelSub:SetPoint("TOPLEFT", panelTitle, "BOTTOMLEFT", 0, -4)
panelSub:SetWidth(400)
panelSub:SetJustifyH("LEFT")

local close = createButton(panel, "X", 26)
close:SetPoint("TOPRIGHT", -12, -11)
close:SetScript("OnClick", function() panel:Hide() end)

local scroll = CreateFrame("ScrollFrame", "ForeverDungeonScroll", panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 16, -58)
scroll:SetPoint("BOTTOMRIGHT", -32, 16)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(410, 1)
scroll:SetScrollChild(content)

local rows = {}
local function getRow(index)
    if rows[index] then return rows[index] end
    local row = CreateFrame("Button", nil, content)
    row:SetSize(405, 42)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", 2, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetWidth(245)
    row.name:SetJustifyH("LEFT")

    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.source:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.source:SetWidth(245)
    row.source:SetJustifyH("LEFT")

    row.delta = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.delta:SetPoint("RIGHT", -5, 0)
    row.delta:SetWidth(100)
    row.delta:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(self)
        if self.itemID and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then
                GameTooltip:SetItemByID(self.itemID)
            elseif self.itemLink then
                GameTooltip:SetHyperlink(self.itemLink)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    row:SetScript("OnClick", function(self)
        if self.itemLink and IsShiftKeyDown and IsShiftKeyDown() and ChatEdit_InsertLink then
            ChatEdit_InsertLink(self.itemLink)
        end
    end)

    rows[index] = row
    return row
end

function FD:ShowDetails()
    if not self.currentInstance then
        self:Print("No dungeon scan is available yet.")
        return
    end

    local results = self.results or {}
    panelTitle:SetText(self.currentInstance.name or "Forever Dungeon")
    local source = self.dataSource and (" • data: " .. self.dataSource) or ""
    local unknown = tonumber(self.unknownCount) or 0
    local unknownText = unknown > 0 and string.format(" • %d unscorable yet", unknown) or ""
    panelSub:SetText(string.format("%d meaningful upgrade%s%s%s", #results, #results == 1 and "" or "s", unknownText, source))

    for _, row in ipairs(rows) do row:Hide() end
    local y = -2
    for i, result in ipairs(results) do
        local row = getRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        row.itemID = result.itemID
        row.itemLink = result.link
        row.icon:SetTexture(result.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(result.link or result.name or ("Item " .. tostring(result.itemID)))
        row.source:SetText(result.boss or "Unknown source")
        if result.isNew then
            row.delta:SetText("|cff20ff20NEW SLOT|r")
        else
            row.delta:SetText(string.format("|cff20ff20+%.1f%%|r", result.percent or 0))
        end
        row:Show()
        y = y - 42
    end

    if #results == 0 then
        local row = getRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        row.itemID = nil
        row.itemLink = nil
        local incomplete = self.dataPartial == true or (tonumber(self.unknownCount) or 0) > 0
        row.icon:SetTexture(incomplete
            and "Interface\\Icons\\INV_Misc_QuestionMark"
            or "Interface\\RaidFrame\\ReadyCheck-Ready")
        row.name:SetText(incomplete and "Upgrade status unknown" or "No meaningful upgrades found")
        row.source:SetText(incomplete
            and "Loot data is incomplete or contains unscorable items."
            or "No upgrades found in the available complete loot data.")
        row.delta:SetText("")
        row:Show()
        y = y - 42
    end

    content:SetHeight(math.max(1, -y + 8))
    panel:Show()
end

function FD:HideUI()
    toast:Hide()
    panel:Hide()
end

function FD:ShowTestUI()
    self.currentInstance = { name = "Scarlet Monastery — TEST" }
    self.dataSource = "Test data"
    self.unknownCount = 0
    self.results = {
        { itemID = 7717, name = "Ravager", link = "|cff0070dd|Hitem:7717::::::::|h[Ravager]|h|r", boss = "Herod", percent = 8.4, icon = "Interface\\Icons\\INV_Axe_12" },
        { itemID = 7718, name = "Herod's Shoulder", link = "|cff0070dd|Hitem:7718::::::::|h[Herod's Shoulder]|h|r", boss = "Herod", percent = 5.1, icon = "Interface\\Icons\\INV_Shoulder_01" },
        { itemID = 10330, name = "Scarlet Leggings", link = "|cff0070dd|Hitem:10330::::::::|h[Scarlet Leggings]|h|r", boss = "Scarlet Commander Mograine", percent = 1.7, icon = "Interface\\Icons\\INV_Pants_03" },
    }
    self:ShowToast("Scarlet Monastery", "|cff20ff203 upgrades available|r • best: +8.4%", true, 10)
end
