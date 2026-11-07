class_name ArmoredTransport
extends Enemy
## Armored Transport: slow air hauler that crosses the screen sideways, with a belly gun that fires slow
## aimed pairs at XF-0. Sometimes drops a repair pickup (chance in its EnemyData). Spawn it just off the
## left or right edge; it flies toward the far side. data.fire_interval is the pause between pairs.

## Slight downward drift while crossing, in px/s.
@export var drift_down: float = 12.0
## How far past the far edge it goes before it's removed.
@export var exit_margin: float = 80.0
## Seconds on screen before the belly gun opens up.
@export var warmup: float = 0.8
## The pair leaves the gun this far apart, in px.
@export var pair_spacing: float = 8.0

var _direction: float = 1.0
var _on_screen_time: float = 0.0
var _cooldown: float = 0.0

@onready var _gun: Node2D = $Visual/Gun


func _ready() -> void:
	super()
	_direction = 1.0 if position.x < get_viewport_rect().size.x * 0.5 else -1.0
	# Art faces right; flip it when crossing right-to-left.
	_visual.scale.x = _direction
	# The shadow copied the outline before the flip.
	($Shadow as DropShadow).refresh()


func _tick(delta: float) -> void:
	position += Vector2(_direction * data.speed, drift_down) * delta
	var width: float = get_viewport_rect().size.x
	if (_direction > 0.0 and position.x > width + exit_margin) or (_direction < 0.0 and position.x < -exit_margin):
		escape()
		return
	if not is_on_screen():
		return
	_on_screen_time += delta
	_cooldown -= delta
	if _on_screen_time < warmup or _cooldown > 0.0:
		return
	_cooldown = data.fire_interval
	var aim: Vector2 = direction_to_target()
	var side: Vector2 = aim.orthogonal() * pair_spacing * 0.5
	fire(_gun.global_position - side, aim)
	fire(_gun.global_position + side, aim)
