class_name Player
extends Area2D
## XF-0. Moves, tells its weapons when to fire, takes hits, grazes and Overclocks.

signal destroyed
## Overclock's Meltdown pulse: the Level turns enemy rounds in this circle into salvage.
signal meltdown_pulse(center: Vector2, radius: float)
## The player called in a Saturation Strike (DESIGN.md §7.4); the Level clears the screen.
signal strike_called

@export var move_speed: float = 300.0
## Keeps the airframe visual fully on screen, not just its centre.
@export var screen_margin: Vector2 = Vector2(26.0, 36.0)
## Lowest y the play area reaches (the top of the HUD console). 0 = the bottom of the screen.
var play_area_bottom: float = 0.0
## Highest y the play area reaches (the bottom of the top HUD console). 0 = the top of the screen.
var play_area_top: float = 0.0
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
## Refit morph (DESIGN.md §5.3): a sector after new refits starts in the old airframe, then flows
## into the new one. A weight-class change plays a slower morph with a liquid ripple.
@export var refit_morph_delay: float = 0.6
@export var refit_morph_time: float = 0.3
@export var class_morph_time: float = 0.7
## Enemies to destroy for one Saturation Strike charge.
@export var kills_per_strike: int = 80
@export var max_strike_charges: int = 3
## Vector Dash: how far the hull stretches along the dash, as a fraction of its length.
@export var dash_stretch: float = 0.35

## Always-on auto-fire: the FC-1 refit or the accessibility setting (DESIGN.md §7.3), never a key.
var autofire: bool = false
## Seconds left on a timed Fire Control pickup.
var _autofire_left: float = 0.0
var _invulnerable_left: float = 0.0
var _dead: bool = false
var _glow_time: float = 0.0
var _default_thresher_speed: float = 0.55

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
@onready var _systems: ShipSystems = $ShipSystems
@onready var _trail: LiquidTrail = $Visual/LiquidTrail


func _ready() -> void:
	_default_thresher_speed = _combat_morph.thresher_speed_multiplier
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
	_update_trail_anchor(_combat_morph.current_shape())
	refresh_systems()
	_play_refit_morph()


## Plays the refit morph if the loadout changed since the last sector.
func _play_refit_morph() -> void:
	var before: AirframeShape = GameState.shown_airframe
	var class_changed: bool = GameState.shown_class != GameState.weight_class
	var after: AirframeShape = _combat_morph.gunship_shape()
	GameState.shown_airframe = after
	GameState.shown_class = GameState.weight_class
	if before == null or before.parts == after.parts:
		return
	_morph_system.snap_to(before)
	await get_tree().create_timer(refit_morph_delay, false).timeout
	if _dead:
		return
	if class_changed:
		_ripple()
		AudioManager.play("assimilate", -2.0)
	else:
		AudioManager.play("morph_to_thresher", -4.0)
	_morph_system.morph_to(_combat_morph.current_shape(), class_morph_time if class_changed else refit_morph_time)


## The loadout changed mid-sector (debug keys): rebuild both forms and flow into the new shape.
func refresh_airframe() -> void:
	_combat_morph.rebuild()
	var class_changed: bool = GameState.shown_class != GameState.weight_class
	GameState.shown_airframe = _combat_morph.gunship_shape()
	GameState.shown_class = GameState.weight_class
	if class_changed:
		_ripple()
	_morph_system.morph_to(_combat_morph.current_shape(), class_morph_time if class_changed else refit_morph_time)
	_hardpoints.apply_shape(_combat_morph.current_shape(), refit_morph_time)
	_update_trail_anchor(_combat_morph.current_shape())


## The liquid trail leaves from the tail of whatever shape the ship is in.
func _update_trail_anchor(shape: AirframeShape) -> void:
	var tail: float = 20.0
	for point: Vector2 in shape.parts.get("Hull", PackedVector2Array()):
		tail = maxf(tail, point.y)
	_trail.tail_offset = Vector2(0.0, tail)


## Liquid wobble as the airframe grows into a new weight class.
func _ripple() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_airframe, "scale", Vector2(1.15, 0.9), class_morph_time * 0.3)
	tween.tween_property(_airframe, "scale", Vector2(0.95, 1.06), class_morph_time * 0.3)
	tween.tween_property(_airframe, "scale", Vector2.ONE, class_morph_time * 0.4)


## Propulsion sets the speeds (Swept-Wing raises Thresher form speed). Re-run after a refit or field mod.
func refresh_systems() -> void:
	_systems.refresh()
	var thresher: float = _systems.thresher_speed_multiplier()
	_combat_morph.thresher_speed_multiplier = thresher if thresher > 0.0 else _default_thresher_speed
	# Field mods (AP Rounds) change damage too.
	_refresh_damage()


