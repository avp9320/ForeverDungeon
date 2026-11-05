# ForeverDungeon

A deliberately small WoW: Forever dungeon helper. When you enter a dungeon, it checks the dungeon's loot against the gear you are wearing and briefly tells you whether anything inside is a meaningful upgrade.

It is not a dungeon journal and it is not meant to stay open.

## How the Forever stack works

- **ForeverLoot** — knows what drops from each dungeon and boss.
- **ForeverUpgrade** — decides whether an item is an upgrade for your current Warrior setup.
- **ForeverDungeon** — combines those two and shows only the upgrades when you enter the instance.

No AtlasLoot dependency is required.

## What it does

- Detects when you enter a dungeon or raid.
- Reads the current instance, encounters, and loot from **ForeverLoot**, including the 30 Hall of Thanes and Ruins of Lordaeron reference drops and future loot the player has observed.
- Never treats an incomplete reference/beta catalog as definitive proof there are no upgrades. Both the entry notification and detail panel show unknown coverage instead of falsely giving an all-clear.
- Uses **ForeverUpgrade** for the actual gear comparison and active Arms/Fury/Protection profile.
- Shows a small temporary notification such as `3 upgrades available • best: +8.4%`.
- Automatically disappears after a few seconds.
- `View Upgrades` opens a compact list showing only upgrade items and the boss/source.
- `/fd` reopens the latest list whenever you want it.
- Updates the list after gear, level, or talent changes while you are in the instance.
- Uses the same upgrade threshold as ForeverUpgrade by default.
- No permanent window and no minimap button.

## Installation

The repository includes automated release packaging. Point WoWUp at this GitHub repository for update management.

## Requirements

- **ForeverUpgrade**
- **ForeverLoot**

Both are declared addon dependencies so WoW loads them before ForeverDungeon.

## Commands

- `/fd` — reopen the most recent result window.
- `/fd scan` — force a scan of your current dungeon.
- `/fd test` — preview the notification UI without being in a dungeon.
- `/fd on` / `/fd off` — enable or disable automatic entry scans.
- `/fd threshold 2` — use a 2% minimum when threshold inheritance is disabled.
- `/fd inherit on|off` — inherit ForeverUpgrade's threshold (default: on).
- `/fd no-upgrades on|off` — show/hide the short notification when nothing is worth chasing.
- `/fd status` — show current status and whether ForeverLoot is available.

## First test

After installing all three Forever addons, log in and run:

`/fd test`

That previews the temporary notification and detail panel.

Then run:

`/fd status`

It should report `ForeverLoot=on`.

## Current scope

Version 0.2.6 is Warrior-first because upgrade decisions come from ForeverUpgrade. ForeverLoot is deliberately separate from the scoring layer, so the same loot database can support more classes later without changing the dungeon UI.
