class_name WeaponIcon
extends Control
## Small HUD picture of a weapon, drawn in code from its data (placeholder art, no image files):
## tracer streams per barrel, a cyan beam, straight rockets, a curving seeker, or a module hexagon.

const TRACER: Color = Color(0.94, 0.925, 0.88)
const BEAM_CORE: Color = Color(0.91, 1.0, 1.0)
const BEAM_GLOW: Color = Color(0.25, 0.85, 0.82, 0.45)
const MISSILE: Color = Color(0.78, 0.8, 0.82)
const EXHAUST: Color = Color(1.0, 0.7, 0.3)
const SMOKE: Color = Color(0.55, 0.56, 0.58, 0.8)
const EMPTY: Color = Color(1.0, 1.0, 1.0, 0.2)

## The weapon to draw, or null for an empty hardpoint.
var weapon: WeaponData:
	set(new_weapon):
		if new_weapon == weapon:
			return
		weapon = new_weapon
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.1, 1.0))
	if weapon is ModuleData:
		_draw_module(weapon as ModuleData)
	elif weapon is GunData:
		_draw_gun(weapon as GunData)
	elif weapon is BeamData:
		_draw_beam()
	elif weapon is MissileData:
		_draw_missiles(weapon as MissileData)
	else:
		draw_rect(Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0)), EMPTY, false, 1.0)


func _draw_gun(gun: GunData) -> void:
	var spacing: float = 6.0
	for i: int in gun.barrel_count:
		var x: float = size.x * 0.5 + (i - (gun.barrel_count - 1) * 0.5) * spacing
		draw_line(Vector2(x, size.y - 5.0), Vector2(x, 5.0), Color(TRACER, 0.55), 1.0)
		draw_line(Vector2(x, 8.0), Vector2(x, 3.0), TRACER, 2.0)
		draw_rect(Rect2(x - 1.5, size.y - 6.0, 3.0, 4.0), MISSILE)


func _draw_beam() -> void:
	var x: float = size.x * 0.5
	draw_line(Vector2(x, size.y - 4.0), Vector2(x, 2.0), BEAM_GLOW, 6.0)
	draw_line(Vector2(x, size.y - 4.0), Vector2(x, 2.0), BEAM_CORE, 2.0)
	draw_circle(Vector2(x, size.y - 4.0), 2.5, BEAM_CORE)


func _draw_missiles(missile: MissileData) -> void:
	if missile.homing:
		# One seeker curving in from the side, with its smoke trail.
		var center: Vector2 = Vector2(size.x - 4.0, size.y - 2.0)
		draw_arc(center, size.x * 0.55, PI, PI * 1.45, 8, SMOKE, 1.0)
		_draw_rocket(Vector2(size.x * 0.5 + 1.0, 7.0), 0.5)
		return
	# Two straight rockets side by side.
	for x: float in [size.x * 0.32, size.x * 0.68]:
		draw_line(Vector2(x, size.y - 2.0), Vector2(x, 12.0), SMOKE, 1.0)
		_draw_rocket(Vector2(x, 7.0), 0.0)


func _draw_rocket(tip: Vector2, tilt: float) -> void:
	var forward: Vector2 = Vector2.UP.rotated(tilt)
	var side: Vector2 = forward.orthogonal() * 1.5
	var tail: Vector2 = tip - forward * 8.0
	draw_colored_polygon(PackedVector2Array([tip, tail + side, tail - side]), MISSILE)
	draw_line(tail, tail - forward * 3.0, EXHAUST, 2.0)


## A glowing hexagon in the module's colour with a small sign for what it does.
func _draw_module(module: ModuleData) -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.45
	var hexagon: PackedVector2Array = PackedVector2Array()
	for i: int in 6:
		hexagon.append(center + Vector2.from_angle(PI / 6.0 + i * PI / 3.0) * radius)
	draw_colored_polygon(hexagon, Color(module.color, 0.25))
	hexagon.append(hexagon[0]) # Closes the outline.
	draw_polyline(hexagon, module.color, 1.5)
	var sign_color: Color = module.color.lerp(Color.WHITE, 0.5)
	if module is SpreadCannonData:
		for i: int in 5:
			var angle: float = -PI / 2.0 + (i - 2) * 0.35
			draw_line(center + Vector2(0.0, radius * 0.45), center + Vector2.from_angle(angle) * radius * 0.6, sign_color, 1.0)
	elif module is FlakBurstData:
		draw_circle(center + Vector2(0.0, -2.0), radius * 0.22, sign_color)
		for i: int in 8:
			var ray: Vector2 = Vector2.from_angle(i * PI / 4.0)
			draw_line(center + Vector2(0.0, -2.0) + ray * radius * 0.3, center + Vector2(0.0, -2.0) + ray * radius * 0.5, sign_color, 1.0)
	elif module is DrillLanceData:
		var drill: PackedVector2Array = PackedVector2Array([center + Vector2(-radius * 0.3, radius * 0.5),
				center + Vector2(radius * 0.3, radius * 0.5), center + Vector2(0.0, -radius * 0.65)])
		draw_colored_polygon(drill, sign_color)
		for i: int in 3:
			var y: float = radius * (0.3 - i * 0.3)
			draw_line(center + Vector2(-radius * 0.2, y), center + Vector2(radius * 0.2, y - 2.0), module.color, 1.0)
	elif module is DroneBayData:
		# Two little drones circling a dot.
		draw_arc(center, radius * 0.45, 0.0, TAU, 16, Color(module.color, 0.6), 1.0)
		for side: float in [-1.0, 1.0]:
			var at: Vector2 = center + Vector2(radius * 0.45 * side, 0.0)
			draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -3.5), at + Vector2(3.0, 2.5), at + Vector2(-3.0, 2.5)]), sign_color)
		draw_circle(center, 1.5, sign_color)
	else:
		draw_circle(center, radius * 0.25, sign_color)
