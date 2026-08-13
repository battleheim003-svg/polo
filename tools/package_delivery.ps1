param(
    [string]$Root = "F:\polo"
)

$ErrorActionPreference = "Stop"

$deliveryDir = Join-Path $Root "delivery"
$sourceZip = Join-Path $deliveryDir "chogan-source.zip"
$artifactZip = Join-Path $deliveryDir "chogan-prototype-delivery.zip"
$manifestPath = Join-Path $deliveryDir "MANIFEST.txt"
$checksumsPath = Join-Path $deliveryDir "CHECKSUMS.sha256"

New-Item -ItemType Directory -Force $deliveryDir | Out-Null
Remove-Item -LiteralPath $sourceZip -Force -ErrorAction SilentlyContinue

$includeRoots = @(
    ".gitignore",
    "project.godot",
    "export_presets.cfg",
    "README.md",
    "ARCHITECTURE.md",
    "BALANCE.md",
    "CHANGELOG.md",
    "assets",
    "autoload",
    "data",
    "docs",
    "domain",
    "scenes",
    "tests",
    "tools",
    "ui"
)

$sourceItems = foreach ($item in $includeRoots) {
    Join-Path $Root $item
}

Compress-Archive -LiteralPath $sourceItems -DestinationPath $sourceZip -Force

$deliveryRelative = @(
    "builds\chogan-debug.apk",
    "builds\chogan-release.apk",
    "docs\ANDROID_QA.md",
    "docs\DELIVERY.md",
    "README.md",
    "CHANGELOG.md",
    "BALANCE.md",
    "ARCHITECTURE.md",
    "tools\android_install_and_run.ps1",
    "balance_report.json"
)
$deliveryItems = foreach ($item in $deliveryRelative) {
    Join-Path $Root $item
}
$deliveryItems += $sourceZip

Remove-Item -LiteralPath $artifactZip -Force -ErrorAction SilentlyContinue
Compress-Archive -LiteralPath $deliveryItems -DestinationPath $artifactZip -Force

$filesForManifest = @(
    (Join-Path $Root "builds\chogan-debug.apk"),
    (Join-Path $Root "builds\chogan-release.apk"),
    $sourceZip,
    $artifactZip
)

$manifestLines = @()
$checksumLines = @()
foreach ($file in $filesForManifest) {
    $item = Get-Item -LiteralPath $file
    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $file
    $relative = $item.FullName.Replace($Root + "\", "")
    $manifestLines += "$relative`t$($item.Length) bytes`t$($hash.Hash)"
    $checksumLines += "$($hash.Hash)  $relative"
}

$manifestLines | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$checksumLines | Set-Content -LiteralPath $checksumsPath -Encoding ASCII

Write-Host "Packaged source: $sourceZip"
Write-Host "Packaged delivery: $artifactZip"
Write-Host "Wrote manifest: $manifestPath"
Write-Host "Wrote checksums: $checksumsPath"
