# Chogan: Masters of the Field

Prototype name in Persian: Chogan: Salar-e Meydan.

This repository contains a playable graybox Godot 4.x prototype for an offline, deterministic two-dimensional chogan auto-battler match. It focuses on the match core, seed reproducibility, tactical commands, event-driven UI, tests, and balance simulation.

## Godot Version

Designed for Godot 4.x with the Compatibility renderer. Verified with Godot 4.7.1 stable from `C:\Users\LEGION\Downloads\Godot_v4.7.1-stable_win64.exe`.

## Open And Run

1. Open `project.godot` in Godot 4.x.
2. Run the main scene `res://scenes/boot/boot.tscn`.
3. Use Quick Start or Preparation.
4. In match, use the Persian tactic buttons to change the coach command.

The game uses a 1920x1080 landscape viewport, canvas stretch, large touch-friendly buttons, and the Compatibility renderer for Android-oriented 2D.

## Tests

Run from a terminal with Godot installed:

```powershell
godot --headless --path . -s res://tests/test_runner.gd
```

Smoke test for scene-facing data and match loop:

```powershell
godot --headless --path . -s res://tests/smoke_scene_runner.gd
```

The runner covers deterministic seed replay, different-seed variation, zone bounds, scoring, attack direction after goals, stamina/focus bounds, skill activation guard, incompatible action guard, hook/ride-off/free-hit behavior, chukker transitions, substitution, extra-time bounds, headless completion, corrupt save detection, and data loading. It passed 20 checks on Godot 4.7.1.

## Balance Simulator

Run 1000 headless matches:

```powershell
godot --headless --path . -s res://tools/balance_simulator.gd
```

It writes `balance_report.json` at the project root and prints a statistical summary.

## Android Export

The project settings are prepared for landscape, Compatibility rendering, touch-friendly UI, canvas stretch, and offline play. To export:

1. Install Godot Android export templates.
2. Configure Android SDK/JDK paths in Godot.
3. Create an Android export preset in the editor.
4. Build from the editor or with:

```powershell
godot --headless --path . --export-release Android builds/chogan.apk
```

Android debug export was completed with Godot 4.7.1. Android SDK 35 and Java 17 are present, Godot's Java SDK path was set to `C:/Program Files/Java/jdk-17`, a debug keystore was created at `C:/Users/LEGION/AppData/Roaming/Godot/keystores/debug.keystore`, and the official Godot 4.7.1 Android export templates were installed.

Generated APK:

```text
F:\polo\builds\chogan-debug.apk
F:\polo\builds\chogan-release.apk
```

APK QA notes are in `docs/ANDROID_QA.md`. A connected device or emulator was not available during verification; use `tools/android_install_and_run.ps1` once one is attached.

Delivery packages:

```text
F:\polo\delivery\chogan-source.zip
F:\polo\delivery\chogan-prototype-delivery.zip
F:\polo\delivery\CHECKSUMS.sha256
F:\polo\delivery\MANIFEST.txt
```

## Current Limits

The prototype uses generated Control nodes and placeholder visuals. It has no online play, accounts, ads, payments, gacha, battle pass, leaderboard, 3D, realistic horse physics, or live operations.
