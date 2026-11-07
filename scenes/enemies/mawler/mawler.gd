class_name Mawler
extends Enemy
## HEG-X9 "MAWLER" Mining Crawler, the sector boss (DESIGN.md §8). Crawls in from the top and holds
## the top third of the screen, driving against the scroll so it stays put.
## Phase 1 (100-66%): the flank turrets fire aimed bursts; the plated body shrugs off hits until
## both turrets are gone (their damage comes off the boss's health).
## Phase 2 (66-33%): the jaws open on the core, spray debris fans (graze fodder) and launch Recon Drones.
## Phase 3 (33-0%): damaged and erratic, a rotating double spiral from the core, screen shake.
## Talks up to the Level with signals for drops, drones, blasts and shake; the Level does the spawning.

signal part_destroyed(at: Vector2, module: ModuleData)
signal drone_requested(at: Vector2)
signal blast_requested(at: Vector2)
signal shake_requested(strength: float, duration: float)

enum Phase { ENTERING, TURRETS, JAWS, MELTDOWN, DYING }

## HUD name (translation key).
@export var name_key: String = "BOSS_MAWLER"
## Where the body centre stops, in screen pixels from the top.
@export var hold_y: float = 190.0
@export var entry_speed: float = 90.0
## Health left when both turrets are gone: the body is plated until then.
@export var turrets_fraction: float = 0.34
## Health where phase 3 begins.
@export var meltdown_fraction: float = 0.33
@export var drone_scene: PackedScene

@export_group("Phase 2: jaws")
@export var debris_interval: float = 1.6
@export var debris_count: int = 11
## Total width of the debris fan, in degrees, aimed straight down the screen.
@export var debris_spread_degrees: float = 100.0
@export var debris_speed_min: float = 110.0
@export var debris_speed_max: float = 180.0
@export var debris_damage: int = 8
@export var debris_tint: Color = Color(0.62, 0.5, 0.38)
@export var drone_interval: float = 4.0
@export var drones_per_launch: int = 2

@export_group("Phase 3: meltdown")
@export var spiral_interval: float = 0.09
@export var spiral_step_degrees: float = 21.0
@export var spiral_arms: int = 2
@export var spiral_speed: float = 170.0
@export var spiral_damage: int = 10
@export var spiral_tint: Color = Color(1.0, 0.55, 0.2)
## The spiral fires for this long, then rests, so there's always a window to reposition.
@export var spiral_burst_time: float = 2.6
@export var spiral_rest_time: float = 1.1
## Erratic drift of the whole machine, and the shudder of its plates, in pixels.
@export var sway: float = 16.0
@export var jitter: float = 2.0
@export var damaged_tint: Color = Color(0.72, 0.62, 0.56)

@export_group("Death")
@export var death_time: float = 2.6
@export var death_blast_gap: float = 0.12
@export var final_blasts: int = 8

var phase: Phase = Phase.ENTERING

var _phase_time: float = 0.0
var _base_x: float = 0.0
var _turrets_left: int = 2
var _debris_cooldown: float = 0.0
var _drone_cooldown: float = 0.0
var _spiral_cooldown: float = 0.0
var _spiral_angle: float = 0.0
var _spiral_cycle: float = 0.0
var _tread_scroll: float = 0.0
var _plate_flash: float = 0.0

@onready var _turrets: Array[MawlerTurret] = [$TurretL, $TurretR]
@onready var _body: Node2D = $Visual/Body
@onready var _jaws: Array[Polygon2D] = [$Visual/JawL, $Visual/JawR]
@onready var _core: Polygon2D = $Visual/Core
@onready var _stumps: Array[Polygon2D] = [$Visual/StumpL, $Visual/StumpR]
@onready var _smoke: Array[CPUParticles2D] = [$Visual/SmokeL, $Visual/SmokeR]
@onready var _tread_bars: Array[Node2D] = [$Visual/TreadBarsL, $Visual/TreadBarsR]
@onready var _hitboxes: Array[CollisionShape2D] = [$BodyHitbox, $TreadHitboxL, $TreadHitboxR]


func _ready() -> void:
	super()
	for turret: MawlerTurret in _turrets:
		turret.boss = self
		turret.round_pool = round_pool
		turret.target = target
		turret.destroyed.connect(_on_turret_destroyed)
	for stump: Polygon2D in _stumps:
		stump.visible = false
	_core.modulate = Color(0.35, 0.35, 0.35)


## Seekers only bother with it once the core is open; before that the turrets are the targets.
func is_targetable() -> bool:
	return phase == Phase.JAWS or phase == Phase.MELTDOWN


func _tick(delta: float) -> void:
	_phase_time += delta
	# Drives forward at exactly the ground's speed, so it holds its place on screen.
	position.y -= ground_speed * delta
	_scroll_treads(delta)
	if _plate_flash > 0.0:
		_plate_flash -= delta
		if _plate_flash <= 0.0:
			_body.modulate = damaged_tint if phase == Phase.MELTDOWN else Color.WHITE
	match phase:
		Phase.ENTERING:
			position.y = move_toward(position.y, hold_y, entry_speed * delta)
			if is_equal_approx(position.y, hold_y):
				_set_phase(Phase.TURRETS)
		Phase.JAWS:
			_update_jaws(delta)
		Phase.MELTDOWN:
			_update_meltdown(delta)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_phase_time = 0.0
	match new_phase:
		Phase.JAWS:
			_base_x = position.x
			_open_jaws()
			_debris_cooldown = 1.0
			_drone_cooldown = 2.0
		Phase.MELTDOWN:
			_base_x = position.x
			_body.modulate = damaged_tint
			for smoke: CPUParticles2D in _smoke:
				smoke.emitting = true
			_spiral_cycle = 0.0
			shake_requested.emit(8.0, 0.6)


