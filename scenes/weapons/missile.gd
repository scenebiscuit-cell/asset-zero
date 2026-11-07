class_name Missile
extends PooledObject
## Player missile or rocket. Seekers turn toward their target; rockets fly straight.
## Both leave a thin smoke trail and burst on hit.

const OFFSCREEN_MARGIN: float = 48.0
## Enemies, air and ground (CLAUDE.md collision layers 3 and 4).
const ENEMY_MASK: int = (1 << 2) | (1 << 3)

## Seconds between trail points; the trail is a fixed number of points that shuffle along.
@export var trail_interval: float = 0.025
## How long the burst and trail linger after a hit, before the missile goes back to the pool.
@export var burst_time: float = 0.45
## How often a missile without a target looks for one.
@export var retarget_interval: float = 0.15

var damage: int = 0
var _data: MissileData
var _pool: MissilePool
var _ahead_only: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _target: Enemy
var _life: float = 0.0
var _retarget_left: float = 0.0
var _trail_left: float = 0.0
## Above zero once it has burst: no longer flying, just letting the effects finish.
var _burst_left: float = 0.0
var _age: float = 0.0
## Built once, reused for every blast.
var _query: PhysicsShapeQueryParameters2D
var _circle: CircleShape2D

@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _body: Node2D = $Visual/Body
@onready var _trail: Line2D = $Visual/Trail
@onready var _burst: CPUParticles2D = $Visual/Burst


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_circle = CircleShape2D.new()
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = _circle
	_query.collision_mask = ENEMY_MASK
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


func activate(start: Vector2, direction: Vector2, missile_data: MissileData, missile_damage: int,
		ahead_only: bool, pool: MissilePool) -> void:
	global_position = start
	_data = missile_data
	_pool = pool
	_ahead_only = ahead_only
	damage = missile_damage
	_velocity = direction.normalized() * _data.speed
	rotation = _velocity.angle() + PI / 2.0
	_target = null
	_life = _data.lifetime
	_retarget_left = 0.0
	_trail_left = trail_interval
	_burst_left = 0.0
	_age = 0.0
	_body.scale = Vector2.ONE * _data.visual_scale
	_body.visible = true
	_trail.modulate.a = 1.0
	for i: int in _trail.get_point_count():
		_trail.set_point_position(i, start)
	_hitbox.set_deferred("disabled", false)
	_start()


func _physics_process(delta: float) -> void:
	if _burst_left > 0.0:
		_burst_left -= delta
		_trail.modulate.a = clampf(_burst_left / burst_time, 0.0, 1.0)
		_update_trail(delta)
		if _burst_left <= 0.0:
			deactivate()
		return
	_steer(delta)
	position += _velocity * delta
	rotation = _velocity.angle() + PI / 2.0
	_update_trail(delta)
	_life -= delta
	_age += delta
	if _data.submunition != null and _age >= _data.split_delay:
		_split()
	elif _life <= 0.0:
		_burst_now()
	elif not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		deactivate()


func _steer(delta: float) -> void:
	if not _data.homing:
		return
	if not is_instance_valid(_target) or _target.hp <= 0 or not _target.is_targetable():
		_target = null
		_retarget_left -= delta
		if _retarget_left <= 0.0:
			_retarget_left = retarget_interval
			_target = _pool.find_target(global_position, _ahead_only, _data.thresher_seek_cone_degrees)
	if _target == null:
		return
	var wanted: float = global_position.direction_to(_target.global_position).angle()
	var turned: float = rotate_toward(_velocity.angle(), wanted, deg_to_rad(_data.turn_rate_degrees) * delta)
	_velocity = Vector2.from_angle(turned) * _data.speed


## The trail is drawn in world space (top_level), so it stays where the smoke was left.
func _update_trail(delta: float) -> void:
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left += trail_interval
		for i: int in range(_trail.get_point_count() - 1, 0, -1):
			_trail.set_point_position(i, _trail.get_point_position(i - 1))
	_trail.set_point_position(0, global_position)


func _on_area_entered(area: Area2D) -> void:
	if not is_active() or _burst_left > 0.0:
		return
	if area is Enemy:
		if _data.blast_radius <= 0.0:
			(area as Enemy).take_damage(damage)
		_burst_now()


func _burst_now() -> void:
	_burst_left = burst_time
	_body.visible = false
	_hitbox.set_deferred("disabled", true)
	_burst.restart()
	if _data.blast_radius > 0.0:
		_blast()


## GBU Bunker Buster: damages everything in the radius, ground units extra.
func _blast() -> void:
	_pool.blast_effect(global_position)
	_circle.radius = _data.blast_radius
	_query.transform = Transform2D(0.0, global_position)
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(_query, 24):
		var enemy: Enemy = hit["collider"] as Enemy
		if enemy == null:
			continue
		var ground: bool = enemy.data.layer == EnemyData.Layer.GROUND
		enemy.take_damage(roundi(damage * (_data.ground_damage_multiplier if ground else 1.0)))


## Mk3 Cluster Missile: the carrier pops and fans out its submunitions along its heading.
func _split() -> void:
	var sub: MissileData = _data.submunition
	var count: int = maxi(_data.submunition_count, 1)
	var sub_damage: int = roundi(float(damage) / maxf(_data.damage, 1.0) * sub.damage)
	for i: int in count:
		var t: float = 0.5 if count == 1 else float(i) / (count - 1)
		var degrees: float = lerpf(-0.5, 0.5, t) * _data.split_fan_degrees
		_pool.launch(global_position, _velocity.rotated(deg_to_rad(degrees)), sub, sub_damage, _ahead_only)
	_burst_left = burst_time
	_body.visible = false
	_hitbox.set_deferred("disabled", true)
	_burst.restart()
