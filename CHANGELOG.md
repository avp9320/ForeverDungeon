# Changelog

## 0.2.7 - 2026-11-05
- Inherit ForeverUpgrade's corrected Warrior armor/required-level rules and no-fake-empty-slot checks.
- Handle unscorable comparisons as unknown, not proven non-upgrades.
- Use ForeverUpgrade's configured Protection recommendation priority where available.
- Replace extreme percentages with STRONG and label all estimates as item-score differences.


## 0.2.1 - 2026-11-01

- Corrected release packaging so the ForeverLoot adapter is included in the installable ZIP.
- This is the first release users should install for the ForeverLoot-based architecture.

## 0.2.0 - 2026-11-01

- Replaced AtlasLootClassic Continued integration with the new **ForeverLoot** addon.
- ForeverLoot is now a required dependency alongside ForeverUpgrade.
- Dungeon scans now read instances, encounters, and item IDs directly from ForeverLoot's integration API.
- `/fd status` now reports ForeverLoot availability.
- Removed AtlasLoot-specific runtime and packaging references.

## 0.1.0 - 2026-11-01

- Initial ForeverDungeon build.
- Temporary dungeon-entry upgrade notification.
- Compact upgrade-only detail panel.
- `/fd` reopen command and `/fd test` UI preview.
- ForeverUpgrade scoring integration.
- Initial AtlasLootClassic Continued loot-data integration.
- Automatic rescans after relevant character changes.
- Inherits ForeverUpgrade's upgrade threshold by default.
- No permanent frame or minimap button.
