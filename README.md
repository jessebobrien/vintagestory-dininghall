# Dining Hall (Vintage Story mod)

Short description
This mod detects when players are inside a Dining Hall (a small, enclosed room containing a table) and computes a simple "room value" based on nearby furnishings. The current prototype shows client-side debug messages when entering or leaving a detected dining hall.

Current status
- Detection heuristic and client debug display: implemented (prototype).
- Build/packaging helpers: `scripts/test.ps1` (build/package without bump) and `scripts/release.ps1` (release packaging with optional bump).
- Server-side buff-on-eat: planned (not implemented).

Quick start (Windows, PowerShell)
1) Quick test (build, package, install to local Mods):

```powershell
.\scripts\test.ps1 -GamePath 'C:\Users\jesse\AppData\Roaming\Vintagestory'
```

This will build the mod, create `dist/DiningHall_<version>.zip`, and copy the zip directly into `%APPDATA%\VintagestoryData\Mods` for testing.

2) Release package (bump version and create release zip):

```powershell
.\scripts\release.ps1 -Part patch
```

By default `release.ps1` bumps `modinfo.json`. To package without changing `modinfo.json`, pass `-NoVersionBump`:

```powershell
.\scripts\release.ps1 -NoVersionBump -GamePath 'C:\Users\jesse\AppData\Roaming\Vintagestory'
```

Testing notes
- In game, make a small enclosed room and place a table block inside. Enter the room and look for chat messages:
	- `[DiningHall] Entered dining area — value: X`
	- `[DiningHall DEBUG] Room value: X`

Developer notes
- The project targets `net472` to match Vintage Story's runtime.
- Local builds can use the real game API DLLs by copying `VintagestoryAPI.dll` and `VintagestoryLib.dll` into `./libs` or by passing `-GamePath` to the scripts.
- `src/Stubs.cs` and conditional `STUBS` compilation exist for CI-friendly builds that don't require the real DLLs.

Planned work
- Implement server-side eating-event hook to grant temporary stat buffs when players eat inside a detected dining hall. Buff duration/intensity will scale with room value and player count.
- Add tests for the detection heuristic and value calculation.
- Improve detection accuracy and reduce false positives.

If you'd like the README to include more API details, test cases, or contribution guidelines, tell me what sections to add and I'll expand it.


