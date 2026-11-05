class_name Player
extends Area2D
## XF-0. Moves, tells its weapons when to fire, takes hits, grazes and Overclocks.

signal destroyed
## Overclock's Meltdown pulse: the Level turns enemy rounds in this circle into salvage.
signal meltdown_pulse(center: Vector2, radius: float)

enum InputMode { KEYBOARD, MOUSE }

@export var move_speed: float = 300.0
## Keeps the airframe visual fully on screen, not just its centre.
@export var screen_margin: Vector2 = Vector2(26.0, 36.0)
## Set by whatever scene the player is placed in; rounds live there, not on the ship.
@export var round_pool: RoundPool
@export var missile_pool: MissilePool
@export var invulnerable_time: float = 1.0
@export var flash_interval: float = 0.08
@export var collapse_time: float = 0.6
## Hull colour at the peak of the white-hot Overclock pulse (values above 1 brighten).
@export var overclock_glow: Color = Color(1.9, 1.5, 1.15)
## Fire Control: seconds of auto-fire per activation, and how many pickups can be stored.
@export var fire_control_duration: float = 10.0
@export var max_fire_control_charges: int = 2

## Always-on auto-fire: the FC-1 refit or the accessibility setting (DESIGN.md §7.3), never a key.
var autofire: bool = false
var _input_mode: InputMode = InputMode.KEYBOARD
## Seconds left on a timed Fire Control pickup.
var _autofire_left: float = 0.0
var _invulnerable_left: float = 0.0
var _dead: bool = false
var _glow_time: float = 0.0

@onready var _hardpoints: Hardpoints = $Hardpoints
@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _airframe: Node2D = $Visual/Airframe
@onready var _shadow: DropShadow = $Shadow
@onready var _morph_system: MorphSystem = $MorphSystem
@onready var _combat_morph: CombatMorph = $CombatMorph
@onready var _hit_splash: CPUParticles2D = $Visual/HitSplash
@onready var _death_splash: CPUParticles2D = $Visual/DeathSplash
@onready var _graze_spark: CPUParticles2D = $Visual/GrazeSpark
@onready var _graze_area: GrazeArea = $GrazeArea
@onready var _overclock: Overclock = $Overclock
@onready var _assimilate_fx: AssimilateFx = $Visual/AssimilateFx


func _ready() -> void:
	_hardpoints.setup(round_pool, missile_pool)
	_hardpoints.apply_shape(_combat_morph.current_shape(), 0.0)
	area_entered.connect(_try_hit)
	_morph_system.shape_changed.connect(_shadow.refresh)
	_combat_morph.form_changed.connect(_on_form_changed)
	_graze_area.grazed.connect(_on_grazed)
	_overclock.meltdown.connect(meltdown_pulse.emit)
	_overclock.started.connect(_refresh_damage)
	_overclock.finished.connect(_on_overclock_finished)
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
	_try_activate_fire_control()
	_update_timed_autofire(delta)
	_hardpoints.set_firing(autofire or _autofire_left > 0.0 or Input.is_action_pressed("fire"))
	_update_invulnerability(delta)
	_update_overclock_glow(delta)


## Timed auto-fire from a Fire Control pickup. A second pickup tops the timer back up, it doesn't stack.
## A Fire Control pickup is stored, not used; the player starts it with the Fire Control key.
## Returns false when storage is full, so the pickup isn't wasted.
func store_fire_control() -> bool:
	if GameState.fire_control_charges >= max_fire_control_charges:
		return false
	GameState.fire_control_charges += 1
	return true


func _try_activate_fire_control() -> void:
	if not Input.is_action_just_pressed("fire_control"):
		return
	if GameState.fire_control_charges <= 0 or _autofire_left > 0.0 or autofire:
		return
	GameState.fire_control_charges -= 1
	grant_autofire(fire_control_duration)
	AudioManager.play("overclock_on", -8.0)


