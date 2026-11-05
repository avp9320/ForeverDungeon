# v1.0 acceptance checklist

This is a release gate, not a claim of implementation. README claims and static code inspection do not substitute for live-client evidence. Check a box only after its behavior is verified; record test date/client and evidence in this file.

- [ ] Verify instance detection and loot source mapping in live dungeons
- [ ] Verify ForeverLoot/ForeverUpgrade integration and threshold behavior
- [ ] Never present incomplete catalogs as definitive no-upgrade results
- [ ] Test gear/spec changes, temporary notification, reopen and reload
- [ ] Verify dependency loading and release packaging

## Evidence

- Code review: 2026-11-05 — commit 1986b91 bounds automatic item-cache retries to three per scan and rejects stale instance scans after zone changes; manual /fd scan resets retry budget. This addresses indefinite rescan loops but remains untested in the live client.
- Automated/static tests: pending (no executable WoW client test harness verified in this run)
- Live WoW: Forever client verification: pending
- Release ZIP and WoWUp installation: pending

## Status

Pre-1.0. Features described in README may be implemented but are not accepted as verified here until tested. Avoid declaring v1.0 solely on version metadata.

## Phase 1 implementation — shared loot sources (2026-11-05)

- [x] Preserve all documented boss names when the same item ID appears under multiple bosses (`Core.lua`, commit `d43962c`). Comparison remains deduplicated per item, while the upgrade detail entry now displays all distinct source names and exposes `bosses` for future consumers.
- [ ] Verify shared-drop source labels against a real ForeverLoot catalog in the client; no Lua runtime or live-game test performed for this change.
