# real-build-and-install.ps1
# Locate Vintage Story install, copy real API DLLs to ./libs, build Release, and install into Mods folder.
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
# repository root is parent of scripts directory
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
Set-Location $repoRoot

function Find-GamePath {
    param([string]$hint)
    if ($hint) {
        if (Test-Path $hint) { return $hint }
    }

    $candidates = @(
        "$env:ProgramFiles\\Steam\\steamapps\\common\\VintageStory",
        "$env:ProgramFiles(x86)\\Steam\\steamapps\\common\\VintageStory",
        "$env:ProgramFiles\\VintageStory",
        "$env:ProgramFiles(x86)\\VintageStory",
        "$env:ProgramFiles\\Vintagestory",
        "$env:ProgramFiles(x86)\\Vintagestory"
    )

    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $found = Get-ChildItem -Path $c -Filter VintagestoryAPI.dll -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { return $found.DirectoryName }
        }
    }
    return $null
}

if (-not $GamePath) { $GamePath = Find-GamePath }
if (-not $GamePath) {
    Write-Error "Could not find Vintage Story installation. Pass -GamePath 'C:\\\\path\\to\\VintageStory' or copy the API DLLs into ./libs manually."
    exit 2
}

Write-Host "Using game path: $GamePath"

New-Item -ItemType Directory -Force -Path libs | Out-Null
$dlls = @('VintagestoryAPI.dll','VintagestoryLib.dll')
foreach ($d in $dlls) {
    $src = Join-Path $GamePath $d
    if (-not (Test-Path $src)) { Write-Warning "Missing $d in game path: $src"; continue }
    Copy-Item $src -Destination libs -Force
    Write-Host "Copied $d to ./libs"
}

Write-Host "Building project (Release)..."
dotnet build .\DiningHallMod.csproj -c Release
if ($LASTEXITCODE -ne 0) { Write-Error "dotnet build failed"; exit 3 }

$built = Join-Path (Join-Path (Resolve-Path '.').ProviderPath 'bin\\Release\\net472') 'DiningHallMod.dll'
if (-not (Test-Path $built)) { Write-Error "Built DLL not found at $built"; exit 4 }

$mods = Join-Path $env:APPDATA 'VintagestoryData\\Mods\\DiningHall'
New-Item -ItemType Directory -Force -Path $mods | Out-Null
Copy-Item $built -Destination $mods -Force
Write-Host "Installed DLL to $mods"

$pdb = [IO.Path]::ChangeExtension($built,'.pdb')
if (Test-Path $pdb) { Copy-Item $pdb -Destination $mods -Force; Write-Host 'Copied PDB' }

if (Test-Path modinfo.json) { Copy-Item modinfo.json -Destination $mods -Force; Write-Host 'Copied modinfo.json' }

Write-Host 'Real-API build and install completed successfully.'
exit 0