func grant_autofire(seconds: float) -> void:
	if _dead:
		return
	_autofire_left = maxf(_autofire_left, seconds)


func autofire_time_left() -> float:
	return maxf(_autofire_left, 0.0)


func is_overclocked() -> bool:
	return _overclock.active


func overclock_time_left() -> float:
	return _overclock.time_left()


func overclock_max_time() -> float:
	return _overclock.max_duration


## Absorbs an enemy weapon module onto the Salvage Mount (DESIGN.md §5.8). Only one at a time:
## a new one replaces the old, which splashes away.
func assimilate(module: ModuleData) -> void:
	if _dead:
		return
	if _hardpoints.equipped(WeaponData.Hardpoint.SALVAGE_MOUNT) != null:
		_hardpoints.unequip(WeaponData.Hardpoint.SALVAGE_MOUNT)
		_hit_splash.restart()
	_assimilate_fx.play(module.color)
	await _assimilate_fx.absorbed
	if not _dead:
		_hardpoints.equip(module)


## The module dissolves at the end of the sector (DESIGN.md §5.8).
func dissolve_module() -> void:
	if _hardpoints.equipped(WeaponData.Hardpoint.SALVAGE_MOUNT) == null:
		return
	_hardpoints.unequip(WeaponData.Hardpoint.SALVAGE_MOUNT)
	_hit_splash.restart()


## Never shortens invulnerability that's already running.
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


func _on_grazed(at: Vector2) -> void:
	if _dead:
		return
	GameState.add_overclock(GameState.OVERCLOCK_PER_GRAZE)
	_graze_spark.global_position = at
	_graze_spark.restart()
	AudioManager.play("graze_tick", -8.0)
	Events.grazed.emit(at)


func _on_overclock_finished() -> void:
	_refresh_damage()
	grant_invulnerability(_overclock.end_invulnerability)


## Lance form and Overclock both boost damage; they multiply.
func _refresh_damage() -> void:
	var overclock_bonus: float = _overclock.damage_multiplier if _overclock.active else 1.0
	_hardpoints.set_damage_multiplier(_combat_morph.damage_multiplier() * overclock_bonus)


## White-hot pulsing hull with a slight ripple while Overclocked (DESIGN.md §5.3).
func _update_overclock_glow(delta: float) -> void:
	if not _overclock.active:
		if _glow_time > 0.0:
			_glow_time = 0.0
			_airframe.modulate = Color(1.0, 1.0, 1.0, _airframe.modulate.a)
			_airframe.scale = Vector2.ONE
		return
	_glow_time += delta
	var pulse: float = 0.5 + 0.5 * sin(_glow_time * 14.0)
	var hot: Color = Color.WHITE.lerp(overclock_glow, 0.6 + 0.4 * pulse)
	_airframe.modulate = Color(hot.r, hot.g, hot.b, _airframe.modulate.a)
	_airframe.scale = Vector2.ONE * (1.0 + 0.025 * sin(_glow_time * 22.0))


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
	_hardpoints.set_converged(is_lance)
	_refresh_damage()
	_hardpoints.apply_shape(_combat_morph.current_shape(), _combat_morph.morph_time)
	_set_hitbox(_combat_morph.current_shape(), _combat_morph.morph_time)


## The hitbox follows the airframe: it narrows as the wings fold into Lance form.
func _set_hitbox(shape: AirframeShape, duration: float) -> void:
	var capsule: CapsuleShape2D = _hitbox.shape as CapsuleShape2D
	_graze_area.set_radius(shape.graze_radius, duration)
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
	elif area is EnemyHazard:
		take_damage((area as EnemyHazard).damage)
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
	_hardpoints.shut_down()
	set_physics_process(false)
	_combat_morph.set_physics_process(false)
	_hitbox.set_deferred("disabled", true)
	_graze_area.enabled = false
	_overclock.cancel()
	_airframe.modulate = Color.WHITE
	_airframe.scale = Vector2.ONE
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
