local _, FD = ...
FD = _G.ForeverDungeon or FD

local function currentMapID()
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then return id end
    end
end

function FD:GetForeverLootAddon()
    return _G.ForeverLoot
end

function FD:IsForeverLootReady()
    local FL = self:GetForeverLootAddon()
    return FL and type(FL.GetInstanceByMapID) == "function" and type(FL.GetEncounters) == "function" and type(FL.GetInstanceLoot) == "function"
end

local function findInstance(FL, instanceName)
    local mapID = currentMapID()
    local instance

    if mapID and type(FL.GetInstanceByMapID) == "function" then
        local ok, value = pcall(FL.GetInstanceByMapID, FL, mapID)
        if ok then instance = value end
    end

    if not instance and instanceName and type(FL.FindInstanceByName) == "function" then
        local ok, value = pcall(FL.FindInstanceByName, FL, instanceName)
        if ok then instance = value end
    end

    if not instance and type(FL.Rescan) == "function" then
        pcall(FL.Rescan, FL)
        if mapID and type(FL.GetInstanceByMapID) == "function" then
            local ok, value = pcall(FL.GetInstanceByMapID, FL, mapID)
            if ok then instance = value end
        end
        if not instance and instanceName and type(FL.FindInstanceByName) == "function" then
            local ok, value = pcall(FL.FindInstanceByName, FL, instanceName)
            if ok then instance = value end
        end
    end

    return instance
end

local function itemIDFromLoot(item)
    if type(item) ~= "table" then return nil end
    local itemID = tonumber(item.itemID)
    if itemID and itemID > 0 then return itemID end
    if type(item.link) == "string" then
        return tonumber(string.match(item.link, "item:(%d+)"))
    end
    return nil
end

local function addLootItems(target, loot)
    local seen = {}
    for _, item in ipairs(loot or {}) do
        local itemID = itemIDFromLoot(item)
        if itemID and not seen[itemID] then
            seen[itemID] = true
            target[#target + 1] = itemID
        end
    end
end

function FD:GetForeverLoot(instanceID, instanceName, difficultyID)
    local FL = self:GetForeverLootAddon()
    if not self:IsForeverLootReady() then return nil end

    local instance = findInstance(FL, instanceName)
    if not instance then return nil end

    local out = {
        name = instance.displayName or instance.name or instanceName,
        bosses = {},
        foreverLootInstanceID = instance.journalInstanceID,
    }

    local encounters = {}
    do
        local ok, value = pcall(FL.GetEncounters, FL, instance)
        if ok and type(value) == "table" then encounters = value end
    end

    for _, encounter in ipairs(encounters) do
        local loot = {}
        local ok, value = pcall(FL.GetInstanceLoot, FL, instance, encounter.encounterID)
        if ok and type(value) == "table" then loot = value end

        local entry = {
            name = encounter.name or ("Boss " .. tostring(encounter.index or (#out.bosses + 1))),
            items = {},
        }
        addLootItems(entry.items, loot)
        if #entry.items > 0 then
            out.bosses[#out.bosses + 1] = entry
        end
    end

    -- Some journals can expose instance loot without encounter rows. Preserve
    -- that data rather than treating the dungeon as empty.
    if #out.bosses == 0 then
        local ok, loot = pcall(FL.GetInstanceLoot, FL, instance, nil)
        if ok and type(loot) == "table" then
            local entry = { name = "Instance Loot", items = {} }
            addLootItems(entry.items, loot)
            if #entry.items > 0 then
                out.bosses[1] = entry
            end
        end
    end

    if #out.bosses > 0 then
        -- A Classic fallback may list only a fraction of actual Forever drops.
        -- Pass its completeness through so the UI never says "no upgrades".
        out.partial = instance.isStatic == true
        return out, out.partial and "Classic baseline (partial)" or "ForeverLoot"
    end
end

function FD:GetLootForInstance(instanceID, instanceName, difficultyID)
    local loot, source = self:GetForeverLoot(instanceID, instanceName, difficultyID)
    if loot then return loot, source end
    return self:GetBuiltinLoot(instanceID, instanceName)
end
