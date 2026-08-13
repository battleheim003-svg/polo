# Changelog

## Prototype Build

- Created Godot 4.x project configuration with Compatibility renderer, landscape viewport, stretch settings, input map, autoloads, README, and gitignore.
- Added typed domain definitions for riders, horses, teams, ball, match state, events, deterministic RNG, data repository, rule AI, and match engine.
- Implemented two-team four-rider match simulation across two chukkers.
- Implemented five-zone field logic with bounded ball movement.
- Implemented possession, line owner, attack direction, goals, shots, strikes, passes, hooks, ride-offs, recoveries, fouls, free hits, stamina, focus, skills, coach commands, substitutions, extra time, and match end.
- Added prototype data for six riders, four horse traits, two full teams, and five tactical commands.
- Added Boot, Menu, Preparation, Match, and Results scenes with Persian UI text and functional buttons.
- Added event queue playback and Tween-based ball movement between zones.
- Added headless test runner with 20 required checks.
- Added 1000-match balance simulator with JSON report output.
- Added save service with schema version, backup file, defaults, and corrupt data handling.
- Added architecture and balance documentation.
- Fixed Godot 4.7 parser issues around reserved `trait` identifiers and type inference.
- Verified the domain test runner and 1000-match balance simulator with Godot 4.7.1.
- Added a smoke scene runner and verified the boot scene can start in headless mode.
- Completed Android preset details for SDK 35 and generated the local debug keystore.
- Downloaded and installed the official Godot 4.7.1 Android export templates.
- Fixed Android export configuration for ETC2/ASTC and non-Gradle SDK overrides.
- Built and signed `builds/chogan-debug.apk`.
- Verified APK signature, zip alignment, manifest badging, SDK values, and native ABIs.
- Added Android QA notes and a PowerShell install-and-launch helper.
- Built and verified a release APK signed with a prototype release keystore.
- Added reproducible delivery packaging with source zip, full delivery zip, manifest, and SHA-256 checksums.

## Iteration 1 Stabilization

- Added interactive lineup preparation with four role slots, tap-to-select/tap-to-place swapping, validation, role fit, horse info, and active synergy display.
- Added `LineupTools` for role fit, lineup validation, and deterministic synergy detection.
- Passed selected lineup into `MatchState`.
- Added data-driven synergy activation/events and mechanical effects for matched horses, midfield whirl, wall and spear, and fearless team.
- Added line owner bonus to dominance breakdowns and visible match feedback.
- Reworked fouls to use control, horse calmness, fatigue, pressure, command state, and synergy risk; free hits now transfer line ownership.
- Added distinct skill effects for the six prototype riders.
- Added coach command duration and per-chukker command use tracking.
- Added player break decision support between chukkers.
- Added deterministic tie-break to prevent final draws.
- Expanded balance simulator output to include all major actions, free hits, line-owner changes, synergies, command usage, lineup, and stamina.
- Changed Android package id to `com.battleheim.chogan`.
- Removed keystore secrets from `export_presets.cfg`.
- Added `docs/CHOGAN_RND.md`.
