# Gate A.7 Camera, Scale & Readability Report

Date: 2026-08-13
Scope: Gate A.7 only. Gate B was not started.

## Summary

Gate A.7 moves the Gate A scene from a permanent full-field view to a controlled follow-camera presentation. The camera now targets the active rider/ball pair, leads toward aim/movement, zooms in after the opening overview, keeps the play space in bounds, and briefly zooms out around goal feedback. Rider, ball, aim, and strike readability are improved for normal play without manual zoom.

## Changes

- Added follow-camera state: `camera_center`, `camera_zoom`, target camera, overview time, goal zoom, and reduce-motion flag.
- Replaced direct world-to-screen scaling with camera-aware `_map()` and `_scale()`.
- Increased rider screen size in follow view.
- Increased ball visual size and outline readability.
- Enlarged and lengthened aim path in camera follow.
- Added ball edge indicator when the ball leaves the current frame.
- Simplified HUD text and removed `Rider 1`, `STA`, and `FOCUS` debug wording from the main header.
- Replaced touch command labels with compact symbols.
- Added Gate A.7 camera/readability test runner.

## Screenshots

Directory:

`reports/interactive-match/gate-a7/`

Files:

- `01_overview_start.png` - 1920x1017 - sha256 `dd50996ce58c25d6...`
- `02_camera_follow.png` - 1920x1017 - sha256 `5b32425866a8f061...`
- `03_rider_scale_gallop.png` - 1920x1017 - sha256 `4a7798016c29a58f...`
- `04_aim_charge_readable.png` - 1920x1017 - sha256 `41ab61701796d36c...`
- `05_strike_pose.png` - 1920x1017 - sha256 `8eb345242a9cb932...`
- `06_ball_follow.png` - 1920x1017 - sha256 `ddf12e3c5640f7d5...`
- `07_goal_camera_feedback.png` - 1920x1017 - sha256 `f6ae5b80908d3d38...`
- `08_mobile_20x9_hud.png` - 1920x1017 - sha256 `7f282a5f5ea52e4e...`
- `09_device_gameplay.png` - real device screenshot captured after launch; contains an external floating video overlay, so it is device-render proof but not clean visual proof.

Note: captures are from the real non-headless Godot window. The window client area reported by Godot was 1920x1017 in this desktop environment.

## Gameplay Video

Path:

`reports/interactive-match/gate-a7-gameplay.mp4`

Metadata:

- FPS: 30.0
- Duration: 30.0 seconds
- Frames: 900
- Resolution: 1920x1016
- Codec: mp4v
- Size: 8,294,577 bytes
- SHA256 prefix: `e24d18b65ef55c63...`

`ffprobe` is not installed on this machine, so metadata was recorded with OpenCV video inspection. The video is encoded from 900 consecutive frames captured from a real non-headless Godot run at 30fps. It is not a 5fps proof video and does not include webcam, browser, or desktop overlays.

## Tests

- Parse: PASS using absolute `--log-file`; no `user://logs` error.
- Interactive engine: PASS, `INTERACTIVE TESTS PASSED: 10 checks`.
- Camera/readability runner: PASS, `GATE A7 CAMERA READABILITY TEST PASSED`.
- Scene smoke: PASS, `INTERACTIVE SCENE SMOKE PASSED`.
- Visual capture: PASS, `GATE A7 VISUAL CAPTURE PASSED`.
- Video frame capture: PASS, `GATE A7 VIDEO FRAMES PASSED`.

Remaining warning:

- `Failed to read the root certificate store` appears in headless Godot logs and is unrelated to the scene or gameplay.

## Review ZIP

Path:

`delivery/chogan-gate-a7-review.zip`

Expected contents:

- Gate A.7 screenshots only
- Gate A.7 gameplay video
- Gate A.7 report
- No `.import` files
- No Gate A.5 or Gate A.6 screenshot folders
- No APK

## Android

Temporary APK:

`builds/chogan-gate-a7-debug.apk`

Package:

`com.battleheim.chogan.gatea`

Verification:

- Package verified with `aapt`.
- Signature verified with APK Signature Scheme v2 and v3.
- SHA256: `B29D30C8191E481166B2A6C6354A18468E13F001BB324D42EBF29D5291E0DC4B`

Install:

- PASS after user enabled/approved USB install.

Launch:

- PASS
- Focused activity: `com.battleheim.chogan.gatea/com.godot.game.GodotAppLauncher`
- PID observed: `12730`

## Device Verification

Passed/recorded:

- Device install: PASS
- Device launch/render: PASS
- Touch input: BASIC PASS using adb tap/swipe
- Physical display: 1080x2400
- TOTAL PSS: 245090 KB
- TOTAL RSS: 342384 KB
- gfxinfo sample: 25 frames, 9 janky frames, 50th percentile 20ms, 90th percentile 34ms
- Package-filtered logcat: no `FATAL EXCEPTION`, `ANR`, or `AndroidRuntime` crash found

Not fully passed:

- Device screenshot is not clean because an external floating video overlay was active on the phone.
- Multi-touch was not proven by adb automation.
- Safe area requires a clean overlay-free screenshot/manual confirmation.

## CHOGAN_GATE_A7_PACKET

Verdict: ITERATE
RiderScreenSize: PASS
CameraFollow: PASS
CameraLead: PASS
CameraBounds: PASS
BallVisibility: PASS
BallOffscreenIndicator: PASS_FOUNDATION
HUDMobileReadability: PASS_DESKTOP_20X9_CAPTURE
AimReadability: PASS
GoalSequence: PASS_FOUNDATION
PersianPresentation: PASS_FOUNDATION
VideoFPS: 30.0
VideoDuration: 30.0s
VideoResolution: 1920x1016
GameplayVideo: reports/interactive-match/gate-a7-gameplay.mp4
Screenshots: reports/interactive-match/gate-a7/
ReviewZip: delivery/chogan-gate-a7-review.zip
ReviewZipContentsVerified: PASS - A.7 screenshots including device capture, A.7 video, and A.7 report
AndroidAPK: PASS - builds/chogan-gate-a7-debug.apk
DeviceInstall: PASS
Touch: BASIC_PASS_ADB
MultiTouch: NOT_VERIFIED_ON_DEVICE
SafeArea: PARTIAL_BLOCKED_BY_FLOATING_OVERLAY
Memory: TOTAL_PSS_245090_KB
FPSDevice: GFXINFO_SAMPLE_25_FRAMES_9_JANKY
CrashANR: PASS_NO_PACKAGE_FATAL_OR_ANR_FOUND
CriticalIssues: Device screenshot contains external floating overlay; multitouch not proven
ReadyForGateB: NO
