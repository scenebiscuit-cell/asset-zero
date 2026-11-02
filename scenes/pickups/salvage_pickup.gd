class_name SalvagePickup
extends Area2D
## Pooled salvage scrap. Bursts out, drifts with the ground, then gets pulled into XF-0.

signal expired(pickup: SalvagePickup)

@export var magnet_radius: float = 90.0
@export var collect_radius: float = 16.0
@export var pull_speed: float = 600.0
@export var pull_accel: float = 2400.0
## Matches the ground scroll so scrap looks like it's lying on the terrain.
@export var drift_speed: float = 60.0
@export var burst_drag: float = 4.0
@export var spin_speed: float = 4.0

var value: int = 1
var _target: Node2D
var _velocity: Vector2 = Vector2.ZERO
var _magnetized: bool = false
# Starts true so the pool's first deactivate() files it as free.
var _active: bool = true

@onready var _visual: Node2D = $Visual


func activate(start: Vector2, velocity: Vector2, pickup_value: int, target: Node2D) -> void:
	global_position = start
	_velocity = velocity
	value = pickup_value
	_target = target
	_magnetized = false
	_active = true
	visible = true
	set_physics_process(true)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	visible = false
	set_physics_process(false)
	expired.emit(self)


func _physics_process(delta: float) -> void:
	_visual.rotation += spin_speed * delta

	if is_instance_valid(_target):
		var to_target: Vector2 = _target.global_position - global_position
		var distance: float = to_target.length()
		if distance < collect_radius:
			GameState.add_salvage(value)
			deactivate()
			return
		# Once caught it stays caught, so it can't fall back out of range.
		if distance < magnet_radius:
			_magnetized = true
		if _magnetized:
			_velocity = _velocity.move_toward(to_target / distance * pull_speed, pull_accel * delta)

	if not _magnetized:
		_velocity = _velocity.lerp(Vector2(0.0, drift_speed), clampf(burst_drag * delta, 0.0, 1.0))

	position += _velocity * delta
	if global_position.y > get_viewport_rect().size.y + 20.0:
		deactivate()
