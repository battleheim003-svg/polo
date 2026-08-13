# Chogan Playtest Build Report

Date: 2026-08-13  
Verdict: READY FOR MANUAL PLAYTEST

## 1. Final Verdict

READY FOR MANUAL PLAYTEST — debug APK installed and launched on a real Android device, initial in-app flow was smoke-tested, and no Chogan crash/ANR was found in captured package-focused logcat. A full three-run human playtest is still required.

ReadinessScore: 86/100

## 2. Project

- Version: 0.2.0 vertical-slice-playtest
- Version Code: 2
- Package: `com.battleheim.chogan`
- Godot: 4.7.1.stable.official.a13da4feb
- Commit at start: `1118d21`
- Branch: `main`
- Missing requested doc: `AGENTS.md`

## 3. Tests

- Godot version: exit 0
- Parse check: exit 0
- Domain/data tests: exit 0, 20 checks passed
- Run tests: exit 0, 18 checks passed
- UI smoke: exit 0
- Match simulation: exit 0
- Run simulation: exit 0
- Debug Android export: exit 0
- Release Android export: Godot reported release keystore missing in preset, then APK was signed externally with local project keystore and verified by `apksigner`
- Signature verify: exit 0 for debug and release
- Device install debug: exit 0
- Device launch debug: exit 0
- Release install on device: exit 1, `INSTALL_FAILED_UPDATE_INCOMPATIBLE` because debug package with different signature was already installed

Known repeated warning: Godot headless runs reported Windows root certificate/editor settings warnings. They did not fail tests or exports.

## 4. Match Balance

Fresh 1000-match batch:

- Player win rate: 52.0%
- Enemy win rate: 48.0%
- Win gap: 4.0%
- Draw rate: 0.0%
- Average goals: 2.738
- Extra-time rate: 17.1%
- Average logical length: 318.54 seconds
- Foul rate: 5.782
- Skill activation rate: 10.225
- Synergy effects: 1917

Acceptance: PASS.

## 5. Run Simulation

Fresh 1000-run batches:

- Random: completion 31.0%, boss reach 55.5%, average coins 15.555, average rewards 2.649.
- Aggressive: completion 52.0%, boss reach 70.7%, average coins 23.334, average rewards 3.267.
- Conservative: completion 34.4%, boss reach 59.5%, average coins 20.049, average rewards 2.265.

No simulator crash or infinite loop observed.

## 6. APKs

Debug:

- Path: `F:\polo\builds\chogan-vertical-slice-debug.apk`
- Size: 57,766,480 bytes
- SHA256: `C71010DC0824215CFD57977DCA34F362F08199F3DDAA9A36FD9DA907AED0FA94`
- Package: `com.battleheim.chogan`
- Version: 0.2.0, code 2
- Min SDK: 24
- Target SDK: 36
- ABI: `arm64-v8a`, `armeabi-v7a`
- Signature: v2 true, v3 true

Release:

- Path: `F:\polo\builds\chogan-vertical-slice-release.apk`
- Size: 52,559,985 bytes
- SHA256: `55FC62F8B6AA3D7C19097A5C8F62EE8B047C2C3AE41EF7DFB8B71ED1A345939B`
- Package: `com.battleheim.chogan`
- Version: 0.2.0, code 2
- Min SDK: 24
- Target SDK: 36
- ABI: `arm64-v8a`, `armeabi-v7a`
- Signature: v2 true, v3 true

## 7. Device

- ADB status: `device`
- Serial: masked, suffix `...190e`
- Model: `2201116SG`
- Product/device: `veux_eea` / `veux`
- Android: 13
- ABI: `arm64-v8a`
- Screen: 1080x2400
- Density: 440

## 8. Install And Launch

- Debug install command: `adb install -r builds/chogan-vertical-slice-debug.apk`
- Debug install result: PASS
- Launch command: `adb shell monkey -p com.battleheim.chogan -c android.intent.category.LAUNCHER 1`
- Launch result: PASS
- PID after launch: 32362
- Focused activity: `com.battleheim.chogan/com.godot.game.GodotAppLauncher`
- Orientation: app launched and remained focused; detailed orientation field was not returned by `dumpsys input`

## 9. Device Flow QA

- Main Menu: PASS
- Tutorial: PARTIAL
- Run Map: PARTIAL
- Preparation: PARTIAL
- Match: PARTIAL
- Chukker Break: NOT TESTED
- Reward: NOT TESTED
- Event: NOT TESTED
- Camp: NOT TESTED
- Market: NOT TESTED
- Boss: NOT TESTED
- Run Result: NOT TESTED
- Save/Continue: NOT TESTED
- Back: NOT TESTED
- Pause: NOT TESTED
- Speed x2: NOT TESTED

The tested device path confirms install, launch, focus, screenshots, and several initial in-app taps. Full run completion needs manual playtest.

