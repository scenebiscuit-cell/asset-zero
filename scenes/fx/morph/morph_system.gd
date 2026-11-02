class_name MorphSystem
extends Node
## The one shared shape-tween system (DESIGN.md §5.3). Flows a set of Polygon2D nodes from whatever
## outline they have now to a target AirframeShape. Combat Morph, refit morphs, weight-class changes
## and Assimilate all go through this. Don't write a second one.

## Fires every step of a morph, so things that copy the outline (drop shadow) can follow.
signal shape_changed
signal morph_finished

## The node whose Polygon2D children get morphed.
@export var airframe_path: NodePath = ^"../Visual/Airframe"
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT

var _parts: Dictionary[String, Polygon2D] = {}
var _from: Dictionary[String, PackedVector2Array] = {}
var _to: Dictionary[String, PackedVector2Array] = {}
# Scratch arrays reused every step so a morph never allocates per frame.
var _work: Dictionary[String, PackedVector2Array] = {}
var _tween: Tween


func _ready() -> void:
	var airframe: Node = get_node(airframe_path)
	for child: Node in airframe.get_children():
		if child is Polygon2D:
			_parts[child.name] = child as Polygon2D


## Jumps straight to a shape with no animation.
func snap_to(shape: AirframeShape) -> void:
	if _tween:
		_tween.kill()
	for part_name: String in shape.parts:
		if _parts.has(part_name):
			_parts[part_name].polygon = shape.parts[part_name]
	shape_changed.emit()


## Flows from the current outline to `shape` over `duration` seconds. Interrupting a morph
## in progress starts the new one from wherever the points are right now, so it never jumps.
func morph_to(shape: AirframeShape, duration: float) -> void:
	if _tween:
		_tween.kill()
	_from.clear()
	_to.clear()
	_work.clear()
	for part_name: String in shape.parts:
		if not _parts.has(part_name):
			push_warning("MorphSystem: no Polygon2D named '%s' under %s" % [part_name, airframe_path])
			continue
		var current: PackedVector2Array = _parts[part_name].polygon
		var target: PackedVector2Array = shape.parts[part_name]
		# Point counts must match to tween point-by-point; resample the shorter one if they don't.
		var count: int = maxi(current.size(), target.size())
		_from[part_name] = resample(current, count)
		_to[part_name] = resample(target, count)
		var work: PackedVector2Array = PackedVector2Array()
		work.resize(count)
		_work[part_name] = work
	_tween = create_tween()
	_tween.tween_method(_apply, 0.0, 1.0, duration).set_trans(transition).set_ease(easing)
	_tween.finished.connect(_on_tween_finished)


func is_morphing() -> bool:
	return _tween != null and _tween.is_running()


func _apply(t: float) -> void:
	for part_name: String in _from:
		var a: PackedVector2Array = _from[part_name]
		var b: PackedVector2Array = _to[part_name]
		var out: PackedVector2Array = _work[part_name]
		for i: int in a.size():
			out[i] = a[i].lerp(b[i], t)
		_parts[part_name].polygon = out
	shape_changed.emit()


func _on_tween_finished() -> void:
	morph_finished.emit()


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