## Flying is keyboard or gamepad only, so the cursor hides during play and shows in menus
## (every menu pauses the game).
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY, NOTIFICATION_UNPAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		NOTIFICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	# Analog on a gamepad stick: a half push flies at half speed.
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed: float = move_speed * _systems.speed_multiplier() * _combat_morph.speed_multiplier() \
			* GameState.class_speed_multiplier()
	var step: Vector2 = direction * speed * delta + _systems.dash_offset(delta)
	position += step
	# The live metal: tips trail the body as it moves, and the trail shows while the metal is liquid.
	_morph_system.set_velocity(step / delta)
	_trail.strength = _morph_system.liquid()

	_clamp_to_screen()
	_try_activate_fire_control()
	_try_call_strike()
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


## Each kill fills the strike meter; a full meter becomes a stored charge. With storage full the
## meter stays full until a charge is used.
func register_kill() -> void:
	if GameState.strike_charges >= max_strike_charges:
		GameState.strike_progress = kills_per_strike
		return
	GameState.strike_progress += 1
	if GameState.strike_progress >= kills_per_strike:
		GameState.strike_charges += 1
		GameState.strike_progress = kills_per_strike if GameState.strike_charges >= max_strike_charges else 0


## 0-1 fill of the strike meter.
func strike_fill() -> float:
	return clampf(float(GameState.strike_progress) / maxi(kills_per_strike, 1), 0.0, 1.0)


func _try_call_strike() -> void:
	if _dead or not Input.is_action_just_pressed("strike") or GameState.strike_charges <= 0:
		return
	GameState.strike_charges -= 1
	if GameState.strike_progress >= kills_per_strike:
		# Storage was full, so the waiting full meter starts over.
		GameState.strike_progress = 0
	strike_called.emit()


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


## The cap one activation can reach; Heat Capacitors raise it, so the HUD bar never overflows.
func overclock_max_time() -> float:
	return _overclock.max_duration + GameState.overclock_bonus_time


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
	# Retention Matrix: this sector end keeps the module.
	if GameState.retention_charges > 0:
		GameState.retention_charges -= 1
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
	_morph_system.flinch()
	_graze_spark.global_position = at
	_graze_spark.restart()
	AudioManager.play("graze_tick", -8.0)
	Events.grazed.emit(at)


func _on_overclock_finished() -> void:
	_refresh_damage()
	grant_invulnerability(_overclock.end_invulnerability)


## Thresher form, Overclock and AP Rounds all boost damage; they multiply.
func _refresh_damage() -> void:
	var overclock_bonus: float = _overclock.damage_multiplier if _overclock.active else 1.0
	var field_bonus: float = 1.0 + GameState.damage_bonus
	_hardpoints.set_damage_multiplier(_combat_morph.damage_multiplier() * overclock_bonus * field_bonus)


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


## `hit_from` is where the hit landed, relative to the ship; the hull dents there (Plating takes it otherwise).
func take_damage(amount: int, hit_from: Vector2 = Vector2.INF) -> void:
	if _dead:
		return
	_hit_splash.restart()
	var on_plating: bool = GameState.plating > 0
	if GameState.damage_armor(roundi(amount * _combat_morph.damage_taken_multiplier())):
		_die()
		return
	if hit_from.is_finite() and not on_plating:
		_morph_system.dent(hit_from)
	_systems.on_hit(on_plating)
	_invulnerable_left = invulnerable_time


func _on_form_changed(is_thresher: bool) -> void:
	_hardpoints.set_converged(is_thresher)
	_refresh_damage()
	_hardpoints.apply_shape(_combat_morph.current_shape(), _combat_morph.morph_time)
	_set_hitbox(_combat_morph.current_shape(), _combat_morph.morph_time)
	# Thresher form is the metal unlocked: it ripples the whole time it's held (DESIGN.md §5.3).
	_morph_system.set_liquid(1.0 if is_thresher else 0.0, _combat_morph.morph_time)
	_update_trail_anchor(_combat_morph.current_shape())


## The hitbox follows the airframe: it narrows as the wings fold into Thresher form.
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
	if _dead or _invulnerable_left > 0.0 or _systems.is_phased():
		return
	if area is EnemyRound:
		var enemy_round: EnemyRound = area as EnemyRound
		if not enemy_round.is_active():
			return
		take_damage(enemy_round.damage, to_local(enemy_round.global_position))
		enemy_round.deactivate()
	elif area is EnemyHazard:
		take_damage((area as EnemyHazard).damage, to_local(area.global_position))
	elif area is Enemy and not _systems.ignores_contact():
		take_damage((area as Enemy).data.contact_damage, to_local(area.global_position))


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
	# The live metal stops; the collapse below takes over.
	_morph_system.set_velocity(Vector2.ZERO)
	_morph_system.set_process(false)
	_trail.strength = 0.0
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


## Vector Dash: the hull goes liquid, stretched along the dash and see-through.
func set_liquid(on: bool, direction: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	if not on:
		_airframe.modulate.a = 1.0
		return
	_morph_system.stretch_along(direction, dash_stretch)
	_morph_system.flinch()
	_airframe.modulate.a = 0.55


func _clamp_to_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	if play_area_bottom > 0.0:
		screen.y = minf(screen.y, play_area_bottom)
	position = position.clamp(screen_margin + Vector2(0.0, play_area_top), screen - screen_margin)
