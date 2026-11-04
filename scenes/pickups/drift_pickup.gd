class_name DriftPickup
extends PooledObject
## Base for pooled power-up pickups: drifts with the ground, pulses, gets pulled in when XF-0 is
## close. Each pickup overrides _on_collected() with what it actually does.

@export var collect_radius: float = 22.0
@export var magnet_radius: float = 60.0
@export var pull_speed: float = 400.0
## Matches the ground scroll so it looks like it's lying on the terrain.
@export var drift_speed: float = 60.0
@export var pulse_speed: float = 5.0

var _target: Node2D
var _age: float = 0.0

@onready var _visual: Node2D = $Visual


func activate(at: Vector2, target: Node2D) -> void:
	global_position = at
	_target = target
	_age = 0.0
	_start()


func _physics_process(delta: float) -> void:
	_age += delta
	_visual.scale = Vector2.ONE * (1.0 + 0.12 * sin(_age * pulse_speed))
	var velocity: Vector2 = Vector2(0.0, drift_speed)
	if is_instance_valid(_target) and _target.visible:
		var to_target: Vector2 = _target.global_position - global_position
		var distance: float = to_target.length()
		if distance < collect_radius:
			_on_collected(_target)
			deactivate()
			return
		if distance < magnet_radius:
			velocity = to_target / distance * pull_speed
	position += velocity * delta
	if global_position.y > get_viewport_rect().size.y + 30.0:
		deactivate()


## What the pickup does when XF-0 reaches it.
func _on_collected(_collector: Node2D) -> void:
	pass
