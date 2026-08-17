# Gate A.6 Visual Foundation Report

Date: 2026-08-13
Scope: Gate A.6 only. No Gate B systems were added.

## Summary

Gate A.6 replaces the earlier debug-primitive look with a more coherent visual foundation:

- Continuous field with grass bands, sand perimeter, center line/circle, attack/defense arcs, readable goals, border motif, flags, and Persian-inspired skyline.
- One controlled horse/rider in debug harness scope.
- More recognizable horse/rider cutout with body, head/neck, tail, legs, saddle, rider, mallet, shadow, selection ring, gallop bob, leg motion, dust, and strike pose change.
- Ball with cream fill, dark outline, shadow, readable trail, and impact glow.
- Segmented aim path with arrowhead, charge variation, and non-debug styling.
- HUD rebuilt as a compact lapis/gold panel with score, chukker, timer, stamina, focus, and pause.
- Goal feedback now includes flash, particles, gold emphasis, Persian `گل!` toast, score change, and rider reaction.

## Evidence

Screenshots:

`reports/interactive-match/gate-a6/`

- `01_field.png`
- `02_rider_idle.png`
- `03_rider_gallop.png`
- `04_aim_charge.png`
- `05_strike_impact.png`
- `06_ball_motion.png`
- `07_goal_feedback.png`
- `08_touch_hud.png`

Device screenshot:

- `09_device_gameplay.png` was not produced because APK install was blocked by the phone.

Gameplay video:

`reports/interactive-match/gate-a6-gameplay.mp4`

- Clean MP4 generated from a real non-headless Godot run.
- No webcam, browser, desktop overlay, or unrelated window content.
- Duration: 39.0 seconds.
- Resolution: 1920x1017.
- Size: 2,131,469 bytes.

## Tests

- Parse: PASS with `--log-file F:\polo\reports\interactive-match\gate_a6_parse.log`.
- Interactive engine: PASS, `INTERACTIVE TESTS PASSED: 10 checks`.
- Scene smoke: PASS, `INTERACTIVE SCENE SMOKE PASSED`.
- Visual capture: PASS, `GATE A6 VISUAL CAPTURE PASSED`.
- Video frame capture: PASS, `GATE A6 VIDEO FRAMES PASSED`.

The previous `user://logs/...` error is resolved for test/export runs by passing an absolute `--log-file` path per run. The remaining Windows warning is `Failed to read the root certificate store`, which is unrelated to the gameplay scene and did not fail the runs.

## Android

Temporary Gate A.6 APK:

`builds/chogan-gate-a6-debug.apk`

Package:

`com.battleheim.chogan.gatea`

Verification:

- Package name verified with `aapt`.
- Version name: `0.2.0`
- Version code: `2`
- Min SDK: `24`
- Target SDK: `36`
- Signature verified with APK Signature Scheme v2 and v3.
- SHA256: `899952903995CA7308E62C6A61B01E28782D4F5D8932DD610306DFF6E7FE7C44`

Install:

- BLOCKED by device/user restriction.
- `adb install -r F:\polo\builds\chogan-gate-a6-debug.apk`
- Result: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`

The restriction was not bypassed.

## Device Verification

Detected device:

- Serial: `66cfb60e190e`
- Model: `2201116SG`

Blocked items:

- Device launch
- Real device screenshot
- Real device gameplay video
- Touch joystick
- Touch aim
- Charge hold/release strike
- Multi-touch
- Safe area on device
- PSS memory
- Frame stats/FPS
- Logcat runtime check
- Crash/ANR runtime check

## Remaining Issues

- Device install must be allowed manually on the phone before Android Gate A.6 can pass.
- Multi-touch remains unverified.
- Device performance/logcat remain unverified.
- The current visual foundation is still placeholder art, not final art.
- `09_device_gameplay.png` is missing until device launch succeeds.

## CHOGAN_GATE_A6_PACKET

Verdict: ITERATE
FieldQuality: PASS
RiderRecognizability: PASS
HorseAnimation: PASS_FOUNDATION
AimQuality: PASS
BallReadability: PASS
HUDQuality: PASS
GoalFeedback: PASS
PersianIdentity: PASS_FOUNDATION
NonHeadlessCapture: PASS
GameplayVideoClean: PASS
ParseStatus: PASS
LogPathStatus: PASS_USER_LOG_ERROR_RESOLVED
AndroidAPK: PASS
DeviceInstall: BLOCKED_INSTALL_FAILED_USER_RESTRICTED
Touch: NOT_VERIFIED_ON_DEVICE
MultiTouch: NOT_VERIFIED_ON_DEVICE
Landscape: PASS_DESKTOP_CAPTURE
SafeArea: NOT_VERIFIED_ON_DEVICE
Memory: NOT_MEASURED_ON_DEVICE
FPS: NOT_MEASURED_ON_DEVICE
CrashANR: NOT_VERIFIED_ON_DEVICE
Screenshots: PASS - reports/interactive-match/gate-a6/
GameplayVideo: PASS - reports/interactive-match/gate-a6-gameplay.mp4
CriticalIssues: Device install blocked by user restriction; device touch/multitouch/performance/logcat unavailable
ReadyForGateB: NO