func _open_jaws() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_jaws[0], "rotation", -1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_jaws[1], "rotation", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_core, "modulate", Color(1.0, 1.0, 1.0), 0.7)
	shake_requested.emit(5.0, 0.5)


## Phase 2: debris fans down the screen and drones out of the jaws.
func _update_jaws(delta: float) -> void:
	_core.modulate = Color.WHITE.lerp(Color(1.4, 1.2, 1.0), 0.5 + 0.5 * sin(_phase_time * 6.0))
	_debris_cooldown -= delta
	if _debris_cooldown <= 0.0:
		_debris_cooldown = debris_interval
		_spray_debris()
	_drone_cooldown -= delta
	if _drone_cooldown <= 0.0:
		_drone_cooldown = drone_interval
		for i: int in drones_per_launch:
			var side: float = -1.0 if i % 2 == 0 else 1.0
			drone_requested.emit(_jaw_point() + Vector2(side * 30.0, 0.0))


func _spray_debris() -> void:
	if round_pool == null:
		return
	var step: float = deg_to_rad(debris_spread_degrees) / maxf(debris_count - 1, 1)
	var first: float = -deg_to_rad(debris_spread_degrees) * 0.5
	for i: int in debris_count:
		var direction: Vector2 = Vector2.DOWN.rotated(first + step * i + randf_range(-0.04, 0.04))
		round_pool.fire(_jaw_point(), direction * randf_range(debris_speed_min, debris_speed_max), debris_damage, debris_tint)


## Phase 3: erratic drift and a rotating double spiral from the core, in bursts.
func _update_meltdown(delta: float) -> void:
	position.x = _base_x + sin(_phase_time * 2.6) * sway
	_visual.position = Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
	_core.modulate = Color.WHITE.lerp(Color(1.6, 1.3, 1.0), 0.5 + 0.5 * sin(_phase_time * 14.0))
	_spiral_cycle = fmod(_spiral_cycle + delta, spiral_burst_time + spiral_rest_time)
	if _spiral_cycle >= spiral_burst_time:
		return
	_spiral_cooldown -= delta
	if _spiral_cooldown <= 0.0:
		_spiral_cooldown = spiral_interval
		_fire_spiral()


func _fire_spiral() -> void:
	if round_pool == null:
		return
	for arm: int in spiral_arms:
		var angle: float = _spiral_angle + TAU * arm / spiral_arms
		round_pool.fire(_jaw_point(), Vector2.from_angle(angle) * spiral_speed, spiral_damage, spiral_tint)
	_spiral_angle += deg_to_rad(spiral_step_degrees)


func _jaw_point() -> Vector2:
	return _core.global_position


func _scroll_treads(delta: float) -> void:
	# Bars roll down the tread as the crawler drives forward.
	_tread_scroll = fmod(_tread_scroll + 60.0 * delta, 30.0)
	for bars: Node2D in _tread_bars:
		var count: int = bars.get_child_count()
		for i: int in count:
			var bar: Node2D = bars.get_child(i) as Node2D
			bar.position.y = fmod(-90.0 + i * 30.0 + _tread_scroll, 180.0) - 90.0 + 0.0
			bar.position.y = wrapf(-85.0 + i * 30.0 + _tread_scroll, -85.0, 95.0)


## Plated until both turrets are gone: hits only flash the body. The core takes damage after that.
func take_damage(amount: int) -> void:
	if _dead:
		return
	if phase == Phase.ENTERING or phase == Phase.TURRETS:
		_body.modulate = Color(1.6, 1.6, 1.6)
		_plate_flash = FLASH_TIME
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	_flash_left = FLASH_TIME
	_visual.modulate = FLASH_MODULATE
	if phase == Phase.JAWS and hp <= data.max_hp * meltdown_fraction:
		_set_phase(Phase.MELTDOWN)


## Turret damage comes off the boss's health, down to the floor where the core opens.
func turret_damaged(amount: int) -> void:
	hp = maxi(hp - amount, _turret_floor())


func _turret_floor() -> int:
	return roundi(data.max_hp * (1.0 - turrets_fraction))


func _on_turret_destroyed(turret: Enemy) -> void:
	_turrets_left -= 1
	var index: int = _turrets.find(turret as MawlerTurret)
	if index >= 0:
		_stumps[index].visible = true
	part_destroyed.emit(turret.global_position, turret.data.module)
	blast_requested.emit(turret.global_position)
	shake_requested.emit(6.0, 0.4)
	if _turrets_left <= 0 and phase == Phase.TURRETS:
		hp = _turret_floor()
		_set_phase(Phase.JAWS)


## The long way down: blasts ripple over the body, then it goes up all at once.
func _die() -> void:
	if _dead:
		return
	_dead = true
	phase = Phase.DYING
	for hitbox: CollisionShape2D in _hitboxes:
		hitbox.set_deferred("disabled", true)
	for smoke: CPUParticles2D in _smoke:
		smoke.emitting = true
	_death_sequence()


func _death_sequence() -> void:
	var blasts: int = int(death_time / death_blast_gap)
	for i: int in blasts:
		blast_requested.emit(global_position + Vector2(randf_range(-170.0, 170.0), randf_range(-100.0, 90.0)))
		shake_requested.emit(4.0 + 8.0 * i / blasts, 0.25)
		_visual.modulate = FLASH_MODULATE if i % 3 == 0 else Color.WHITE
		await get_tree().create_timer(death_blast_gap).timeout
		if not is_inside_tree():
			return
	for i: int in final_blasts:
		blast_requested.emit(global_position + Vector2(randf_range(-190.0, 190.0), randf_range(-110.0, 100.0)))
	shake_requested.emit(14.0, 0.7)
	destroyed.emit(self)
	queue_free()
