class_name StrikeFlash
extends CanvasLayer
## Full-screen white flash for a Saturation Strike. Sits under the HUD so the readouts stay legible.

@export var peak_alpha: float = 0.85
@export var fade_time: float = 0.6

var _tween: Tween

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	_visual.modulate.a = 0.0


func play() -> void:
	if _tween != null:
		_tween.kill()
	_visual.modulate.a = peak_alpha
	_tween = create_tween()
	_tween.tween_property(_visual, "modulate:a", 0.0, fade_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
