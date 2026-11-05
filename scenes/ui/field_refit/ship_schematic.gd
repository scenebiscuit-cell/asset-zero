class_name ShipSchematic
extends Control
## Top-down blueprint of XF-0 for the Field Refit screen (DESIGN.md §7.1): Gunship and Lance form
## side by side, drawn from the same AirframeShape data the ship uses, with a marker on each
## hardpoint. The hardpoint of the offer in focus pulses.

@export var gunship_shape: AirframeShape
@export var lance_shape: AirframeShape
@export var draw_scale: float = 2.3
@export var line_color: Color = Color(0.35, 0.85, 1.0, 0.85)
@export var fill_color: Color = Color(0.35, 0.85, 1.0, 0.08)
@export var marker_color: Color = Color(0.35, 0.85, 1.0, 0.5)
@export var highlight_color: Color = Color(1.0, 0.7, 0.2)
## Engine and Hull have no offset in the shape data yet, so they sit at fixed spots.
@export var engine_offset: Vector2 = Vector2(0.0, 22.0)
@export var hull_offset: Vector2 = Vector2(0.0, -2.0)

## Hardpoint to pulse (WeaponData.Hardpoint), or -1 for none.
var highlight: int = -1:
	set(value):
		highlight = value
		queue_redraw()

var _time: float = 0.0
## Only the outline is drawn, so these parts are skipped (they sit inside the hull).
var _skip_parts: PackedStringArray = PackedStringArray(["Highlight", "Sensor", "EngineGlow"])


func _process(delta: float) -> void:
	_time += delta
	if highlight >= 0:
		queue_redraw()


func _draw() -> void:
	# A bit below centre: the Lance form's long nose needs the room at the top.
	var centers: Array[Vector2] = [Vector2(size.x * 0.27, size.y * 0.6), Vector2(size.x * 0.73, size.y * 0.6)]
	var shapes: Array[AirframeShape] = [gunship_shape, lance_shape]
	for i: int in 2:
		if shapes[i] != null:
			_draw_ship(shapes[i], centers[i])


func _draw_ship(shape: AirframeShape, center: Vector2) -> void:
	draw_set_transform(center, 0.0, Vector2(draw_scale, draw_scale))
	var width: float = 1.2 / draw_scale
	for part: String in shape.parts:
		if _skip_parts.has(part):
			continue
		var points: PackedVector2Array = shape.parts[part]
		if points.size() < 3:
			continue
		draw_colored_polygon(points, fill_color)
		var outline: PackedVector2Array = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, line_color, width)
	var spots: Dictionary[int, Array] = {
		WeaponData.Hardpoint.NOSE: [shape.muzzle_offset + Vector2(0.0, 8.0)],
		WeaponData.Hardpoint.WING_PYLONS: [shape.pylon_offset, Vector2(-shape.pylon_offset.x, shape.pylon_offset.y)],
		WeaponData.Hardpoint.ENGINE: [engine_offset],
		WeaponData.Hardpoint.HULL: [hull_offset],
		WeaponData.Hardpoint.SALVAGE_MOUNT: [shape.mount_offset],
	}
	var pulse: float = 0.5 + 0.5 * sin(_time * 8.0)
	for hardpoint: int in spots:
		var lit: bool = hardpoint == highlight
		for spot: Vector2 in spots[hardpoint]:
			var half: float = (3.2 if lit else 2.0)
			var rect: Rect2 = Rect2(spot - Vector2(half, half), Vector2(half, half) * 2.0)
			if lit:
				draw_rect(rect.grow(1.5 + pulse * 2.0), Color(highlight_color, 0.35 * (1.0 - pulse)), false, width * 1.5)
				draw_rect(rect, Color(highlight_color, 0.6 + 0.4 * pulse))
			else:
				draw_rect(rect, marker_color, false, width)
	draw_set_transform(Vector2.ZERO)
