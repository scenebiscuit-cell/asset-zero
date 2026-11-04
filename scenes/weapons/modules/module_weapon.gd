class_name ModuleWeapon
extends Weapon
## Base for assimilated modules on the Salvage Mount. Extrudes out of the hull when mounted
## (DESIGN.md §5.3) and colours its pod with the module's glow.

@export var extrude_time: float = 0.25

var module: ModuleData

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	module = data as ModuleData
	_visual.modulate = Color(module.color, 1.0).lerp(Color.WHITE, 0.35)
	_visual.scale = Vector2(0.1, 0.1)
	create_tween().tween_property(_visual, "scale", Vector2.ONE, extrude_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
