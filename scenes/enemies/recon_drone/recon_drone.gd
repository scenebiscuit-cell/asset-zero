class_name ReconDrone
extends Enemy
## RD-2 Recon Drone: flies straight down and fires one weak, slow round at XF-0.

## Seconds on screen before its shot, picked at random so a formation doesn't fire as one wall.
@export var fire_delay_min: float = 0.4
@export var fire_delay_max: float = 1.6
## Chance (0-1) this drone fires at all, so big formations stay dodgeable.
@export_range(0.0, 1.0) var fire_chance: float = 0.7

var _fire_delay: float = 0.0
var _fired: bool = false


func _ready() -> void:
	super()
	_fire_delay = randf_range(fire_delay_min, fire_delay_max)
	_fired = randf() >= fire_chance


func _tick(delta: float) -> void:
	position.y += data.speed * delta
	if _fired or not is_on_screen():
		return
	_fire_delay -= delta
	if _fire_delay <= 0.0:
		_fired = true
		fire(global_position + Vector2(0.0, 10.0), direction_to_target())
