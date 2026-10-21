# Crownlands Implementation Plan

**Goal:** Expand the existing Roblox place into the requested staged medieval RPG, starting with a verified playable foundation.
**Architecture:** Server-authoritative services, replicated definitions, client-only input and UI controllers. Source files mirror Explorer. Installation runs only in Studio edit mode and preserves the original clearing.
**Tech Stack:** Roblox Studio, Luau, Parts, Motor6D, RemoteEvents, ProximityPrompt.
**Spec:** `docs/requirements.ru.txt` (user-supplied requirements).

## Global Constraints
- No publishing, external paid assets, or security setting changes.
- Preserve the working clearing and back up the place before installation.
- No claims about persistence, concurrent clients, mobile devices, or load without actual verification.
- Build actual implementations; later phases remain explicitly pending instead of empty services or dummy buttons.

## Review Focus
- Repeated Play requests must not grant duplicate starter items.
- Malformed remote payloads, spam, and distant prompts must not mutate state.
- Death/respawn must reset movement state and reconnect HUD.
- Client input must not set stamina or movement speed on the server.
- GUI layout must fit a phone viewport and remain usable after respawn.

## Task 1: Foundation
- [x] Run failing Studio acceptance assertions for Shared, Remotes, MainMenu, HUD, Map and village spawn.
- [x] Implement Shared/Config, UtilityModules and server-authoritative PlayerStateService.
- [x] Generate connected map zones, safe village spawn, interaction points, lighting and templates.
- [x] Implement menu, appearance presets, onboarding, HUD, keyboard/gamepad/touch sprint.
- [x] Install, verify syntax and run Play acceptance tests including stamina, distance validation, death/respawn and malformed requests.

## Task 2: Combat
- [x] Add weapon definitions, server combat validation, sword/shield models and training opponent.
- [x] Connect attack, heavy, block/parry, dodge and replicated visual feedback.
- [x] Test cooldown, range, wall obstruction, safe-zone player protection and opponent death/respawn.

## Subsequent independently verifiable phases
3. Inventory/equipment/gold and atomic NPC purchases/sales.
4. Resource nodes, smithing/repair, farming/hunting and profession output.
5. Dialogues, five quests, one-time rewards, reputation, guards and prison.
6. Versioned profiles, retrying saves and session locks; real published test-place roundtrip required.
7. Durable player trade, groups, shared events; two-client and disconnect tests required.
8. Animation/audio, streaming/mobile QA and measured server load.

The local directory is not a Git repository. Keep backups and readable sources; do not invent commits.

## Execution record
- Foundation and combat implemented and verified in Studio. NPC economy, inventory, resource collection and one intro quest implemented in addition.
- 51 edit-time assertions, 23 runtime gameplay assertions, 20 economy assertions passed.
- Two simulated clients passed replication/equipment/HUD checks and server safe-zone/wilderness PvP checks.
- Independent review found fast-release throttling bugs; regression reproduced, releases exempted from action throttle, then the complete multiplayer suite passed.
- Mobile emulator revealed default touch combat overlap; replaced default CAS touch buttons with a HUD grid. Phone QA performed after correction.
- Remaining original RPG phases are explicitly pending in README; no persistent storage or player-to-player trade is claimed.
