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

Write-Host "Invoking release script to build/package without bumping version..."
& "$repoRoot\scripts\release.ps1" -NoVersionBump -GamePath $GamePath
