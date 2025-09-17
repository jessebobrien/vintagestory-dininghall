Testing plan for DiningHall mod

Singleplayer test
- Build the mod (see README) and copy `DiningHallMod.dll` into your Vintage Story Mods folder.
- Start Vintage Story singleplayer, create a small enclosed room (walls + floor + ceiling).
- Place a table block inside and stand in the room.
- Expect: chat message appears: `[DiningHall DEBUG] Room value: X` where X >= 10.

Multiplayer test
- Run a Vintage Story server and put the mod DLL in the server's Mods folder and in each client's Mods folder if required.
- Have two players stand in the same enclosed room near the table.
- Expect: both clients see the room value; later when buffing is implemented, duration should increase per player.

Edge cases to verify
- Table outside (open area) — currently may still return value; this is expected for the prototype.
- Many decorative blocks — room value scales with gold/engraving matches found.

Next test steps
- Add HUD overlay and only display on enter/exit to reduce spam.
- Implement actual room flooding to detect enclosed spaces and mark them as Dining Halls.
