# Changelog

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