## 10. Logcat

- Launch log: `F:\polo\reports\device\chogan-logcat-launch.txt`
- Flow log: `F:\polo\reports\device\chogan-logcat-flow.txt`
- Chogan crash/ANR: none found in filtered checks.
- Noted non-blocking system AppSearch indexing warnings outside the Chogan runtime.

## 11. Performance

- Launch memory snapshot: total PSS about 236,535 KB.
- Graphics PSS: about 91,748 KB.
- Frame stats: only 20 launch frames captured; not representative of gameplay.
- FPS: NOT MEASURED.

## 12. Screenshots And Recording

- `F:\polo\screenshots\chogan-device-main.png`
- `F:\polo\screenshots\chogan-device-after-start.png`
- `F:\polo\screenshots\chogan-device-flow-2.png`
- `F:\polo\screenshots\chogan-device-flow-3.png`
- `F:\polo\screenshots\chogan-device-flow-4.png`
- `F:\polo\reports\device\chogan-device-smoke.mp4`

Recording note: device rejected 2400x1080 codec setup and retried at 1280x720.

## 13. Git And Security

- Branch: `main`
- Source tree before report docs: clean except ignored artifacts.
- APK, ZIP, logcat, screenshots, recordings, keystores, and `.godot` are ignored and not committed.
- `export_presets.cfg` contains no keystore password, key password, release alias, or private keystore path.
- No secret was added to Git.

## 14. Playtest Package

- Path: `F:\polo\delivery\chogan-vertical-slice-playtest.zip`
- Size: 111,881,859 bytes
- SHA256: `610CB5FDB45E97670A775E78225353FB6777CF5B7CD807460855C11056BC4C1A`
- Contents: debug APK, release APK, Persian install guide, playtest form, owner QA checklist, bug report form, release notes, SHA256 sums, screenshots, short recording, filtered logcat.

## 15. Remaining Limits

- Full three-match run was not completed on device.
- Save/Continue was not verified on device.
- Release APK was not launched on device due debug/release signature mismatch.
- FPS was not measured.
- Device screenshots were captured but not visually rendered by the local image inspection tool in this session.

## 16. Next Step

Playtest انسانی سه-Run با فرم فارسی و چک لیست مالک.

## 17. Copy Packet

```text
CHOGAN_PLAYTEST_BUILD_PACKET
Verdict: READY FOR MANUAL PLAYTEST
ReadinessScore: 86/100
Version: 0.2.0 vertical-slice-playtest
VersionCode: 2
PackageID: com.battleheim.chogan
GodotVersion: 4.7.1.stable.official.a13da4feb
Commit: 1118d21
Tests: PASS domain/data 20, run 18, smoke, parse
MatchBalance: PASS player 52.0 enemy 48.0 gap 4.0 draw 0.0
ExtraTimeRate: 17.1%
AverageGoals: 2.738
RandomRunBalance: completion 31.0 boss 55.5 coins 15.555
AggressiveRunBalance: completion 52.0 boss 70.7 coins 23.334
ConservativeRunBalance: completion 34.4 boss 59.5 coins 20.049
DebugAPK: F:\polo\builds\chogan-vertical-slice-debug.apk
DebugAPKSize: 57766480
DebugAPK_SHA256: C71010DC0824215CFD57977DCA34F362F08199F3DDAA9A36FD9DA907AED0FA94
ReleaseAPK: F:\polo\builds\chogan-vertical-slice-release.apk
ReleaseAPKSize: 52559985
ReleaseAPK_SHA256: 55FC62F8B6AA3D7C19097A5C8F62EE8B047C2C3AE41EF7DFB8B71ED1A345939B
SignatureStatus: debug/release apksigner v2 true, v3 true
MinSDK: 24
TargetSDK: 36
ABIs: arm64-v8a, armeabi-v7a
DeviceModel: 2201116SG
AndroidVersion: 13
ADBStatus: device
InstallStatus: debug PASS, release NOT TESTED due signature mismatch with installed debug
LaunchStatus: debug PASS
OrientationStatus: landscape launch observed, detailed dumpsys orientation not returned
SaveContinueDeviceTest: NOT TESTED
DeviceFlowSummary: Main Menu PASS; Tutorial/Run Map/Preparation/Match PARTIAL; full run NOT TESTED
LogcatStatus: no Chogan crash/ANR found
PerformanceStatus: launch memory PSS 236535 KB; FPS NOT MEASURED
PlaytestPackage: F:\polo\delivery\chogan-vertical-slice-playtest.zip
PlaytestPackage_SHA256: 610CB5FDB45E97670A775E78225353FB6777CF5B7CD807460855C11056BC4C1A
SecurityStatus: no secrets committed; APK/log/screenshot/video ignored
CriticalIssues: full manual run and save/continue still required on device
RecommendedNextStep: Playtest انسانی سه-Run
```
