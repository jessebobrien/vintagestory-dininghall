<#
bump-version-and-release.ps1

Bumps semver in modinfo.json (patch/minor/major), runs packaging to produce a release zip in dist/, and prints the new zip path.

Usage:
  .\scripts\bump-version-and-release.ps1 -Part patch
  .\scripts\bump-version-and-release.ps1 -Part minor
  .\scripts\bump-version-and-release.ps1 -Part major

#>
param(
    [ValidateSet('patch','minor','major')]
    [string]$Part = 'patch',
    [switch]$GamePath
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
Set-Location $repoRoot

$modinfoPath = Join-Path $repoRoot 'modinfo.json'
$modinfo = Get-Content $modinfoPath -Raw | ConvertFrom-Json

function Parse-SemVer($s) {
    if ($s -match '^(\d+)\.(\d+)\.(\d+)$') { return @([int]$matches[1],[int]$matches[2],[int]$matches[3]) }
    throw "modinfo.json version '$s' is not semver (MAJOR.MINOR.PATCH)"
}

$parts = Parse-SemVer $modinfo.version
switch ($Part) {
    'patch' { $parts[2]++ }
    'minor' { $parts[1]++; $parts[2] = 0 }
    'major' { $parts[0]++; $parts[1] = 0; $parts[2] = 0 }
}
$newVersion = "$($parts[0]).$($parts[1]).$($parts[2])"
$modinfo.version = $newVersion
$modinfo | ConvertTo-Json -Depth 4 | Set-Content -NoNewline $modinfoPath -Encoding UTF8
Write-Host "Bumped version to $newVersion"

# Build & package
Write-Host "Building (Release)..."
dotnet build .\DiningHallMod.csproj -c Release

Write-Host "Packaging release zip..."
$dist = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$dll = Join-Path $repoRoot 'bin\Release\net472\DiningHallMod.dll'
$pdb = Join-Path $repoRoot 'bin\Release\net472\DiningHallMod.pdb'
$icon = Join-Path $repoRoot 'modicon.png'

if (-not (Test-Path $dll)) { throw "Built DLL not found at $dll" }

if (-not (Test-Path $icon)) {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 64,64
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try { $g.Clear([System.Drawing.Color]::FromArgb(255,200,200,200)); $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,120,120,120)); $g.FillRectangle($brush,8,8,48,48); $brush.Dispose(); $letterBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,255,255)); $g.FillRectangle($letterBrush,14,18,4,28); $g.FillRectangle($letterBrush,20,18,10,6); $g.FillRectangle($letterBrush,20,34,10,6); $g.FillRectangle($letterBrush,28,24,4,16); $g.FillRectangle($letterBrush,36,18,4,28); $g.FillRectangle($letterBrush,48,18,4,28); $g.FillRectangle($letterBrush,40,30,8,4); $letterBrush.Dispose(); $bmp.Save($icon,[System.Drawing.Imaging.ImageFormat]::Png) } finally { $g.Dispose(); $bmp.Dispose() }
}

$zipName = "${($modinfo.name)}_${($modinfo.version)}.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$files = @($dll, $pdb, (Join-Path $repoRoot 'modinfo.json'), $icon)
Compress-Archive -Path $files -DestinationPath $zipPath

if (-not (Test-Path $zipPath)) { throw "Package zip not found at $zipPath" }
Write-Host "Created release zip: $zipPath"
Write-Host 'Done.'
