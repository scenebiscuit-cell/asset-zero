# ASSET ZERO — Build Roadmap

Build **one milestone at a time** (A → E). Inside a milestone, Claude Code builds one small step, tells you how to check it worked, and waits for your OK before the next step.

Git: each milestone gets its own branch from `main` and ends with a pull request. Merge only when you say "merge".

How to hand a milestone to Claude Code (in VS Code, terminal at `C:\Projects\asset-zero`, run `claude`):
> "Read CLAUDE.md, DESIGN.md and ROADMAP.md. Do Milestone A on a new branch. Build one step at a time, tell me how to check each one worked, and wait for my OK before the next step. Open a pull request when the milestone is done."

---

## Milestone A — Flying, shooting and morphing feel good

- [x] **Step 0: Project setup**
  - New Godot 4 project named `asset-zero`, Compatibility renderer
  - Window/viewport 540×960, stretch `canvas_items`, aspect `keep`
  - Input map actions: `move_up/down/left/right` (WASD + arrows), `fire` (Space, J, left mouse), `morph` (Shift, K, right mouse), `overclock` (E, L, middle mouse), ~~`toggle_autofire` (F)~~ (removed 2026-11-02, see decisions log), `pause` (Esc, P)
  - Project lives in `C:\Projects\asset-zero`; folder layout from CLAUDE.md, `.gitignore` for Godot
  - Git repo with `main` as the default branch; first commit of the plan files on `main`, then branch `milestone-a` for the build
  - Optional: create the GitHub repo `asset-zero` under `scenebiscuit-cell` so pull requests work
  - Empty `Main` scene that runs
  - **Do a test web export now** (single-threaded) and open it in a browser so web problems show up early
  - **Done when:** the project runs a dark empty screen on desktop AND in the browser

- [x] **Step 1: Player ship moves**
  - XF-0 Light-class airframe in Gunship form (angular fighter silhouette, gunmetal with cyan accents) drawn with placeholder shapes (`Visual` child node)
  - Keyboard movement and mouse-follow movement, whichever was used last wins
  - Ship stays inside the screen
  - **Done when:** the ship moves smoothly with keyboard and mouse and can't leave the screen

- [x] **Step 2: M20 Autocannon + projectile pooling**
  - Hold fire to shoot a stream of tracer rounds upward (auto-fire is a power-up now, not a key: DESIGN.md §7.3)
  - Placeholder effects in the Mech Havoc style (DESIGN.md §11 Effects reference): thin pale tracers and a warm muzzle-flash cone with additive blending
  - Rounds come from a pool (reused, not created/destroyed each shot)
  - **Done when:** holding fire shoots steadily and the projectile count stays stable (check the Remote scene tree / debugger)

- [x] **Step 3: Scrolling background + first enemy**
  - Scrolling placeholder jungle background (air layer and ground layer) using the Verdance palette, grain overlay and top-left lighting from DESIGN.md §11; air units cast drop shadows
  - RD-2 Recon Drone flies down in a line, takes damage, flashes white on hit, explodes (placeholder particles)
  - Drops salvage pickups that get pulled into the player when close; salvage counter in the debug output
  - **Done when:** you can shoot drones, they explode, and you collect salvage

- [x] **Step 4: Player damage and death**
  - Armor (health), contact damage, enemy rounds, 1 s invulnerability with flashing and a splash effect, small hitbox
  - Death: airframe collapses into a liquid splash, MISSION FAILED → press a key to restart
  - **Done when:** you can die and restart cleanly with no leftover projectiles or enemies

- [x] **Step 5: Morph system + Combat Morph**
  - Shared **morph system**: tweens a Polygon2D (or set of polygons) from one point list to another. Airframe shapes stored as data (DESIGN.md §5.3 technical note)
  - Combat Morph from DESIGN.md §5.6: hold `morph` → Lance form (0.15 s morph), release → Gunship form
  - Lance form: 55% speed, 140% damage, autocannon fire converges into a tight stream
  - Distinct placeholder sound for each morph direction
  - **Done when:** tapping and holding morph feels instant, the shape flows smoothly both ways, and speed, damage and fire pattern change correctly

