class_name BackgroundLayer
extends Node2D
## Placeholder scrolling terrain in the Verdance palette (DESIGN.md §11.8). The pattern repeats
## every screen height, is drawn once as two stacked copies, and the node just slides down and wraps.
## Light comes from the top-left: raised things get a highlight up-left and a shadow down-right.

enum Style { GROUND, HAZE }

const SIZE: Vector2 = Vector2(540.0, 960.0)

# Verdance: dark jungle over oxblood mining earth, toxic-teal water, concrete HEG structures.
const JUNGLE_FLOOR: Color = Color("0d1810")
const CANOPY_DARK: Color = Color("16281a")
const CANOPY_LIGHT: Color = Color("27402a")
const CANOPY_HIGHLIGHT: Color = Color("3d5636")
const DEEP_SHADOW: Color = Color("090c08")
const EARTH: Color = Color("5b2d2c")
const EARTH_SHADOW: Color = Color("461f1f")
const EARTH_LIGHT: Color = Color("715049")
const WATER_SHALLOW: Color = Color("4a7d5c")
const WATER_MID: Color = Color("2a6b58")
const WATER_DEEP: Color = Color("1c6250")
const CONCRETE: Color = Color("6e6e6e")
const CONCRETE_LIGHT: Color = Color("89816c")
const CONCRETE_SHADOW: Color = Color("363331")
const HAZARD_YELLOW: Color = Color("c9a227")
const HAZARD_DARK: Color = Color("1e1e1b")
const HAZARD_ORANGE: Color = Color("b45424")

@export var style: Style = Style.GROUND
@export var scroll_speed: float = 60.0
@export var pattern_seed: int = 471
@export var pit_count: int = 2
@export var canopy_count: int = 90
@export var structure_count: int = 3


func _process(delta: float) -> void:
	position.y = fposmod(position.y + scroll_speed * delta, SIZE.y)


func _draw() -> void:
	for copy_top: float in [0.0, -SIZE.y]:
		if style == Style.GROUND:
			_draw_ground(copy_top)
		else:
			_draw_haze(copy_top)
	draw_set_transform(Vector2.ZERO)


