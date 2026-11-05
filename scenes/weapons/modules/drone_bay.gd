class_name DroneBay
extends ModuleWeapon
## Drone Bay module (DESIGN.md §5.8). Gunship form: allied drones orbit XF-0 and shoot at the
## nearest enemy. Lance form: they line up beside the nose and fire straight ahead.
## The drones are fixed child nodes (never spawned or freed in play), set top_level so they trail
## behind XF-0 in world space instead of being locked to it.

var _bay: DroneBayData
var _drones: Array[Node2D] = []
var _cooldowns: PackedFloat32Array = PackedFloat32Array()
var _angle: float = 0.0


func _ready() -> void:
	super()
	_bay = data as DroneBayData
	for child: Node in $Drones.get_children():
		var drone: Node2D = child as Node2D
		if _drones.size() >= _bay.drone_count:
			drone.visible = false
			continue
		drone.global_position = global_position # Launch out of the bay.
		_drones.append(drone)
	_cooldowns.resize(_drones.size())
	for i: int in _drones.size():
		# Staggered, so the drones take turns instead of firing in lockstep.
		_cooldowns[i] = _bay.fire_interval * float(i) / _drones.size()


func _physics_process(delta: float) -> void:
	_angle = fmod(_angle + _bay.orbit_speed * delta, TAU)
	var follow: float = 1.0 - exp(-_bay.follow_sharpness * delta)
	for i: int in _drones.size():
		var drone: Node2D = _drones[i]
		drone.global_position = drone.global_position.lerp(_slot(i), follow)
		var aim: Vector2 = _aim(drone)
		drone.rotation = aim.angle() + PI / 2.0 # Drone art points up.
		_cooldowns[i] -= delta
		if not firing or not enabled or round_pool == null:
			_cooldowns[i] = maxf(_cooldowns[i], 0.0)
			continue
		if _cooldowns[i] <= 0.0:
			_cooldowns[i] += _bay.fire_interval
			round_pool.fire(drone.global_position, aim * _bay.round_speed, scaled_damage(_bay.damage), _bay.round_tint)


## Where drone i should be right now.
func _slot(i: int) -> Vector2:
	if converged:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var row: float = float(i / 2) # Extra drones line up behind the first pair.
		return global_position + Vector2(_bay.lance_offset.x * side, _bay.lance_offset.y + row * 14.0)
	return global_position + Vector2.from_angle(_angle + TAU * i / _drones.size()) * _bay.orbit_radius


## Lance form fires straight ahead; Gunship form aims at the nearest enemy in range.
func _aim(drone: Node2D) -> Vector2:
	if converged or missile_pool == null:
		return Vector2.UP
	var target: Enemy = missile_pool.find_target(drone.global_position, false, 180.0)
	if target == null or drone.global_position.distance_to(target.global_position) > _bay.aim_range:
		return Vector2.UP
	return drone.global_position.direction_to(target.global_position)
