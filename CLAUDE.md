# CLAUDE.md — Instructions for Claude Code

## About this project

ASSET ZERO is a vertical-scrolling roguelite shoot 'em up made in **Godot 4 with GDScript**. The full design is in `DESIGN.md` and the build plan is in `ROADMAP.md`. Read both before starting any task.

## About the developer

- Solo developer, beginner programmer. Knows HTML/CSS, some JavaScript, some terminal and Git. Strong art and design background (Adobe, painting).
- Windows PC with PowerShell, VS Code, Godot 4, Claude Code. Project folder: `C:\Projects\asset-zero`.
- Explain things briefly and plainly. Before using a new Godot concept (signals, Resources, autoloads, pooling), explain it in 1–2 plain sentences.
- Any terminal commands you give must be PowerShell and start with `cd C:\Projects\asset-zero`.

## How to work

1. **Work one milestone at a time.** The developer will usually hand over a whole milestone from `ROADMAP.md` (e.g. "Do Milestone A"). Build its steps in order. Don't start the next milestone or add features that aren't in the roadmap.
2. **Small, testable steps inside the milestone.** After each step, stop and give:
   - a short list of files created/changed
   - **how to check it worked**: which scene to run, which keys to press, what should happen
   - anything the developer must do by hand in the Godot editor
   Wait for the developer to confirm the check passed before moving to the next step.
3. **Git: branch and pull request, never push to main.** Start each milestone on a new branch from the current `main` (e.g. `milestone-a`). Commit after each confirmed step with a clear message. At the end of the milestone, push the branch and open a pull request. Only merge when the developer says "merge".
4. **Ask before** adding plugins/addons, changing the project structure, changing the design, or deleting files.
5. If a request conflicts with `DESIGN.md`, point it out and ask which is right. If a decision changes, update `DESIGN.md` and add a line to the decisions log in `ROADMAP.md`.
6. Tick a step's box in `ROADMAP.md` only after the developer confirms its check passed.
7. When the developer reports a bug, ask for the exact error text from Godot's Output/Debugger panel if it wasn't given.

## Code rules

- Godot 4 (check `project.godot` for the exact version), GDScript only, no C#.
- Use **static typing** (`var speed: float = 300.0`, `func take_damage(amount: int) -> void:`).
- Use `snake_case` for files, functions and variables, `PascalCase` for class names and node names.
- Keep scripts small and focused. One script per scene where possible.
- Put tunable numbers in `@export` variables or Resource files, not hardcoded in logic.
- Weapon systems, refits, weapon modules, enemies, waves, levels and airframe shapes are **custom Resources** (`class_name WeaponData extends Resource`, etc.) stored as `.tres` files under `data/`.
- Use **signals** to talk upward (child → parent / to the game), direct calls downward.
- Global state lives in autoloads only: `GameState` (run data: salvage, armor, installed refits, assimilated module, overclock meter, threat level), `Events` (global signal bus), `SaveManager` (meta progression and settings), `AudioManager`.
- **Pool** player rounds, missiles, enemy rounds and pickups. Never `queue_free()` / `instantiate()` per projectile.
- Every object's visuals go in a child node named `Visual` so placeholder art can be swapped later without touching logic.
- Placeholder art is drawn in code or with Polygon2D/Line2D. Do not add image files unless asked.
- Use collision layers consistently (see below). Don't make everything collide with everything.
- Comment the *why*, not the *what*. Short comments only.
- All player-facing text goes through Godot's translation system (`tr()` with keys in a CSV), so the game can be translated later. Keep text short and plain.

## Web export constraints (important)

- Renderer must stay **Compatibility**.
- Web export is **single-threaded**: don't use `Thread` or features that need threads.
- Audio can't play until the player clicks. The title screen handles this.
- Keep performance in mind: ~400 projectiles max, avoid heavy shaders, avoid per-frame allocations.

## Folder layout

```
res://
  autoload/        game_state.gd, events.gd, save_manager.gd, audio_manager.gd
  scenes/
    main/          main.tscn (scene switching)
    player/        player.tscn, player.gd, combat_morph.gd, overclock.gd, graze_area
    weapons/       rounds, beam, missile scenes and scripts
    enemies/       one folder per enemy + boss
    pickups/       salvage, repair, weapon_module
    levels/        level.tscn, wave_director.gd, background
    ui/            hud, menus, field_refit, armory, briefing
    fx/            explosions, particles, screen_shake, morph (shared shape-tween system)
  data/
    weapons/  refits/  modules/  enemies/  waves/  levels/  shapes/
  resources/       custom Resource class scripts (weapon_data.gd, etc.)
  audio/           sfx/, music/
  tests/           test scenes for trying single objects
```

## Collision layers

| Layer | Name |
|---|---|
| 1 | player |
| 2 | player_bullets |
| 3 | enemies_air |
| 4 | enemies_ground |
| 5 | enemy_bullets |
| 6 | pickups |

## Core systems to keep consistent

- **Morph system** (`scenes/fx/morph`): one shared system that tweens polygon point lists. Used by Combat Morph, refit morphs, weight class changes and Assimilate. Don't write a second one.
- **Combat Morph**: every weapon and module needs both a Gunship and a Lance behavior (DESIGN.md §5.6, §5.8).
- **Graze**: done with an Area2D on the player that watches the enemy_bullets layer; each round may count only once.

## Editing Godot files

- Prefer writing `.gd` scripts. Keep `.tscn` scenes simple. When you edit a `.tscn` file by text, keep it valid and tell the developer to reopen the scene in Godot to check it.
- If something is easier to set up by clicking in the Godot editor (e.g. Input Map, export presets), give short step-by-step instructions instead of editing the file by text.

## Theme words (use these in code, UI and file names)

Military hardware style, like a mech game's loadout screen. XF-0 (the player's aircraft), Armor (health), Plating (regenerating shield), Salvage (in-run currency), Combat Data (meta currency), Refits (upgrades), Hardpoints (Nose, Wing Pylons, Engine, Hull, Salvage Mount), Weight class (Light/Medium/Heavy/Assault), Field Refit (the pick-1-of-3 screen), Armory (the shop), R&D (meta unlocks), Combat Morph (switching between **Gunship form** and **Lance form**), Graze / near miss, Overclock (meter + white-hot burst), Meltdown pulse, Assimilate (absorbing an enemy weapon), Weapon module, Elite (yellow-outlined enemy), HSD Threat Level (LOW/ELEVATED/HIGH/SEVERE). Weapons use designations like "M20 Autocannon" (see DESIGN.md §6). Don't use old names like biomass, mutation, reform, scrap currency, Foundry or Integrity. Precision mode is now Lance form.

## Don't

- Don't use names, terms, art, sounds or level layouts from existing games, films or franchises (see DESIGN.md §15).
- Don't add features from the "Later" list in DESIGN.md.
- Don't rewrite working systems unless asked.
