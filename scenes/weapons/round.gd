class_name Round
extends PooledObject
## A straight-flying round. Player and enemy rounds both build on this.

## How far past the screen edge a round travels before it's recycled.
const OFFSCREEN_MARGIN: float = 32.0

var damage: int = 0
var _velocity: Vector2 = Vector2.ZERO


func activate(start: Vector2, velocity: Vector2, round_damage: int) -> void:
	global_position = start
	rotation = velocity.angle() + PI / 2.0
	_velocity = velocity
	damage = round_damage
	_start()


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		deactivate()
