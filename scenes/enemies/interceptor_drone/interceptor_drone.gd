class_name InterceptorDrone
extends Enemy
## ID-4 Interceptor Drone: weaves down the screen on a sine wave and fires one slow aimed round.

## Half-width of the weave in px.
@export var wave_amplitude: float = 90.0
## Full weaves per second.
@export var wave_frequency: float = 0.5
## Seconds after spawning before its single shot.
@export var fire_delay: float = 0.9

var _start_x: float = 0.0
var _age: float = 0.0
var _fired: bool = false


func _ready() -> void:
	super()
	_start_x = position.x


func _tick(delta: float) -> void:
	_age += delta
	position.y += data.speed * delta
	position.x = _start_x + wave_amplitude * sin(_age * wave_frequency * TAU)
	# Lean into the turn.
	_visual.rotation = -cos(_age * wave_frequency * TAU) * 0.35
	if not _fired and _age >= fire_delay and is_on_screen():
		_fired = true
		fire(global_position + Vector2(0.0, 10.0), direction_to_target())
