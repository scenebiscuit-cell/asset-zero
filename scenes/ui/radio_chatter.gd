class_name RadioChatter
extends CanvasLayer
## Radio-chatter pop-ups (DESIGN.md §9.1, §11): one line of HSD traffic typed out on a strip under
## the top console, held, then faded. Runs while paused, because Threat rises on the refit screens.
## Doesn't block input. Any later chatter line goes through say().

## Wait before the Threat line, so it follows the CLASS UPGRADE banner instead of fighting it.
@export var threat_delay: float = 1.2
@export var type_time: float = 0.9
@export var hold_time: float = 3.0
@export var fade_time: float = 0.5

var _tween: Tween
var _pending: String = ""

@onready var _panel: Control = $Panel
@onready var _line: Label = $Panel/Line


func _ready() -> void:
	_panel.modulate.a = 0.0
	Events.threat_level_changed.connect(_on_threat_level_changed)


func _on_threat_level_changed(_threat_level: int) -> void:
	say(tr("RADIO_THREAT_RISE"), threat_delay, "threat_alarm")


## Types out `text` after `wait` seconds, playing `sound` (an AudioManager name) as it starts.
func say(text: String, wait: float = 0.0, sound: String = "") -> void:
	if _tween:
		_tween.kill()
	_pending = text
	_tween = create_tween()
	_tween.tween_interval(maxf(wait, 0.0))
	_tween.tween_callback(_begin.bind(sound))
	_tween.tween_property(_line, "visible_ratio", 1.0, type_time)
	_tween.tween_interval(hold_time)
	_tween.tween_property(_panel, "modulate:a", 0.0, fade_time)


func _begin(sound: String) -> void:
	_line.text = _pending
	_line.visible_ratio = 0.0
	_panel.modulate.a = 1.0
	if sound != "":
		AudioManager.play(sound, -6.0)
