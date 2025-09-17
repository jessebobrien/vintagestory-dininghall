# Vintage Story Dining Hall Mod — Local Build Only

This repo contains a small Vintage Story mod that detects a Dining Hall room and displays a debug value when a player enters it. To keep things simple we now focus on local builds only (no CI workflows).

Quick local build and package (Windows, PowerShell)

1) Build the mod (Release):

```powershell
dotnet build .\DiningHallMod.csproj -c Release
```

2) Install for testing (copy to your Mods folder):

```powershell
$mods = Join-Path $env:APPDATA 'VintagestoryData\Mods\DiningHall'
New-Item -ItemType Directory -Force -Path $mods | Out-Null
Copy-Item -Path .\bin\Release\net472\DiningHallMod.dll -Destination $mods -Force
Copy-Item -Path .\modinfo.json -Destination $mods -Force
```

3) Optional: use the helper scripts added in `scripts/`:

- `scripts\make-test-zip-and-install.ps1` — builds, packages, and copies the produced zip to your local Mods folder for quick testing.
- `scripts\bump-version-and-release.ps1` — bump semver in `modinfo.json` (patch/minor/major), build and produce a release zip in `dist/`.

Examples:

```powershell
.\scripts\make-test-zip-and-install.ps1
.\scripts\bump-version-and-release.ps1 -Part patch
```

Notes
- The project targets `net472` by default. Vintage Story uses .NET Framework — if your environment differs, update the target framework in `DiningHallMod.csproj`.
- STUBS builds and the `STUBS` symbol exist for CI-friendly builds; since we're not using CI, you can build against your local game DLLs by copying them into `./libs` or passing `-GamePath` to `package.ps1`.

Minimal test
- Start the game after installing the DLL and stand near a table in an enclosed room. Look for chat messages with `[DiningHall DEBUG] Room value: X`.

If you want me to remove other helper scripts and keep only these two, I already removed older helpers; let me know if you want any additional cleanup.

