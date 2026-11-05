class_name AAEmplacement
extends Enemy
## AA Emplacement: ground turret that scrolls with the terrain, tracks XF-0 and fires aimed rounds.

## How fast the turret can turn, in radians per second.
@export var turn_speed: float = 3.0
## Seconds on screen before the first shot, so it never fires the instant it appears.
@export var warmup: float = 0.6
## Distance from the turret pivot to the end of the barrel.
@export var barrel_length: float = 16.0
## Only fires when the barrel is this close to pointing at XF-0, so shots never go wild mid-turn.
@export var aim_tolerance_degrees: float = 8.0
## Rounds per burst. The turret keeps tracking between rounds, so a burst follows a moving XF-0.
@export var burst_count: int = 2
@export var burst_gap: float = 0.12

var _on_screen_time: float = 0.0
var _cooldown: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0

@onready var _turret: Node2D = $Visual/Turret


func _tick(delta: float) -> void:
	if not is_on_screen():
		return
	_on_screen_time += delta
	# Turret art points up (-y), so its "forward" is rotation - 90 degrees.
	var wanted: float = direction_to_target().angle() + PI / 2.0
	_turret.rotation = rotate_toward(_turret.rotation, wanted, turn_speed * delta)
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = burst_gap
			_burst_left -= 1
			_fire_barrel()
		return
	_cooldown -= delta
	var aimed: bool = absf(angle_difference(_turret.rotation, wanted)) <= deg_to_rad(aim_tolerance_degrees)
	if _on_screen_time >= warmup and _cooldown <= 0.0 and aimed:
		_cooldown = data.fire_interval
		_burst_left = burst_count - 1
		_burst_timer = burst_gap
		_fire_barrel()


func _fire_barrel() -> void:
	var forward: Vector2 = Vector2.from_angle(_turret.global_rotation - PI / 2.0)
	fire(_turret.global_position + forward * barrel_length, forward)
