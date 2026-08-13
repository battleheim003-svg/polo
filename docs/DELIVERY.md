# Chogan Prototype Delivery

## Ready Artifacts

- Debug APK: `F:\polo\builds\chogan-debug.apk`
- Release APK: `F:\polo\builds\chogan-release.apk`
- Source package: `F:\polo\delivery\chogan-source.zip`
- Full delivery package: `F:\polo\delivery\chogan-prototype-delivery.zip`
- Checksums: `F:\polo\delivery\CHECKSUMS.sha256`
- Manifest: `F:\polo\delivery\MANIFEST.txt`
- Android QA: `F:\polo\docs\ANDROID_QA.md`
- Balance report: `F:\polo\balance_report.json`

## Verified

- Godot test runner: `TESTS PASSED: 20 checks`
- Godot smoke runner: `SMOKE PASSED: scene data and match loop are available`
- Android debug export: built, signed, aligned, manifest checked
- Android release export: built, signed, aligned, manifest checked
- 1000-match balance simulator: completed
- Source package excludes `.godot`, `.godot_user`, logs, downloads, APK build outputs, and keystores.

## Not Run

Device/emulator install was not completed because no Android device was available through `adb devices -l`, and starting the AVD was too slow for this handoff.

## Fast Install Later

Connect an Android device with USB debugging enabled, then run:

```powershell
powershell -ExecutionPolicy Bypass -File F:\polo\tools\android_install_and_run.ps1 -Build release
```
