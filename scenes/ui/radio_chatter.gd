class_name RadioChatter
extends CanvasLayer
## Radio-chatter pop-ups (DESIGN.md §9.1, §11): one line of HSD traffic typed out on a strip under
## the top console, held, then faded. Runs while paused, because Threat rises on the refit screens.
## Doesn't block input. Any later chatter line goes through say().
##
## A line is remembered in GameState until it has finished showing: Threat rises on the Field Refit
## screen, and the Level reloads for the next sector, so the strip that started it may not live to
## finish it. The next sector's strip picks the line up.

## Wait before the Threat line, so it follows the CLASS UPGRADE banner instead of fighting it.
@export var threat_delay: float = 1.6
@export var type_time: float = 0.9
@export var hold_time: float = 3.0
@export var fade_time: float = 0.5

var _tween: Tween
var _key: String = ""

@onready var _panel: Control = $Panel
@onready var _line: Label = $Panel/Line


func _ready() -> void:
	_panel.modulate.a = 0.0
	Events.threat_level_changed.connect(_on_threat_level_changed)
	if GameState.pending_chatter != "":
		say(GameState.pending_chatter, threat_delay, GameState.pending_chatter_sound)


func _on_threat_level_changed(_threat_level: int) -> void:
	say("RADIO_THREAT_RISE", threat_delay, "threat_alarm")


## Types out the line with translation key `key` after `wait` seconds, playing `sound` (an
## AudioManager name) as it starts. A new line replaces one still showing.
func say(key: String, wait: float = 0.0, sound: String = "") -> void:
	if _tween:
		_tween.kill()
	_key = key
	GameState.pending_chatter = key
	GameState.pending_chatter_sound = sound
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_interval(maxf(wait, 0.0))
	_tween.tween_callback(_begin.bind(sound))
	_tween.tween_property(_line, "visible_ratio", 1.0, type_time)
	_tween.tween_interval(hold_time)
	_tween.tween_property(_panel, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(_finish)


func _begin(sound: String) -> void:
	_line.text = tr(_key)
	_line.visible_ratio = 0.0
	_panel.modulate.a = 1.0
	if sound != "":
		AudioManager.play(sound, -6.0)


func _finish() -> void:
	if GameState.pending_chatter == _key:
		GameState.pending_chatter = ""
		GameState.pending_chatter_sound = ""