## Milestone B — A real level

- [x] **Step 6: Enemy set + elites**
  - ID-4 Interceptor Drone, AA Emplacement (aims at player), Mining Platform, Armored Transport, HG-7 Gunship from DESIGN.md §8
  - Elite variant for any enemy: yellow outline, 2× HP, 2× salvage (module drops come later in Step 11)
  - Enemy stats live in Resource files (`data/enemies/*.tres`)
  - Rare timed Fire Control pickup drop: auto-fire for ~10 s (DESIGN.md §7.3)
  - **Done when:** a test scene spawns each enemy, normal and elite, and each one behaves as described

- [x] **Step 7: Wave director + level flow**
  - Waves defined as Resources (enemies, formation, entry side, path)
  - Director spends a growing difficulty budget to spawn waves; has a `threat_multiplier` and `elite_chance` (fixed at Threat 1 values for now); level lasts ~2–3 minutes, then "SECTOR CLEAR"
  - Level settings (wave pool, length, budget) as Resources for levels 1–3
  - **Done when:** Level 1 plays start to finish and ends with "SECTOR CLEAR"

- [x] **Step 8: HUD + pause**
  - Cockpit-style HUD: Armor bar, Plating bar, Overclock meter (empty for now), salvage count, weight class, HSD Threat label, assimilated weapon slot, level number, auto-fire indicator
  - Pause menu (resume, quit to menu)
  - **Done when:** HUD updates correctly during play and pause works

- [x] **Step 9: Grazing + Overclock**
  - Graze detection from DESIGN.md §5.4 / §5.7: each enemy round counts once when it passes inside the graze radius without hitting; spark + tick sound
  - Overclock meter fills from salvage, near misses and elite kills
  - Overclock activation: Meltdown pulse turns nearby enemy rounds into salvage, 5 s of ×1.5 damage + heat aura that destroys rounds, salvage extends it (max 10 s), 0.5 s invulnerability at the end
  - **Done when:** you can fill the meter by grazing and collecting, trigger Overclock, and survive a dense bullet pattern with it

## Milestone C — Loadouts, refits and assimilation

- [x] **Step 10: Data-driven weapon systems + hardpoints**
  - Weapon system using Resources; Nose, Wing Pylon, Engine, Hull and Salvage Mount hardpoints
  - M20 Autocannon levels 1–2, HEL-1 Beam Laser, R1 Rocket Pod, Mk1 Seeker missiles, each with its Lance-form behavior
  - Debug keys (only in debug builds) to give yourself weapons for testing
  - **Done when:** you can switch between all of these with debug keys and each fires correctly in both forms

- [x] **Step 11: Assimilate**
  - Elites drop their weapon module (DESIGN.md §5.8): glowing hexagon that drifts for ~6 s
  - Fly into it → absorb animation → module mounts on the Salvage Mount and fires with your main weapon
  - All 4 modules (Spread Cannon, Flak Burst, Drill Lance, Drone Bay) with Gunship and Lance behaviors, as Resources (`data/modules/*.tres`)
  - Only one module at a time (new replaces old); dissolves at level end
  - **Done when:** killing each elite type drops its module, and each module works in both forms

- [x] **Step 12: Field Refit (loadout) screen**
  - After a level: pick 1 of 3 random refits on a ship schematic (both forms side by side) that highlights the hardpoint; one reroll that costs salvage (rising price)
  - Refits as Resources (`data/refits/*.tres`); handles level-ups and the level-3 Variant A/B choice
  - Nose swap rule (Autocannon line OR Beam Laser line)
  - **Done when:** finishing a level shows the offer and the chosen refit actually changes the ship

- [ ] **Step 13: Armory shop**
  - 4 items for salvage, always at least one repair, prices scale per level
  - **Done when:** you can buy, can't buy what you can't afford, and can leave

