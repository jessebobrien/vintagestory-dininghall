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
    [switch]$ForceStubs,
    [string]$Configuration = "Release",
    [switch]$NoInstall,
    [switch]$IncludePdb
)

Write-Host "Starting build-and-install..."

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

# Helper: copy with retry to handle locked files (game running)
function Copy-WithRetry($src, $dest, $tries = 5, $delaySec = 2) {
    for ($i = 0; $i -lt $tries; $i++) {
        try {
            Copy-Item $src -Destination $dest -Force -ErrorAction Stop
            return $true
        }
        catch {
            if ($i -lt ($tries - 1)) {
                Write-Host "Copy failed (attempt $($i+1)), retrying in $delaySec seconds..."
                Start-Sleep -Seconds $delaySec
            }
            else {
                Write-Warning "Failed to copy $src to $dest after $tries attempts: $($_.Exception.Message)"
                return $false
            }
        }
    }
}

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


# If we are doing a STUBS build but a libs folder exists, temporarily move it out of the way
$movedLibs = $false
$libsPath = Join-Path $root 'libs'
$libsTemp = Join-Path $root 'libs.__bak_for_stubs'

$useStubs = $ForceStubs -or -not (Test-Path (Join-Path $libsPath 'VintagestoryAPI.dll'))

if ($useStubs -and (Test-Path $libsPath)) {
    try {
        Write-Host "Temporarily moving existing ./libs to ./libs.__bak_for_stubs to avoid conflicts during STUBS build..."
        if (Test-Path $libsTemp) { Remove-Item $libsTemp -Recurse -Force }
        Move-Item -Path $libsPath -Destination $libsTemp -Force
        $movedLibs = $true
    }
    catch {
        Write-Warning "Failed to move ./libs aside: $($_.Exception.Message)"
    }
}

try {
    if ($useStubs) {
        Write-Host "Building with STUBS (fast dev build)..."
        dotnet build .\DiningHallMod.csproj -c $Configuration /p:DefineConstants=STUBS
    }
    else {
        Write-Host "Building against Vintage Story API DLLs in ./libs..."
        dotnet build .\DiningHallMod.csproj -c $Configuration
    }
}
finally {
    # restore libs if we moved them
    if ($movedLibs) {
        try {
            if (Test-Path $libsPath) { Remove-Item $libsPath -Recurse -Force }
            Move-Item -Path $libsTemp -Destination $libsPath -Force
            Write-Host "Restored ./libs from ./libs.__bak_for_stubs"
        }
        catch {
            Write-Warning "Failed to restore ./libs from backup: $($_.Exception.Message)"
        }
    }
}

$builtDir = Join-Path $root ("bin\" + $Configuration)
$built = Join-Path $builtDir "net472\DiningHallMod.dll"
$pdb = Join-Path $builtDir "net472\DiningHallMod.pdb"
if (-not (Test-Path $built)) {
    Write-Error "Build failed or DLL not found at $built"
    exit 1
}

if ($useStubs) {
    # STUBS builds are for CI/dev; do not install them into the game Mods folder because
    # they define stubbed API types that the game runtime won't recognize. Save to dist/stubs
    # so you can inspect them, but skip installing to your live Mods folder by default.
    $stubsDist = Join-Path $root 'dist\stubs'
    New-Item -ItemType Directory -Force -Path $stubsDist | Out-Null
    Copy-Item $built -Destination $stubsDist -Force
    Write-Host "STUBS build complete — saved to $stubsDist. Do NOT install STUBS-built DLLs into the game's Mods folder."

    if ($IncludePdb -and (Test-Path $pdb)) {
        Copy-Item $pdb -Destination $stubsDist -Force
        Write-Host "Copied PDB to $stubsDist"
    }

    if (-not $NoInstall) {
        Write-Warning "Skipping installation of STUBS build into Mods folder to avoid runtime incompatibility. Use a real-API build to install into the game."
    }
}
else {
    if (-not $NoInstall) {
        New-Item -ItemType Directory -Force -Path $ModsPath | Out-Null
        Copy-Item $built -Destination $ModsPath -Force
        Write-Host "Installed DiningHallMod.dll to $ModsPath"

        if ($IncludePdb -and (Test-Path $pdb)) {
            Copy-Item $pdb -Destination $ModsPath -Force
            Write-Host "Copied PDB to $ModsPath"
        }
    }
    else {
        Write-Host "Build complete; skipping install (NoInstall flag set)."
    }
}

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
