local _, FD = ...
FD = _G.ForeverDungeon or FD

local function addonLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        return ok and loaded
    elseif IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        return ok and loaded
    end
    return false
end

local function loadAddon(name)
    if addonLoaded(name) then return true end
    if InCombatLockdown and InCombatLockdown() then return false end

    if C_AddOns and C_AddOns.LoadAddOn then
        local ok = pcall(C_AddOns.LoadAddOn, name)
        return ok and addonLoaded(name)
    elseif LoadAddOn then
        local ok = pcall(LoadAddOn, name)
        return ok and addonLoaded(name)
    end
    return false
end

function FD:TryLoadAtlasLoot()
    if _G.AtlasLoot and _G.AtlasLoot.ItemDB then return true end

    loadAddon("AtlasLootClassic")
    loadAddon("AtlasLootClassic_DungeonsAndRaids")

    return _G.AtlasLoot and _G.AtlasLoot.ItemDB and true or false
end

local function currentMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then return id end
    end
end

local function contentMatches(content, instanceID, mapID, instanceName)
    if type(content) ~= "table" then return false end
    if instanceID and tonumber(content.InstanceID) == tonumber(instanceID) then return true end
    if mapID and tonumber(content.MapID) == tonumber(mapID) then return true end

    local rawName
    if content.GetName then
        local ok, value = pcall(content.GetName, content, true)
        if ok then rawName = value end
    end
    rawName = rawName or content.name
    if rawName and instanceName and string.lower(tostring(rawName)) == string.lower(instanceName) then
        return true
    end
    return false
end

local function bossName(content, boss, bossIndex)
    if type(boss) == "table" and boss.name then return tostring(boss.name) end
    if content and content.GetNameForItemTable then
        local ok, value = pcall(content.GetNameForItemTable, content, bossIndex, true)
        if ok and value then return tostring(value) end
    end
    return "Boss " .. tostring(bossIndex)
end

local function pickDifficulty(moduleData, content, difficultyID)
    if moduleData and moduleData.GetDifficultyByID and difficultyID then
        local ok, value = pcall(moduleData.GetDifficultyByID, moduleData, difficultyID)
        if ok and value then return value end
    end
    if content and content.LoadDifficulty then return content.LoadDifficulty end
    return 1
end

local function rowItemID(row)
    if type(row) ~= "table" then return nil end
    local value = row[2]
    if type(value) == "number" and value > 0 then return value end
    if type(value) == "string" then
        local id = tonumber(string.match(value, "item:(%d+)"))
        if id then return id end
    end
    return nil
end

function FD:GetAtlasLoot(instanceID, instanceName, difficultyID)
    if not self:TryLoadAtlasLoot() then return nil end

    local AL = _G.AtlasLoot
    local itemDB = AL and AL.ItemDB
    local storage = itemDB and itemDB.Storage
    if type(storage) ~= "table" then return nil end

    local mapID = currentMapID()

    for addonName, moduleData in pairs(storage) do
        if type(moduleData) == "table" then
            for contentName, content in pairs(moduleData) do
                if type(contentName) == "string" and contentMatches(content, instanceID, mapID, instanceName) then
                    local out = {
                        name = instanceName,
                        bosses = {},
                        atlasAddon = addonName,
                        atlasContent = contentName,
                    }
                    local items = content.items
                    if type(items) == "table" then
                        local diff = pickDifficulty(moduleData, content, difficultyID)
                        for bossIndex = 1, #items do
                            local boss = items[bossIndex]
                            local rows
                            if itemDB.GetItemTable then
                                local ok, value = pcall(itemDB.GetItemTable, itemDB, addonName, contentName, bossIndex, diff)
                                if ok and type(value) == "table" then rows = value end
                            end
                            rows = rows or (type(boss) == "table" and boss[diff])

                            if type(rows) == "table" then
                                local entry = { name = bossName(content, boss, bossIndex), items = {} }
                                local seen = {}
                                for _, row in ipairs(rows) do
                                    local itemID = rowItemID(row)
                                    if itemID and not seen[itemID] then
                                        seen[itemID] = true
                                        entry.items[#entry.items + 1] = itemID
                                    end
                                end
                                if #entry.items > 0 then
                                    out.bosses[#out.bosses + 1] = entry
                                end
                            end
                        end
                    end
                    if #out.bosses > 0 then
                        return out, "AtlasLoot"
                    end
                end
            end
        end
    end
end

function FD:GetLootForInstance(instanceID, instanceName, difficultyID)
    local atlas, source = self:GetAtlasLoot(instanceID, instanceName, difficultyID)
    if atlas then return atlas, source end
    return self:GetBuiltinLoot(instanceID, instanceName)
end
