class_name FlakRound
extends PooledObject
## Flak Burst round: flies a set distance (or until it touches an enemy), then bursts and damages
## every enemy inside the blast.

const OFFSCREEN_MARGIN: float = 32.0
## Enemies, air and ground (CLAUDE.md collision layers 3 and 4).
const ENEMY_MASK: int = (1 << 2) | (1 << 3)

@export var blast_time: float = 0.25

var _velocity: Vector2 = Vector2.ZERO
var _distance_left: float = 0.0
var _damage: int = 0
var _radius: float = 0.0
var _blast_left: float = 0.0
var _query: PhysicsShapeQueryParameters2D
var _circle: CircleShape2D

@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _shell: Node2D = $Visual/Shell
@onready var _blast: Polygon2D = $Visual/Blast
@onready var _sparks: CPUParticles2D = $Visual/Sparks


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Built once and reused for every burst.
	_circle = CircleShape2D.new()
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = _circle
	_query.collision_mask = ENEMY_MASK
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


func activate(start: Vector2, velocity: Vector2, burst_distance: float, damage: int, radius: float,
		tint: Color) -> void:
	global_position = start
	rotation = velocity.angle() + PI / 2.0
	_velocity = velocity
	_distance_left = burst_distance
	_damage = damage
	_radius = radius
	_blast_left = 0.0
	modulate = tint
	_shell.visible = true
	_blast.visible = false
	_hitbox.set_deferred("disabled", false)
	_start()


func _physics_process(delta: float) -> void:
	if _blast_left > 0.0:
		_blast_left -= delta
		var t: float = 1.0 - _blast_left / blast_time
		# The blast polygon is 10 px across its radius at scale 1.
		_blast.scale = Vector2.ONE * (_radius / 10.0) * lerpf(0.5, 1.0, t)
		_blast.modulate.a = 1.0 - t
		if _blast_left <= 0.0:
			deactivate()
		return
	var step: Vector2 = _velocity * delta
	position += step
	_distance_left -= step.length()
	if _distance_left <= 0.0:
		_burst()
	elif not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(global_position):
		deactivate()


func _on_area_entered(area: Area2D) -> void:
	if is_active() and _blast_left <= 0.0 and area is Enemy:
		_burst()


func _burst() -> void:
	_blast_left = blast_time
	_shell.visible = false
	_blast.visible = true
	_hitbox.set_deferred("disabled", true)
	_sparks.restart()
	_circle.radius = _radius
	_query.transform = Transform2D(0.0, global_position)
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(_query, 16):
		var enemy: Enemy = hit["collider"] as Enemy
		if enemy != null:
			enemy.take_damage(_damage)
