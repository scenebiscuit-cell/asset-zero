class_name Explosion
extends Node2D
## Pooled explosion (DESIGN.md §11): flash -> fireballs + sparks -> debris with smoke trails -> scorch mark.
## Drifts with the ground so the smoke and scorch stay where the kill happened.

signal expired(explosion: Explosion)

@export var flash_time: float = 0.1
@export var fireball_time: float = 0.35
@export var debris_count: int = 6
@export var debris_speed_min: float = 70.0
@export var debris_speed_max: float = 260.0
@export var debris_drag: float = 2.5
## How long debris flies (and its trail grows) before it lands.
@export var debris_fly_time: float = 0.7
## Max turn rate of debris, so trails curve slightly.
@export var debris_curl: float = 0.9
@export var debris_tumble_speed: float = 12.0
@export var trail_point_interval: float = 0.03
## Width of the smoke at its widest (the old end near the blast).
@export var trail_width: float = 5.0
## Smoke spreads out this much more while it fades.
@export var trail_spread: float = 1.8
@export var trail_fade_time: float = 1.8
## The grey cloud at the centre: how long it takes to spread out and thin away.
@export var smoke_time: float = 2.0
@export var smoke_drift_speed: float = 14.0
@export var scorch_hold_time: float = 1.5
@export var scorch_fade_time: float = 2.5
## Matches the ground scroll speed.
@export var drift_speed: float = 60.0

const DEBRIS_HOT: Color = Color("ffb030")
const DEBRIS_COLD: Color = Color("2a2826")
const SMOKE: Color = Color(0.42, 0.41, 0.38)

var _age: float = 0.0
var _trail_timer: float = 0.0
var _lifetime: float = 0.0
# Starts true so the pool's first deactivate() files it as free.
var _active: bool = true
var _debris_velocity: PackedVector2Array = PackedVector2Array()
var _debris_turn: PackedFloat32Array = PackedFloat32Array()
var _debris_nodes: Array[Polygon2D] = []
var _trail_nodes: Array[Line2D] = []
var _fireball_nodes: Array[Polygon2D] = []
var _fireball_ramp: Gradient
var _puff_nodes: Array[Polygon2D] = []
var _puff_drift: PackedVector2Array = PackedVector2Array()

@onready var _flash: Node2D = $Visual/Flash
@onready var _fireballs: Node2D = $Visual/Fireballs
@onready var _sparks: CPUParticles2D = $Visual/Sparks
@onready var _smoke: Node2D = $Visual/Smoke
@onready var _debris: Node2D = $Visual/Debris
@onready var _trails: Node2D = $Visual/Trails
@onready var _scorch: Node2D = $Visual/Scorch


func _ready() -> void:
	_lifetime = maxf(debris_fly_time + trail_fade_time, maxf(smoke_time, scorch_hold_time + scorch_fade_time))
	_fireball_ramp = Gradient.new()
	_fireball_ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	_fireball_ramp.colors = PackedColorArray([Color("e4cc24"), Color("cc8424"), Color("b45424"), Color("9c3c24")])
	for child: Node in _fireballs.get_children():
		_fireball_nodes.append(child as Polygon2D)
	for child: Node in _smoke.get_children():
		_puff_nodes.append(child as Polygon2D)
	_puff_drift.resize(_puff_nodes.size())
	_build_debris()


## Made once when the pool fills, never during play.
func _build_debris() -> void:
	# Point 0 is the oldest end of the trail (near the blast): wide and thin smoke.
	# The chunk end is fresh: narrow and dense. Mid-grey, since black vanishes on the dark jungle.
	var trail_colors: Gradient = Gradient.new()
	trail_colors.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	trail_colors.colors = PackedColorArray([
		Color(0.45, 0.44, 0.41, 0.0), Color(0.45, 0.44, 0.41, 0.12), Color(0.55, 0.54, 0.5, 0.26)])
	var trail_shape: Curve = Curve.new()
	trail_shape.add_point(Vector2(0.0, 1.0))
	trail_shape.add_point(Vector2(1.0, 0.2))

	_debris_velocity.resize(debris_count)
	_debris_turn.resize(debris_count)
	for i: int in debris_count:
		var trail: Line2D = Line2D.new()
		trail.width = trail_width
		trail.width_curve = trail_shape
		trail.gradient = trail_colors
		trail.joint_mode = Line2D.LINE_JOINT_ROUND
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		_trails.add_child(trail)
		_trail_nodes.append(trail)
		var chunk: Polygon2D = Polygon2D.new()
		chunk.polygon = _chunk_shape()
		_debris.add_child(chunk)
		_debris_nodes.append(chunk)


## A small irregular chunk, so no two pieces of debris look the same.
func _chunk_shape() -> PackedVector2Array:
	var shape: PackedVector2Array = PackedVector2Array()
	var size: float = randf_range(1.6, 2.6)
	for i: int in 5:
		shape.append(Vector2.from_angle(TAU * i / 5.0) * size * randf_range(0.6, 1.3))
	return shape


