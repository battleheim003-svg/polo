# Android QA

## Artifacts

- Debug: `F:\polo\builds\chogan-debug-iteration.apk`
- Release: `F:\polo\builds\chogan-release-iteration.apk`

Sizes:

- Debug: 57,722,863 bytes
- Release: 52,516,368 bytes

SHA256:

- Debug: `18993994B41E8DC2BF8CDC67BAAA5CAD55863B34E7F218410B7A0D525D8D8060`
- Release: `A2B8ECE59196692C72398601B8179610CAA96C96458B3C4FF07E7FF9F7FF5D3D`

## Verification

Debug APK signature:

- v2: verified
- v3: verified
- signer: Android debug key

Release APK signature:

- v2: verified
- v3: verified
- signer: local prototype release key

Manifest summary from `aapt dump badging`:

- package: `com.battleheim.chogan`
- versionCode: `1`
- versionName: `0.1.0`
- app label: `Chogan: Masters of the Field`
- debug APK debuggable: yes
- release APK debuggable: no
- min SDK: `24`
- target SDK: `36`
- native ABIs: `arm64-v8a`, `armeabi-v7a`

## Device Status

Device/emulator install was not executed in this pass.

## Install And Launch

```powershell
powershell -ExecutionPolicy Bypass -File F:\polo\tools\android_install_and_run.ps1 -Build debug -ApkPath F:\polo\builds\chogan-debug-iteration.apk
powershell -ExecutionPolicy Bypass -File F:\polo\tools\android_install_and_run.ps1 -Build release -ApkPath F:\polo\builds\chogan-release-iteration.apk
```

The script launches package `com.battleheim.chogan`.

## Signing Hygiene

`export_presets.cfg` does not store keystore paths, aliases, or passwords. Signing was performed through local machine configuration/commands and secrets were not committed.
