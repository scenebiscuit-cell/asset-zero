class_name Player
extends Area2D
## XF-0. Handles movement only for now.

enum InputMode { KEYBOARD, MOUSE }

@export var move_speed: float = 300.0
## Keeps the airframe visual fully on screen, not just its centre.
@export var screen_margin: Vector2 = Vector2(26.0, 36.0)

var _input_mode: InputMode = InputMode.KEYBOARD


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_input_mode = InputMode.MOUSE


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_input_mode = InputMode.KEYBOARD

	if _input_mode == InputMode.KEYBOARD:
		position += direction * move_speed * delta
	else:
		# Capped at move_speed so mouse play isn't faster than keyboard.
		position = position.move_toward(get_global_mouse_position(), move_speed * delta)

	_clamp_to_screen()


func _clamp_to_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	position = position.clamp(screen_margin, screen - screen_margin)
