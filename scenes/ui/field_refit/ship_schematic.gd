class_name ShipSchematic
extends Control
## Top-down blueprint of XF-0 for the Field Refit screen (DESIGN.md §7.1): Gunship and Thresher form
## side by side, drawn from the same AirframeShape data the ship uses, with a marker on each
## hardpoint. The hardpoint of the offer in focus pulses.

## Same shapes the ship flies with, built from the current loadout every redraw.
@export var airframes: AirframeSet
@export var draw_scale: float = 2.3
## 0 = classes drawn at their full size difference, 1 = every class drawn the same size.
@export var class_shrink: float = 0.8
## Space kept between the drawing and the panel edge, in pixels.
@export var fit_margin: float = 8.0
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
var _skip_parts: PackedStringArray = PackedStringArray(["Highlight", "Sensor", "EngineGlow", "Outline", "HullShade",
		"WingPanelL", "WingPanelR", "IntakeL", "IntakeR", "EdgeL", "EdgeR", "StripeL", "StripeR"])


func _process(delta: float) -> void:
	_time += delta
	if highlight >= 0:
		queue_redraw()


func _draw() -> void:
	# A bit below centre: the Thresher form's long nose needs the room at the top.
	var centers: Array[Vector2] = [Vector2(size.x * 0.27, size.y * 0.6), Vector2(size.x * 0.73, size.y * 0.6)]
	if airframes == null:
		return
	var shapes: Array[AirframeShape] = [airframes.build(false), airframes.build(true)]
	# One zoom for both forms, so they stay true to size next to each other.
	var zoom: float = minf(_fit_zoom(shapes[0], centers[0]), _fit_zoom(shapes[1], centers[1]))
	for i: int in 2:
		_draw_ship(shapes[i], centers[i], zoom)


## Bigger weight classes still look bigger, but grow less than in flight; long noses (railgun,
## Thresher form) shrink the drawing so nothing pokes out of the panel.
func _fit_zoom(shape: AirframeShape, center: Vector2) -> float:
	var zoom: float = draw_scale / pow(shape.overlay_scale, class_shrink)
	var top: float = 0.0
	var bottom: float = 0.0
	var side: float = 0.0
	for part: String in shape.parts:
		for point: Vector2 in shape.parts[part]:
			top = minf(top, point.y)
			bottom = maxf(bottom, point.y)
			side = maxf(side, absf(point.x))
	# Room to the panel edge or to the middle, whichever is nearer.
	if side > 0.0:
		zoom = minf(zoom, (minf(center.x, absf(size.x * 0.5 - center.x)) - fit_margin * 0.5) / side)
	if top < 0.0:
		zoom = minf(zoom, (center.y - fit_margin) / -top)
	if bottom > 0.0:
		zoom = minf(zoom, (size.y - center.y - fit_margin) / bottom)
	return zoom


func _draw_ship(shape: AirframeShape, center: Vector2, zoom: float) -> void:
	draw_set_transform(center, 0.0, Vector2(zoom, zoom))
	var width: float = 1.2 / zoom
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
		WeaponData.Hardpoint.ENGINE: [engine_offset * shape.overlay_scale],
		WeaponData.Hardpoint.HULL: [hull_offset * shape.overlay_scale],
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
