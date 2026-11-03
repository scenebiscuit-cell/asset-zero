class_name ArmoredTransport
extends Enemy
## Armored Transport: slow air hauler that crosses the screen sideways. Sometimes drops a repair pickup
## (chance in its EnemyData). Spawn it just off the left or right edge; it flies toward the far side.

## Slight downward drift while crossing, in px/s.
@export var drift_down: float = 12.0
## How far past the far edge it goes before it's removed.
@export var exit_margin: float = 80.0

var _direction: float = 1.0


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
		queue_free() # Got away: no salvage.
