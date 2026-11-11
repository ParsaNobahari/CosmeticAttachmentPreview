# Agent context

## Purpose

Cosmetic Attachment Preview is a PAYDAY 2 SuperBLT mod. It keeps previewed weapon attachment models visible in-game and across sessions without equipping those attachments. Preserve the equipped blueprint for weapon stats and gameplay. Changes should remain focused on cosmetic previews unless the user requests otherwise.

## Files and behavior

- `mod.txt` registers the SuperBLT hooks.
- `mod.lua` owns persistence, migration, part filtering, and cosmetic blueprint application.
- `blackmarketgui.lua` saves changes made with the preview controls and clears saved previews when the player clears the weapon preview.
- `blackmarketmanager.lua` injects saved cosmetics into the game's cached preview blueprint. Its table-and-version cache avoids repeatedly overwriting fresh vanilla preview actions.
- `weaponfactorymanager.lua` assembles cosmetic parts while returning the original equipped blueprint to the weapon and assembly callback.
- `README.md` contains player-facing installation and usage instructions.

Saved data lives in `mods/saves/cosmetic_attachment_preview.json` using SuperBLT's `SavePath`, not inside the mod folder. The format is `saved[factory_id][part_type] = part_id`; `false` means use the factory default part for that type, or remove the type if there is no default. The old numeric-slot format is migrated when part data is available. Configurations are shared by weapons with the same factory ID.

Previewing without a mod saves the default/none marker, including when the attachment is equipped. Clearing the weapon preview removes that weapon's saved cosmetic overrides. Magazines are allowed; explicitly filtered types include ammo, underbarrels, bipods, and charms. Keep the existing filtering unless a change has been investigated and requested.

## Important constraints

- Do not mutate the equipped blueprint or shared factory default blueprint when applying cosmetics. Weapon stats should use the equipped blueprint, not the cosmetic one.
- The preview blueprint is a cached table used by the vanilla UI; changes to injection timing can cause the displayed preview and assembled model to disagree.
- PAYDAY 2 part dependencies, forbidden parts, and spawned part units can affect behavior beyond blueprint stats. Do not assume a model swap is safe for every attachment without investigating and testing it.
- Respect existing save data and compatibility with SuperBLT's Lua and JSON APIs. In particular, preserve `false` markers when loading and saving.
- Do not commit generated saves, logs, or game files.

## Validation

There is no automated test suite checked into this repository. Check Lua syntax and `mod.txt` JSON after edits, and use an offline stub harness if available. Offline tests cannot establish actual in-game behavior. When possible, test previewing a replacement attachment, removing an equipped gadget, reverting an equipped grip to default, previewing a magazine, clearing previews, entering a heist, and restarting the game. Verify that equipped attachments and stats remain unchanged. Report what was and was not tested.
