class_name EliteOutline
extends Node2D
## Yellow halo around every shape in an elite's Visual (DESIGN.md §5.8). Added in code by Enemy,
## so enemy scenes don't need to know about it. Redraws each frame so turrets that rotate stay outlined.

@export var color: Color = Color(1.0, 0.85, 0.2, 0.95)
@export var width: float = 5.0

var source: Node2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if source == null:
		return
	_draw_branch(source, Transform2D.IDENTITY)


func _draw_branch(node: Node, xform: Transform2D) -> void:
	for child: Node in node.get_children():
		var item: Node2D = child as Node2D
		if item == null or not item.visible:
			continue
		var child_xform: Transform2D = xform * item.transform
		# Painted-on shadows aren't part of the machine, so they get no outline.
		if item is Polygon2D and not String(item.name).contains("Shadow"):
			var outline: PackedVector2Array = child_xform * (item as Polygon2D).polygon
			outline.append(outline[0]) # Close the loop.
			draw_polyline(outline, color, width)
		_draw_branch(item, child_xform)
