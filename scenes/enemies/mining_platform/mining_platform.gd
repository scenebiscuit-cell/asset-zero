class_name MiningPlatform
extends Enemy
## Mining Platform: big ground rig with no attack. Tanky, worth a lot of salvage. Its drill keeps spinning.

@export var drill_spin_speed: float = 2.5

@onready var _drill: Node2D = $Visual/Drill


func _tick(delta: float) -> void:
	_drill.rotation += drill_spin_speed * delta