func _draw_ground(top: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = pattern_seed
	# Areas the jungle must leave open: x, y, radius.
	var cleared: Array[Vector3] = []

	draw_rect(Rect2(0.0, top, SIZE.x, SIZE.y), JUNGLE_FLOOR)

	for i: int in pit_count:
		var y: float = (i + 0.5) * SIZE.y / pit_count + rng.randf_range(-80.0, 80.0)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = clampf(_road_x(y) + side * rng.randf_range(90.0, 130.0), 70.0, SIZE.x - 70.0)
		var radius: float = rng.randf_range(55.0, 80.0)
		var outline: PackedVector2Array = _blob(rng, radius, 12, 0.22)
		cleared.append(Vector3(x, y, radius))
		for shift: float in _wrap_shifts(y, radius):
			_draw_pit(Vector2(x, top + y + shift), outline)

	var pond_y: float = rng.randf_range(100.0, SIZE.y - 100.0)
	var pond_x: float = SIZE.x - 90.0 if _road_x(pond_y) < SIZE.x * 0.5 else 90.0
	var pond_radius: float = rng.randf_range(45.0, 60.0)
	var pond: PackedVector2Array = _blob(rng, pond_radius, 12, 0.25)
	cleared.append(Vector3(pond_x, pond_y, pond_radius))
	for shift: float in _wrap_shifts(pond_y, pond_radius):
		_draw_pond(Vector2(pond_x, top + pond_y + shift), pond, pond_radius)

	_draw_road(top)

	for i: int in canopy_count:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		var radius: float = rng.randf_range(12.0, 30.0)
		var shade: float = rng.randf()
		var outline: PackedVector2Array = _blob(rng, radius, 9, 0.2)
		if absf(pos.x - _road_x(pos.y)) < radius + 18.0 or _is_cleared(pos, radius, cleared):
			continue
		for shift: float in _wrap_shifts(pos.y, radius * 1.5):
			_draw_canopy(Vector2(pos.x, top + pos.y + shift), outline, radius, shade)

	for i: int in structure_count:
		var size: Vector2 = Vector2(rng.randf_range(54.0, 80.0), rng.randf_range(38.0, 56.0))
		var pad_y: float = (i + 0.3) * SIZE.y / structure_count + rng.randf_range(-40.0, 40.0)
		var road_x: float = _road_x(pad_y)
		var pad_x: float = road_x + 30.0 if road_x < SIZE.x * 0.5 else road_x - 30.0 - size.x
		var has_tank: bool = rng.randf() < 0.6
		for shift: float in _wrap_shifts(pad_y + size.y * 0.5, size.y):
			_draw_structure(Rect2(pad_x, top + pad_y + shift, size.x, size.y), has_tank)

	draw_set_transform(Vector2.ZERO)
	_draw_side_shade(top)


func _draw_pit(center: Vector2, outline: PackedVector2Array) -> void:
	# A hole lit from the top-left shows its lit wall on the bottom-right, so inner layers shift up-left.
	_draw_shape(outline, center, 1.0, EARTH_LIGHT)
	_draw_shape(outline, center + Vector2(-4.0, -4.0), 0.82, EARTH)
	_draw_shape(outline, center + Vector2(-7.0, -7.0), 0.58, EARTH_SHADOW)
	_draw_shape(outline, center + Vector2(-8.0, -8.0), 0.3, EARTH_SHADOW.darkened(0.3))


func _draw_pond(center: Vector2, outline: PackedVector2Array, radius: float) -> void:
	_draw_shape(outline, center, 1.0, WATER_SHALLOW)
	_draw_shape(outline, center + Vector2(1.0, 1.0), 0.8, WATER_MID)
	_draw_shape(outline, center + Vector2(3.0, 3.0), 0.55, WATER_DEEP)
	draw_set_transform(center)
	var glint: Color = Color(WATER_SHALLOW.lightened(0.3), 0.5)
	draw_line(Vector2(-radius * 0.5, -radius * 0.35), Vector2(-radius * 0.15, -radius * 0.45), glint, 1.5)
	draw_line(Vector2(-radius * 0.3, -radius * 0.15), Vector2(-radius * 0.05, -radius * 0.22), glint, 1.0)


func _draw_road(top: float) -> void:
	draw_set_transform(Vector2.ZERO)
	# Built from sine waves whose period is the screen height, so it tiles seamlessly.
	# Runs a little past both ends so the two copies overlap instead of leaving a notch at the seam.
	var road: PackedVector2Array = PackedVector2Array()
	var y: float = -48.0
	while y <= SIZE.y + 48.0:
		road.append(Vector2(_road_x(y), top + y))
		y += 24.0
	draw_polyline(road, EARTH_SHADOW, 34.0)
	draw_polyline(road, EARTH, 26.0)
	# Tyre tracks.
	for track_x: float in [-6.0, 6.0]:
		var track: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in road:
			track.append(point + Vector2(track_x, 0.0))
		draw_polyline(track, Color(EARTH_LIGHT, 0.45), 2.0)


func _draw_canopy(center: Vector2, outline: PackedVector2Array, radius: float, shade: float) -> void:
	var shadow_offset: Vector2 = Vector2(radius * 0.25 + 2.0, radius * 0.3 + 3.0)
	_draw_shape(outline, center + shadow_offset, 1.0, Color(DEEP_SHADOW, 0.6))
	_draw_shape(outline, center, 1.0, CANOPY_DARK.lerp(CANOPY_LIGHT, shade))
	_draw_shape(outline, center + Vector2(-radius, -radius) * 0.25, 0.5, Color(CANOPY_HIGHLIGHT, 0.55))


func _draw_structure(rect: Rect2, has_tank: bool) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(rect.position + Vector2(6.0, 8.0), rect.size), Color(DEEP_SHADOW, 0.55))
	draw_rect(rect, CONCRETE)
	# Bevel: lit top/left edges, shaded bottom/right edges.
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), CONCRETE_LIGHT)
	draw_rect(Rect2(rect.position, Vector2(2.0, rect.size.y)), CONCRETE_LIGHT)
	draw_rect(Rect2(rect.position.x, rect.end.y - 2.0, rect.size.x, 2.0), CONCRETE_SHADOW)
	draw_rect(Rect2(rect.end.x - 2.0, rect.position.y, 2.0, rect.size.y), CONCRETE_SHADOW)
	_draw_hazard_stripes(Rect2(rect.position + Vector2(2.0, 4.0), Vector2(rect.size.x - 4.0, 6.0)))
	draw_rect(rect.grow(-1.0), Color(HAZARD_ORANGE, 0.6), false, 1.0)
	if has_tank:
		var tank_center: Vector2 = rect.position + rect.size * Vector2(0.62, 0.6)
		var tank_radius: float = minf(rect.size.x, rect.size.y) * 0.24
		draw_circle(tank_center + Vector2(3.0, 4.0), tank_radius, Color(DEEP_SHADOW, 0.5))
		draw_circle(tank_center, tank_radius, CONCRETE_SHADOW.lerp(CONCRETE, 0.6))
		draw_circle(tank_center - Vector2(tank_radius, tank_radius) * 0.3, tank_radius * 0.45, CONCRETE_LIGHT)


