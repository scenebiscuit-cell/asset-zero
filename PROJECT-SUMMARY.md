# ASSET ZERO — Project Summary (for sharing with Claude)

## Who I am / how I work
- Solo developer, beginner programmer (know HTML/CSS, some terminal and Git; strong art/design background in Adobe and painting).
- Building in **Godot 4 (GDScript)**, using VS Code with **Claude Code** and **GitHub Copilot**. Keeping costs low.
- My project folder has 4 files the AI tools work from: `DESIGN.md` (game design, source of truth), `ROADMAP.md` (21 build steps, Step 0–20), `CLAUDE.md` and `.github/copilot-instructions.md` (coding rules). I build one roadmap step at a time.

## The game
**ASSET ZERO** is a vertical-scrolling roguelite shoot 'em up inspired by *Raptor: Call of the Shadows* (1994): shoot air and ground targets, earn currency, upgrade between levels, beat a boss.

**Story:** Megacorporations strip-mine planets. Halcyon Extraction Group built **XF-0**, an experimental strike craft made of programmable liquid metal. It went rogue and now flies mercenary contracts against Halcyon. Corporate radio calls it "the asset" / "Asset Zero." Tone: gritty military sci-fi, "edgy Captain Planet."

**Look:** always reads as hard-edged military hardware (modern stealth fighters/gunships); the liquid metal shows only when it changes shape. Placeholder art = simple vector shapes drawn in Godot. Cockpit-style military UI (monospace, green/amber).

## Core hook (4 mechanics)
1. **Combat Morph:** hold a button to flow from wide **Gunship form** into narrow **Lance form** (55% speed, 140% damage, all weapons converge forward). Release to flow back.
2. **Assimilate:** elite enemies (yellow outline) drop their weapon as a module; fly into it to absorb it onto a **Salvage Mount** hardpoint until the level ends. 4 modules: Spread Cannon, Flak Burst, Drill Lance, Drone Bay.
3. **Overclock:** meter fills from salvage pickups, near misses (grazing bullets) and elite kills. Trigger it to melt nearby enemy bullets into salvage, then 5 s of 1.5× damage with a bullet-destroying heat aura.
4. **Threat Level:** the corp escalates as you grow (LOW → SEVERE): more enemies and elites, more salvage.

## Loadout / progression (MechWarrior-style)
- **Hardpoints:** Nose (primary), Wing Pylons (missiles), Engine, Hull, Salvage Mount.
- **Weight class** grows with refits: Light → Medium → Heavy → Assault (more armor, a bit slower; hitbox stays small).
- Weapon lines with military designations, 3 levels each, level 3 picks Variant A or B:
  - Autocannon: M20 → M20D Twin → M40 Flak Battery / RG-9 Railgun
  - Beam Laser: HEL-1 → HEL-2 → HEL-3T Thermal Lance / HEL-3S Split Array
  - Seeker Missiles: Mk1 → Mk2 Pod → Mk3 Cluster / GBU Bunker Buster
  - Propulsion: Afterburner → Swept-Wing → Razor Wing / Vector Dash
  - Armor: Ablative → Composite → Reactive Armor / Nanite Repair
- Between levels: **Field Refit** (free pick 1 of 3, on a loadout schematic) then **Armory** shop.
- Currency: **Salvage** (per run), **Combat Data** (kept forever, spent in **R&D** unlocks).

## Demo scope (first release)
- 1 sector (jungle planet Verdance), 3 levels (~2–3 min each) + boss **HEG-X9 "MAWLER" Mining Crawler** (3 phases).
- 6 enemy types (Recon Drone, Interceptor Drone, AA Emplacement, Mining Platform, Armored Transport, HG-7 Gunship).
- Runs of 10–15 minutes. Keyboard + mouse. **Web browser demo on itch.io** first.

## Technical rules
- Godot 4 Compatibility renderer, 540×960 portrait, single-threaded web export.
- Static typing, data-driven Resources (`.tres`) for weapons, refits, modules, enemies, waves, shapes.
- Object pooling for bullets/pickups; one shared morph (polygon-tween) system for all shape changes.
- All player text through Godot's translation system (future localization).

## Business / audience notes
- Biggest Steam markets: US, China, Russia, Germany, UK. English and Simplified Chinese are the top Steam languages.
- Plan: translate the Steam store page into Simplified Chinese first (Chinese title idea: 零号资产).
- To do before a Steam page: Steam name search + USPTO trademark search for "Asset Zero."
- Stay original: no names/terms from Raptor, BattleTech/MechWarrior, or Terminator.

## Parked for later
Contract board (mission choice), ramming build, laser-designated strikes, heat system, more sectors, gamepad/Steam Deck, Steam release.

## Current status
Planning done; about to start ROADMAP Step 0 (project setup + test web export).
