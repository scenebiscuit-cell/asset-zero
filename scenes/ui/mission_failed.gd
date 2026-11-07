class_name MissionFailedScreen
extends CanvasLayer
## Shown when XF-0 is destroyed. Any key or click restarts the level.

## Stops a fire key that was held at the moment of death from skipping the screen.
@export var input_delay: float = 0.6

var _accepting_input: bool = false


func _ready() -> void:
	visible = false


func show_screen() -> void:
	visible = true
	await get_tree().create_timer(input_delay).timeout
	_accepting_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
		_accepting_input = false
		GameState.end_run()
		# Reloading rebuilds the level, so no rounds, enemies or pickups carry over.
		get_tree().reload_current_scene()
