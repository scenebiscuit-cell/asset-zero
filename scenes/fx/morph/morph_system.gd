class_name MorphSystem
extends Node
## The one shared shape-tween system (DESIGN.md §5.3). Flows a set of Polygon2D nodes from whatever
## outline they have now to a target AirframeShape. Combat Morph, refit morphs, weight-class changes
## and Assimilate all go through this. Don't write a second one.
##
## It also runs the live metal: a slow ripple while the metal is liquid (Thresher form), tips that lag
## the body when the ship moves, a stretch on a dash, dents that heal and a shiver on a graze. All of
## that is an offset laid over the resting outline every frame, so a morph and the live metal stack.

## Fires every step of a morph or live deformation, so things that copy the outline (drop shadow) can follow.
signal shape_changed
signal morph_finished

## The node whose Polygon2D children get morphed.
@export var airframe_path: NodePath = ^"../Visual/Airframe"
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT
## Liquid metal flows, it doesn't slide: points move in a wave from nose to tail. 0 = all at once.
@export_range(0.0, 0.9) var flow_spread: float = 0.45
## How far each point bulges past its path on the way, like a ripple. 0 = none.
@export var ripple: float = 0.12

@export_group("Live metal")
## Resting ripple at full liquid (Thresher form), in pixels at the outline.
@export var liquid_amplitude: float = 1.4
## Ripple speed (radians per second) and length along the hull (pixels per wave). It travels nose to tail.
@export var liquid_speed: float = 7.0
@export var liquid_wavelength: float = 22.0
## Movement lag: the tips trail the body by this many pixels per 100 px/s of speed.
@export var flex: float = 1.5
## Speed above this adds no more lag, so a dash doesn't fold the ship in half.
@export var flex_max_speed: float = 320.0
## How fast the lag catches up (per second); lower is springier.
@export var flex_smoothing: float = 10.0
## How fast a dash stretch relaxes (per second).
@export var stretch_decay: float = 9.0
## A hit pushes the hull in around the impact: radius and depth in pixels, and the time to heal.
@export var dent_radius: float = 12.0
@export var dent_depth: float = 6.0
@export var dent_heal_time: float = 0.45
## Graze: a brief shiver through the metal.
@export var flinch_amplitude: float = 1.0
@export var flinch_time: float = 0.25
## Small, fine parts (tines, glow slits, wingtip lights) ripple as one piece, phased from their centre:
## a wave running through a 2 px tine would twist it inside out.
@export var rigid_parts: PackedStringArray = ["EdgeL", "EdgeR", "WingPanelL", "WingPanelR", "WingLightL", "WingLightR"]

const MAX_DENTS: int = 4

var _parts: Dictionary[String, Polygon2D] = {}
# The undeformed outline of every part: what the morph tween writes and the live metal reads.
var _rest: Dictionary[String, PackedVector2Array] = {}
var _from: Dictionary[String, PackedVector2Array] = {}
var _to: Dictionary[String, PackedVector2Array] = {}
# Scratch arrays reused every step so a morph never allocates per frame.
var _work: Dictionary[String, PackedVector2Array] = {}
var _out: Dictionary[String, PackedVector2Array] = {}
# When each point starts moving, 0..flow_spread of the morph.
var _delays: Dictionary[String, PackedFloat32Array] = {}
var _base_colors: Dictionary[String, Color] = {}
var _color_from: Dictionary[String, Color] = {}
var _color_to: Dictionary[String, Color] = {}
# Parts shrinking away this morph; emptied once it ends.
var _hiding: PackedStringArray = PackedStringArray()
var _tween: Tween

# Live metal state.
var _extent: float = 30.0
var _time: float = 0.0
var _liquid: float = 0.0
var _liquid_target: float = 0.0
var _liquid_rate: float = INF
var _velocity: Vector2 = Vector2.ZERO
var _lag: Vector2 = Vector2.ZERO
var _stretch_dir: Vector2 = Vector2.UP
var _stretch: float = 0.0
var _flinch: float = 0.0
var _dent_at: PackedVector2Array = PackedVector2Array()
var _dent_left: PackedFloat32Array = PackedFloat32Array()
var _dirty: bool = false
var _was_live: bool = false
var _presented_frame: int = -1


