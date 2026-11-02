class_name WeaponData
extends Resource
## Stats for one weapon system level. Stored as .tres files in data/weapons/.

## Seconds between shots.
@export var fire_interval: float = 0.07
@export var round_speed: float = 1100.0
@export var damage: int = 10
## Random scatter per round in Gunship form, in degrees. Lance form converges this to zero.
@export var spread_degrees: float = 4.0
