class_name Player
extends Area2D
## XF-0. Moves and tells its weapons when to fire.

enum InputMode { KEYBOARD, MOUSE }

@export var move_speed: float = 300.0
## Keeps the airframe visual fully on screen, not just its centre.
@export var screen_margin: Vector2 = Vector2(26.0, 36.0)
## Set by whatever scene the player is placed in; rounds live there, not on the ship.
@export var round_pool: RoundPool

## Turned on by Fire Control power-ups or the accessibility setting (DESIGN.md §7.3), never by a key.
var autofire: bool = false
var _input_mode: InputMode = InputMode.KEYBOARD

@onready var _autocannon: Autocannon = $Autocannon


func _ready() -> void:
	_autocannon.round_pool = round_pool


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
	_autocannon.firing = autofire or Input.is_action_pressed("fire")


func _clamp_to_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	position = position.clamp(screen_margin, screen - screen_margin)
