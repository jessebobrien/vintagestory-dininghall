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

3) Optional: create a packaged zip using the helper script (generates `dist\DiningHall_<version>.zip`):

```powershell
.\package.ps1
# or: .\package.ps1 -GamePath 'C:\Path\To\VintageStory'
```

Notes
- The project targets `net472` by default. Vintage Story uses .NET Framework — if your environment differs, update the target framework in `DiningHallMod.csproj`.
- STUBS builds and the `STUBS` symbol exist for CI-friendly builds; since we're not using CI, you can build against your local game DLLs by copying them into `./libs` or passing `-GamePath` to `package.ps1`.

Minimal test
- Start the game after installing the DLL and stand near a table in an enclosed room. Look for chat messages with `[DiningHall DEBUG] Room value: X`.

If you want me to remove all CI workflow files from the repo and push that change, I will do that next (I can also leave the files but disabled). If you'd rather keep them but disabled, tell me and I'll only update the README.

