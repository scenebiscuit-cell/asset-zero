extends Node2D
## Test only: fires aimed enemy rounds at the player so damage can be tried before real shooters exist.

@export var round_pool: RoundPool
@export var target: Node2D
@export var fire_interval: float = 0.5
@export var round_speed: float = 220.0
@export var damage: int = 10

var _cooldown: float = 1.0


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0 or not is_instance_valid(target):
		return
	_cooldown += fire_interval
	var aim: Vector2 = global_position.direction_to(target.global_position)
	round_pool.fire(global_position, aim * round_speed, damage)
