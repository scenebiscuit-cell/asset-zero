class_name DropShadow
extends Node2D
## Dark copy of an air unit's shape, cast down-right onto the ground (light comes from the top-left).
## Give this node a z_index between the terrain and the air units (terrain -10, shadows -8, haze -5).
## Ground units don't get one: the shadow is what tells the player something is airborne.

@export var shadow_offset: Vector2 = Vector2(10.0, 14.0)
@export var shadow_color: Color = Color(0.02, 0.03, 0.02, 0.45)
@export var source_path: NodePath = ^"../Visual"
## Which Polygon2D children of the source cast a shadow. Empty = all of them.
## Pick shapes that don't overlap, or the overlaps show up as darker patches.
@export var shape_names: PackedStringArray = PackedStringArray()

var _polygons: Array[PackedVector2Array] = []


func _ready() -> void:
	position = shadow_offset
	refresh()


## Re-reads the outline. Call after the shape changes (e.g. from the morph system).
func refresh() -> void:
	_polygons.clear()
	var source: Node2D = get_node(source_path) as Node2D
	for child: Node in source.get_children():
		var shape: Polygon2D = child as Polygon2D
		if shape == null or not shape.visible:
			continue
		if not shape_names.is_empty() and not shape_names.has(shape.name):
			continue
		_polygons.append((source.transform * shape.transform) * shape.polygon)
	queue_redraw()


func _draw() -> void:
	for outline: PackedVector2Array in _polygons:
		draw_colored_polygon(outline, shadow_color)
