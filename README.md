# Vintage Story Dining Hall Mod

## Overview
This mod adds a new room type, the Dining Hall, to Vintage Story. Players who eat food while inside a dining hall receive a temporary stats boost. The effect's duration and intensity scale based on the number of players present and the fanciness of the room's furnishings.

## Features
- **Dining Hall Room Type:** Detects when a player is inside a dining hall.
- **Stats Boost on Eating:** Grants a temporary stats boost when eating in a dining hall.
- **Dynamic Effect Duration:** Each additional player present increases the boost duration by 1 hour.
- **Furnishing-Based Intensity:** Fancy furnishings (e.g., items with gold engraving) increase the intensity of the boost.
- **Configurable Effects:** Easily adjust which stats are boosted and how furnishings affect intensity.

## TODO

## Building and testing locally

These instructions assume you're on Windows (PowerShell) and want to quickly build a DLL you can drop into Vintage Story's `Mods` folder for testing.

1. Build with MSBuild / Visual Studio

	- Open the project in Visual Studio (create a new Class Library project and add the `src` files), or use the provided `DiningHallMod.csproj` with `msbuild` or `dotnet build`.

2. Quick build with `dotnet` (may require .NET SDK installed):

```powershell
dotnet build .\DiningHallMod.csproj -c Release
```

3. After building, copy the produced DLL to your Vintage Story `Mods` folder. Example paths you might copy to (adjust for your installation):

```powershell

---

*Created: September 17, 2025*
```

4. Start Vintage Story. The client will log a notification when the mod loads. Stand near a table in your world to see debug messages in chat showing the computed room value.

Notes and assumptions:
- This repository contains a minimal single `.cs` source file. You may need to adjust target framework/assembly name for your local Vintage Story version. Vintage Story traditionally uses .NET Framework (e.g., net472); ensure the project targets the framework compatible with your game.
- The mod currently uses a simple box-scan heuristic. For more accurate room detection, integrate with Vintage Story's room/structure APIs.

## Included project file

`DiningHallMod.csproj` is included to make it easier to build. It targets `net472` by default; change target framework if needed.

## Minimal testing plan
- Singleplayer: place a table inside a small enclosed room and stand inside; check chat for "[DiningHall DEBUG] Room value: X".
- Multiplayer: connect multiple players to the same enclosed room and verify calculations (future: buff duration scaling by player count).

## Packaging for distribution

Distribution format (convention): `MODNAME_SEMVER.zip` containing:
- `*.dll` (the compiled mod assembly)
- `*.pdb` (optional debug symbols)
- `modinfo.json` (required)
- `modicon.png` (recommended)
- `MODNAME.deps.json` (listing runtime dependencies and engine version)

Use the provided `package.ps1` script to build and package the mod. Example:

```powershell
.\package.ps1
```

This will build the project (STUBS by default), generate a placeholder `modicon.png` if missing, create `MODNAME.deps.json`, and write `dist\MODNAME_VERSION.zip`.

If you want to build against the real game DLLs during packaging, pass the `-GamePath` parameter:

```powershell
.\package.ps1 -GamePath 'C:\Path\To\VintageStory'
```