func activate(at: Vector2) -> void:
	global_position = at
	_age = 0.0
	_trail_timer = 0.0
	_active = true
	visible = true

	_flash.visible = true
	_flash.scale = Vector2.ONE * 0.6
	_flash.modulate.a = 1.0

	_fireballs.visible = true
	for fireball: Polygon2D in _fireball_nodes:
		fireball.position = Vector2.from_angle(randf() * TAU) * randf_range(0.0, 9.0)
		fireball.scale = Vector2.ONE * 0.5

	_sparks.restart()
	_sparks.emitting = true

	_smoke.visible = true
	for i: int in _puff_nodes.size():
		var direction: Vector2 = Vector2.from_angle(randf() * TAU)
		_puff_nodes[i].position = direction * randf_range(0.0, 6.0)
		_puff_nodes[i].scale = Vector2.ONE * 0.4
		_puff_drift[i] = direction * smoke_drift_speed * randf_range(0.5, 1.0)

	_debris.visible = true
	_debris.modulate.a = 1.0
	_trails.modulate.a = 1.0
	for i: int in debris_count:
		var angle: float = (TAU * i + randf_range(-0.5, 0.5)) / debris_count
		_debris_velocity[i] = Vector2.from_angle(angle) * randf_range(debris_speed_min, debris_speed_max)
		_debris_turn[i] = randf_range(-debris_curl, debris_curl)
		_debris_nodes[i].position = Vector2.ZERO
		_debris_nodes[i].rotation = randf() * TAU
		_debris_nodes[i].color = DEBRIS_HOT
		_trail_nodes[i].width = trail_width
		_trail_nodes[i].clear_points()
		_trail_nodes[i].add_point(Vector2.ZERO)

	_scorch.rotation = randf() * TAU
	_scorch.scale = Vector2.ONE * randf_range(0.8, 1.2)
	_scorch.modulate.a = 1.0
	set_process(true)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	visible = false
	set_process(false)
	_sparks.emitting = false
	expired.emit(self)


func _process(delta: float) -> void:
	_age += delta
	position.y += drift_speed * delta
	_update_flash()
	_update_fireballs()
	_update_smoke(delta)
	_update_debris(delta)
	_update_scorch()
	if _age >= _lifetime or global_position.y > get_viewport_rect().size.y + 120.0:
		deactivate()


func _update_flash() -> void:
	if not _flash.visible:
		return
	var t: float = _age / flash_time
	_flash.scale = Vector2.ONE * lerpf(0.6, 1.6, t)
	_flash.modulate.a = 1.0 - t
	if t >= 1.0:
		_flash.visible = false


func _update_fireballs() -> void:
	if not _fireballs.visible:
		return
	var t: float = _age / fireball_time
	if t >= 1.0:
		_fireballs.visible = false
		return
	var color: Color = _fireball_ramp.sample(t)
	color.a = 1.0 - t * t
	for fireball: Polygon2D in _fireball_nodes:
		fireball.color = color
		fireball.scale = Vector2.ONE * lerpf(0.5, 1.2, sqrt(t))


func _update_smoke(delta: float) -> void:
	if not _smoke.visible:
		return
	var t: float = _age / smoke_time
	if t >= 1.0:
		_smoke.visible = false
		return
	# Grows fast at first, then thins out as it spreads.
	var color: Color = SMOKE
	color.a = 0.5 * (1.0 - t) * (1.0 - t)
	var size: float = lerpf(0.4, 2.2, sqrt(t))
	for i: int in _puff_nodes.size():
		_puff_nodes[i].position += _puff_drift[i] * delta
		_puff_nodes[i].scale = Vector2.ONE * size
		_puff_nodes[i].color = color


func _update_debris(delta: float) -> void:
	if _age < debris_fly_time:
		_trail_timer += delta
		var add_point: bool = _trail_timer >= trail_point_interval
		if add_point:
			_trail_timer -= trail_point_interval
		var heat: float = clampf(_age / (debris_fly_time * 0.5), 0.0, 1.0)
		# Tumbling slows as the chunk does.
		var slowdown: float = 1.0 - _age / debris_fly_time
		for i: int in debris_count:
			var velocity: Vector2 = _debris_velocity[i].rotated(_debris_turn[i] * delta)
			velocity *= maxf(1.0 - debris_drag * delta, 0.0)
			_debris_velocity[i] = velocity
			var chunk: Polygon2D = _debris_nodes[i]
			chunk.position += velocity * delta
			chunk.rotation += debris_tumble_speed * slowdown * delta * (1.0 if i % 2 == 0 else -1.0)
			chunk.color = DEBRIS_HOT.lerp(DEBRIS_COLD, heat)
			if add_point:
				_trail_nodes[i].add_point(chunk.position)
	else:
		# Landed: the chunks stay on the ground and fade with the smoke, which spreads as it thins.
		var fade: float = clampf((_age - debris_fly_time) / trail_fade_time, 0.0, 1.0)
		_debris.modulate.a = 1.0 - fade
		_trails.modulate.a = 1.0 - fade
		var width: float = trail_width * lerpf(1.0, trail_spread, fade)
		for trail: Line2D in _trail_nodes:
			trail.width = width


func _update_scorch() -> void:
	var fade: float = (_age - scorch_hold_time) / scorch_fade_time
	_scorch.modulate.a = clampf(1.0 - fade, 0.0, 1.0)