- [ ] **Step 14: All systems, weight classes + refit morph**
  - Every weapon, Propulsion and Armor level from DESIGN.md §6, including the Variant A/B choices, plus all field mods (including Heat Capacitor and Retention Matrix)
  - Each refit changes the airframe's Gunship AND Lance shapes, using the morph system from Step 5 (~0.3 s refit morph)
  - Weight classes Light → Assault (§5.2) with "CLASS UPGRADE" callout
  - **Done when:** every refit works, looks different in both forms, morphs smoothly, and weight class changes at the right refit counts

- [ ] **Step 15: Threat Level**
  - Threat = weight class (DESIGN.md §9.1); feeds the wave director's budget multiplier, elite chance and salvage bonus
  - HUD label updates; radio-chatter pop-up + alarm when Threat rises
  - **Done when:** growing to each weight class visibly increases enemy pressure, elites and salvage

## Milestone D — Complete run

- [ ] **Step 16: Boss — HEG-X9 MAWLER**
  - Three phases from DESIGN.md §8 (turrets drop Flak Burst modules), boss health bar, big death sequence
  - **Done when:** the boss can be fought and beaten with all three phases working

- [ ] **Step 17: Full run structure**
  - Title (click to start) → menu (Deploy, R&D, Settings) → mission briefing → L1 → Field Refit → Armory → L2 → … → boss → Mission Complete / Mission Failed
  - Combat Data earned (includes highest Threat reached), saved to `user://save.cfg`, R&D screen with ~6 unlocks
  - Mission briefing sometimes offers the FC-1 Fire Control Computer for Combat Data (auto-fire for that run only); Settings → Accessibility → Auto-fire (DESIGN.md §7.3)
  - **Done when:** a full run works start to finish, and unlocks persist after closing the game

## Milestone E — Polish and release

- [ ] **Step 18: Juice and sound**
  - Hit-stop, screen shake (with toggle), muzzle flashes, more particles, Overclock and Assimilate effects, clustered explosions with shockwave rings and ground scorch marks (DESIGN.md §11)
  - SFX for everything (jsfxr), level music and boss music, volume settings
  - **Done when:** the feel checklist in DESIGN.md §10 is all done

- [ ] **Step 19: Balance pass and bug fixing**
  - Play 10+ full runs, write down problems, fix the biggest ones
  - Check that Lance form, Overclock and modules all feel worth using, and that Threat 4 is hard but fair
  - **Done when:** a run takes 10–15 minutes and is beatable but not easy

- [ ] **Step 20: itch.io demo release**
  - Final web export, test in Chrome, Firefox and Edge
  - itch.io page: screenshots, GIFs (show off Combat Morph, Assimilate and Overclock), short description, controls
  - Before any Steam page: Steam name search + USPTO trademark search for "Asset Zero"; plan a Simplified Chinese store page (DESIGN.md §14b)
  - **Done when:** the demo is live on itch.io

---

## Notes / decisions log

Write down decisions here as you make them (date — decision), so the AI tools know about them.