func _ready() -> void:
	var airframe: Node = get_node(airframe_path)
	for child: Node in airframe.get_children():
		if child is Polygon2D:
			var part: Polygon2D = child as Polygon2D
			_parts[child.name] = part
			_base_colors[child.name] = part.color
			_rest[child.name] = part.polygon
			_out[child.name] = PackedVector2Array()
	_update_extent()


## Jumps straight to a shape with no animation.
func snap_to(shape: AirframeShape) -> void:
	if _tween:
		_tween.kill()
	for part_name: String in shape.parts:
		if _parts.has(part_name):
			_rest[part_name] = shape.parts[part_name]
	for part_name: String in _parts:
		_parts[part_name].color = shape.part_colors.get(part_name, _base_colors[part_name])
	_update_extent()
	_present()


## Flows from the current outline to `shape` over `duration` seconds. Interrupting a morph
## in progress starts the new one from wherever the points are right now, so it never jumps.
func morph_to(shape: AirframeShape, duration: float) -> void:
	if _tween:
		_tween.kill()
	_from.clear()
	_to.clear()
	_work.clear()
	_delays.clear()
	_hiding.clear()
	_prepare_colors(shape)
	var top: float = INF
	var bottom: float = -INF
	for part_name: String in shape.parts:
		for point: Vector2 in shape.parts[part_name]:
			top = minf(top, point.y)
			bottom = maxf(bottom, point.y)
	var height: float = maxf(bottom - top, 1.0)
	for part_name: String in shape.parts:
		if not _parts.has(part_name):
			push_warning("MorphSystem: no Polygon2D named '%s' under %s" % [part_name, airframe_path])
			continue
		var current: PackedVector2Array = _rest[part_name]
		var target: PackedVector2Array = shape.parts[part_name]
		# An empty part is hidden: a new one grows out of its own centre (it extrudes from the hull),
		# a removed one shrinks into its centre and then empties.
		if target.size() < 3 and current.size() < 3:
			_rest[part_name] = target
			continue
		if target.size() < 3:
			target = collapsed(current)
			_hiding.append(part_name)
		elif current.size() < 3:
			current = collapsed(target)
		# Point counts must match to tween point-by-point; resample the shorter one if they don't.
		var count: int = maxi(current.size(), target.size())
		_from[part_name] = resample(current, count)
		_to[part_name] = resample(target, count)
		var work: PackedVector2Array = PackedVector2Array()
		work.resize(count)
		_work[part_name] = work
		var delays: PackedFloat32Array = PackedFloat32Array()
		delays.resize(count)
		for i: int in count:
			delays[i] = flow_spread * clampf((_to[part_name][i].y - top) / height, 0.0, 1.0)
		_delays[part_name] = delays
	_update_extent(shape.parts.get("Hull", PackedVector2Array()))
	_tween = create_tween()
	_tween.tween_method(_apply, 0.0, 1.0, duration).set_trans(transition).set_ease(easing)
	_tween.finished.connect(_on_tween_finished)


func _prepare_colors(shape: AirframeShape) -> void:
	_color_from.clear()
	_color_to.clear()
	for part_name: String in _parts:
		var target: Color = shape.part_colors.get(part_name, _base_colors[part_name])
		if _parts[part_name].color != target:
			_color_from[part_name] = _parts[part_name].color
			_color_to[part_name] = target


func is_morphing() -> bool:
	return _tween != null and _tween.is_running()


# ---------------- Live metal ----------------

## How liquid the metal is right now, 0 (locked armour) to 1 (Thresher form, fully flowing).
func liquid() -> float:
	return _liquid


## Unlocks (1) or locks (0) the metal over `duration` seconds; 0 = at once.
func set_liquid(amount: float, duration: float = 0.0) -> void:
	_liquid_target = clampf(amount, 0.0, 1.0)
	var distance: float = absf(_liquid_target - _liquid)
	_liquid_rate = INF if duration <= 0.0 or distance == 0.0 else distance / duration


