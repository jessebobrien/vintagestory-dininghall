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
Write-Host "Building (Release) and packaging..."
dotnet build .\DiningHallMod.csproj -c Release
if ($GamePath) { .\package.ps1 -GamePath $GamePath } else { .\package.ps1 }

$zipName = "$($modinfo.name)_$($modinfo.version).zip"
$zipPath = Join-Path $repoRoot (Join-Path 'dist' $zipName)
if (-not (Test-Path $zipPath)) { throw "Package zip not found at $zipPath" }

Write-Host "Created release zip: $zipPath"
Write-Host 'Done.'
