# Chogan Vertical Slice Report

Date: 2026-08-13  
Version: 0.2.0  
Package: `com.battleheim.chogan`

## Verdict

GO for initial local vertical-slice handoff. The slice is playable as a short cup run with tutorial, prep, three-match structure, rewards, branches, boss, save/continue, and local-only simulation data.

## Scope Delivered

- Added deterministic run domain: `RunState`, `RunEngine`, map generation, node unlocks, rewards, camp, event, market, and boss completion.
- Added playable scenes for tutorial, run map, node resolution, reward choice, and run result.
- Added three distinct enemy teams: East Wind, Stoneguard, and Cup Guardians.
- Added boss AI profile plus defensive enemy behavior.
- Kept match/run logic outside UI scripts.

## Match Balance

Final 1000-match batch:

- Player win rate: 52.0%
- Enemy win rate: 48.0%
- Win gap: 4.0%
- Draw rate: 0.0%
- Average goals: 2.738
- Extra-time rate: 17.1%
- Average length: 318.54 seconds
- Foul rate: 5.782

Pass: average goals are within 1.8-3.2, final draws are zero, extra-time is below 25%, and win gap is below 10%.

## Run Simulation

Three batches of 1000 runs were executed:

- Random: completion 31.0%, boss reach 55.5%, average coins 15.555.
- Aggressive: completion 52.0%, boss reach 70.7%, average coins 23.334.
- Conservative: completion 34.4%, boss reach 59.5%, average coins 20.049.

Logical duration target is represented as 24 minutes per run.

## Tests

- `tests/test_runner.gd`: passed, 20 checks.
- `tests/run_test_runner.gd`: passed, 18 checks.
- `tests/smoke_scene_runner.gd`: passed.
- Parse check: passed.

Godot emitted a Windows root certificate warning during headless runs; it did not fail local tests.

## Build Targets

Expected APK outputs:

- `builds/chogan-vertical-slice-debug.apk`
- `builds/chogan-vertical-slice-release.apk`

## Known Limits

- No real-device QA was performed in this pass.
- No measured FPS, memory, thermal, or battery profiling was performed.
- Visual/audio assets are placeholders.
- No online services, backend, live ops, analytics SDK, ads, or payments are included.

## Handoff

Primary playtest route: Start Cup Run -> Tutorial -> Preparation -> Match -> Reward -> Branch -> Match/Elite -> Reward -> Market/Camp -> Boss -> Run Result.
