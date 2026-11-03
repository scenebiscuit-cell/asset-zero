class_name Player
extends Area2D
## XF-0. Moves, tells its weapons when to fire, and takes hits.

signal destroyed

enum InputMode { KEYBOARD, MOUSE }

@export var move_speed: float = 300.0
## Keeps the airframe visual fully on screen, not just its centre.
@export var screen_margin: Vector2 = Vector2(26.0, 36.0)
## Set by whatever scene the player is placed in; rounds live there, not on the ship.
@export var round_pool: RoundPool
@export var invulnerable_time: float = 1.0
@export var flash_interval: float = 0.08
@export var collapse_time: float = 0.6

## Always-on auto-fire: the FC-1 refit or the accessibility setting (DESIGN.md §7.3), never a key.
var autofire: bool = false
var _input_mode: InputMode = InputMode.KEYBOARD
## Seconds left on a timed Fire Control pickup.
var _autofire_left: float = 0.0
var _invulnerable_left: float = 0.0
var _dead: bool = false

@onready var _autocannon: Autocannon = $Autocannon
@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _airframe: Node2D = $Visual/Airframe
@onready var _shadow: DropShadow = $Shadow
@onready var _morph_system: MorphSystem = $MorphSystem
@onready var _combat_morph: CombatMorph = $CombatMorph
@onready var _hit_splash: CPUParticles2D = $Visual/HitSplash
@onready var _death_splash: CPUParticles2D = $Visual/DeathSplash


func _ready() -> void:
	_autocannon.round_pool = round_pool
	area_entered.connect(_try_hit)
	_morph_system.shape_changed.connect(_shadow.refresh)
	_combat_morph.form_changed.connect(_on_form_changed)
	_set_hitbox(_combat_morph.current_shape(), 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_input_mode = InputMode.MOUSE


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_input_mode = InputMode.KEYBOARD

	var speed: float = move_speed * _combat_morph.speed_multiplier()
	if _input_mode == InputMode.KEYBOARD:
		position += direction * speed * delta
	else:
		# Capped at speed so mouse play isn't faster than keyboard.
		position = position.move_toward(get_global_mouse_position(), speed * delta)

	_clamp_to_screen()
	_update_timed_autofire(delta)
	_autocannon.firing = autofire or _autofire_left > 0.0 or Input.is_action_pressed("fire")
	_update_invulnerability(delta)


## Timed auto-fire from a Fire Control pickup. A second pickup tops the timer back up, it doesn't stack.
func grant_autofire(seconds: float) -> void:
	if _dead:
		return
	_autofire_left = maxf(_autofire_left, seconds)


func autofire_time_left() -> float:
	return maxf(_autofire_left, 0.0)


func is_overclocked() -> bool:
	return false


func overclock_time_left() -> float:
	return 0.0


func overclock_max_time() -> float:
	return 10.0


func _update_timed_autofire(delta: float) -> void:
	if _autofire_left > 0.0:
		_autofire_left -= delta


func take_damage(amount: int) -> void:
	if _dead:
		return
	_hit_splash.restart()
	if GameState.damage_armor(amount):
		_die()
		return
	_invulnerable_left = invulnerable_time


func _on_form_changed(is_lance: bool) -> void:
	_autocannon.converged = is_lance
	_autocannon.damage_multiplier = _combat_morph.damage_multiplier()
	# The muzzle (and its flash) slides out to the new nose as the shape flows.
	var muzzle: Vector2 = _combat_morph.current_shape().muzzle_offset
	create_tween().tween_property(_autocannon, "position", muzzle, _combat_morph.morph_time)
	_set_hitbox(_combat_morph.current_shape(), _combat_morph.morph_time)


## The hitbox follows the airframe: it narrows as the wings fold into Lance form.
func _set_hitbox(shape: AirframeShape, duration: float) -> void:
	var capsule: CapsuleShape2D = _hitbox.shape as CapsuleShape2D
	if duration <= 0.0:
		capsule.radius = shape.hitbox_radius
		capsule.height = shape.hitbox_height
		_hitbox.position = shape.hitbox_offset
		return
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(capsule, "radius", shape.hitbox_radius, duration)
	tween.tween_property(capsule, "height", shape.hitbox_height, duration)
	tween.tween_property(_hitbox, "position", shape.hitbox_offset, duration)


func _try_hit(area: Area2D) -> void:
	if _dead or _invulnerable_left > 0.0:
		return
	if area is EnemyRound:
		var enemy_round: EnemyRound = area as EnemyRound
		if not enemy_round.is_active():
			return
		take_damage(enemy_round.damage)
		enemy_round.deactivate()
	elif area is Enemy:
		take_damage((area as Enemy).data.contact_damage)


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_left <= 0.0:
		return
	_invulnerable_left -= delta
	var blink_on: bool = int(_invulnerable_left / flash_interval) % 2 == 0
	_airframe.modulate.a = 0.25 if blink_on else 1.0
	if _invulnerable_left <= 0.0:
		_airframe.modulate.a = 1.0
		# area_entered won't fire again for something we're already touching.
		for area: Area2D in get_overlapping_areas():
			_try_hit(area)


func _die() -> void:
	_dead = true
	_autocannon.firing = false
	set_physics_process(false)
	_combat_morph.set_physics_process(false)
	_hitbox.set_deferred("disabled", true)
	_airframe.modulate.a = 1.0
	_death_splash.restart()

	# Liquid collapse: the airframe loses its shape, spreads flat and falls away.
	var tween: Tween = create_tween()
	tween.tween_property(_airframe, "scale", Vector2(1.3, 0.7), collapse_time * 0.2)
	tween.tween_property(_airframe, "scale", Vector2(2.2, 0.05), collapse_time * 0.8).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_airframe, "position:y", 40.0, collapse_time * 0.8).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_airframe, "modulate:a", 0.0, collapse_time * 0.8)
	# No airframe, no shadow on the ground.
	tween.parallel().tween_property(_shadow, "modulate:a", 0.0, collapse_time * 0.8)
	destroyed.emit()


func _clamp_to_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	position = position.clamp(screen_margin, screen - screen_margin)