## The ship's movement this frame, so the tips can trail the body. Call every physics frame.
func set_velocity(velocity: Vector2) -> void:
	_velocity = velocity


## Pulls the hull out along `direction` (a dash); `amount` is the fraction of the ship's length. Relaxes on its own.
func stretch_along(direction: Vector2, amount: float) -> void:
	if direction.length_squared() > 0.0:
		_stretch_dir = direction.normalized()
	_stretch = maxf(_stretch, amount)


## Pushes the hull in around `at` (airframe space, where the hit landed); heals over dent_heal_time.
func dent(at: Vector2) -> void:
	var slot: int = _dent_at.size()
	if slot >= MAX_DENTS:
		# Full: reuse the one closest to healed.
		slot = 0
		for i: int in _dent_left.size():
			if _dent_left[i] < _dent_left[slot]:
				slot = i
	else:
		_dent_at.append(Vector2.ZERO)
		_dent_left.append(0.0)
	_dent_at[slot] = at.limit_length(_extent)
	_dent_left[slot] = dent_heal_time


## A brief shiver through the metal (a graze).
func flinch() -> void:
	_flinch = 1.0


func _process(delta: float) -> void:
	_time += delta
	_liquid = move_toward(_liquid, _liquid_target, _liquid_rate * delta)
	var lag_target: Vector2 = _velocity.limit_length(flex_max_speed) * (flex / 100.0)
	_lag = _lag.lerp(lag_target, 1.0 - exp(-flex_smoothing * delta))
	_stretch *= exp(-stretch_decay * delta)
	if _stretch < 0.002:
		_stretch = 0.0
	_flinch = maxf(_flinch - delta / flinch_time, 0.0)
	for i: int in range(_dent_left.size() - 1, -1, -1):
		_dent_left[i] -= delta
		if _dent_left[i] <= 0.0:
			_dent_at.remove_at(i)
			_dent_left.remove_at(i)
	var live: bool = _is_live()
	# One last plain frame when the metal settles, so no offset is left behind.
	if (live or _was_live or _dirty) and _presented_frame != Engine.get_process_frames():
		_present()
	_was_live = live


func _is_live() -> bool:
	return _liquid > 0.001 or _lag.length_squared() > 0.01 or _stretch > 0.0 or _flinch > 0.0 \
			or not _dent_left.is_empty()


## The live-metal offset for one resting outline point. `phase_y` is the height the ripple phase is
## taken at: the point's own, or the part's centre for rigid parts.
func _offset(p: Vector2, phase_y: float) -> Vector2:
	# Tips (r near 1) trail the body; the centre barely moves.
	var r2: float = minf(p.length_squared() / (_extent * _extent), 1.0)
	var offset: Vector2 = -_lag * r2
	if _stretch > 0.0:
		var along: float = _stretch_dir.dot(p)
		var across: Vector2 = p - _stretch_dir * along
		offset += _stretch_dir * along * _stretch - across * _stretch * 0.4
	var amplitude: float = liquid_amplitude * _liquid + flinch_amplitude * _flinch
	if amplitude > 0.0:
		var phase: float = _time * liquid_speed + phase_y * TAU / liquid_wavelength
		# Fades out near the centreline, so thin parts straddling it (spine cores, barrel) don't twist.
		offset.x += clampf(p.x / 3.0, -1.0, 1.0) * amplitude * sin(phase)
		offset.y += amplitude * 0.35 * cos(phase * 0.7)
	for i: int in _dent_at.size():
		var distance: float = p.distance_to(_dent_at[i])
		if distance < dent_radius and p.length_squared() > 0.25:
			var depth: float = dent_depth * (_dent_left[i] / dent_heal_time) * (1.0 - distance / dent_radius)
			offset -= p.normalized() * depth
	return offset


