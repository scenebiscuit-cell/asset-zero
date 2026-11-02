# ASSET ZERO — Game Design Document

> Title: **ASSET ZERO** (chosen 2026-10-29; still needs a Steam name search and a USPTO trademark search before the Steam page is bought). Other names in this doc are placeholders and can change.
> This file is the single source of truth for what the game is. If code and this doc disagree, ask the developer which one is right.

## 1. Pitch

A vertical-scrolling roguelite shoot 'em up in the spirit of 90s PC shooters (earn cash, upgrade your jet, blow up everything below you), with a mech-game twist: **your aircraft is made of programmable liquid metal. It transforms between combat forms mid-fight, absorbs enemy weapons, and rebuilds itself into heavier airframes as the run goes on.**

Megacorporations are fighting over the resources of distant planets and stripping them bare. Halcyon Extraction Group built an experimental liquid-metal strike craft, the **XF-0**, to protect its mining operations. The prototype went rogue, and now it flies mercenary contracts for Halcyon's rivals. That's you. Every drone, gun emplacement and mining platform you destroy leaves **salvage**, and you absorb it to refit: mount bigger guns, add missile pylons, bolt on armor, and grow from a light interceptor into an assault-class gunship. Tone: gritty military sci-fi with an "edgy Captain Planet" streak: a corporate weapon turned against the corporations.

### The hook (what makes this game different)

1. **Combat Morph:** hold one button and the jet flows into a different shape with a different way of fighting (§5.6).
2. **Assimilate:** destroy an elite enemy, fly into its dropped weapon, and your metal absorbs it as a new gun (§5.8).
3. **Overclock:** fly close to danger and collect salvage to charge a white-hot burst that melts enemy fire into salvage (§5.7).
4. **Threat Level:** the stronger you get, the harder the corporation fights back, and the better the rewards (§9.1).

## 2. Pillars

1. **Feels great to shoot.** Responsive movement, heavy-hitting weapons, satisfying explosions. If it's not fun with simple shapes, it won't be fun with art.
2. **Shapeshifting is the star.** Morphing, assimilating and refitting should be the most satisfying things in the game, visually and mechanically.
3. **Loadout building.** Like customizing a mech: hardpoints, weapon systems, armor, weight class. Every refit visibly changes the airframe and how it plays.
4. **Short, replayable runs.** One run is 10–15 minutes in the demo. Randomized waves and refit offers keep runs different.
5. **Small scope, finished.** Ship the demo before adding anything.

## 3. Demo scope (target for first itch.io release)

- **1 sector** (one planet, one enemy corporation)
- **3 levels + 1 boss**, played in order as a single run
- **Combat Morph** (Gunship form ↔ Lance form)
- **Assimilate** (4 enemy weapon modules)
- **Overclock** meter
- **Threat Level** (4 tiers tied to weight class)
- **3 weapon systems** (Autocannon, Beam Laser, Seeker Missiles), each with 3 refit levels
- **2 support systems** (Propulsion, Armor)
- **4 weight classes** (Light → Medium → Heavy → Assault)
- **6 regular enemy types (any can spawn as an elite) + 1 boss**
- **Pick-1-of-3 Field Refit after each level + Armory shop**
- **Small meta progression** (persistent currency that unlocks new systems)
- **Platform:** Web browser (itch.io), Godot 4 HTML5 export
- **Controls:** Keyboard and mouse

