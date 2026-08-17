# Gate A.5 Visual & Device Verification

Date: 2026-08-13
Scope: Gate A only. No Gate B features were added or expanded.

## Command Status

- No long-running Godot/ADB/emulator process was left active at the start of this pass.
- A later parallel Godot verification attempt stalled on the shared `user://logs` copy path; the Godot processes were stopped safely with `Stop-Process`.
- Created files and healthy source changes were preserved.
- Follow-up Godot smoke and engine runs were executed serially. They returned exit code `0`, while Godot still printed `ERROR: Failed to open 'user://logs/...'`.

## Non-Headless Scene

- Scene under test: `res://scenes/interactive_match/interactive_match.tscn`
- The scene was launched through real Godot visual capture runners, not a mockup renderer.
- The scene can run as a standalone debug harness without relying on an incomplete `GameSession` autoload.
- Harness usage remains scoped to debug/test entry points and does not change the shipped boot scene.

## Screenshots

Screenshot directory:

`reports/interactive-match/screenshots/`

Captured frames:

- `01_full_field.png`
- `02_rider_moving.png`
- `03_aim_path.png`
- `04_ball_after_strike.png`
- `05_goal_score.png`
- `06_hud_touch_controls.png`

Visual check:

- Continuous field, side margins, field lines, and two goals are visible.
- Controlled rider uses a recognizable horse/rider silhouette with selection ring and direction marker.
- Ball is visible with outline/shadow and short trail.
- Aim arrow is visible.
- HUD is readable and does not cover the main play area.
- Touch controls are visible in landscape.
- Goal feedback and score change are visible in `05_goal_score.png`.

## Gameplay Video

Video path:

`reports/interactive-match/gate-a-gameplay.mp4`

Recorded from a real Godot run by capturing live Godot frames and encoding them to MP4.

- Size: `3,222,407` bytes
- Duration target: 20-40 seconds
- Captured content includes rider movement, aim state, strike, ball movement, goal, and score feedback.

## Desktop Input

Status: PASS by scene smoke/visual runner and manual visual verification.

- WASD/arrow movement path is wired through the Gate A input layer.
- Mouse aim is wired.
- Mouse release strike is wired.
- Movement shows acceleration, deceleration, and turning rather than teleporting.

## Android Build

Temporary Gate A debug APK:

`builds/chogan-gate-a-debug.apk`

Package:

`com.battleheim.chogan.gatea`

APK verification:

- Package name verified by `aapt`.
- Version name: `0.2.0`
- Version code: `2`
- Min SDK: `24`
- Target SDK: `36`
- Signature verified with APK Signature Scheme v2 and v3.
- SHA256: `FA3DB8DAA234E9C3852EDB2AB087DC2ED818FD3D45B379499E69C4FD256376C5`

The main project was restored after the temporary export:

- `run/main_scene="res://scenes/boot/boot.tscn"`
- `package/unique_name="com.battleheim.chogan"`

## Device Install And Launch

Device detected:

- Serial: `66cfb60e190e`
- Model: `2201116SG`
- Android: `13`

Install result:

- BLOCKED
- `adb install -r builds\chogan-gate-a-debug.apk` failed with:
  `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`

Because install was blocked by the device/user restriction, device launch, device screenshot, device logcat, and device performance could not be completed honestly.

## Touch

Desktop touch UI visual presence: PASS.

Device touch verification: BLOCKED by failed APK install.

Manual steps still required on device:

1. Unlock the phone.
2. Enable/allow Install via USB for this session.
3. Install `builds/chogan-gate-a-debug.apk`.
4. Launch `com.battleheim.chogan.gatea`.
5. Test left joystick, aim pad, charge hold, release strike, pause/back, and simultaneous move + aim.

## Goal

Status: PASS in scene smoke and visual capture.

- Ball can be struck.
- Ball enters the goal.
- Score changes and goal feedback appears.

## Landscape And Safe Area

Status: PARTIAL PASS.

- Desktop/non-headless captures show landscape layout with HUD and touch controls readable.
- Device-specific safe-area and 20:9 validation are blocked until APK install succeeds.

## Performance

Desktop smoke: PASS by exit code.

Device performance: BLOCKED by failed APK install.

- PSS memory: not measured on device.
- Frame stats/FPS: not measured on device.
- Crash/ANR: no device result available.
- Logcat: not collected because app could not be installed/launched.

## Parse And Scene Smoke

- Scene smoke runner: PASS by serial Godot exit code `0`.
- Interactive engine runner: PASS by serial Godot exit code `0`.
- Parse/check-only: BLOCKED by Godot `user://logs` copy error in the local environment.
- The log-copy error is separate from gameplay scene behavior, but it prevents marking the final parse rerun as a clean PASS in this report.

## Remaining Gate A.5 Issues

- Device install is blocked by `INSTALL_FAILED_USER_RESTRICTED`.
- Device touch and multi-touch are not verified.
- Device safe-area/performance/logcat are not verified.
- Godot intermittently prints `Failed to open user://logs/...` during command-line validation.
- Intermediate frame folders and `.import` sidecars exist under `reports/interactive-match/` as generated verification artifacts.

## CHOGAN_GATE_A_VISUAL_PACKET

Verdict: ITERATE
NonHeadlessScene: PASS
VisualReadability: PASS
RiderVisual: PASS
FieldVisual: PASS
BallVisibility: PASS
AimVisibility: PASS
MovementFeel: PASS
GoalFeedback: PASS
DesktopControl: PASS
AndroidAPK: PASS
DeviceInstall: BLOCKED - INSTALL_FAILED_USER_RESTRICTED
DeviceLaunch: BLOCKED
TouchControl: BLOCKED_ON_DEVICE
MultiTouch: NOT_VERIFIED_ON_DEVICE
Landscape: PARTIAL_PASS
SafeArea: NOT_VERIFIED_ON_DEVICE
Memory: NOT_MEASURED_ON_DEVICE
FPS: NOT_MEASURED_ON_DEVICE
CrashANR: NOT_VERIFIED_ON_DEVICE
Screenshots: PASS - reports/interactive-match/screenshots/
GameplayVideo: PASS - reports/interactive-match/gate-a-gameplay.mp4
CriticalIssues: Device install permission blocked, multi-touch not verified, device perf/logcat not collected
ReadyForGateB: NO
