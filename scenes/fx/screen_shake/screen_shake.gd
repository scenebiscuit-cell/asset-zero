class_name ScreenShake
extends Node
## Shakes its parent Node2D (the Level) with random offsets that die down over the shake's length.
## A new request on top of a running one keeps whichever is stronger and longer. The HUD is a
## CanvasLayer, so it stays still. `enabled` is the switch for the settings toggle (Step 18).

@export var enabled: bool = true
## Hard cap on the offset, in pixels, so a huge request never shows the edge of the world.
@export var max_offset: float = 18.0

var _strength: float = 0.0
var _left: float = 0.0
var _duration: float = 1.0
var _base: Vector2 = Vector2.ZERO
var _target: Node2D


func _ready() -> void:
	_target = get_parent() as Node2D
	_base = _target.position


## `strength` is the starting offset in pixels; it fades to nothing over `duration` seconds.
func shake(strength: float, duration: float) -> void:
	if not enabled or _target == null:
		return
	_strength = maxf(_strength, strength)
	_left = maxf(_left, duration)
	_duration = maxf(_duration if _left > duration else duration, 0.01)


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		_target.position = _base
		_strength = 0.0
		return
	var amount: float = minf(_strength * clampf(_left / _duration, 0.0, 1.0), max_offset)
	_target.position = _base + Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
