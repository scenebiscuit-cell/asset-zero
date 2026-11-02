class_name BackgroundLayer
extends Node2D
## Placeholder scrolling terrain. The pattern repeats every screen height, is drawn
## once as two stacked copies, and the node just slides down and wraps.

enum Style { GROUND, HAZE }

const SIZE: Vector2 = Vector2(540.0, 960.0)

@export var style: Style = Style.GROUND
@export var scroll_speed: float = 60.0
@export var pattern_seed: int = 471


func _process(delta: float) -> void:
	position.y = fposmod(position.y + scroll_speed * delta, SIZE.y)


func _draw() -> void:
	for copy_top: float in [0.0, -SIZE.y]:
		if style == Style.GROUND:
			_draw_ground(copy_top)
		else:
			_draw_haze(copy_top)


func _draw_ground(top: float) -> void:
	# Darker at the sides so the middle of the screen reads first.
	var edge: Color = Color(0.015, 0.035, 0.025)
	var middle: Color = Color(0.04, 0.09, 0.06)
	var half: float = SIZE.x * 0.5
	var bottom: float = top + SIZE.y
	draw_polygon(
		PackedVector2Array([Vector2(0.0, top), Vector2(half, top), Vector2(half, bottom), Vector2(0.0, bottom)]),
		PackedColorArray([edge, middle, middle, edge]))
	draw_polygon(
		PackedVector2Array([Vector2(half, top), Vector2(SIZE.x, top), Vector2(SIZE.x, bottom), Vector2(half, bottom)]),
		PackedColorArray([middle, edge, edge, middle]))

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = pattern_seed

	# Road: built from sine waves whose period is the screen height, so it tiles seamlessly.
	var road: PackedVector2Array = PackedVector2Array()
	var y: float = 0.0
	while y <= SIZE.y:
		road.append(Vector2(_road_x(y), top + y))
		y += 24.0
	draw_polyline(road, Color(0.11, 0.09, 0.06), 30.0)
	draw_polyline(road, Color(0.15, 0.12, 0.08), 20.0)

	# Jungle canopy blobs.
	for i: int in 70:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		var radius: float = rng.randf_range(10.0, 34.0)
		var shade: float = rng.randf()
		if absf(pos.x - _road_x(pos.y)) < radius + 16.0:
			continue # Keep the road clear.
		var color: Color = Color(0.03, 0.07, 0.045).lerp(Color(0.06, 0.13, 0.07), shade)
		_draw_wrapped_circle(top, pos, radius, color)

	# Mining structures: muted grey pads with hazard stripes, set beside the road.
	for i: int in 3:
		var size: Vector2 = Vector2(rng.randf_range(50.0, 80.0), rng.randf_range(36.0, 56.0))
		var pad_y: float = rng.randf_range(60.0, SIZE.y - 120.0)
		var road_x: float = _road_x(pad_y)
		var pad_x: float = road_x + 40.0 if road_x < half else road_x - 40.0 - size.x
		var rect: Rect2 = Rect2(pad_x, top + pad_y, size.x, size.y)
		draw_rect(rect, Color(0.12, 0.12, 0.11))
		draw_rect(rect, Color(0.3, 0.18, 0.07), false, 2.0)
		_draw_hazard_stripes(Rect2(rect.position, Vector2(rect.size.x, 6.0)))


func _draw_haze(top: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = pattern_seed
	# Faint speed streaks and mist, scrolling faster than the ground for depth.
	for i: int in 24:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		var length: float = rng.randf_range(50.0, 160.0)
		draw_rect(Rect2(pos.x, top + pos.y, 1.5, length), Color(0.7, 0.9, 0.8, 0.05))
	for i: int in 8:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		_draw_wrapped_circle(top, pos, rng.randf_range(40.0, 90.0), Color(0.5, 0.7, 0.6, 0.025))


func _road_x(y: float) -> float:
	var t: float = y / SIZE.y * TAU
	return 290.0 + 110.0 * sin(t) + 40.0 * sin(t * 2.0)


## Draws a circle, plus a copy one screen-height away if it crosses the seam.
func _draw_wrapped_circle(top: float, pos: Vector2, radius: float, color: Color) -> void:
	draw_circle(Vector2(pos.x, top + pos.y), radius, color)
	if pos.y < radius:
		draw_circle(Vector2(pos.x, top + pos.y + SIZE.y), radius, color)
	elif pos.y > SIZE.y - radius:
		draw_circle(Vector2(pos.x, top + pos.y - SIZE.y), radius, color)


func _draw_hazard_stripes(rect: Rect2) -> void:
	draw_rect(rect, Color(0.08, 0.07, 0.05))
	var x: float = rect.position.x
	while x < rect.end.x - 6.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.end.y), Vector2(x + 4.0, rect.position.y),
			Vector2(x + 8.0, rect.position.y), Vector2(x + 4.0, rect.end.y)]),
			Color(0.38, 0.32, 0.08))
		x += 10.0
