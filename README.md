# Eyeless Tempering Made Easy

A tiny Pillars of Eternity 1 data patch for The White March Part II finale.

It makes the tempered Abydon dialogue option much easier to access by changing the Abydon finale
conversation requirement from:

`n_abydon_arguments_won == 3`

to:

`n_abydon_arguments_won == 0`

This follows the approach discussed in the Obsidian forum thread:
https://forums.obsidian.net/topic/90887-quick-tutorial-how-to-change-the-wm2-ending/

## Installation

Close the game, then run `install.bat`. If the installer cannot find the game automatically, paste
the Pillars of Eternity install location when prompted.

Quotes are optional in the prompt; paths with spaces and parentheses work, for example:

`C:\Program Files (x86)\Steam\steamapps\common\Pillars of Eternity`

## Uninstall

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

The installer restores the one-time backup:

`px2_04_cv_abydon_finale.conversation.eyeless-tempering-made-easy-backup`

## Notes

- This is a data patch, not a DLL hook.
- It only edits `px2_04_cv_abydon_finale.conversation`.
- It refuses to patch if it cannot find exactly one matching tempered Abydon requirement.
- Load a save from before you tell the Eyeless whether they should reconstruct Abydon.

## License

MIT. This repository contains only original installer/docs, not Obsidian game assets.