**Out of scope for the demo** (write ideas into the "Later" list at the bottom, don't build them): more sectors, multiple starting airframes, heat management, contract board, laser-designated strikes, gamepad, touch, story cutscenes, online leaderboards, co-op, Steam features.

## 4. Setting (sector 1)

- **Planet:** Verdance, a jungle world being strip-mined.
- **Enemy corp:** Halcyon Extraction Group (HEG) and its private army, **Halcyon Security Division (HSD)**. Industrial orange/grey, hazard stripes, drones, gun emplacements, armored transports.
- **The player:** **XF-0**, an experimental strike craft built from programmable liquid metal. No visible pilot. Corporate radio chatter calls it "the asset" or "Asset Zero" (the game's title).
- **Contract framing:** Each run starts with a short mission briefing in military style:
  > CONTRACT 0471 — CLIENT: VOSS-ARMAND HOLDINGS
  > OBJECTIVE: Disrupt HEG extraction ops, Verdance Sector 1.
  > COLLATERAL: Acceptable. Expected.

## 5. Player: XF-0

### 5.1 Hardpoints

The airframe has **hardpoints**, like a mech:

| Hardpoint | Holds | Starts with |
|---|---|---|
| Nose | Primary weapon (Autocannon or Beam Laser line) | M20 Autocannon |
| Wing pylons (L+R) | Secondary weapon (Seeker Missile line) | Empty |
| Engine | Propulsion line | Stock thrusters |
| Hull | Armor line | Bare frame (no plating) |
| Salvage Mount | One assimilated enemy weapon (§5.8) | Empty |

### 5.2 Weight class

The airframe grows as you refit. **Weight class** is based on the total number of refits installed:

| Class | Refits | Size | Bonus | Penalty |
|---|---|---|---|---|
| Light (interceptor) | 0–2 | Small, sleek | — | — |
| Medium (strike fighter) | 3–5 | Bigger, more angular | +15 max Armor | −5% speed |
| Heavy (gunship) | 6–8 | Wide, armored, extra pylons visible | +30 max Armor | −10% speed |
| Assault | 9+ | Huge flying fortress | +50 max Armor | −15% speed |

The **hitbox stays the same small size** in every class (genre standard), so a bigger ship isn't unfair. Moving up a class plays a bigger morph and a "CLASS UPGRADE: MEDIUM" callout. Weight class also sets the **Threat Level** (§9.1).

### 5.3 Liquid-metal behavior (visual rules)

The ship always looks like a hard-edged military aircraft. The liquid metal shows in moments:

- **Combat Morph:** flowing transition between Gunship and Lance form (§5.6).
- **Refit morph:** every refit plays a quick ~0.3 s flowing transition from the old airframe to the new one. Weapons extrude out of the hull.
- **Assimilate:** the enemy weapon module gets swallowed into the hull and re-extrudes on the Salvage Mount.
- **Salvage absorb:** scrap pickups get pulled in and melt into the hull with a small ripple.
- **Overclock:** the hull glows white-hot and ripples.
- **Damage:** when hit, the armor splashes briefly and droplets fly off. At low Armor the outline gets unstable and drippy.
- **Death:** the airframe loses its shape, collapses into a liquid splash and falls.

**Technical note:** all of these use one shared morph system that tweens polygon points from one shape to another. Every airframe shape (each form × weight class × refit) is just a list of points, so the same system handles every transformation.

### 5.4 Stats

| Stat | Start value | Notes |
|---|---|---|
| Armor | 100 | Health. Run ends at 0. Repairable in the Armory |
| Plating | 0 | Regenerating shield, absorbs damage first, recharges after 3 s without being hit |
| Move speed | 300 px/s | Gunship form. Changed by Propulsion and weight class |
| Hitbox | small circle, ~6 px radius | Much smaller than the ship visual |
| Graze radius | ~28 px | Enemy rounds passing inside this (but not hitting) count as near misses for Overclock |
| Invulnerability after hit | 1.0 s | Ship flashes |

### 5.5 Controls

| Action | Keyboard | Mouse |
|---|---|---|
| Move | WASD / Arrow keys | Ship moves toward cursor (capped at move speed) |
| Fire | Hold Space or J | Hold left mouse button |
| Combat Morph (Lance form) | Hold Shift or K | Hold right mouse button |
| Overclock | E or L | Middle mouse button |
| Auto-fire toggle | F | Settings option |
| Pause | Esc / P | — |

Keyboard and mouse can both work in the same session. Whichever moved last takes control.

### 5.6 Combat Morph

XF-0 has two combat forms. **Hold** the Morph button for Lance form, and release to flow back to Gunship form. The morph takes **0.15 s** (fast, it must feel responsive) and can be done at any time.

| | Gunship form (default) | Lance form (hold Morph) |
|---|---|---|
| Shape | Wide, wings spread, weapons angled outward | Narrow arrowhead, wings folded back, weapons pulled to the nose |
| Speed | 100% | 55% (for precise dodging) |
| Fire pattern | Weapons use their normal spread | Every weapon **converges** forward into a tight stream |
| Damage | 100% | 140% |
| Ground targets | Normal | Normal |
| Seeker Missiles | Seek any target | Seek only targets ahead of the ship |
| Graze radius | 28 px | 36 px (easier to charge Overclock while threading bullets) |

How each weapon line converges in Lance form:

- **Autocannon lines:** all barrels fire straight ahead in one tight stream. The Flak Battery spread closes to a narrow cone. The Railgun fires faster.
- **Beam Laser lines:** the beam gets thinner and brighter. The Split Array's three beams merge into one.
- **Assimilated weapons:** each module defines its own Lance behavior (§5.8).

Every refit changes **both** shapes. The Gunship and Lance shapes for each weight class are drawn as a pair.

### 5.7 Overclock

A meter (0–100) on the HUD.

**Filling it:**
- +2 per salvage pickup
- +1 per near miss (an enemy round passes through the graze radius without hitting; each round counts only once)
- +10 for destroying an elite
- The meter does not drain while waiting

**Using it** (needs a full meter, press Overclock):
1. **Meltdown pulse:** all enemy rounds within ~160 px are instantly destroyed and turned into salvage pickups.
2. For **5 seconds**: the hull glows white-hot, damage ×1.5, and a heat aura (radius ~40 px) destroys enemy rounds that touch it.
3. Each salvage pickup during Overclock adds +0.25 s (max total 10 s), so aggressive players can chain it.
4. When it ends: 0.5 s of invulnerability so it never ends in a cheap death.

Overclock is the "panic button" and the "go aggressive" button in one. It does not damage enemies directly; it protects you and boosts your guns.

### 5.8 Assimilate

**Elites:** any regular enemy can spawn as an **elite** (chance set by Threat Level, §9.1). Elites have a yellow outline, 2× HP, drop 2× salvage, and always drop their **weapon module** if their type has one.

**Weapon modules:** a glowing hexagonal pickup that drifts slowly down the screen for ~6 s, then breaks apart. Fly into it to assimilate it. The module mounts on the **Salvage Mount** and fires automatically alongside your main weapon whenever you fire.

- Only **one** assimilated weapon at a time. Picking up a new one replaces the old one (the old one splashes away).
- Lasts until the **end of the level**, then dissolves (unless a Retention Matrix field mod says otherwise).
- Modules have no ammo limit.

| Module | Dropped by | Gunship behavior | Lance behavior |
|---|---|---|---|
| Spread Cannon | HG-7 Gunship (elite) | 5-way fan of medium rounds | 5 rounds stacked in a tight line |
| Flak Burst | AA Emplacement (elite) | Rounds explode in a small blast after a short distance | Longer range before exploding |
| Drill Lance | Mining Platform (elite) | Short-range spinning drill beam that pierces everything | Drill extends twice as far |
| Drone Bay | Armored Transport (elite) | Releases 2 small allied drones that orbit and shoot | Drones line up beside the nose and fire forward |

Recon and Interceptor drones don't carry modules. The **Retention Matrix** field mod (§6) keeps your assimilated weapon for one more level.

## 6. Weapon and support systems

All weapons fire while Fire is held. **Missiles fire automatically** on their own timer. Each system has **3 refit levels**, and at level 3 the player picks **one of two variants** (shown as "Variant A / Variant B"). Each level changes the *visual* and the *behavior*, not just the numbers. Names follow a military designation style: a model code plus a plain name. All weapons follow the Lance-form convergence rules in §5.6.

### Autocannon line (nose, starting weapon)

| Level | Designation | Behavior | Visual |
|---|---|---|---|
| 1 | M20 Autocannon | Single stream of fast tracer rounds | Single barrel under the nose |
| 2 | M20D Twin Autocannon | Twin stream | Two barrels |
| 3A | M40 Flak Battery | 3-way spread, rounds burst into fragments on hit | Triple-barrel turret |
| 3B | RG-9 Railgun | Single heavy piercing slug, slower fire, long tracer line | Long rail along the fuselage |

### Beam Laser line (nose, replaces the Autocannon line)

| Level | Designation | Behavior | Visual |
|---|---|---|---|
| 1 | HEL-1 Beam Laser | Thin continuous beam, damage per tick | Emitter lens in the nose |
| 2 | HEL-2 Focused Beam | Wider beam, longer reach | Larger lens assembly |
| 3A | HEL-3T Thermal Lance | Targets keep burning after the beam leaves | Red-hot heat sinks |
| 3B | HEL-3S Split Array | Beam splits into 3 angled beams | Triple-emitter array |

### Seeker Missile line (wing pylons, secondary)

| Level | Designation | Behavior |
|---|---|---|
| 1 | Mk1 Seeker | 2 slow homing missiles every 1.5 s |
| 2 | Mk2 Seeker Pod | 4 faster homing missiles |
| 3A | Mk3 Cluster Missile | Missiles split into small homing submunitions |
| 3B | GBU Bunker Buster | Big slow bombs, large blast radius, strong against ground targets |

> Nose rule: one primary weapon at a time (Autocannon line OR Beam Laser line). Taking a Beam Laser while holding the Autocannon offers a swap. Keeps balance simple.

### Propulsion line (engine)

| Level | Designation | Effect | Visual |
|---|---|---|---|
| 1 | Afterburner Mk1 | +15% speed | Bigger engine glow |
| 2 | Swept-Wing Refit | +30% speed, Lance form moves at 70% instead of 55% | Wings sweep back |
| 3A | Razor Wing | Reinforced blade-edged wings damage enemies you touch (you still take contact damage) | Sharp leading edges |
| 3B | Vector Dash | Double-tap a direction for a short thrust-vectored dash with brief invulnerability (the ship goes liquid for a moment) | Side thruster nozzles |

### Armor line (hull)

| Level | Designation | Effect |
|---|---|---|
| 1 | Ablative Plating | 25 Plating |
| 2 | Composite Plating | 50 Plating, faster recharge |
| 3A | Reactive Armor | Taking a hit blasts a ring of shrapnel outward |
| 3B | Nanite Repair | Slowly restores Armor (cap: 50%) |

### Field mods (filler offers)

Small simple upgrades: AP Rounds (+10% damage), Improved Feed (+10% fire rate), Armor Kit (+20 max Armor), Salvage Magnet (+15% pickup radius), Field Repair (restore 30 Armor), Heat Capacitor (Overclock lasts +1.5 s), Retention Matrix (keep your assimilated weapon one extra level). Keep the list short. **Field mods don't count toward weight class.**

## 7. Economy

- **Salvage** (in-run currency): destroyed enemies break into scrap pickups that get magnetically pulled into XF-0 when close. Ground targets, big enemies and elites drop more. Lost when the run ends. Salvage pickups also charge Overclock.
- **Combat Data** (meta currency): earned at the end of every run, win or lose (based on distance reached, boss kills and highest Threat Level reached). Kept forever, saved to disk.

### 7.1 Between levels (in order)

1. **Field Refit (free):** pick 1 of 3 random refits. Shown on a **loadout screen**: a top-down schematic of the ship (both forms side by side) with its hardpoints, where the offered refit highlights the hardpoint it goes into. Can reroll once for salvage (cost rises each reroll).
2. **Armory (shop):** a black-market arms dealer selling 4 items for salvage. Always includes at least one repair. Prices scale with level. Can leave without buying.
3. Next level.

### 7.2 Meta unlocks (demo)

Spend Combat Data in **R&D** on the main menu to unlock systems so they can appear in offers. Example: Beam Laser line (locked at start), Vector Dash, Mk3 Cluster Missile, Drone Bay module, Retention Matrix, +1 Armory slot. Keep it to ~6 unlocks for the demo.

## 8. Enemies (sector 1, Halcyon Security Division)

Air enemies fly over everything. Ground enemies scroll with the background. All weapons hit both layers in the demo unless a system says otherwise. **Any enemy can spawn as an elite** (§5.8).

| Enemy | Layer | Behavior | HP | Salvage | Elite drops |
|---|---|---|---|---|---|
| RD-2 Recon Drone | Air | Flies straight down in lines/V formations | Low | 1 | — |
| ID-4 Interceptor Drone | Air | Sine-wave path, fires a single slow round | Low | 2 | — |
| AA Emplacement | Ground | Stationary, aims and fires at the player | Medium | 3 | Flak Burst |
| Mining Platform | Ground | Tanky, no attack, big salvage reward | High | 8 | Drill Lance |
| Armored Transport | Air | Slow, crosses sideways, sometimes drops a repair pickup | High | 6 | Drone Bay |
| HG-7 Gunship | Air | Enters, hovers, fires spread patterns, leaves after ~6 s | Medium | 5 | Spread Cannon |

### Boss: HEG-X9 "MAWLER" Mining Crawler

A giant armored strip-mining machine that fills the top third of the screen.

- **Phase 1 (100–66%):** Two flank turrets fire aimed bursts. Destroy the turrets to expose the core. Each destroyed turret drops a Flak Burst module.
- **Phase 2 (66–33%):** Grinding jaws open, spray debris in a wide fan (great for grazing), launches Recon Drones.
- **Phase 3 (33–0%):** Damaged and erratic, rotating spiral bullet pattern, screen shake.
- Big explosion sequence, huge salvage drop, run victory.

## 9. Levels

- Each level is about **2–3 minutes** of vertical scrolling.
- A **wave director** spawns enemy waves from a pool, using a difficulty budget that grows over time and per level, multiplied by the Threat Level.
- Waves are defined as data (which enemies, formation, entry side, path), so new waves can be added without new code.
- Each level ends with a short "SECTOR CLEAR" moment, then the between-level screens.
- Level 1: drones and AA emplacements. Level 2: adds interceptors, mining platforms, transports. Level 3: adds gunships and denser waves. Then the boss.

### 9.1 Threat Level

Halcyon reacts to how dangerous the prototype has become. **Threat Level = weight class.**

| Threat | Weight class | HUD label | Wave budget | Elite chance | Salvage bonus |
|---|---|---|---|---|---|
| 1 | Light | HSD THREAT: LOW | ×1.0 | 5% | +0% |
| 2 | Medium | HSD THREAT: ELEVATED | ×1.15 | 10% | +10% |
| 3 | Heavy | HSD THREAT: HIGH | ×1.3 | 15% | +20% |
| 4 | Assault | HSD THREAT: SEVERE | ×1.5 | 25% | +35% |

When Threat rises, show a radio-chatter pop-up ("HSD-Control: Asset has grown. Escalate response.") and a short alarm sound. The bigger and stronger you get, the more elites (and modules) show up: power growth feeds itself, but so does danger.

## 10. Feel ("juice") checklist

- Enemy flashes white on hit
- Small hit-stop (pause of ~30–60 ms) on big kills and when the player is hit
- Screen shake on explosions (scaled by size, with a settings toggle)
- Sparks, debris, smoke trails on missiles, shell casings from the autocannon
- Muzzle flashes and tracer lines
- Combat Morph feels instant and looks fluid; distinct sound for each direction
- Near-miss sparks and a soft tick sound when grazing
- Overclock activation: white flash, shockwave ring, all nearby enemy rounds melt into salvage
- Assimilate: module gets sucked in, short hit-stop, the new weapon extrudes
- Liquid-metal moments from §5.3
- Player rounds clearly different from enemy fire (enemy rounds: bright pink/orange with a dark outline, always readable)
- Sound for every shot, hit, pickup, morph, refit and explosion

## 11. Art direction

### Placeholder phase (now)

Simple vector / geometric shapes drawn in Godot (Polygon2D, Line2D or `_draw()`), no image files needed.

- **XF-0:** hard-edged military aircraft silhouette (think modern stealth fighters and gunships), gunmetal grey with a chrome highlight and cyan accent lights. Weapons and pylons are visible shapes on the airframe. Gunship and Lance forms must read differently at a glance (wide vs. arrowhead).
- **Halcyon forces:** blocky, utilitarian industrial machines in grey/orange with hazard-yellow stripes. Elites get a yellow outline.
- **Weapon modules:** glowing hexagons in the color of the enemy that dropped them, pulsing
- **Enemy rounds:** hot pink/orange, round, with an outline, always the highest-contrast thing on screen
- **Background:** dark green-black jungle gradient with simple scrolling shapes for terrain, roads and mining structures
- **UI:** military cockpit display style: monospace font, green or amber text on dark panels, thin line borders, designation codes everywhere (like a mech game's loadout screen)

The look should say "military hardware" first. The liquid metal is the surprise in how it changes shape.

### Final art (later, decided after the game is fun)

Likely hand-painted art downscaled to sprites, possibly with a metallic sheen shader. Placeholders must be easy to swap: each object's visuals live in one child node named `Visual`, so art can be replaced without touching game logic. The morph system may need to switch to blended sprites or a shader for final art; decide later.

## 12. Audio

- SFX: generated with jsfxr (free) during development. Heavy, punchy military sounds (cannon thumps, missile whooshes, alarm beeps), plus a metallic liquid sound for morphs, refits, assimilating and salvage pickups.
- Radio chatter as short text pop-ups (no voice acting in the demo): "HSD-Control: Prototype sighted, grid 4."
- Music: royalty-free or commercially-licensed tracks, one for levels and one for the boss
- Web browsers block audio until the player clicks, so the title screen needs a "Click to start"

## 13. Screens

Title (Click to start) → Main menu (Deploy, R&D, Settings) → Mission briefing → Level 1 → Field Refit → Armory → Level 2 → … → Boss → Mission Complete / Mission Failed (shows Combat Data earned) → Main menu

HUD: Armor bar, Plating bar, Overclock meter, salvage count, weight class, HSD Threat label, assimilated weapon icon, level number, auto-fire indicator.

Settings: master/music/SFX volume, screen shake on/off, auto-fire on/off.

## 14. Technical summary

- **Engine:** Godot 4 (latest stable, 4.4 or newer), GDScript with static typing
- **Renderer:** Compatibility (required for web export)
- **Base resolution:** 540 × 960 (portrait), stretch mode `canvas_items`, aspect `keep`; the web page shows it centered with bars at the sides
- **Web export:** single-threaded (no SharedArrayBuffer needed, so itch.io works without special settings)
- **Performance:** object pooling for rounds, missiles and pickups; target max ~400 projectiles on screen
- **Data-driven:** weapon systems, refits, weapon modules, enemies and waves are Godot Resources (`.tres`) so balancing doesn't need code changes
- **Shapes as data:** airframe shapes (per form, weight class and refit) are point lists stored in Resources, used by one shared morph system
- **Save data:** `user://save.cfg` (ConfigFile) for Combat Data, unlocks and settings

## 14b. Audience and localization

- Biggest Steam markets are the US, China, Russia, Germany and the UK; English and Simplified Chinese are the two biggest Steam languages.
- Keep all in-game text short, plain English, and stored in one place (Godot translation CSV) so it can be translated later.
- At release, translate the **store page** into Simplified Chinese first (about $100–300), then consider Japanese and Korean. If the game itself stays English-only, say so clearly on the translated page.
- Chinese title idea for the store page: 零号资产 (have a native speaker confirm).

## 15. Originality rule

Inspired by the *formula* of 90s shooters and by mech-combat loadout games, using real-world military naming style. Mechanics are inspired by genre ideas (focus modes, bomb meters, grazing, adaptive difficulty) but must be our own implementation. Do **not** use names, terms, characters, designs, art, sounds, music, quotes or level layouts from any existing game, film or franchise (for example, no BattleTech/MechWarrior-specific terms like "BattleMech", "PPC", "LRM/SRM", "AC/20", "MechLab" or "Clan", and no Terminator names or likenesses).

## 16. Later (ideas parking lot, not for the demo)

- **Contract board:** between levels, pick 1 of 2–3 missions with modifiers (night op, storm, convoy escort) and different rewards
- **Ramming build:** Assault class + Razor Wing deals crash damage based on mass
- **Laser-designated strikes:** a reticle ahead of the ship paints ground targets; bonus salvage for multi-locks (possible rework of the Seeker Missile line)
- **Heat system** (MechWarrior-style): firing builds heat, overheating jams weapons, heat sinks as a refit line
- More sectors and corporations (each with its own planet, enemies and boss)
- More weapon modules, and a refit that lets you hold two at once
- Several starting airframes (XF-1, XF-2…) with different hardpoint layouts
- Gamepad, Steam Deck and touch support
- Steam release (achievements, cloud saves)
- Daily seeded run
- Hand-painted final art with a metallic shader
