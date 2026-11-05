local ADDON_NAME, FD = ...
FD = FD or {}
_G.ForeverDungeon = FD

FD.ADDON_NAME = ADDON_NAME
FD.VERSION = "0.2.4"
FD.results = {}
FD.currentInstance = nil
FD.lastScanKey = nil
FD.pendingScan = false
FD.dataSource = nil

function FD:Print(text)
    print("|cffd8b45bForever Dungeon:|r " .. tostring(text))
end

function FD:GetUpgradeAddon()
    return _G.ForeverUpgrade
end

function FD:GetThreshold()
    if ForeverDungeonDB and ForeverDungeonDB.inheritThreshold ~= false then
        if ForeverUpgradeDB and tonumber(ForeverUpgradeDB.threshold) then
            return math.max(0, tonumber(ForeverUpgradeDB.threshold))
        end
    end
    return math.max(0, tonumber(ForeverDungeonDB and ForeverDungeonDB.threshold) or 1.0)
end

function FD:IsEnabled()
    return not ForeverDungeonDB or ForeverDungeonDB.enabled ~= false
end
