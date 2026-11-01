local ADDON_NAME, FD = ...
FD = _G.ForeverDungeon or FD

local DEFAULTS = {
    enabled = true,
    threshold = 1.0,
    inheritThreshold = true,
    toastSeconds = 8,
    showNoUpgrades = true,
    autoShowDetails = false,
    debug = false,
}

local function applyDefaults(db, defaults)
    for key, value in pairs(defaults) do
        if db[key] == nil then db[key] = value end
    end
end

local function requestItem(itemID)
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function itemInfo(itemID)
    local link = "item:" .. tostring(itemID)
    if C_Item and C_Item.GetItemInfo then
        local ok, name, itemLink, _, _, _, _, _, _, equipLoc, icon = pcall(C_Item.GetItemInfo, link)
        if ok and name then
            return name, itemLink or link, equipLoc, icon
        end
    elseif GetItemInfo then
        local name, itemLink, _, _, _, _, _, _, equipLoc, icon = GetItemInfo(link)
        if name then return name, itemLink or link, equipLoc, icon end
    end
    return nil, link
end

local function getInstance()
    if not GetInstanceInfo then return nil end
    local ok, name, instanceType, difficultyID, difficultyName, maxPlayers, _, _, instanceID = pcall(GetInstanceInfo)
    if not ok then return nil end
    return {
        name = name,
        instanceType = instanceType,
        difficultyID = difficultyID,
        difficultyName = difficultyName,
        maxPlayers = maxPlayers,
        instanceID = instanceID,
    }
end

local function isDungeon(info)
    if not info or not info.name or info.name == "" then return false end
    return info.instanceType == "party" or info.instanceType == "raid"
end

local function makeScanKey(info)
    return table.concat({ tostring(info.instanceID or 0), tostring(info.difficultyID or 0), tostring(info.name or "") }, ":")
end

local function resultPercent(FU, comparison)
    if FU.UpgradePercent then
        local ok, pct, isNew = pcall(FU.UpgradePercent, FU, comparison)
        if ok then return pct, isNew end
    end
    if comparison and comparison.equipped and comparison.equipped > 0 then
        return (comparison.delta / comparison.equipped) * 100, false
    end
    return nil, comparison and comparison.delta and comparison.delta > 0
end

function FD:EvaluateLoot(loot)
    local FU = self:GetUpgradeAddon()
    if not FU or not FU.CompareItem then
        return nil, "ForeverUpgrade is not loaded."
    end

    local threshold = self:GetThreshold()
    local found, pending, unknown = {}, false, 0
    local dedupe = {}

    for _, boss in ipairs(loot.bosses or {}) do
        for _, itemID in ipairs(boss.items or {}) do
            if not dedupe[itemID] then
                dedupe[itemID] = true
                local name, link, equipLoc, icon = itemInfo(itemID)
                if not name then
                    pending = true
                    unknown = unknown + 1
                    requestItem(itemID)
                else
                    local ok, comparison, reason = pcall(FU.CompareItem, FU, link)
                    if ok and comparison and comparison.delta and comparison.delta > 0 then
                        local pct, isNew = resultPercent(FU, comparison)
                        if isNew or (pct and pct >= threshold) then
                            found[#found + 1] = {
                                itemID = itemID,
                                name = name,
                                link = link,
                                equipLoc = equipLoc,
                                icon = icon,
                                boss = boss.name,
                                percent = pct,
                                isNew = isNew,
                                delta = comparison.delta,
                            }
                        end
                    elseif ok and not comparison and reason == "not_equippable" and equipLoc and equipLoc ~= "" then
                        unknown = unknown + 1
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b)
        if a.isNew ~= b.isNew then return a.isNew end
        if a.isNew and b.isNew then return (a.delta or 0) > (b.delta or 0) end
        return (a.percent or 0) > (b.percent or 0)
    end)

    return found, nil, pending, unknown
end

function FD:FinishScan(info, force)
    local loot, source = self:GetLootForInstance(info.instanceID, info.name, info.difficultyID)
    self.currentInstance = info
    self.dataSource = source

    if not loot then
        self.results = {}
        if force then
            self:Print("No ForeverLoot data found for " .. tostring(info.name) .. ". Make sure ForeverLoot is enabled and has detected the instance.")
        elseif ForeverDungeonDB and ForeverDungeonDB.debug then
            self:Print("No loot data for " .. tostring(info.name))
        end
        return
    end

    local results, err, pending, unknown = self:EvaluateLoot(loot)
    if err then
        self:Print(err)
        return
    end

    self.results = results or {}
    self.unknownCount = unknown or 0
    local count = #self.results
    local best = self.results[1]

    if count > 0 then
        local bestText = best.isNew and "new slot" or string.format("+%.1f%%", best.percent or 0)
        local unknownText = self.unknownCount > 0 and string.format(" • %d unknown", self.unknownCount) or ""
        self:ShowToast(info.name, string.format("|cff20ff20%d upgrade%s available|r • best: %s%s", count, count == 1 and "" or "s", bestText, unknownText), true, ForeverDungeonDB.toastSeconds)
        if ForeverDungeonDB.autoShowDetails then self:ShowDetails() end
    elseif self.unknownCount > 0 then
        self:ShowToast(info.name, string.format("No confirmed upgrades • |cffffff80%d item%s not scorable yet|r", self.unknownCount, self.unknownCount == 1 and "" or "s"), false, ForeverDungeonDB.toastSeconds)
    elseif ForeverDungeonDB.showNoUpgrades then
        self:ShowToast(info.name, "|cff9cff9cNo meaningful upgrades found.|r", false, math.min(5, ForeverDungeonDB.toastSeconds or 8))
    end

    if pending and C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            local current = getInstance()
            if current and makeScanKey(current) == makeScanKey(info) then
                FD:FinishScan(info, false)
            end
        end)
    end
