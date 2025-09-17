<#
test.ps1

Builds the project (Release), packages the mod into a zip, and copies the produced zip into the local Vintage Story Mods folder for quick testing.

Usage:
  .\scripts\test.ps1 [-GamePath 'C:\Path\To\VintageStory']

#>
param(
  [string]$GamePath = $null
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
Set-Location $repoRoot

Write-Host "Invoking release script to build/package without bumping version..."
& "$repoRoot\scripts\release.ps1" -NoVersionBump -GamePath $GamePath
