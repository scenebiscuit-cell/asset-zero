class_name SectorProgress
extends Control
## Thin flight-path track in the right HUD rail: fills from the bottom as the sector goes on, with a
## small marker for XF-0. The top tick is the end of the sector.

@export var track_width: float = 4.0
@export var track_color: Color = Color(1.0, 1.0, 1.0, 0.1)
@export var fill_color: Color = Color(0.55, 1.0, 0.6, 0.95)
@export var marker_color: Color = Color(0.55, 1.0, 0.6, 1.0)
@export var marker_size: float = 6.0

## 0-1. Redraws only when the visible fill moves by at least a pixel.
var value: float = 0.0:
	set(new_value):
		new_value = clampf(new_value, 0.0, 1.0)
		if absf(new_value - value) * size.y >= 1.0 or (new_value >= 1.0 and value < 1.0):
			value = new_value
			queue_redraw()


func _draw() -> void:
	# The track sits flush against the right edge, inside the rail.
	var x: float = size.x - track_width - 1.0
	draw_rect(Rect2(x, 0.0, track_width, size.y), track_color)
	var fill_height: float = size.y * value
	var top: float = size.y - fill_height
	draw_rect(Rect2(x, top, track_width, fill_height), fill_color)
	# End-of-sector tick across the top.
	draw_rect(Rect2(x - 3.0, 0.0, track_width + 3.0, 2.0), marker_color)
	# Marker points into the rail from the play area.
	var tip: Vector2 = Vector2(x - 1.0, top)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-marker_size, -marker_size), tip + Vector2(-marker_size, marker_size)]), marker_color)
