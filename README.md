# Cosmetic Attachment Preview

A PAYDAY 2 SuperBLT mod that keeps previewed weapon attachments on your weapon's model without equipping them. Your equipped attachments and their stats remain unchanged.

## Requirements

- PAYDAY 2
- [SuperBLT](https://superblt.znix.xyz/)

## Installation

1. Install SuperBLT.
2. Copy the `CosmeticAttachmentPreview` folder into your PAYDAY 2 `mods` folder. The folder should contain `mod.txt` directly inside it.
3. Start the game.

## Usage

In the weapon modification menu, select **Preview weapon with mod** to keep an attachment's model. Select **Preview weapon without mod** to show the default attachment or no attachment for that slot, even if an attachment is equipped.

Use **Clear preview** to remove all saved cosmetic previews for that weapon and return to its equipped appearance. Previews are saved automatically and persist between sessions.

Previews are saved by weapon type, so weapons sharing the same factory ID share their cosmetic choices. Some gameplay-affecting attachment types, such as ammunition, underbarrel weapons and bipods, are excluded. Magazines are supported as cosmetic previews.

## Save file

The mod stores its settings in `mods/saves/cosmetic_attachment_preview.json`. Removing the mod or clearing previews does not unequip any attachments.
