class_name BackgroundLayer
extends Node2D
## Placeholder scrolling terrain in the Verdance palette (DESIGN.md §11.8). The pattern repeats
## every screen height, is drawn once as two stacked copies, and the node just slides down and wraps.
## Light comes from the top-left: raised things get a highlight up-left and a shadow down-right.

enum Style { GROUND, HAZE }

## A radar dome on a base is about to scroll onto the screen at `at` (global). The Level spawns a
## destructible dome there, so it scrolls in with the base. Only the GROUND style sends this.
signal dome_entering(at: Vector2)

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
const ROOF: Color = Color("4d5246")
const ROOF_LIGHT: Color = Color("646a5a")
const SANDBAG: Color = Color("7a6a4c")
const MISSILE: Color = Color("c8c6bc")
## Domes are spawned this far above the screen, so they never pop in.
const DOME_SPAWN_MARGIN: float = 30.0

@export var style: Style = Style.GROUND
@export var scroll_speed: float = 60.0
@export var pattern_seed: int = 471
@export var pit_count: int = 2
@export var canopy_count: int = 90
@export var structure_count: int = 3
## Chance (0-1) each base is a SAM site rather than a barracks compound.
@export_range(0.0, 1.0) var sam_chance: float = 0.45

## Radar dome spots in pattern space (0..SIZE), filled while drawing.
var _dome_points: PackedVector2Array = PackedVector2Array()
## Each dome's last scroll position, to spot when it crosses the top edge.
var _dome_scroll: PackedFloat32Array = PackedFloat32Array()
var _domes_seeded: bool = false


func _process(delta: float) -> void:
	position.y = fposmod(position.y + scroll_speed * delta, SIZE.y)
	_update_domes()


## Each pattern point is drawn twice: at p.y + position.y (lower copy) and SIZE.y higher (upper copy).
## A dome enters when its upper copy scrolls past the top edge.
func _update_domes() -> void:
	if _dome_points.is_empty():
		return
	var edge: float = -DOME_SPAWN_MARGIN
	# Screen positions below already include the scroll, so add only where the layer's parent sits.
	var origin: Vector2 = global_position - position
	if not _domes_seeded:
		# First frame: bases already on screen get their domes straight away.
		_domes_seeded = true
		_dome_scroll.resize(_dome_points.size())
		for i: int in _dome_points.size():
			var point: Vector2 = _dome_points[i]
			var upper: float = point.y + position.y - SIZE.y
			_dome_scroll[i] = upper
			if upper + SIZE.y < SIZE.y:
				dome_entering.emit(origin + Vector2(point.x, upper + SIZE.y))
			if upper >= edge:
				dome_entering.emit(origin + Vector2(point.x, upper))
		return
	for i: int in _dome_points.size():
		var point: Vector2 = _dome_points[i]
		var upper: float = point.y + position.y - SIZE.y
		var before: float = _dome_scroll[i]
		_dome_scroll[i] = upper
		# When the layer wraps, the upper copy jumps up a whole screen; that's not an entry,
		# unless the dome sits so low in the pattern that it lands inside the top margin.
		var wrapped: bool = upper < before
		var entered: bool = (wrapped and upper >= edge) or (not wrapped and before < edge and upper >= edge)
		if entered:
			dome_entering.emit(origin + Vector2(point.x, upper))


func _draw() -> void:
	for copy_top: float in [0.0, -SIZE.y]:
		if style == Style.GROUND:
			_draw_ground(copy_top)
		else:
			_draw_haze(copy_top)
	draw_set_transform(Vector2.ZERO)


func _draw_ground(top: float) -> void:
	if top == 0.0:
		_dome_points.clear()
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
		var size: Vector2 = Vector2(rng.randf_range(64.0, 84.0), rng.randf_range(50.0, 62.0))
		var pad_y: float = (i + 0.3) * SIZE.y / structure_count + rng.randf_range(-40.0, 40.0)
		var road_x: float = _road_x(pad_y)
		var pad_x: float = road_x + 30.0 if road_x < SIZE.x * 0.5 else road_x - 30.0 - size.x
		var is_sam: bool = rng.randf() < sam_chance
		var rect: Rect2 = Rect2(pad_x, pad_y, size.x, size.y)
		if top == 0.0:
			_dome_points.append(_sam_dome(rect) if is_sam else _barracks_dome(rect))
		for shift: float in _wrap_shifts(pad_y + size.y * 0.5, size.y):
			var placed: Rect2 = Rect2(rect.position + Vector2(0.0, top + shift), rect.size)
			if is_sam:
				_draw_sam_site(placed, _sam_dome(placed))
			else:
				_draw_barracks(placed, _barracks_dome(placed))

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