## Writes the resting outlines, plus any live offset, into the Polygon2Ds.
func _present() -> void:
	_presented_frame = Engine.get_process_frames()
	_dirty = false
	var live: bool = _is_live()
	for part_name: String in _rest:
		var rest: PackedVector2Array = _rest[part_name]
		var polygon: Polygon2D = _parts[part_name]
		if rest.size() < 3:
			if not polygon.polygon.is_empty():
				polygon.polygon = PackedVector2Array()
			continue
		if not live:
			polygon.polygon = rest
			continue
		var out: PackedVector2Array = _out[part_name]
		if out.size() != rest.size():
			out.resize(rest.size())
		var rigid: bool = rigid_parts.has(part_name)
		var centre_y: float = 0.0
		if rigid:
			for point: Vector2 in rest:
				centre_y += point.y
			centre_y /= rest.size()
		for i: int in rest.size():
			out[i] = rest[i] + _offset(rest[i], centre_y if rigid else rest[i].y)
		# A wave can twist an outline for a frame; such a polygon can't be drawn, so show it undeformed
		# for that frame instead (never a stale one, which could be a half-morphed shape). Mid-morph the
		# undeformed outline can be twisted too; then the part keeps its last good frame.
		if not Geometry2D.triangulate_polygon(out).is_empty():
			polygon.polygon = out
		elif not Geometry2D.triangulate_polygon(rest).is_empty():
			polygon.polygon = rest
	shape_changed.emit()


## How far the hull reaches from the ship's centre; normalises the lag so every class flexes alike.
func _update_extent(hull: PackedVector2Array = PackedVector2Array()) -> void:
	if hull.is_empty():
		hull = _rest.get("Hull", PackedVector2Array())
	var farthest: float = 0.0
	for point: Vector2 in hull:
		farthest = maxf(farthest, point.length())
	_extent = maxf(farthest, 10.0)


func _apply(t: float) -> void:
	for part_name: String in _from:
		var a: PackedVector2Array = _from[part_name]
		var b: PackedVector2Array = _to[part_name]
		var out: PackedVector2Array = _work[part_name]
		var delays: PackedFloat32Array = _delays[part_name]
		for i: int in a.size():
			var point_t: float = clampf((t - delays[i]) / (1.0 - flow_spread), 0.0, 1.0)
			out[i] = a[i].lerp(b[i], point_t + ripple * sin(PI * point_t))
		_rest[part_name] = out
	for part_name: String in _color_from:
		_parts[part_name].color = _color_from[part_name].lerp(_color_to[part_name], t)
	_present()


func _on_tween_finished() -> void:
	for part_name: String in _from:
		_rest[part_name] = _to[part_name]
	for part_name: String in _hiding:
		_rest[part_name] = PackedVector2Array()
	_hiding.clear()
	_present()
	morph_finished.emit()


## Every point moved onto the outline's centre: the same outline, shrunk to nothing.
static func collapsed(points: PackedVector2Array) -> PackedVector2Array:
	var centre: Vector2 = Vector2.ZERO
	for point: Vector2 in points:
		centre += point
	centre /= points.size()
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(points.size())
	out.fill(centre)
	return out


## Spreads `count` points evenly around a closed outline. Lets two shapes with different point
## counts morph into each other (a refit can add a pylon without every shape needing the same count).
static func resample(points: PackedVector2Array, count: int) -> PackedVector2Array:
	if points.size() == count or points.size() < 2:
		return points
	var n: int = points.size()
	var edge_lengths: PackedFloat32Array = PackedFloat32Array()
	edge_lengths.resize(n)
	var perimeter: float = 0.0
	for i: int in n:
		edge_lengths[i] = points[i].distance_to(points[(i + 1) % n])
		perimeter += edge_lengths[i]
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(count)
	var edge: int = 0
	var edge_start: float = 0.0
	for k: int in count:
		var target: float = perimeter * k / count
		while edge < n - 1 and edge_start + edge_lengths[edge] < target:
			edge_start += edge_lengths[edge]
			edge += 1
		var along: float = 0.0 if edge_lengths[edge] == 0.0 else (target - edge_start) / edge_lengths[edge]
		out[k] = points[edge].lerp(points[(edge + 1) % n], clampf(along, 0.0, 1.0))
	return out
