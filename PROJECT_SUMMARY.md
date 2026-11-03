# PROJECT SUMMARY — ASSET ZERO (indie game, solo dev)

> Paste or attach this in a new chat for context. Full details live in the project files: `DESIGN.md`, `ROADMAP.md`, `CLAUDE.md`, `.github/copilot-instructions.md`.

## About me
- Solo developer and beginner programmer: I know HTML/CSS, some terminal and Git, and have a strong art and design background (Adobe, painting).
- Tools: Windows with PowerShell, VS Code, Godot 4, Claude Code (Claude Max plan). Project folder: `C:\Projects\asset-zero`.
- I want to keep costs low and use AI tools for most of the coding.
- This is a fun side project. The goal is a free itch.io web demo first, then possibly a Steam release.

## The game
ASSET ZERO is a modern take on *Raptor: Call of the Shadows* (1994): a vertical-scrolling roguelite shoot 'em up where you earn money, upgrade your ship between levels and fight bosses.

## Story and setting
- Megacorporations are strip-mining planets.
- Halcyon Extraction Group (HEG) built the **XF-0**, an experimental strike jet made of programmable liquid metal. It went rogue, and the corporations call it "the asset."
- It now flies mercenary contracts against HEG and its private army, Halcyon Security Division (HSD).
- Tone: gritty military sci-fi with an "edgy Captain Planet" streak.
- Sector 1 is Verdance, a strip-mined jungle planet.

## Look and naming style
- The ship looks like military hardware, not organic. Naming is MechWarrior-style but for planes: real-military designations like M20 Autocannon, HEL-1 Beam Laser and Mk1 Seeker.
- The liquid metal shows only in moments: the ship flowing between shapes, salvage melting in, splashing when hit.
- Placeholder art is simple vector shapes drawn in Godot: gunmetal and cyan for the player; orange, grey and hazard yellow for the enemy.
- The interface looks like a military cockpit display.
- **Art reference: Raptor: Call of the Shadows (2015 Edition).** Grounded top-down military terrain with a muted earthy palette (oxblood earth, teal water, concrete grey), fine grain, top-left lighting, drop shadows under aircraft, big clustered fireballs, scorched craters, minimal HUD and a terminal-style shop. Adapted to Verdance as jungle over rust-red mining pits. We keep our own pink enemy bullets and gunmetal/cyan jet. Details in DESIGN.md §11.
- **Final art pipeline: Blender (free) driven by Claude Code** through Blender Lab's official MCP connection: 3D models rendered top-down into shaded sprites. Art steps ART-1 to ART-5 run alongside the milestones; ART-1 (pipeline test with the RD-2 drone and the XF-0 morph) comes right after Milestone A. Effects stay code-made.
- **Effects reference: Mech Havoc.** Glowing muzzle-flash cones, thin pale tracers, thick cyan lasers with a white core and bloom, red glowing enemy streaks, coral warning circles before area attacks, and explosions that go flash → sparks → debris with dark smoke trails → lingering scorch marks.

## Core hook (4 unique mechanics)
1. **Combat Morph:** hold a button to flow from the wide Gunship form into the narrow Lance form (55% speed, 140% damage, all weapons focus forward). Release to flow back.
2. **Assimilate:** elite enemies (yellow outline) drop their weapon as a module. Fly into it to absorb it onto a fifth hardpoint, the Salvage Mount, until the level ends. Four modules: Spread Cannon, Flak Burst, Drill Lance, Drone Bay.
3. **Overclock:** salvage pickups, near misses with bullets and elite kills fill a meter. Triggering it melts nearby bullets into salvage, then gives 5 seconds of 1.5× damage and a heat aura that destroys bullets.
4. **Threat Level:** tied to weight class. The bigger your ship gets, the harder HSD fights back (more enemies and elites, more salvage).

## Systems
- **Hardpoints:** Nose, Wing Pylons, Engine, Hull, Salvage Mount.
- **Weight classes:** Light, Medium, Heavy, Assault, based on how many refits are installed.
- **Upgrades ("Refits"):** each system has 3 levels, with a Variant A/B choice at level 3. The five systems are:
  - Autocannon
  - Beam Laser
  - Seeker Missiles
  - Propulsion
  - Armor
- **Between levels:** a free Field Refit (pick 1 of 3 on a loadout schematic), then the Armory shop.
- **Currencies:** Salvage is spent during a run. Combat Data is kept between runs and spent in R&D to unlock new parts.
- **Health:** Armor is health, Plating is a regenerating shield.

## Demo scope
- 1 sector, 3 levels plus the boss HEG-X9 "MAWLER" Mining Crawler (3 phases).
- Six enemy types: RD-2 Recon Drone, ID-4 Interceptor Drone, AA Emplacement, Mining Platform, Armored Transport, HG-7 Gunship.
- Keyboard and mouse controls. Web build on itch.io. A run lasts about 10–15 minutes.

## Tech
- Godot 4 (latest stable), GDScript with static typing
- Compatibility renderer, single-threaded web export
- 540×960 portrait screen
- Data-driven Godot Resources (.tres) and object pooling
- One shared morph system that blends polygon shapes
- All on-screen text goes through Godot's translation system so it can be translated later

## Name and market decisions
- I chose "ASSET ZERO" because plain English works better for Steam's international audience. Steam's biggest markets are the US, China, Russia, Germany and the UK.
- It still needs a Steam name search and a USPTO trademark check before buying a Steam page.
- Plan: translate the store page into Simplified Chinese first.
- On the "Later" list, not in the demo: contract board, ramming build, laser-designated strikes, heat system, gamepad, more sectors.

## Project files (in the project folder)
- `DESIGN.md`: full game design, the source of truth
- `ROADMAP.md`: Steps 0–20, each with a "Done when" check
  - Milestone A: Steps 0–5 (setup → Combat Morph)
  - Milestone B: Steps 6–9 (enemies, waves, HUD, Overclock)
  - Milestone C: Steps 10–15 (weapons, Assimilate, refits, Armory, weight classes, Threat)
  - Milestone D: Steps 16–17 (boss, full run)
  - Milestone E: Steps 18–20 (polish, balance, itch.io release)
- `CLAUDE.md`: rules for Claude Code (milestone at a time, checked steps, branch + PR, explain simply, folder layout, collision layers, game terms)
- `.github/copilot-instructions.md`: copy of the same rules, kept as project notes (Copilot no longer used)

## Workflow
Each milestone goes to Claude Code (VS Code terminal in `C:\Projects\asset-zero`, run `claude`) with this prompt:

> Read CLAUDE.md, DESIGN.md and ROADMAP.md. Do Milestone A on a new branch. Build one step at a time, tell me how to check each one worked, and wait for my OK before the next step. Open a pull request when the milestone is done.

Each milestone gets its own branch and pull request; I merge only when I say "merge". Then `/clear` and start the next milestone.

## Current status
Milestone A (Steps 0–5: setup, flying, Autocannon, terrain and first enemy, damage and death, Combat Morph) is done and merged. Next: ART-1 (Blender pipeline test), then Milestone B.

## Preference
When referring back to earlier instructions or steps, paste them in full rather than saying "from earlier."
