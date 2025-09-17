<#
test.ps1

Builds the project (Release), packages the mod into a zip, and copies the produced zip into the local Vintage Story Mods folder for quick testing.

Usage:
  .\scripts\test.ps1 -NoVersionBump [-GamePath 'C:\Path\To\VintageStory']

#>
param(
  [switch]$NoVersionBump,
  [string]$GamePath = $null
)

# Require an explicit NoVersionBump flag to ensure test runs don't accidentally change versions
if (-not $NoVersionBump)
{
  throw "This script requires -NoVersionBump to run. Use -NoVersionBump to confirm you do not want a version bump."
}

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
Set-Location $repoRoot

Write-Host "Building DiningHallMod (Release)..."
dotnet build .\DiningHallMod.csproj -c Release

# Package directly: collect files and zip
$modinfo = Get-Content .\modinfo.json -Raw | ConvertFrom-Json
$name = $modinfo.name
$version = $modinfo.version
$dist = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$dll = Join-Path $repoRoot 'bin\Release\net472\DiningHallMod.dll'
$pdb = Join-Path $repoRoot 'bin\Release\net472\DiningHallMod.pdb'
$icon = Join-Path $repoRoot 'modicon.png'

if (-not (Test-Path $dll)) { throw "Built DLL not found at $dll" }

# generate simple icon if missing
if (-not (Test-Path $icon)) {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 64,64
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try { $g.Clear([System.Drawing.Color]::FromArgb(255,200,200,200)); $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,120,120,120)); $g.FillRectangle($brush,8,8,48,48); $brush.Dispose(); $letterBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,255,255)); $g.FillRectangle($letterBrush,14,18,4,28); $g.FillRectangle($letterBrush,20,18,10,6); $g.FillRectangle($letterBrush,20,34,10,6); $g.FillRectangle($letterBrush,28,24,4,16); $g.FillRectangle($letterBrush,36,18,4,28); $g.FillRectangle($letterBrush,48,18,4,28); $g.FillRectangle($letterBrush,40,30,8,4); $letterBrush.Dispose(); $bmp.Save($icon,[System.Drawing.Imaging.ImageFormat]::Png) } finally { $g.Dispose(); $bmp.Dispose() }
}

$zipName = "${name}_${version}.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$files = @($dll, $pdb, (Join-Path $repoRoot 'modinfo.json'), $icon)
Compress-Archive -Path $files -DestinationPath $zipPath

# Copy to local Mods folder for testing (place zip directly in Mods, no nested subfolder)
$modsDest = Join-Path $env:APPDATA 'VintagestoryData\Mods'
New-Item -ItemType Directory -Force -Path $modsDest | Out-Null
# Remove any existing DiningHall_*.zip files from the Mods folder before copying
Get-ChildItem -Path $modsDest -Filter 'DiningHall_*.zip' -File -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
Copy-Item $zipPath -Destination $modsDest -Force
Write-Host "Copied $zipName to $modsDest"
Write-Host 'Done.'
