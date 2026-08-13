# Chogan Iteration 1 Report

## 1. Summary Of Changes

- Interactive preparation supports four role slots, rider selection, tap-to-place swapping, validation, role fit, horse stats, tactic choice, and active synergy display.
- Selected lineup is passed into `MatchState`.
- Role fit, line owner, foul chance, free hit, rider skills, coach command duration, break decisions, synergy effects, and tie-break are mechanical.
- Balance simulator reports all major action counts, line owner changes, free hits, synergy effects, command usage, lineup, roles, horses, stamina, and per-match rows.
- Package id changed to `com.battleheim.chogan`.
- Keystore paths/users/passwords were removed from `export_presets.cfg`.
- Git repository was initialized on branch `main`.

## 2. Changed Files

Core changes are in `autoload/game_session.gd`, `domain/match/lineup_tools.gd`, `domain/match/match_engine.gd`, `domain/match/match_state.gd`, `domain/match/balance_config.gd`, `domain/match/rule_ai.gd`, `scenes/preparation/preparation.gd`, `scenes/match/match.gd`, `tests/test_runner.gd`, `tools/balance_simulator.gd`, `tools/android_install_and_run.ps1`, `data/teams/teams.json`, docs, and `export_presets.cfg`.

## 3. Preparation

Preparation is interactive. A player can select a rider, tap a slot, swap riders already in the lineup, inspect role fit and horse stamina/calmness, inspect synergies, choose a starting tactic, and start only when the lineup is valid. `GameSession.set_lineup()` validates and stores the lineup before `start_match()`.

## 4. Mechanics

- Role Fit: exact/adjacent/mismatch values are calculated by `LineupTools.role_fit()` and used in dominance.
- Synergy: four synergies emit activation/effect events and affect stamina drain, zone-3 pass focus, strike/shot bonus, and shot pressure.
- Line Owner: line ownership adds dominance and changes through ride-off, pass, recovery, free hit, and restart.
- Foul: chance uses control, horse calmness, fatigue, pressure, active command, and synergy risk.
- Free Hit: changes possession, holder, control, and line owner.
- Skills: all six prototype riders have distinct deterministic effects.
- Coach Commands: duration and per-chukker usage tracking are active.
- Substitution: break decision exists in UI and deterministic headless flow.

## 5. Tests

- Domain tests: PASS, exit code 0, `TESTS PASSED: 20 checks`
- Smoke: PASS, exit code 0
- Boot scene headless: PASS, exit code 0

New checks cover valid/duplicate/empty lineup, role fit, selected lineup transfer, synergy activation, break decision, final tie-break, line owner dominance breakdown, and coach command duration.

## 6. Determinism

PASS. Same seed and command stream produce the same signature; different seed varies.

## 7. Balance

Latest 1000-match run:

- Matches: 1000
- Player win rate: 50.8%
- Enemy win rate: 49.2%
- Win-rate difference: 1.6 percentage points
- Draw rate: 0.0%
- Average goals: 2.106
- Average length: 398.6 seconds
- Extra-time rate: 49.3%
- Foul rate: 7.609
- Skill activations per match: 12.39

Balance meets the draw, average goals, and win-rate difference targets. Extra-time rate remains a pacing risk.

## 8. Android

- Package id: `com.battleheim.chogan`
- Debug APK: `F:\polo\builds\chogan-debug-iteration.apk`, 57,722,863 bytes, SHA256 `18993994B41E8DC2BF8CDC67BAAA5CAD55863B34E7F218410B7A0D525D8D8060`
- Release APK: `F:\polo\builds\chogan-release-iteration.apk`, 52,516,368 bytes, SHA256 `A2B8ECE59196692C72398601B8179610CAA96C96458B3C4FF07E7FF9F7FF5D3D`
- Debug signature: verified v2/v3.
- Release signature: verified v2/v3 after local signing.
- Badging package id: `com.battleheim.chogan`
- Device test: NOT TESTED.

## 9. Git And Security

- Git repo initialized on branch `main`.
- `.gitignore` excludes `.godot/`, builds, delivery zips, downloads, APK/AAB/ZIP/keystore/JKS/idsig artifacts, generated logs, and temporary audit project copies.
- `export_presets.cfg` no longer contains keystore passwords, aliases, or personal signing paths.

## 10. Remaining Limits

- Extra-time rate remains high and may need pacing tuning.
- Visuals remain graybox/placeholder.
- No real device QA was completed.

## 11. Final Verdict

**GO - ready for Vertical Slice planning.**

The prototype mechanics are substantially more complete, tests pass, balance gates are met, package id is corrected, APKs were built and verified, and remaining issues are appropriate Vertical Slice planning items.

## 12. CHOGAN_ITERATION_AUDIT_PACKET

```text
CHOGAN_ITERATION_AUDIT_PACKET
Verdict: GO
ReadinessScore: 90/100
TestSummary: PASS; domain=20 checks; smoke=PASS; boot=headless PASS
DeterminismSummary: PASS; same seed signature stable, different seed varies
BalanceSummary: 1000 matches; player_win=0.508; enemy_win=0.492; draw=0.0; avg_goals=2.106
FinalDrawRate: 0.0
WinRateDifference: 0.016
AverageGoals: 2.106
PackageID: com.battleheim.chogan
AndroidBuildStatus: PASS; debug and release iteration APKs built; signatures verified
GitStatus: main; commit amended
SecurityStatus: export_presets.cfg signing secrets removed
CriticalRemainingIssues: none blocking Vertical Slice
RecommendedNextStep: begin Vertical Slice planning with pacing and visual pass
```
