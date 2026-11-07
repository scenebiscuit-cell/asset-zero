class_name GunData
extends WeaponData
## Autocannon line: barrels side by side firing tracer rounds.

@export var round_speed: float = 1000.0
## Random scatter per round in Gunship form, in degrees. Thresher form converges this to zero.
@export var spread_degrees: float = 4.0
@export var barrel_count: int = 1
## Gap between barrels in Gunship form, in pixels.
@export var barrel_spacing: float = 7.0
## Gunship form angles the outer barrels outward by this much, in degrees.
@export var splay_degrees: float = 1.5
## Angle between neighbouring barrels for a spread gun (M40 Flak Battery), Gunship form only.
## 0 = barrels fire parallel. Thresher form always fires dead straight.
@export var fan_degrees: float = 0.0
@export_group("Thresher form")
## Thresher form fires this much faster (0.8 = every 0.8x the interval), DESIGN.md §5.6.
@export var thresher_interval_scale: float = 0.8
## Thresher form rounds fly this much faster.
@export var thresher_round_speed_scale: float = 1.2
@export_group("")
@export var round_tint: Color = Color.WHITE
## Tracer length compared to the standard round (the Railgun's long slug).
@export var round_length: float = 1.0
## The round passes through enemies, hitting each one once.
@export var pierce: bool = false
@export_group("Fragments")
## On hit, the round bursts into this many small fragments (M40 Flak Battery).
@export var fragments: int = 0
@export var fragment_damage: int = 4
@export var fragment_speed: float = 520.0
## How far fragments fly before fading out, in pixels.
@export var fragment_range: float = 70.0
