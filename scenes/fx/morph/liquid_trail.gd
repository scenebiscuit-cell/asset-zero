class_name LiquidTrail
extends Line2D
## Liquid metal trailing off the tail while the metal is unlocked (Thresher form, DESIGN.md §5.3).
## A short line of recent tail positions that drifts back and fades, so the ship leaves a smear
## when it moves and a drip when it hovers.

@export var segments: int = 8
## Where the trail leaves the ship, relative to it. The Player moves it to the tail of the current shape.
@export var tail_offset: Vector2 = Vector2(0.0, 28.0)
## How fast the trail falls behind (px/s, screen down) and how tightly it follows the tail (per second).
@export var drift: float = 60.0
@export var follow: float = 16.0

## 0 = hidden, 1 = fully showing. The Player sets it from how liquid the metal is.
var strength: float = 0.0
var _points: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	# Drawn in world space, so the trail stays where the metal was left behind.
	top_level = true
	_points.resize(segments)
	_reset()


func _anchor() -> Vector2:
	return (get_parent() as Node2D).global_position + tail_offset


func _reset() -> void:
	_points.fill(_anchor())
	points = _points


func _process(delta: float) -> void:
	if strength <= 0.001:
		if visible:
			visible = false
			_reset()
		return
	visible = true
	modulate.a = strength
	_points[0] = _anchor()
	var catch_up: float = 1.0 - exp(-follow * delta)
	for i: int in range(1, segments):
		_points[i] = (_points[i] + Vector2(0.0, drift * delta)).lerp(_points[i - 1], catch_up)
	points = _points
