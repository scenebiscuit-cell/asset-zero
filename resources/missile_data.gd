class_name MissileData
extends WeaponData
## Missile line: rockets or homing missiles fired from the wing pylons on their own timer.

## False for unguided rockets (R1 Rocket Pod): they fly straight and never turn.
@export var homing: bool = true
@export var missiles_per_volley: int = 2
@export var speed: float = 280.0
## How fast a missile can turn toward its target, in degrees per second.
@export var turn_rate_degrees: float = 220.0
## Gunship form launches each missile angled outward by this much. Lance form launches straight.
@export var launch_angle_degrees: float = 30.0
## Seconds before a missile that hasn't hit anything bursts on its own.
@export var lifetime: float = 3.0
## Lance form: missiles only seek targets within this angle of straight ahead (DESIGN.md §5.6).
@export var lance_seek_cone_degrees: float = 30.0
## Body size compared to a standard missile (small submunitions, big bombs).
@export var visual_scale: float = 1.0
@export_group("Cluster")
## Mk3 Cluster Missile: after split_delay seconds the missile splits into these.
@export var submunition: MissileData
@export var submunition_count: int = 0
@export var split_delay: float = 0.35
## Total fan of the submunitions, in degrees.
@export var split_fan_degrees: float = 70.0
@export_group("Blast")
## Above 0, the missile bursts in a blast that damages everything inside (GBU Bunker Buster).
@export var blast_radius: float = 0.0
## Extra damage against ground units.
@export var ground_damage_multiplier: float = 1.0
