class_name BeamLaser
extends Weapon
## Beam Laser line (DESIGN.md §6): a continuous beam that stops at the first enemy in its path
## and damages it every tick. Lance form makes it thinner and brighter (§5.6).

## Lance form brightens the beam by this much (values above 1 glow hotter).
@export var lance_brightness: float = 1.6
## Glow width compared to the hit width.
@export var glow_scale: float = 2.6
## Core width compared to the hit width.
@export var core_scale: float = 0.55

var _beam: BeamData
var _tick: float = 0.0
var _afterglow_left: float = 0.0
var _length: float = 0.0

@onready var _cast: ShapeCast2D = $Cast
@onready var _visual: Node2D = $Visual
@onready var _glow: Line2D = $Visual/Glow
@onready var _core: Line2D = $Visual/Core
@onready var _hit_flare: Node2D = $Visual/HitFlare
@onready var _hit_sparks: CPUParticles2D = $Visual/HitSparks


func _ready() -> void:
	_beam = data as BeamData
	_cast.shape = RectangleShape2D.new()
	_cast.target_position = Vector2(0.0, -_beam.reach)
	# The glow keeps the scene's softer alpha; only its hue comes from the data.
	_glow.default_color = Color(_beam.glow_color, _glow.default_color.a)
	_core.default_color = _beam.core_color
	_visual.visible = false
	_apply_width()


func _physics_process(delta: float) -> void:
	if not firing or not enabled:
		_cast.enabled = false
		_hit_sparks.emitting = false
		# Kept counting down, so tapping Fire can't skip the tick timer.
		_tick = maxf(_tick - delta, 0.0)
		_fade_out(delta)
		return
	_cast.enabled = true
	_apply_width()
	_cast.force_shapecast_update()
	var target: Enemy = _closest_enemy()
	_tick -= delta
	if _tick <= 0.0:
		_tick += interval(_beam.fire_interval)
		if target != null:
			target.take_damage(scaled_damage(_beam.damage))
			if _beam.burn_dps > 0.0 and is_instance_valid(target):
				target.apply_burn(_beam.burn_dps * damage_multiplier, _beam.burn_time)
	_afterglow_left = _beam.afterglow_time
	_draw_beam(target != null)


## The enemy nearest the emitter among those the beam touches first.
func _closest_enemy() -> Enemy:
	_length = _beam.reach
	if not _cast.is_colliding():
		return null
	var closest: Enemy = null
	var best: float = INF
	for i: int in _cast.get_collision_count():
		var enemy: Enemy = _cast.get_collider(i) as Enemy
		if enemy == null:
			continue
		var distance: float = global_position.distance_to(_cast.get_collision_point(i))
		if distance < best:
			best = distance
			closest = enemy
	if closest != null:
		_length = best
	return closest


func _apply_width() -> void:
	var width: float = _beam.lance_width if converged else _beam.width
	(_cast.shape as RectangleShape2D).size = Vector2(width, 2.0)
	_glow.width = width * glow_scale
	_core.width = maxf(width * core_scale, 1.5)
	var brightness: float = lance_brightness if converged else 1.0
	_visual.modulate = Color(brightness, brightness, brightness, 1.0)


func _draw_beam(hitting: bool) -> void:
	var end: Vector2 = Vector2(0.0, -_length)
	_glow.set_point_position(1, end)
	_core.set_point_position(1, end)
	_hit_flare.position = end
	_hit_flare.visible = hitting
	_hit_sparks.position = end
	_hit_sparks.emitting = hitting
	_visual.visible = true


## A faint afterglow, then the beam snaps off (DESIGN.md §11 effects, lasers).
func _fade_out(delta: float) -> void:
	if not _visual.visible:
		return
	_afterglow_left -= delta
	if _afterglow_left <= 0.0:
		_visual.visible = false
		return
	_visual.modulate.a = _afterglow_left / _beam.afterglow_time * 0.5
