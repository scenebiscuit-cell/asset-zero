class_name ReconDrone
extends Enemy
## RD-2 Recon Drone: flies straight down and fires a short pair of weak, slow rounds at XF-0.
## The RD-2H Hunter variant (same script, its own scene) also slides sideways to get above XF-0.

## Seconds on screen before its shots, picked at random so a formation doesn't fire as one wall.
@export var fire_delay_min: float = 0.4
@export var fire_delay_max: float = 1.4
## Chance (0-1) this drone fires at all, so big formations stay dodgeable.
@export_range(0.0, 1.0) var fire_chance: float = 0.7
## Rounds per drone, and the gap between them. Each round is aimed fresh, so the pair follows a moving XF-0.
@export var shots: int = 2
@export var shot_gap: float = 0.22
## Sideways speed toward XF-0's column, in px/s. 0 = flies dead straight. Stops homing once level with XF-0.
@export var homing_speed: float = 0.0

var _fire_delay: float = 0.0
var _shots_left: int = 0


func _ready() -> void:
	super()
	_fire_delay = randf_range(fire_delay_min, fire_delay_max)
	_shots_left = shots if randf() < fire_chance else 0


func _tick(delta: float) -> void:
	position.y += data.speed * delta
	if homing_speed > 0.0 and is_instance_valid(target) and position.y < target.global_position.y - 60.0:
		position.x = move_toward(position.x, target.global_position.x, homing_speed * delta)
		_visual.rotation = clampf((target.global_position.x - position.x) * 0.004, -0.35, 0.35)
	if _shots_left <= 0 or not is_on_screen():
		return
	_fire_delay -= delta
	if _fire_delay <= 0.0:
		_shots_left -= 1
		_fire_delay = shot_gap
		fire(global_position + Vector2(0.0, 10.0), direction_to_target())
