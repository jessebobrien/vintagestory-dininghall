<#
make-test-zip-and-install.ps1

Builds the project (Release), runs package.ps1 to create a release zip, and copies the produced zip into the local Vintage Story Mods folder for quick testing.

Usage:
  .\scripts\make-test-zip-and-install.ps1 [-GamePath 'C:\Path\To\VintageStory'] [-NoPackage]

#>
param(
    [string]$GamePath = $null,
    [switch]$NoPackage
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
Set-Location $repoRoot

Write-Host "Building DiningHallMod (Release)..."
dotnet build .\DiningHallMod.csproj -c Release

if (-not $NoPackage) {
    Write-Host "Running package.ps1..."
    if ($GamePath) { .\package.ps1 -GamePath $GamePath } else { .\package.ps1 }
}

# Find produced zip
$modinfo = Get-Content .\modinfo.json -Raw | ConvertFrom-Json
$zipName = "$($modinfo.name)_$($modinfo.version).zip"
$zipPath = Join-Path $repoRoot (Join-Path 'dist' $zipName)
if (-not (Test-Path $zipPath)) { throw "Package zip not found at $zipPath" }

# Copy to local Mods folder for testing
$modsDest = Join-Path $env:APPDATA 'VintagestoryData\Mods\DiningHall'
New-Item -ItemType Directory -Force -Path $modsDest | Out-Null
Copy-Item $zipPath -Destination $modsDest -Force
Write-Host "Copied $zipName to $modsDest"
Write-Host 'Done.'
