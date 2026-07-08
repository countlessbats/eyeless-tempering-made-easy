# Eyeless Tempering Made Easy

A tiny Pillars of Eternity 1 data patch for The White March Part II finale.

It makes the tempered ("Moderated") Abydon ending — the player line *"Then return to Abydon with
perspective as well as memory..."* — **always available, regardless of how many Eyeless arguments
you win.**

## How it actually works (traced through the conversation flow)

- Node **145** ("Debate begins here") is the debate hub, and it links **directly** to node **250**
  — the tempering line (which leads to the tempered response, node 288).
- Node **250** is normally hidden behind `HasConversationNodeBeenPlayed(320)`: it appears only
  after node **320** fires. Node 320 is reached only by fully winning a debate topic
  (`n_abydon_argument_danger/stuck/burden == 2`) and, vanilla, all three
  (`n_abydon_arguments_won == 3`).

So the option is gated on a chain you can miss entirely. An `EqualTo` check can never mean "any
number," and even a satisfied count still requires *reaching* node 320 — which is why the old
"change `3 → 0`" edit didn't reliably work. Instead, this patch **removes node 250's own
`HasConversationNodeBeenPlayed(320)` condition**, so the tempering line is offered at the debate
hub immediately, regardless of arguments. Nothing else is changed — the debate and its counters
behave exactly as vanilla.

(Background thread, for context only — its `3 → 0` suggestion is the fragile approach this patch
replaces: https://forums.obsidian.net/topic/90887-quick-tutorial-how-to-change-the-wm2-ending/ )

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
