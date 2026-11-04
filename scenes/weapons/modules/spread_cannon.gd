class_name SpreadCannon
extends ModuleWeapon
## Spread Cannon module (DESIGN.md §5.8): 5-way fan in Gunship form, 5 rounds stacked in a tight
## line in Lance form.

var _spread: SpreadCannonData
var _cooldown: float = 0.0


func _ready() -> void:
	super()
	_spread = data as SpreadCannonData


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if not firing or not enabled or round_pool == null:
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown > 0.0:
		return
	_cooldown += _spread.fire_interval
	var damage: int = scaled_damage(_spread.damage)
	for i: int in _spread.rounds:
		var start: Vector2 = global_position
		var direction: Vector2 = Vector2.UP
		if converged:
			# Stacked nose to tail, so the whole line lands on one target.
			start.y += i * _spread.lance_spacing
		elif _spread.rounds > 1:
			var t: float = float(i) / (_spread.rounds - 1) - 0.5
			direction = direction.rotated(deg_to_rad(t * _spread.fan_degrees))
		round_pool.fire(start, direction * _spread.round_speed, damage, _spread.round_tint)
