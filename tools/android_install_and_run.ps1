param(
    [ValidateSet("debug", "release")]
    [string]$Build = "debug",
    [string]$ApkPath = "",
    [string]$PackageName = "com.battleheim.chogan"
)

$ErrorActionPreference = "Stop"
$adb = "C:\Users\LEGION\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if (!(Test-Path -LiteralPath $adb)) {
    throw "adb.exe was not found at $adb"
}
if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $ApkPath = "F:\polo\builds\chogan-$Build.apk"
}
if (!(Test-Path -LiteralPath $ApkPath)) {
    throw "APK was not found at $ApkPath"
}

$devicesOutput = & $adb devices -l
$devicesOutput
$connected = $devicesOutput | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "^List of devices" }
if (!$connected) {
    throw "No connected Android device or emulator was found. Enable USB debugging or start an emulator, then run this script again."
}
& $adb install -r $ApkPath
& $adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1
& $adb logcat -c
Write-Host "Installed and launched $PackageName. Use adb logcat to inspect runtime logs."
