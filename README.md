# ForeverDungeon

A deliberately small WoW: Forever dungeon helper. When you enter a dungeon, it checks the dungeon's loot against the gear you are wearing and briefly tells you whether anything inside is a meaningful upgrade.

It is not a dungeon journal and it is not meant to stay open.

## What it does

- Detects when you enter a dungeon or raid.
- Pulls the dungeon's boss/item list from **AtlasLootClassic Continued** when available.
- Uses **ForeverUpgrade** for the actual Warrior gear comparison and active Arms/Fury/Protection profile.
- Shows a small temporary notification such as `3 upgrades available • best: +8.4%`.
- Automatically disappears after a few seconds.
- `View Upgrades` opens a compact list showing only upgrade items and the boss/source.
- `/fd` reopens the latest list whenever you want it.
- Updates the list after gear, level, or talent changes while you are in the instance.
- Uses the same upgrade threshold as ForeverUpgrade by default.
- No permanent window and no minimap button.

## Requirements

### Required

- **ForeverUpgrade** — provides the gear scoring/comparison logic.

### Strongly recommended

- **AtlasLootClassic Continued** — provides current dungeon/boss/drop data. You do not need to use AtlasLoot's UI; ForeverDungeon reads its loaded data in the background.

WoW: Forever's new dungeon loot is still being discovered, so any loot-based addon can only be as complete as the available drop data. Keeping AtlasLootClassic Continued updated lets ForeverDungeon improve as those tables improve.

## Commands

- `/fd` — reopen the most recent result window.
- `/fd scan` — force a scan of your current dungeon.
- `/fd test` — preview the notification UI without being in a dungeon.
- `/fd on` / `/fd off` — enable or disable automatic entry scans.
- `/fd threshold 2` — use a 2% minimum when threshold inheritance is disabled.
- `/fd inherit on|off` — inherit ForeverUpgrade's threshold (default: on).
- `/fd no-upgrades on|off` — show/hide the short notification when nothing is worth chasing.
- `/fd status` — show current status and whether AtlasLoot data is available.

## First test

After installing, log in and run:

`/fd test`

You should get a temporary Scarlet Monastery test notification. Click **View Upgrades** to preview the compact list.

Then run:

`/fd status`

It should say `AtlasLoot=on` if AtlasLootClassic Continued is installed and available.

## Current scope

Version 0.1.0 is Warrior-first because it delegates upgrade decisions to ForeverUpgrade. The architecture is intentionally separated so more classes can be added later without changing the dungeon UI.