func _barracks_dome(rect: Rect2) -> Vector2:
	return rect.position + Vector2(rect.size.x - 13.0, 14.0)


func _sam_dome(rect: Rect2) -> Vector2:
	return rect.position + Vector2(rect.size.x - 10.0, rect.size.y - 10.0)


## Fenced compound with two long barracks huts. The radar dome is a destructible enemy, so only
## its mount ring is painted here; a destroyed dome leaves the bare mount behind.
func _draw_barracks(rect: Rect2, dome: Vector2) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_rect(rect, Color(CONCRETE_SHADOW, 0.55))
	_draw_dashed_rect(rect.grow(-1.0), Color(CONCRETE_LIGHT, 0.7))
	var hut_h: float = (rect.size.y - 14.0) * 0.5
	for row: int in 2:
		var hut: Rect2 = Rect2(rect.position + Vector2(5.0, 5.0 + row * (hut_h + 4.0)), Vector2(rect.size.x - 10.0, hut_h))
		draw_rect(Rect2(hut.position + Vector2(4.0, 5.0), hut.size), Color(DEEP_SHADOW, 0.6))
		# Pitched roof: lit top half, shaded bottom half, ridge line between.
		draw_rect(Rect2(hut.position, Vector2(hut.size.x, hut.size.y * 0.5)), ROOF_LIGHT)
		draw_rect(Rect2(hut.position + Vector2(0.0, hut.size.y * 0.5), Vector2(hut.size.x, hut.size.y * 0.5)), ROOF)
		draw_line(Vector2(hut.position.x, hut.get_center().y), Vector2(hut.end.x, hut.get_center().y), CONCRETE_SHADOW, 1.0)
		var x: float = hut.position.x + 6.0
		while x < hut.end.x - 2.0:
			draw_line(Vector2(x, hut.position.y + 1.0), Vector2(x, hut.end.y - 1.0), Color(CONCRETE_SHADOW, 0.35), 1.0)
			x += 6.0
	_draw_dome_mount(dome)


## Round pad ringed with sandbags, a launcher with four missiles, and a radar dome on a control hut.
func _draw_sam_site(rect: Rect2, dome: Vector2) -> void:
	draw_set_transform(Vector2.ZERO)
	var center: Vector2 = rect.get_center() - Vector2(6.0, 4.0)
	var radius: float = minf(rect.size.x, rect.size.y) * 0.42
	draw_circle(center + Vector2(4.0, 5.0), radius + 4.0, Color(DEEP_SHADOW, 0.5))
	draw_circle(center, radius + 4.0, SANDBAG.darkened(0.35))
	for i: int in 16:
		var bag: Vector2 = center + Vector2.from_angle(TAU * i / 16.0) * (radius + 1.5)
		draw_circle(bag, 3.2, SANDBAG if i % 2 == 0 else SANDBAG.lightened(0.12))
	draw_circle(center, radius - 2.0, CONCRETE)
	draw_circle(center - Vector2(2.0, 2.0), radius - 5.0, CONCRETE_LIGHT.lerp(CONCRETE, 0.6))
	# Launcher on its turntable, angled up-screen.
	draw_set_transform(center, -0.35)
	draw_circle(Vector2.ZERO, 8.0, CONCRETE_SHADOW)
	draw_rect(Rect2(-10.0, -4.0, 20.0, 9.0), HAZARD_DARK)
	for i: int in 4:
		var x: float = -9.0 + i * 5.0
		draw_rect(Rect2(x, -18.0, 3.0, 16.0), MISSILE)
		draw_rect(Rect2(x, -20.0, 3.0, 3.0), HAZARD_ORANGE)
	draw_set_transform(Vector2.ZERO)
	# Control hut under the radar dome.
	var hut: Rect2 = Rect2(dome - Vector2(10.0, 9.0), Vector2(20.0, 18.0))
	draw_rect(Rect2(hut.position + Vector2(3.0, 4.0), hut.size), Color(DEEP_SHADOW, 0.6))
	draw_rect(hut, CONCRETE)
	draw_rect(Rect2(hut.position, Vector2(hut.size.x, 2.0)), CONCRETE_LIGHT)
	_draw_dome_mount(dome)


func _draw_dome_mount(at: Vector2) -> void:
	draw_circle(at, 8.5, CONCRETE_SHADOW)
	draw_arc(at, 8.5, 0.0, TAU, 16, Color(HAZARD_YELLOW, 0.5), 1.0)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners: PackedVector2Array = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for i: int in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 1.0, 3.0)


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
