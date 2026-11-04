class_name GunData
extends WeaponData
## Autocannon line: barrels side by side firing tracer rounds.

@export var round_speed: float = 1000.0
## Random scatter per round in Gunship form, in degrees. Lance form converges this to zero.
@export var spread_degrees: float = 4.0
@export var barrel_count: int = 1
## Gap between barrels in Gunship form, in pixels.
@export var barrel_spacing: float = 7.0
## Lance form pulls the barrels together into one tight stream (DESIGN.md §5.6).
@export var lance_barrel_spacing: float = 2.0
## Gunship form angles the outer barrels outward by this much, in degrees.
@export var splay_degrees: float = 1.5
