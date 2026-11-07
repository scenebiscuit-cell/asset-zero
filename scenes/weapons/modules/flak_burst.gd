class_name FlakBurst
extends ModuleWeapon
## Flak Burst module (DESIGN.md §5.8): rounds burst in a small blast after a short distance.
## Thresher form fires them straight and lets them fly twice as far before bursting.

var _flak: FlakBurstData
var _cooldown: float = 0.0

## Its own small pool of flak rounds. top_level, so the rounds fly in the world, not with the ship.
@onready var _pool: ObjectPool = $FlakPool


func _ready() -> void:
	super()
	_flak = data as FlakBurstData
	_pool.top_level = true
	_pool.global_position = Vector2.ZERO


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if not firing or not enabled:
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown > 0.0:
		return
	_cooldown += interval(_flak.fire_interval)
	var distance: float = _flak.thresher_burst_distance if converged else _flak.burst_distance
	for i: int in _flak.rounds:
		var t: float = 0.0 if _flak.rounds < 2 else float(i) / (_flak.rounds - 1) - 0.5
		var start: Vector2 = global_position
		var direction: Vector2 = Vector2.UP
		if converged:
			start.x += t * 8.0
		else:
			direction = direction.rotated(deg_to_rad(t * _flak.fan_degrees))
		var flak_round: FlakRound = _pool.acquire() as FlakRound
		if flak_round != null:
			flak_round.activate(start, direction * _flak.round_speed, distance,
					scaled_damage(_flak.damage), _flak.blast_radius, _flak.round_tint)
