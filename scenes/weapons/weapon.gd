class_name Weapon
extends Node2D
## Base for every system mounted on a hardpoint. Hardpoints sets these; each weapon reads them.

var data: WeaponData
var round_pool: RoundPool
var missile_pool: MissilePool
## Fire is held (or auto-fire is on). Missiles ignore it: they fire on their own timer.
var firing: bool = false
## Lance form: every weapon converges forward (DESIGN.md §5.6).
var converged: bool = false
var damage_multiplier: float = 1.0
## False once XF-0 is destroyed, so nothing keeps firing on its own.
var enabled: bool = true
## Where the weapon fires from. Nose weapons use the slot itself; pylon weapons get left and right.
var launch_points: Array[Node2D] = []


func scaled_damage(base: int) -> int:
	return roundi(base * damage_multiplier)
