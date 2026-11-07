class_name StrikeMeter
extends Control
## Kill meter in the left HUD rail, the mirror of the sector track on the right: fills from the
## bottom with every kill; full = one Saturation Strike charge (DESIGN.md §7.4).

@export var track_width: float = 4.0
@export var track_color: Color = Color(1.0, 1.0, 1.0, 0.1)
@export var fill_color: Color = Color(1.0, 0.35, 0.25, 0.95)
@export var full_color: Color = Color(1.0, 0.95, 0.85, 1.0)
## Notches along the track, so progress reads at a glance.
@export var notches: int = 4

## 0-1. Redraws only when the visible fill moves by at least a pixel.
var value: float = 0.0:
	set(new_value):
		new_value = clampf(new_value, 0.0, 1.0)
		if absf(new_value - value) * size.y >= 1.0 or (new_value >= 1.0) != (value >= 1.0):
			value = new_value
			queue_redraw()
## Blinks the track while storage is full and the meter is waiting.
var flash: bool = false:
	set(new_value):
		if new_value != flash:
			flash = new_value
			queue_redraw()


func _draw() -> void:
	# The track sits flush against the left edge, inside the rail.
	var x: float = 1.0
	draw_rect(Rect2(x, 0.0, track_width, size.y), track_color)
	var fill_height: float = size.y * value
	var color: Color = full_color if flash else fill_color
	draw_rect(Rect2(x, size.y - fill_height, track_width, fill_height), color)
	for i: int in range(1, notches):
		var y: float = size.y * float(i) / notches
		draw_rect(Rect2(x + track_width, y - 1.0, 3.0, 2.0), track_color * 3.0)
	# Top tick: the charge line.
	draw_rect(Rect2(x, 0.0, track_width + 3.0, 2.0), fill_color)
