class_name MawlerTurret
extends Enemy
## One of the MAWLER's flank turrets (DESIGN.md §8): tracks XF-0 and fires aimed bursts while the
## boss is in its first phase. Every point of damage it takes comes off the boss's health bar, and
## losing both turrets opens the core. Lives inside the boss scene; the boss wires it up.

## How fast the turret can turn, in radians per second.
@export var turn_speed: float = 2.5
## Distance from the turret pivot to the end of the barrels.
@export var barrel_length: float = 34.0
## Only fires when the barrels are this close to pointing at XF-0.
@export var aim_tolerance_degrees: float = 10.0
@export var burst_count: int = 3
@export var burst_gap: float = 0.11

var boss: Mawler
var _cooldown: float = 1.2
var _burst_left: int = 0
var _burst_timer: float = 0.0

@onready var _mount: Node2D = $Visual/Mount


func _ready() -> void:
	super()
	# Mounted on the boss: no scroll of its own, and drawn on top of the boss, not under the terrain.
	ground_speed = 0.0
	z_index = 0


func _tick(delta: float) -> void:
	# Turret art points up (-y), so its "forward" is rotation - 90 degrees.
	var wanted: float = direction_to_target().angle() + PI / 2.0
	_mount.rotation = rotate_toward(_mount.rotation, wanted, turn_speed * delta)
	if boss == null or boss.phase != Mawler.Phase.TURRETS:
		return
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = burst_gap
			_burst_left -= 1
			_fire_barrels()
		return
	_cooldown -= delta
	var aimed: bool = absf(angle_difference(_mount.rotation, wanted)) <= deg_to_rad(aim_tolerance_degrees)
	if _cooldown <= 0.0 and aimed:
		_cooldown = data.fire_interval
		_burst_left = burst_count - 1
		_burst_timer = burst_gap
		_fire_barrels()


func _fire_barrels() -> void:
	var forward: Vector2 = Vector2.from_angle(_mount.global_rotation - PI / 2.0)
	fire(_mount.global_position + forward * barrel_length, forward)


func take_damage(amount: int) -> void:
	if _dead:
		return
	if boss != null:
		boss.turret_damaged(mini(amount, hp))
	super(amount)
