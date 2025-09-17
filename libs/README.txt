Place Vintage Story API DLLs here to compile the mod locally.

Which files to copy:
- From your Vintage Story installation folder, copy the game's API assemblies (for example, `VintagestoryAPI.dll`, any other API DLLs you use).

Example (PowerShell):

$gameDir = "C:\Program Files\Vintagestory"  # adjust to your install
New-Item -ItemType Directory -Force -Path .\libs
Copy-Item "$gameDir\VintagestoryAPI.dll" .\libs

Then run:

dotnet build .\DiningHallMod.csproj -c Release

If you don't place API DLLs here, the build will fail with missing Vintage Story namespaces (this is expected).