func _draw_side_shade(top: float) -> void:
	# Darker at the sides so the middle of the screen reads first.
	var dark: Color = Color(0.0, 0.0, 0.0, 0.45)
	var clear: Color = Color(0.0, 0.0, 0.0, 0.0)
	var band: float = SIZE.x * 0.22
	var bottom: float = top + SIZE.y
	draw_polygon(
		PackedVector2Array([Vector2(0.0, top), Vector2(band, top), Vector2(band, bottom), Vector2(0.0, bottom)]),
		PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(
		PackedVector2Array([Vector2(SIZE.x - band, top), Vector2(SIZE.x, top), Vector2(SIZE.x, bottom), Vector2(SIZE.x - band, bottom)]),
		PackedColorArray([clear, dark, dark, clear]))


func _draw_haze(top: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = pattern_seed
	# Faint speed streaks and mist, scrolling faster than the ground for depth.
	for i: int in 24:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		var length: float = rng.randf_range(50.0, 160.0)
		draw_rect(Rect2(pos.x, top + pos.y, 1.5, length), Color(0.85, 0.85, 0.8, 0.04))
	for i: int in 8:
		var pos: Vector2 = Vector2(rng.randf_range(0.0, SIZE.x), rng.randf_range(0.0, SIZE.y))
		var radius: float = rng.randf_range(40.0, 90.0)
		for shift: float in _wrap_shifts(pos.y, radius):
			draw_circle(Vector2(pos.x, top + pos.y + shift), radius, Color(0.7, 0.72, 0.68, 0.025))


func _road_x(y: float) -> float:
	var t: float = y / SIZE.y * TAU
	return 290.0 + 110.0 * sin(t) + 40.0 * sin(t * 2.0)


## Irregular round outline centred on (0, 0).
func _blob(rng: RandomNumberGenerator, radius: float, points: int, jitter: float) -> PackedVector2Array:
	var outline: PackedVector2Array = PackedVector2Array()
	for i: int in points:
		var angle: float = TAU * i / points
		outline.append(Vector2.from_angle(angle) * radius * rng.randf_range(1.0 - jitter, 1.0 + jitter))
	return outline


func _draw_shape(outline: PackedVector2Array, center: Vector2, scale_factor: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(scale_factor, scale_factor))
	draw_colored_polygon(outline, color)


## Extra vertical offsets so a shape crossing the seam also shows on the other side.
func _wrap_shifts(y: float, extent: float) -> PackedFloat32Array:
	var shifts: PackedFloat32Array = PackedFloat32Array([0.0])
	if y - extent < 0.0:
		shifts.append(SIZE.y)
	elif y + extent > SIZE.y:
		shifts.append(-SIZE.y)
	return shifts


func _is_cleared(pos: Vector2, radius: float, cleared: Array[Vector3]) -> bool:
	for area: Vector3 in cleared:
		if pos.distance_to(Vector2(area.x, area.y)) < area.z + radius * 0.6:
			return true
	return false


func _draw_hazard_stripes(rect: Rect2) -> void:
	draw_rect(rect, HAZARD_DARK)
	var x: float = rect.position.x
	while x < rect.end.x - 6.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.end.y), Vector2(x + 4.0, rect.position.y),
			Vector2(x + 8.0, rect.position.y), Vector2(x + 4.0, rect.end.y)]),
			HAZARD_YELLOW)
		x += 10.0
