Quick scripts

- `scripts/test.ps1` — build/package and install a test zip into your local Mods folder (does not bump version).
- `scripts/release.ps1` — create a release zip. By default this bumps `modinfo.json`; pass `-NoVersionBump` to skip bumping.

Examples:

```powershell
# quick test
.\scripts\test.ps1 -GamePath 'C:\Users\jesse\AppData\Roaming\Vintagestory'

# release (bump version)
.\scripts\release.ps1 -Part patch

# release without bump
.\scripts\release.ps1 -NoVersionBump -GamePath 'C:\Users\jesse\AppData\Roaming\Vintagestory'
```
