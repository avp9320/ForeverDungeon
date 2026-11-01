local _, FD = ...
FD = _G.ForeverDungeon or FD

-- ForeverDungeon intentionally keeps its bundled database tiny. The preferred
-- source is AtlasLootClassic Continued, which is already maintained for the
-- changing WoW: Forever loot tables. This table gives us a clean place to add
-- verified Forever-specific corrections or emergency fallbacks without
-- duplicating AtlasLoot's entire database.
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
