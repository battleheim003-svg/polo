# CHOGAN_GATE_A8_PACKET

Date: 2026-08-14
Scope: Gate A.8 - Touch Control Rebuild and Match HUD Refresh
Branch: feature/interactive-match

## Verdict

OwnerTouchTest: AWAITING
ReadyForGateB: NO

Gate A.8 has been implemented, parsed, smoke-tested, visually captured, exported to Android, installed on the owner's connected device, and launched. Final approval is intentionally blocked until the product owner performs a real two-finger device test.

## Control Scheme

ControlScheme: Fixed joystick + independent drag aim

MovementTouch: IMPLEMENTED_AUTOMATED_PASS
AimTouch: IMPLEMENTED_AUTOMATED_PASS
SimultaneousMoveAim: IMPLEMENTED_AUTOMATED_PASS
Charge: IMPLEMENTED_AUTOMATED_PASS
ReleaseStrike: IMPLEMENTED_AUTOMATED_PASS
FingerOwnership: IMPLEMENTED_AUTOMATED_PASS
ThirdFingerSafety: IMPLEMENTED_AUTOMATED_PASS

MovementFingerModel:
- The first touch in the bottom-left movement zone owns movement.
- `movement_touch_id` cannot be overwritten by a right-side aim finger or a third finger.
- Releasing the movement owner clears `movement_vector`.

AimFingerModel:
- The first different touch in the bottom-right aim zone owns aim.
- Drag updates `aim_vector` and `charge`.
- Releasing the aim owner emits strike when charge is above the configured threshold.
- Releasing a non-owner finger does not cancel movement or aim.

EventRouting:
- HUD decorative controls use `mouse_filter = IGNORE`.
- Pause is the only permanent HUD button using `mouse_filter = STOP`.
- Touch controls are rendered and handled through an independent `CanvasLayer`.
- Desktop mouse aim remains separate from mobile multitouch ownership.

CoordinateSpace:
- Touch positions are handled in viewport/screen space.
- Touch UI is not transformed by the match camera.
- Joystick and aim visuals are drawn in a CanvasLayer over the match field.

## HUD

FixedJoystick: PASS
RectangularStrikeRemoved: PASS
RectangularSwitchRemoved: PASS
HUDRebuilt: PASS
MockupAlignment: PASS_FOUNDATION
PersianFont: PARTIAL - no bundled licensed Persian font was added in this pass.
RTL: PARTIAL - permanent HUD text is minimized; the goal toast renders Persian text.

Current UI replacements:
- Removed the old large debug joystick surface.
- Removed the old large aim pad.
- Removed rectangular Strike and Switch buttons.
- Replaced the textual header with compact top HUD elements.
- Added visible score/time/chukker at top center.
- Added active rider portrait placeholder plus stamina/focus bars.
- Added a small pause button.
- Added subtle joystick and charge/aim indicators.

## Automated Verification

Parse: PASS
EngineTests: PASS
TouchTests: PASS
SceneSmoke: PASS
VisualCapture: PASS
GameplayVideo: PASS

Evidence:
- `reports/interactive-match/gate_a8_parse_2.log`
- `reports/interactive-match/gate_a8_touch_tests_2.log`
- `reports/interactive-match/gate_a8_smoke_2.log`
- `reports/interactive-match/gate_a8_engine.log`
- `reports/interactive-match/gate_a8_visual_capture.log`
- `reports/interactive-match/gate_a8_video_capture.log`
- `reports/interactive-match/gate-a8/01_normal_hud.png`
- `reports/interactive-match/gate-a8/05_simultaneous_move_aim.png`
- `reports/interactive-match/gate-a8-touch-gameplay.mp4`

GameplayVideo:
- Path: `reports/interactive-match/gate-a8-touch-gameplay.mp4`
- Duration: 24.0 seconds
- Frames: 720
- FPS: 30
- Resolution: 1920x1016
- Size: 6,017,350 bytes

## Android Verification

AndroidAPK: PASS
APKPath: `builds/chogan-gate-a8-debug.apk`
APKPackage: `com.battleheim.chogan.gatea`
APK_SHA256: `8F0409028BC5797F4DC886DF0E72B82C4FAC07592FDFB427CAE0915570F2911E`

DeviceInstall: PASS
DeviceLaunch: PASS
DeviceFocus: PASS
CleanScreenshot: PASS
CrashANR: PASS - no fatal exception or ANR found in captured logcat.

Device:
- Serial: `66cfb60e190e`
- Model: `2201116SG`
- Product: `veux_eea`
- Focus: `com.battleheim.chogan.gatea/com.godot.game.GodotAppLauncher`
- Physical size: `1080x2400`

Device screenshots and logs:
- `reports/interactive-match/gate-a8/08_device_clean.png`
- `reports/interactive-match/gate-a8-device/focus.txt`
- `reports/interactive-match/gate-a8-device/pid.txt`
- `reports/interactive-match/gate-a8-device/display.txt`
- `reports/interactive-match/gate-a8-device/meminfo.txt`
- `reports/interactive-match/gate-a8-device/gfxinfo.txt`
- `reports/interactive-match/gate-a8-device/logcat.txt`

Performance snapshot:
- Total frames rendered: 25
- Janky frames: 2 (8.00%)
- 90th percentile: 16ms
- 95th percentile: 17ms
- 99th percentile: 150ms
- Number missed vsync: 0
- Total PSS: 239,864 KB
- Graphics: 90,356 KB

## Files Changed Or Added

Primary implementation:
- `scenes/interactive_match/interactive_match.gd`
- `scenes/interactive_match/input/dual_touch_controller.gd`
- `scenes/interactive_match/input/dual_touch_controller.tscn`

Tests and capture scripts:
- `tests/gate_a8_touch_controller_test.gd`
- `tests/gate_a8_visual_capture.gd`
- `tests/gate_a8_video_frames.gd`

Artifacts:
- `builds/chogan-gate-a8-debug.apk`
- `reports/interactive-match/gate-a8/`
- `reports/interactive-match/gate-a8-device/`
- `reports/interactive-match/gate-a8-touch-gameplay.mp4`

Preserved:
- `project.godot` restored to `res://scenes/boot/boot.tscn`
- `export_presets.cfg` restored to `com.battleheim.chogan` and `builds/chogan-vertical-slice-debug.apk`

## Critical Issues

- OwnerTouchTest is still awaiting a real two-finger test on the device.
- Persian typography is not final because no licensed Persian font asset was bundled.
- The current device screenshot proves launch and basic visual cleanliness, but does not prove real human multitouch success.

## Owner Test Required

Gate A.8 must remain blocked until the owner confirms the exact real-device interaction sequence:

1. Hold the left joystick and move the rider.
2. Keep the left finger down.
3. Drag a second finger on the right side to aim.
4. Confirm aim appears while rider movement continues.
5. Hold aim for about one second.
6. Release only the right finger.
7. Confirm the ball is struck and rider movement does not stop.
8. Repeat five times.
9. Test Pause and Android Back once.
10. Check readability of the Persian goal text.

ReadyToImplementNext: NO - wait for owner PASS/FAIL.
