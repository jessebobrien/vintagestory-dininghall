
# Testing guide — DiningHall mod

This document explains how to build and test the mod locally using the two helper scripts in `scripts/`. It also lists the variables the scripts accept and step-by-step checks for singleplayer and multiplayer.

Important variables
- `GamePath` (optional): path to your Vintage Story game installation. Some scripts accept a `-GamePath` parameter if you want packaging to reference the real game DLLs. Example: `C:\Games\VintageStory` or the Steam install path.
- `MODS_PATH` (derived): the user's Mods folder where the zip will be copied for testing. By default the helpers copy to `%APPDATA%\VintagestoryData\Mods\DiningHall`.

Prerequisites
- Windows + PowerShell (instructions/tested on PowerShell v5.1). 
- .NET SDK (required for `dotnet build` targeting `net472`).
- A local Vintage Story install for runtime testing (only required for running the game; not required to compile with STUBS).

Scripts you will use
- `scripts\make-test-zip-and-install.ps1`
	- Builds Release, packages the mod, and copies the produced zip into your local Mods folder for testing.
	- Usage (default):

```powershell
.\scripts\test.ps1
```

	- If you want packaging to use your install's API DLLs, pass `-GamePath`:

```powershell
.\scripts\make-test-zip-and-install.ps1 -GamePath 'C:\Path\To\VintageStory'
```

- `scripts\bump-version-and-release.ps1`
	- Bumps `modinfo.json` semver (supports `patch`, `minor`, `major`), builds and packages a release zip into `dist/`.
	- Usage (patch bump):

```powershell
.\scripts\bump-version-and-release.ps1 -Part patch
```

Quick singleplayer test (fast)
1. From repo root run:

```powershell
.\scripts\make-test-zip-and-install.ps1
```

2. Start Vintage Story.
3. Create a small enclosed room (walls + floor + ceiling) and put a table block inside.
4. Stand inside the room near the table. Expected behaviour:
	 - Chat displays a debug message when you enter the room: `[DiningHall DEBUG] Room value: X`.
	 - The computed room value should be > 0 for rooms with a table; decorative/gold blocks increase the value.

Manual build & install (alternative)
1. Build the DLL manually:

```powershell
dotnet build .\DiningHallMod.csproj -c Release
```

2. Copy the built DLL to your Mods folder (example):

```powershell
$mods = Join-Path $env:APPDATA 'VintagestoryData\Mods\DiningHall'
New-Item -ItemType Directory -Force -Path $mods | Out-Null
Copy-Item -Path .\bin\Release\net472\DiningHallMod.dll -Destination $mods -Force
Copy-Item -Path .\modinfo.json -Destination $mods -Force
```

Multiplayer test (server + clients)
1. Ensure the server has the mod installed in its `Mods` folder (server-side DLL). If the server runs on a different machine, copy the DLL there.
2. Each client should also have the mod installed in their `Mods` folder (if required by your game server setup).
3. Start the server and have multiple players join the same enclosed room with a table.
4. Expected behaviour:
	 - Each client sees the `[DiningHall DEBUG] Room value: X` message when entering the room.
	 - Later, when buffs are implemented, verify that duration/intensity scales with player count and furnishing value.

Edge cases and checks
- Table placed in an open area: confirm whether room detection triggers (prototype uses a simple box-scan heuristic; false positives are possible).
- Large rooms: verify performance and that values scale reasonably (no extreme values from many scanned blocks).
- No-table rooms: ensure zero or low values and no buff application.

Packaging & release
 - Use `scripts\release.ps1 -Part <patch|minor|major>` to bump the version and produce a release zip in `dist/`.
- The script updates `modinfo.json`, builds, and runs packaging. It will print the created zip path when finished.

Troubleshooting
- If the helper scripts can't find the zip, ensure `dist/` exists and the project built successfully.
- If you need to explicitly point at your Vintage Story installation, pass `-GamePath 'C:\Path\To\VintageStory'` to the scripts.
- If the game doesn't load the mod, check `modinfo.json` name/version and verify the DLL is in the correct Mods subfolder.

Cleanup
- To remove test zips and generated modicon or deps files, delete the `dist/` folder and `modicon.png` in the repo root (these are ignored by `.gitignore`).

Notes
- CI was intentionally removed to keep the workflow local-only. The `STUBS` conditional compilation is still available in code if you later want CI builds that do not require the game DLLs.

If you want, I can add a single one-page `scripts/README.md` with these quick commands — say the word and I'll add it.
