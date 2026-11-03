class_name PauseMenu
extends CanvasLayer
## Esc / P pauses. Keeps running while the game is paused (process_mode ALWAYS in the scene).
## "Abort mission" ends the run; it returns to the main menu once that exists (Step 17).

## Turned off by the Level while MISSION FAILED or SECTOR CLEAR is up.
var allowed: bool = true

@onready var _resume: Button = $Root/Panel/Lines/Resume
@onready var _abort: Button = $Root/Panel/Lines/Abort


func _ready() -> void:
	visible = false
	_resume.pressed.connect(_close)
	_abort.pressed.connect(_abort_mission)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		_close()
	elif allowed:
		_open()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Pause automatically if the window (or browser tab) loses focus mid-fight.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and allowed and not visible:
		_open()


func _open() -> void:
	visible = true
	get_tree().paused = true
	_resume.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false


func _abort_mission() -> void:
	get_tree().paused = false
	GameState.end_run()
	get_tree().reload_current_scene()
