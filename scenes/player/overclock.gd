class_name Overclock
extends Node2D
## Overclock (DESIGN.md §5.7). With a full meter, press `overclock`:
## 1. Meltdown pulse: enemy rounds near XF-0 become salvage (the Level does the converting).
## 2. A few seconds of white-hot hull, boosted damage and a heat aura that burns rounds away.
## 3. Each salvage pickup during it adds a little time, up to a cap.
## 4. When it ends, XF-0 gets a short invulnerability (the Player applies it on `finished`).

signal started
signal finished
signal meltdown(center: Vector2, radius: float)

@export var pulse_radius: float = 160.0
@export var duration: float = 5.0
## Total time one activation can reach, extensions included.
@export var max_duration: float = 10.0
@export var extend_per_salvage: float = 0.25
@export var damage_multiplier: float = 1.5
@export var aura_radius: float = 40.0
@export var end_invulnerability: float = 0.5
@export var ring_time: float = 0.35

## Turned off by the Player on death.
var enabled: bool = true
var active: bool = false

var _time_left: float = 0.0
var _granted: float = 0.0
var _age: float = 0.0
var _ring_age: float = -1.0

@onready var _heat_aura: Area2D = $HeatAura


func _ready() -> void:
	(($HeatAura/Shape as CollisionShape2D).shape as CircleShape2D).radius = aura_radius
	_heat_aura.area_entered.connect(_on_aura_touched)
	Events.salvage_collected.connect(_on_salvage_collected)


func _physics_process(delta: float) -> void:
	if active:
		_age += delta
		_time_left -= delta
		if _time_left <= 0.0:
			_end()
	elif enabled and Input.is_action_just_pressed("overclock") and GameState.is_overclock_full():
		_begin()
	if _ring_age >= 0.0:
		_ring_age += delta
		if _ring_age > ring_time:
			_ring_age = -1.0
	if active or _ring_age >= 0.0:
		queue_redraw()


func time_left() -> float:
	return maxf(_time_left, 0.0)


## Stops a running Overclock early with no end bonus (used on death).
func cancel() -> void:
	enabled = false
	if active:
		active = false
		_time_left = 0.0
		_heat_aura.set_deferred("monitoring", false)
		queue_redraw()
		Events.overclock_ended.emit()


func _begin() -> void:
	active = true
	# Heat Capacitor field mods add time.
	_time_left = duration + GameState.overclock_bonus_time
	_granted = _time_left
	_age = 0.0
	_ring_age = 0.0
	GameState.overclock = 0.0
	# Deferred: collision changes aren't allowed mid physics step. Rounds already inside fire area_entered.
	_heat_aura.set_deferred("monitoring", true)
	AudioManager.play("overclock_on")
	meltdown.emit(global_position, pulse_radius)
	started.emit()
	Events.overclock_started.emit()


func _end() -> void:
	active = false
	_time_left = 0.0
	_heat_aura.set_deferred("monitoring", false)
	queue_redraw()
	finished.emit()
	Events.overclock_ended.emit()


func _on_aura_touched(area: Area2D) -> void:
	var enemy_round: EnemyRound = area as EnemyRound
	if active and enemy_round != null and enemy_round.is_active():
		enemy_round.deactivate()


func _on_salvage_collected() -> void:
	if not active:
		return
	var extra: float = minf(extend_per_salvage, max_duration + GameState.overclock_bonus_time - _granted)
	if extra > 0.0:
		_granted += extra
		_time_left += extra


func _draw() -> void:
	if active:
		var flicker: float = 1.0 + 0.06 * sin(_age * 12.0)
		draw_circle(Vector2.ZERO, aura_radius * flicker, Color(1.0, 0.45, 0.1, 0.16))
		draw_circle(Vector2.ZERO, aura_radius * 0.62 * flicker, Color(1.0, 0.7, 0.3, 0.14))
		draw_arc(Vector2.ZERO, aura_radius * flicker, 0.0, TAU, 40, Color(1.0, 0.6, 0.2, 0.45), 1.5)
	if _ring_age >= 0.0:
		var t: float = _ring_age / ring_time
		var radius: float = lerpf(20.0, pulse_radius, 1.0 - (1.0 - t) * (1.0 - t))
		draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 0.95, 0.85, 0.3 * (1.0 - t)))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 1.0 - t), 1.0 + 4.0 * (1.0 - t))
