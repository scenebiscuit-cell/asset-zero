class_name RadarDome
extends Enemy
## Radar dome on a background barracks or SAM site. No attack: a small target worth a little salvage.
## Spawned by the Level when its base scrolls into view, so it stays lined up with the base.

@export var blink_interval: float = 0.6

var _blink: float = 0.0

@onready var _light: Node2D = $Visual/Light


func _tick(delta: float) -> void:
	_blink += delta
	_light.visible = fmod(_blink, blink_interval * 2.0) < blink_interval
