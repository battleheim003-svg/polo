# Gate A Report

Date: 2026-08-13  
Branch: `feature/interactive-match`

## Scope

Gate A only:

- continuous 2D field
- one directly controllable rider
- weighted horse movement
- visible hittable ball
- aim and strike
- goals and goal detection
- base camera/full-field framing and HUD
- desktop and touch controls
- scene smoke test
- real Godot headless execution

Deferred: full eight-rider match, full AI, hook, ride-off, line of ball, boss, run integration, preparation redesign, broad art, full audio, Android device QA.

## Long-Running Command

The previous `interactive_scene_smoke` run was stuck with a Godot process still consuming CPU after the script had already failed. The process was safely stopped. No created files were deleted and no healthy source changes were reverted.

Root cause: the scene smoke test tried to access `/root/GameSession` from a `SceneTree` script before the normal project autoload context was available.

## Files Created Or Changed

Created:

- `domain/interactive/interactive_match_engine.gd`
- `scenes/interactive_match/interactive_match.tscn`
- `scenes/interactive_match/interactive_match.gd`
- `tests/interactive_match_test_runner.gd`
- `tests/interactive_scene_smoke.gd`
- `docs/INTERACTIVE_MATCH_REFERENCE_ANALYSIS.md`
- `docs/INTERACTIVE_MATCH_ARCHITECTURE.md`
- `reports/interactive-match/BASELINE.md`
- `reports/interactive-match/GATE_A_REPORT.md`

Changed:

- `docs/RELEASE_NOTES_VERTICAL_SLICE_PLAYTEST.md`

Reverted to pre-Gate-A routing/scope:

- `scenes/preparation/preparation.gd` remains routed to the old match scene.
- `export_presets.cfg` remains version `0.2.0` / code `2`.

## Test Results

- Parse: PASS
- Interactive engine tests: PASS, 10 checks
- Interactive scene smoke: PASS

Logs:

- `reports/audit/gate_a_parse_3.log`
- `reports/audit/gate_a_engine_tests_2.log`
- `reports/audit/gate_a_scene_smoke_3.log`

Godot still emits the known Windows root certificate warning. It did not fail Gate A.

## Gate A Questions

- Does the rider really move? YES. Test verifies controlled rider moves right, stays in bounds, and drains stamina.
- Does the ball really get hit? YES. Test verifies strike releases the ball and applies velocity.
- Does aim work? YES. Strike uses the input aim vector, including desktop/mouse or touch action flag path.
- Does goal register? YES. Test drives the ball into the goal and verifies score and goal stat.
- Does the scene run in Godot? YES. `interactive_scene_smoke.gd` instantiates and processes the scene successfully.

## Remaining Gate A Issues

- Scene smoke is headless; no visual screenshot was captured in this reduced scope.
- Camera is full-field framing, not a polished follow camera yet.
- Touch controls are functional buttons/pads, but multi-touch was not device-tested.
- Visuals are coherent placeholder shapes, not final art.
- The interactive scene is intentionally not connected to preparation/run yet.
