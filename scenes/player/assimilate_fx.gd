class_name AssimilateFx
extends Node2D
## Assimilate effect (DESIGN.md §5.3, §10): the module's hexagon is pulled into the hull, a short
## hit-stop, then the hull ripples like liquid. The Player mounts the module on `absorbed`.

signal absorbed

@export var absorb_time: float = 0.18
## Real seconds the game runs in slow motion at the moment of absorbing.
@export var hit_stop_time: float = 0.07
@export var hit_stop_scale: float = 0.05
@export var ripple_time: float = 0.3
@export var airframe_path: NodePath = ^"../Airframe"

@onready var _hex: Polygon2D = $Hex
@onready var _airframe: Node2D = get_node(airframe_path)


func _ready() -> void:
	_hex.visible = false


func play(color: Color) -> void:
	_hex.color = Color(color, 0.9)
	_hex.scale = Vector2.ONE * 1.8
	_hex.visible = true
	AudioManager.play("assimilate", -4.0)
	var tween: Tween = create_tween()
	tween.tween_property(_hex, "scale", Vector2.ONE * 0.15, absorb_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_hit_stop)


func _hit_stop() -> void:
	_hex.visible = false
	Engine.time_scale = hit_stop_scale
	# Real time, and runs even if the game is paused, so slow motion can never get stuck on.
	get_tree().create_timer(hit_stop_time, true, false, true).timeout.connect(_end_hit_stop)


func _end_hit_stop() -> void:
	Engine.time_scale = 1.0
	absorbed.emit()
	var tween: Tween = create_tween()
	tween.tween_property(_airframe, "scale", Vector2(1.18, 0.88), ripple_time * 0.3)
	tween.tween_property(_airframe, "scale", Vector2(0.94, 1.06), ripple_time * 0.3)
	tween.tween_property(_airframe, "scale", Vector2.ONE, ripple_time * 0.4)
