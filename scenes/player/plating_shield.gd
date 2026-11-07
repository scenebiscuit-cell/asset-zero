class_name PlatingShield
extends Node2D
## Plating made visible (DESIGN.md §5.4): a ring of hex plates around XF-0. Brighter the fuller the
## Plating is, flashes when it soaks a hit, and is gone when Plating is empty.

@export var radius: Vector2 = Vector2(34.0, 38.0)
@export var plates: int = 14
@export var plate_size: float = 5.0
@export var color: Color = Color(0.35, 0.85, 1.0)
@export var flash_time: float = 0.25

var _time: float = 0.0
var _flash_left: float = 0.0
var _fraction: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	_flash_left = maxf(_flash_left - delta, 0.0)
	var fraction: float = 0.0
	if GameState.max_plating > 0:
		fraction = float(GameState.plating) / GameState.max_plating
	visible = fraction > 0.0 or _flash_left > 0.0
	if visible:
		_fraction = fraction
		queue_redraw()


## Called when a hit lands on Plating.
func flash() -> void:
	_flash_left = flash_time


func _draw() -> void:
	var flash_t: float = _flash_left / flash_time
	var alpha: float = 0.15 + 0.35 * _fraction + 0.5 * flash_t
	# Plates drift slowly round the hull; missing plates show lost Plating.
	var shown: int = ceili(plates * maxf(_fraction, flash_t))
	for i: int in shown:
		var angle: float = _time * 0.6 + TAU * i / plates
		var at: Vector2 = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var hexagon: PackedVector2Array = PackedVector2Array()
		for k: int in 6:
			hexagon.append(at + Vector2.from_angle(PI / 6.0 + k * PI / 3.0) * plate_size)
		draw_colored_polygon(hexagon, Color(color, alpha * 0.45))
		hexagon.append(hexagon[0])
		draw_polyline(hexagon, Color(color.lerp(Color.WHITE, flash_t), alpha), 1.0)
