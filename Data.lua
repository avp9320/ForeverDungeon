local _, FD = ...
FD = _G.ForeverDungeon or FD

-- ForeverDungeon reads boss loot from the independent ForeverLoot addon.
-- There is no AtlasLoot dependency. Keep this optional override table for
-- emergency or locally verified corrections when ForeverLoot cannot provide
-- a known item/source yet; do not claim an empty table means no loot drops.
--
-- Format:
-- FD.BUILTIN_LOOT[instanceID] = {
--   name = "Dungeon Name",
--   bosses = {
--     { name = "Boss Name", items = { 12345, 67890 } },
--   },
-- }
FD.BUILTIN_LOOT = FD.BUILTIN_LOOT or {}

-- Optional aliases for instances whose runtime ID/name differs on Forever.
FD.INSTANCE_NAME_ALIASES = {
    ["the deadmines"] = "deadmines",
    ["deadmines"] = "deadmines",
    ["scarlet monastery - armory"] = "scarlet monastery",
    ["scarlet monastery - cathedral"] = "scarlet monastery",
    ["scarlet monastery - graveyard"] = "scarlet monastery",
    ["scarlet monastery - library"] = "scarlet monastery",
}

function FD:GetBuiltinLoot(instanceID, instanceName)
    if instanceID and FD.BUILTIN_LOOT[instanceID] then
        return FD.BUILTIN_LOOT[instanceID], "Built-in"
    end

    local needle = string.lower(instanceName or "")
    local alias = FD.INSTANCE_NAME_ALIASES[needle] or needle
    for _, data in pairs(FD.BUILTIN_LOOT) do
        local candidate = string.lower(data.name or "")
        if candidate == needle or candidate == alias then
            return data, "Built-in"
        end
    end
end
