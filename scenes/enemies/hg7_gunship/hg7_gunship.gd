class_name HG7Gunship
extends Enemy
## HG-7 Gunship: flies in, hovers and fires at XF-0, alternating wide fans with tight fast bursts, then leaves after ~7 s.

enum Phase { ENTERING, HOVERING, LEAVING }

## Where it stops to hover, as a fraction of screen height (randomised between these).
@export var hover_y_min: float = 0.16
@export var hover_y_max: float = 0.3
@export var hover_time: float = 7.0
## Starts slowing down this far above its hover point.
@export var entry_brake_distance: float = 80.0
@export var bob_amount: float = 6.0
## Rounds per volley; volleys cycle through this list.
@export var volley_sizes: PackedInt32Array = PackedInt32Array([7, 3, 9, 3])
## Total width of each fan, in degrees.
@export var spread_degrees: float = 70.0
## Volleys this small are tight, fast aimed bursts instead of fans.
@export var tight_max_count: int = 3
@export var tight_spread_degrees: float = 9.0
@export var tight_speed_scale: float = 1.4

var _phase: Phase = Phase.ENTERING
var _hover_y: float = 0.0
var _phase_time: float = 0.0
var _cooldown: float = 0.6
var _volley: int = 0

@onready var _muzzle: Node2D = $Visual/Muzzle


func _ready() -> void:
	super()
	_hover_y = get_viewport_rect().size.y * randf_range(hover_y_min, hover_y_max)


func _tick(delta: float) -> void:
	_phase_time += delta
	match _phase:
		Phase.ENTERING:
			# Eases in: fast at first, settling onto its hover point.
			var brake: float = clampf((_hover_y - position.y) / entry_brake_distance, 0.0, 1.0)
			position.y = move_toward(position.y, _hover_y, maxf(data.speed * 1.5 * brake, 50.0) * delta)
			if absf(position.y - _hover_y) < 1.0:
				_set_phase(Phase.HOVERING)
		Phase.HOVERING:
			position.y = _hover_y + sin(_phase_time * 2.0) * bob_amount
			_cooldown -= delta
			if _cooldown <= 0.0:
				_cooldown = data.fire_interval
				_fire_volley()
			if _phase_time >= hover_time:
				_set_phase(Phase.LEAVING)
		Phase.LEAVING:
			position.y -= data.speed * minf(_phase_time * 2.0, 1.0) * delta
			if position.y < -60.0:
				escape()


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0


func _fire_volley() -> void:
	var count: int = volley_sizes[_volley % volley_sizes.size()]
	_volley += 1
	var aim: Vector2 = direction_to_target()
	if count <= tight_max_count:
		fire_fan(_muzzle.global_position, aim, count, tight_spread_degrees, tight_speed_scale)
	else:
		fire_fan(_muzzle.global_position, aim, count, spread_degrees)
