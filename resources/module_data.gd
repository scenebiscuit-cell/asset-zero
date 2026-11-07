class_name ModuleData
extends WeaponData
## An enemy weapon module (DESIGN.md §5.8): dropped by elites, assimilated onto the Salvage Mount,
## fires whenever Fire is held. Each module adds its own numbers in a subclass.

## Glow colour of the pickup, the HUD icon and the mounted pod (the colour of the enemy it came from).
@export var color: Color = Color(1.0, 0.6, 0.2)
## Tint for the module's own rounds. Kept pale so they never look like enemy fire.
@export var round_tint: Color = Color(1.0, 0.88, 0.65)