end

function FD:ScanCurrentDungeon(force)
    if not self:IsEnabled() and not force then return end
    local info = getInstance()
    if not isDungeon(info) then
        if force then self:Print("You are not currently inside a dungeon or raid.") end
        return
    end

    local key = makeScanKey(info)
    if not force and key == self.lastScanKey then return end
    self.lastScanKey = key

    if C_Timer and C_Timer.After then
        C_Timer.After(1.0, function() FD:FinishScan(info, force) end)
    else
        self:FinishScan(info, force)
    end
end

local function boolText(v) return v and "on" or "off" end

local function help()
    FD:Print("/fd                 reopen the latest scan")
    FD:Print("/fd scan            rescan the current dungeon")
    FD:Print("/fd test            show a fake dungeon notification")
    FD:Print("/fd on|off          enable/disable entry scans")
    FD:Print("/fd threshold <n>   set FD threshold (used if inherit is off)")
    FD:Print("/fd inherit on|off  inherit ForeverUpgrade's threshold")
    FD:Print("/fd no-upgrades on|off  show the short 'nothing here' notice")
    FD:Print("/fd status")
end

local function slash(input)
    local command, rest = string.match(input or "", "^(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    rest = string.lower(rest or "")

    if command == "" then
        if FD.currentInstance then FD:ShowDetails() else FD:Print("No dungeon scan yet. Use /fd test to preview the UI.") end
    elseif command == "scan" then
        FD:ScanCurrentDungeon(true)
    elseif command == "test" then
        FD:ShowTestUI()
    elseif command == "on" or command == "off" then
        ForeverDungeonDB.enabled = command == "on"
        FD:Print("automatic dungeon scans " .. boolText(ForeverDungeonDB.enabled))
    elseif command == "threshold" then
        local n = tonumber(rest)
        if n then
            ForeverDungeonDB.threshold = math.max(0, n)
            FD:Print(string.format("ForeverDungeon threshold set to %.1f%%", ForeverDungeonDB.threshold))
        else
            FD:Print(string.format("threshold is %.1f%%", FD:GetThreshold()))
        end
    elseif command == "inherit" then
        if rest == "on" or rest == "off" then
            ForeverDungeonDB.inheritThreshold = rest == "on"
        end
        FD:Print("inherit ForeverUpgrade threshold: " .. boolText(ForeverDungeonDB.inheritThreshold))
    elseif command == "no-upgrades" or command == "noupgrades" then
        if rest == "on" or rest == "off" then
            ForeverDungeonDB.showNoUpgrades = rest == "on"
        end
        FD:Print("no-upgrade notice: " .. boolText(ForeverDungeonDB.showNoUpgrades))
    elseif command == "status" then
        FD:Print(string.format("v%s • enabled=%s • threshold=%.1f%% • inherit=%s • ForeverLoot=%s",
            FD.VERSION, boolText(ForeverDungeonDB.enabled), FD:GetThreshold(), boolText(ForeverDungeonDB.inheritThreshold), boolText(FD:IsForeverLootReady())))
    elseif command == "help" then
        help()
    else
        help()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(events.RegisterEvent, events, "ZONE_CHANGED_NEW_AREA")
pcall(events.RegisterEvent, events, "PLAYER_EQUIPMENT_CHANGED")
pcall(events.RegisterEvent, events, "PLAYER_LEVEL_UP")
pcall(events.RegisterEvent, events, "PLAYER_TALENT_UPDATE")
pcall(events.RegisterEvent, events, "TRAIT_CONFIG_UPDATED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ForeverDungeonDB = ForeverDungeonDB or {}
        applyDefaults(ForeverDungeonDB, DEFAULTS)
        SLASH_FOREVERDUNGEON1 = "/fd"
        SLASH_FOREVERDUNGEON2 = "/foreverdungeon"
        SlashCmdList.FOREVERDUNGEON = slash
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            FD:Print("v" .. FD.VERSION .. " loaded. Temporary dungeon upgrade alerts are on.")
        end)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1.5, function() FD:ScanCurrentDungeon(false) end)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_LEVEL_UP" or event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
        if FD.currentInstance then
            C_Timer.After(0.5, function()
                local info = getInstance()
                if isDungeon(info) then FD:FinishScan(info, false) end
            end)
        end
    end
end)
