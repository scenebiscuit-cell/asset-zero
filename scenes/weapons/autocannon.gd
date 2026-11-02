class_name Autocannon
extends Node2D
## Nose weapon. Placed at the muzzle; the player tells it when to fire.

@export var data: WeaponData

var round_pool: RoundPool
var firing: bool = false
var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if not firing or round_pool == null:
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown <= 0.0:
		round_pool.fire(global_position, Vector2.UP * data.round_speed, data.damage)
		_cooldown += data.fire_interval
