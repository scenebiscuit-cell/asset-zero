class_name ClassCallout
extends CanvasLayer
## "CLASS UPGRADE: MEDIUM" (DESIGN.md §5.2) when XF-0 moves up a weight class: a banner slides down
## over the top of the screen, holds, and slides back up. Runs while paused, because upgrades
## happen on the Field Refit and Armory screens. Doesn't block input.

const NAME_KEYS: Array[String] = ["CLASS_NAME_LIGHT", "CLASS_NAME_MEDIUM", "CLASS_NAME_HEAVY", "CLASS_NAME_ASSAULT"]

@export var slide_time: float = 0.3
@export var hold_time: float = 2.2

var _tween: Tween

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Lines/Title
@onready var _bonus: Label = $Root/Lines/Bonus


func _ready() -> void:
	_root.position.y = -_root.size.y
	_root.visible = false
	Events.weight_class_changed.connect(show_callout)


func show_callout(weight_class: int) -> void:
	_title.text = tr(NAME_KEYS[weight_class])
	var speed_loss: int = roundi((1.0 - GameState.CLASS_SPEED[weight_class]) * 100.0)
	_bonus.text = tr("CLASS_BONUS") % [GameState.CLASS_ARMOR_BONUS[weight_class], speed_loss]
	AudioManager.play("overclock_on", -4.0)
	if _tween:
		_tween.kill()
	_root.visible = true
	_tween = create_tween()
	_tween.tween_property(_root, "position:y", 0.0, slide_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_time)
	_tween.tween_property(_root, "position:y", -_root.size.y, slide_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_root.hide)
