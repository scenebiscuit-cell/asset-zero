class_name PlayerRound
extends Area2D
## Pooled tracer round. Never freed: the pool switches it on and off.

signal expired(player_round: PlayerRound)

## How far past the screen edge a round travels before it's recycled.
const OFFSCREEN_MARGIN: float = 32.0

var damage: int = 0
var _velocity: Vector2 = Vector2.ZERO
# Starts true so the pool's first deactivate() files it as free.
var _active: bool = true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func activate(start: Vector2, velocity: Vector2, round_damage: int) -> void:
	global_position = start
	rotation = velocity.angle() + PI / 2.0
	_velocity = velocity
	damage = round_damage
	_active = true
	visible = true
	set_physics_process(true)
	# Deferred because changing collision state mid-physics-step isn't allowed.
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	expired.emit(self)


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		deactivate()


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if area is Enemy:
		(area as Enemy).take_damage(damage)
		deactivate()
