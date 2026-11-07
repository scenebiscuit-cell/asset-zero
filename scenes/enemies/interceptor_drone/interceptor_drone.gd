class_name InterceptorDrone
extends Enemy
## ID-4 Interceptor Drone: weaves down the screen on a sine wave, firing short aimed bursts as it goes.
## data.fire_interval is the pause between bursts.

## Half-width of the weave in px.
@export var wave_amplitude: float = 90.0
## Full weaves per second.
@export var wave_frequency: float = 0.5
## Seconds after spawning before its first burst.
@export var fire_delay: float = 0.8
## Rounds per burst and the gap between them.
@export var burst_count: int = 2
@export var burst_gap: float = 0.14

var _start_x: float = 0.0
var _age: float = 0.0
var _cooldown: float = 0.0
var _burst_left: int = 0


func _ready() -> void:
	super()
	_start_x = position.x
	_cooldown = fire_delay


func _tick(delta: float) -> void:
	_age += delta
	position.y += data.speed * delta
	position.x = _start_x + wave_amplitude * sin(_age * wave_frequency * TAU)
	# Lean into the turn.
	_visual.rotation = -cos(_age * wave_frequency * TAU) * 0.35
	if not is_on_screen():
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	fire(global_position + Vector2(0.0, 10.0), direction_to_target())
	_burst_left = burst_count - 1 if _burst_left <= 0 else _burst_left - 1
	_cooldown = burst_gap if _burst_left > 0 else data.fire_interval
