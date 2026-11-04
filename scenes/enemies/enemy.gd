class_name Enemy
extends Area2D
## Shared enemy logic: health, elite status, hit flash, death, ground scroll and firing.
## Each enemy's own script adds movement in _tick().

signal destroyed(enemy: Enemy)
## An air unit got away (off the bottom, or out its exit route) without being destroyed.
signal escaped(enemy: Enemy)

const FLASH_TIME: float = 0.06
## Multiplying every colour this hard pushes it to white.
const FLASH_MODULATE: Color = Color(10.0, 10.0, 10.0)
## How far below the screen an enemy can go before it's removed.
const OFFSCREEN_MARGIN: float = 40.0
const ELITE_HP_MULTIPLIER: int = 2
const ELITE_SALVAGE_MULTIPLIER: int = 2
# Collision layers from CLAUDE.md.
const LAYER_ENEMIES_AIR: int = 1 << 2
const LAYER_ENEMIES_GROUND: int = 1 << 3
## Ground units draw between the terrain (-10) and air-unit shadows (-8).
const GROUND_Z_INDEX: int = -9

@export var data: EnemyData

## All set by the spawner (Level / wave director) before add_child().
var elite: bool = false
var round_pool: RoundPool
var target: Node2D
var ground_speed: float = 60.0

var hp: int = 0
## Yellow halo, only on elites.
var elite_outline: EliteOutline
var _flash_left: float = 0.0
var _dead: bool = false

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	hp = data.max_hp * (ELITE_HP_MULTIPLIER if elite else 1)
	if data.layer == EnemyData.Layer.GROUND:
		collision_layer = LAYER_ENEMIES_GROUND
		z_index = GROUND_Z_INDEX
	else:
		collision_layer = LAYER_ENEMIES_AIR
	if elite:
		elite_outline = EliteOutline.new()
		elite_outline.source = _visual
		add_child(elite_outline)
		move_child(elite_outline, 0) # Drawn first, so it sits under the shapes as a halo.


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_visual.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	if data.layer == EnemyData.Layer.GROUND:
		position.y += ground_speed * delta
	_tick(delta)
	if is_below_screen():
		escape()


## Per-enemy behaviour. Override in each enemy's script.
func _tick(_delta: float) -> void:
	pass


func take_damage(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	_flash_left = FLASH_TIME
	_visual.modulate = FLASH_MODULATE


## False while an enemy can't be hit (e.g. a burrowed Mining Platform), so seekers skip it.
func is_targetable() -> bool:
	return true


func salvage_value() -> int:
	return data.salvage * (ELITE_SALVAGE_MULTIPLIER if elite else 1)


## Fires one enemy round from `start` (global) along `direction`.
func fire(start: Vector2, direction: Vector2) -> void:
	if round_pool == null:
		return
	round_pool.fire(start, direction.normalized() * data.round_speed, data.round_damage)


func direction_to_target() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.DOWN
	return global_position.direction_to(target.global_position)


func is_on_screen() -> bool:
	return get_viewport_rect().has_point(global_position)


func is_below_screen() -> bool:
	return global_position.y > get_viewport_rect().size.y + OFFSCREEN_MARGIN


## Leaves the fight with no salvage. Only aircraft count as a breach; ground units just scroll away.
func escape() -> void:
	if _dead:
		return
	_dead = true
	if data.layer == EnemyData.Layer.AIR:
		escaped.emit(self)
	queue_free()


func _die() -> void:
	_dead = true
	destroyed.emit(self)
	queue_free()
