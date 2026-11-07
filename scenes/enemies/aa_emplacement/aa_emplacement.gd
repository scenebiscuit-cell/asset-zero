class_name AAEmplacement
extends Enemy
## AA Emplacement: ground turret that scrolls with the terrain, tracks XF-0 and fires aimed bursts,
## with a wide fan every other shot. The AA Sweeper variant (same script, its own scene) instead
## rakes a long burst across an arc, so XF-0 has to pick a gap and go through it.

## How fast the turret can turn, in radians per second.
@export var turn_speed: float = 3.0
## Seconds on screen before the first shot, so it never fires the instant it appears.
@export var warmup: float = 0.6
## Distance from the turret pivot to the end of the barrel.
@export var barrel_length: float = 16.0
## Only fires when the barrel is this close to pointing at XF-0, so shots never go wild mid-turn.
@export var aim_tolerance_degrees: float = 8.0
## Rounds per burst. The turret keeps tracking between rounds, so a burst follows a moving XF-0.
@export var burst_count: int = 3
@export var burst_gap: float = 0.12
## Every Nth shot is a fan instead of a burst (0 = never).
@export var fan_every: int = 2
@export var fan_count: int = 5
@export var fan_degrees: float = 44.0
## Sweeper: when above 0, a burst starts this far to one side of XF-0 and rakes across to the other.
@export var sweep_degrees: float = 0.0

var _on_screen_time: float = 0.0
var _cooldown: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0
var _shots: int = 0
var _sweep_from: float = 0.0
var _sweep_to: float = 0.0

@onready var _turret: Node2D = $Visual/Turret


func _tick(delta: float) -> void:
	if not is_on_screen():
		return
	_on_screen_time += delta
	# Turret art points up (-y), so its "forward" is rotation - 90 degrees.
	var wanted: float = direction_to_target().angle() + PI / 2.0
	if _burst_left > 0 and sweep_degrees > 0.0:
		# Mid-sweep: the turret rakes across its arc instead of tracking.
		var t: float = 1.0 - float(_burst_left) / float(burst_count)
		_turret.rotation = lerp_angle(_sweep_from, _sweep_to, t)
	else:
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
	if _on_screen_time < warmup or _cooldown > 0.0 or not aimed:
		return
	_cooldown = data.fire_interval
	_shots += 1
	if fan_every > 0 and _shots % fan_every == 0:
		_fire_fan()
		return
	if sweep_degrees > 0.0:
		var half: float = deg_to_rad(sweep_degrees) * 0.5
		var side: float = 1.0 if _shots % 2 == 0 else -1.0 # Alternate the sweep direction.
		_sweep_from = wanted - half * side
		_sweep_to = wanted + half * side
		_turret.rotation = _sweep_from
	_burst_left = burst_count - 1
	_burst_timer = burst_gap
	_fire_barrel()


func _forward() -> Vector2:
	return Vector2.from_angle(_turret.global_rotation - PI / 2.0)


func _fire_barrel() -> void:
	var forward: Vector2 = _forward()
	fire(_turret.global_position + forward * barrel_length, forward)


func _fire_fan() -> void:
	var forward: Vector2 = _forward()
	fire_fan(_turret.global_position + forward * barrel_length, forward, fan_count, fan_degrees)