- 2026-11-04 — Field Refit reroll: one per screen, costs 15 salvage + 10 for each reroll already bought this run. Field Repair and Armor Kit field mods added early (Step 12) as filler so there are always 3 cards; the other field mods come in Step 14. DESIGN.md §7.1.
- 2026-11-04 — Fire Control pickups are now stored (up to 2, kept between sectors) and started with a new Fire Control key (Q / I / mouse side button). Its HUD panel moved above the Overclock meter and spells out READY - PRESS Q, then counts down AUTO-FIRE. DESIGN.md §5.5, §7.3, §13.
- 2026-11-04 — Mining Platform now looks like a drill tank (treads, turret, drill as the barrel); burrowing digs into a dirt mound, and a mound churns up where it will resurface. Background bases are now barracks compounds and SAM sites; their radar domes are destructible ground targets worth 1 salvage that don't count toward waves or SECTOR CLEAR. DESIGN.md §8, §11.
- 2026-11-04 — Mining Platform now attacks: a large drill that tracks XF-0, winds up (glows red) and thrusts out, 20 Armor on touch. It burrows and resurfaces somewhere else on screen up to 3 times, then scrolls away. DESIGN.md §8 enemy table.
- 2026-11-04 — Enemies made tougher (~30% more HP): RD-2 25, ID-4 20, AA 80, HG-7 120, Transport 210, Mining Platform 290. The M20 now needs 3 rounds for an RD-2 (2 in Lance form).
- 2026-11-04 — Missile line is now 4 levels: R1 Rocket Pod (unguided) at level 1, then Mk1 Seeker, Mk2 Seeker Pod, and the Cluster Missile / Bunker Buster variants at level 4, so homing missiles take longer to get. M20D Twin Autocannon toned down (7 damage per round, 0.09 s between shots). DESIGN.md §2/§5.1/§5.6/§6.
- 2026-11-03 — Fullscreen: stretch aspect stays `keep`, so the 540×960 battlefield is centred at full screen height with dark bars at the sides, and the HUD and rails stay inside it on its edges (like Raptor). Tried first and dropped: a battlefield widened to the whole monitor (changed balance between screens) and HUD panels moved out into cockpit side panels (felt disconnected). The BREACH popup was removed (distracting); the salvage penalty and Perimeter Held bonus stay. DESIGN.md §9, §14.
- 2026-11-03 — Added a sector progress track to the HUD (right rail) and an F11 / Alt+Enter fullscreen toggle (in SaveManager until the Settings screen exists). DESIGN.md §5.5, §13.
- 2026-11-03 — Sector 1 shortened to 90 s (was 150 s) so the run gets going quickly; later sectors stay 2–3 minutes. DESIGN.md §9.
- 2026-11-03 — Breach penalty: each enemy aircraft that escapes costs 2 salvage; a sector with no escapes pays a 25-salvage Perimeter Held bonus at SECTOR CLEAR. Enemy round damage raised (RD-2 8, others 12). DESIGN.md §8, §9.
- 2026-11-03 — RD-2 Recon Drones now fire one weak, slow aimed round (about a third of them since 2026-11-03 retune, at a random moment) so Sector 1 has rounds to dodge and graze. AA Emplacements fire 2-round bursts every 1.4 s and appear more often (pairs from 45 s). DESIGN.md §8.

- 2026-11-02 — XF-0 hitbox changed from a ~6 px circle to a capsule over the body + wing roots (~24 px wide in Gunship form, ~14 px in Lance form), stored per airframe shape and morphing with it. Lance form is now also the dodge form. Same size in every weight class. DESIGN.md §5.2, §5.4, §5.6.

- 2026-11-02 — Auto-fire is no longer a standard control (F key removed). It comes from the FC-1 Fire Control Computer (one-run purchase for Combat Data at the briefing, only when offered) or a rare timed Fire Control pickup; an Accessibility setting keeps it available for players who need it. DESIGN.md §5.5, §7.3, §13.
- 2026-11-02 — Effects reference added from Mech Havoc footage (DESIGN.md §11): glowing muzzle cones, thin tracers, cyan beam lasers with bloom, red glowing enemy streaks, coral warning circles, flash → sparks → debris smoke trails → scorch. Raptor stays the world/ship reference.
- 2026-11-02 — Detailed art direction written from 2015 Edition gameplay footage (DESIGN.md §11): palette, terrain, drop shadows, grain, explosions, minimal HUD + terminal-style shop. Kept our pink enemy bullets and gunmetal/cyan player.
- 2026-11-02 — Art direction: aim for a look similar to Raptor: Call of the Shadows (2026 update) — grounded top-down military terrain, shaded metal aircraft, big explosions. Reference screenshots in gitignored `art-reference/raptor/` (study only). See DESIGN.md §11.
- 2026-10-31 — Workflow: one milestone per Claude Code session, small checked steps inside it, branch + pull request per milestone, merge only on "merge". Copilot dropped; `.github/copilot-instructions.md` kept as project notes.
- 2026-10-29 — Renamed the game to ASSET ZERO (plain English, works for international players, comes from the story). Needs a trademark check before Steam.
- 2026-10-29 — Added Combat Morph, Assimilate, Overclock and Threat Level as the game's core hook. Contract board, ramming build and laser-designated strikes parked in DESIGN.md "Later".
