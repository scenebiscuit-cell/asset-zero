class_name EnemyData
extends Resource
## Stats for one enemy type. Stored as .tres files in data/enemies/. Elite multipliers live on Enemy.

enum Layer { AIR, GROUND }

## Air units fly over everything; ground units sit on the terrain and scroll with it.
@export var layer: Layer = Layer.AIR
@export var max_hp: int = 20
## Own movement speed in px/s (ground units get the terrain scroll on top).
@export var speed: float = 180.0
## Number of salvage pickups dropped on death.
@export var salvage: int = 1
## Armor lost when XF-0 flies into this enemy. Ground units can't be flown into.
@export var contact_damage: int = 20

@export_group("Fire")
@export var fire_interval: float = 1.5
@export var round_speed: float = 220.0
@export var round_damage: int = 10
