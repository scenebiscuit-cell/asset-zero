class_name Explosion
extends Node2D
## One-shot placeholder explosion. Frees itself once the sparks are done.

@export var flash_time: float = 0.12

var _age: float = 0.0

@onready var _sparks: CPUParticles2D = $Visual/Sparks
@onready var _flash: Polygon2D = $Visual/Flash


func _ready() -> void:
	_sparks.finished.connect(queue_free)
	_sparks.emitting = true


func _process(delta: float) -> void:
	_age += delta
	var t: float = _age / flash_time
	_flash.scale = Vector2.ONE * (1.0 + t)
	_flash.modulate.a = 1.0 - t
	if t >= 1.0:
		_flash.visible = false
		set_process(false)
