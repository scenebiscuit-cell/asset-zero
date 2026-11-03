extends Node2D
## Test only: rotating spiral of enemy rounds for trying grazing and Overclock.
## F1 fills the Overclock meter so it can be triggered straight away.

@export var round_pool: RoundPool
@export var arms: int = 3
@export var interval: float = 0.12
## Radians per second the spiral turns.
@export var spin_speed: float = 1.3
@export var round_speed: float = 150.0
@export var damage: int = 10

var _cooldown: float = 1.0
var _angle: float = 0.0


func _ready() -> void:
	print("Overclock test: graze the spiral to charge the meter. F1 = fill meter, E = Overclock.")


func _physics_process(delta: float) -> void:
	_angle += spin_speed * delta
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown += interval
	for i: int in arms:
		round_pool.fire(global_position, Vector2.from_angle(_angle + TAU * i / arms) * round_speed, damage)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F1:
		GameState.overclock = GameState.OVERCLOCK_MAX
