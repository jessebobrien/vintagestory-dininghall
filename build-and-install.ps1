<#
build-and-install.ps1

Automates building the mod and installing the produced DLL into your Vintage Story Mods folder.

Usage:
  .\build-and-install.ps1 [-GamePath <path>] [-ModsPath <path>] [-ForceStubs]

If a valid Vintage Story API DLL is found (VintagestoryAPI.dll) in common install locations or the provided -GamePath,
the script will copy it to ./libs and build against the real API. Otherwise it falls back to a STUBS build.
#>

param(
    [string]$GamePath,
    [string]$ModsPath = "$(Join-Path $env:APPDATA 'VintagestoryData\Mods\DiningHall')",
    [switch]$ForceStubs
)

Write-Host "Starting build-and-install..."

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

function TryFindGameDll {
    param([string]$searchRoot)
    if (-not (Test-Path $searchRoot)) { return $null }
    try {
        $found = Get-ChildItem -Path $searchRoot -Filter VintagestoryAPI.dll -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.DirectoryName }
    }
    catch { }
    return $null
}

if (-not $GamePath -and -not $ForceStubs) {
    $candidates = @(
        "$env:ProgramFiles\VintageStory",
        "$env:ProgramFiles(x86)\VintageStory",
        "$env:ProgramFiles\Vintagestory",
        "$env:ProgramFiles(x86)\Vintagestory",
        "$env:ProgramFiles(x86)\Steam\steamapps\common\VintageStory",
        "$env:ProgramFiles\Steam\steamapps\common\VintageStory"
    )

    foreach ($c in $candidates) {
        $p = TryFindGameDll -searchRoot $c
        if ($p) { $GamePath = $p; break }
    }
}

if ($GamePath) {
    Write-Host "Found game path: $GamePath"
    New-Item -ItemType Directory -Force -Path libs | Out-Null
    $dlls = @('VintagestoryAPI.dll','VintagestoryLib.dll')
    foreach ($d in $dlls) {
        $src = Join-Path $GamePath $d
        if (Test-Path $src) {
            Copy-Item $src -Destination libs -Force
            Write-Host "Copied $d to ./libs"
        }
    }
}

if ($ForceStubs -or -not (Test-Path libs\VintagestoryAPI.dll)) {
    Write-Host "Building with STUBS (fast dev build)..."
    dotnet build .\DiningHallMod.csproj -c Release /p:DefineConstants=STUBS
}
else {
    Write-Host "Building against Vintage Story API DLLs in ./libs..."
    dotnet build .\DiningHallMod.csproj -c Release
}

$built = Join-Path $root "bin\Release\net472\DiningHallMod.dll"
if (-not (Test-Path $built)) {
    Write-Error "Build failed or DLL not found at $built"
    exit 1
}

New-Item -ItemType Directory -Force -Path $ModsPath | Out-Null
Copy-Item $built -Destination $ModsPath -Force
Write-Host "Installed DiningHallMod.dll to $ModsPath"

# Copy modinfo and supporting files so Vintage Story recognizes the mod folder
$supportFiles = @('modinfo.json', 'README.md', 'TESTING.md')
foreach ($f in $supportFiles) {
    $src = Join-Path $root $f
    if (Test-Path $src) {
        Copy-Item $src -Destination $ModsPath -Force
        Write-Host "Copied $f to $ModsPath"
    }
}
Write-Host "Done. Start Vintage Story and check logs/chat for mod messages."
