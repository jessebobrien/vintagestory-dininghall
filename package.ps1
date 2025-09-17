<#
package.ps1

Builds the mod (STUBS by default), generates a placeholder modicon.png, creates a deps json file, and packages the mod into a ZIP suitable for distribution.

Usage:
  .\package.ps1            # build with STUBS and package
  .\package.ps1 -GamePath 'C:\Path\To\VintageStory'  # build against real API DLLs if available

#>

param(
    [string]$GamePath = $null,
    [switch]$ForceStubs
)

Set-Location $PSScriptRoot

if ($GamePath) {
    Write-Host "Using game path: $GamePath"
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

$useStubs = $ForceStubs -or -not (Test-Path libs\VintagestoryAPI.dll)
if ($useStubs) {
    Write-Host "Building with STUBS..."
    dotnet build .\DiningHallMod.csproj -c Release /p:DefineConstants=STUBS
}
else {
    Write-Host "Building against real game DLLs in ./libs..."
    dotnet build .\DiningHallMod.csproj -c Release
}

$dll = Join-Path $PSScriptRoot 'bin\Release\net472\DiningHallMod.dll'
$pdb = Join-Path $PSScriptRoot 'bin\Release\net472\DiningHallMod.pdb'
if (-not (Test-Path $dll)) { throw "Built DLL not found at $dll" }

# Read modinfo
$modinfo = Get-Content .\modinfo.json -Raw | ConvertFrom-Json
$name = $modinfo.name
$version = $modinfo.version

# Generate placeholder modicon.png if missing
$iconPath = Join-Path $PSScriptRoot 'modicon.png'
if (-not (Test-Path $iconPath)) {
    Write-Host "Generating placeholder modicon.png..."
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 64,64
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(255,200,200,200))
    $font = New-Object System.Drawing.Font 'Arial',24,[System.Drawing.FontStyle]::Bold
    $brush = [System.Drawing.Brushes]::DarkSlateGray
    $g.DrawString('DH',$font,[System.Drawing.Brushes]::Black,8,16)
    $bmp.Save($iconPath,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# Create deps json
$deps = [PSCustomObject]@{
    name = $name
    version = $version
    dependencies = @(
        @{ name = 'VintageStory'; version = $modinfo.vintagestory.apiVersion }
    )
}
$depsPath = Join-Path $PSScriptRoot "$name.deps.json"
$deps | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $depsPath

# Package files
$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipName = "$name" + "_" + "$version" + ".zip"
$zipPath = Join-Path $dist $zipName

$filesToInclude = @($dll, $pdb, (Join-Path $PSScriptRoot 'modinfo.json'), $iconPath, $depsPath)

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path $filesToInclude -DestinationPath $zipPath

Write-Host "Packaged $zipPath"
Write-Host "Done."
