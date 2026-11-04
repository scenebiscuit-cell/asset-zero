class_name HudBar
extends Control
## Segmented cockpit-display bar (DESIGN.md §11 UI): dark panel, thin border, lit segments.

@export var fill_color: Color = Color(1.0, 0.7, 0.2)
@export var empty_color: Color = Color(1.0, 1.0, 1.0, 0.07)
@export var panel_color: Color = Color(0.03, 0.04, 0.04, 0.85)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.18)
@export var segments: int = 20
@export var gap: float = 1.0

## 0-1. Setting it redraws only when it actually changes.
var value: float = 1.0:
	set(new_value):
		new_value = clampf(new_value, 0.0, 1.0)
		if not is_equal_approx(new_value, value):
			value = new_value
			queue_redraw()
## Overrides fill_color while set (e.g. a warning colour). Clear with Color(0, 0, 0, 0).
var tint: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(new_tint):
		if new_tint != tint:
			tint = new_tint
			queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, panel_color)
	var inner: Rect2 = rect.grow(-2.0)
	var seg_width: float = (inner.size.x - gap * (segments - 1)) / segments
	var lit: int = ceili(value * segments - 0.001)
	var color: Color = tint if tint.a > 0.0 else fill_color
	for i: int in segments:
		var seg: Rect2 = Rect2(inner.position.x + i * (seg_width + gap), inner.position.y, seg_width, inner.size.y)
		draw_rect(seg, color if i < lit else empty_color)
	draw_rect(rect, border_color, false, 1.0)
