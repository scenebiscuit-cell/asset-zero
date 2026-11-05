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
## Burning (HEL-3T Thermal Lance): damage is dealt in small ticks, and the hull glows orange.
const BURN_TICK: float = 0.2
const BURN_TINT: Color = Color(1.6, 0.75, 0.35)

## Bottom of the play area (top of the HUD console), set by the Level. 0 = the screen bottom.
static var play_area_bottom: float = 0.0
## Top of the play area (under the top HUD console). Enemies above it are hidden and hold fire.
static var play_area_top: float = 0.0

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
var _burn_left: float = 0.0
var _burn_dps: float = 0.0
var _burn_tick_left: float = 0.0

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
	if _burn_left > 0.0:
		_update_burn(delta)


## Sets the enemy burning; a new burn refreshes the timer and keeps the stronger damage.
func apply_burn(dps: float, duration: float) -> void:
	if _dead or dps <= 0.0:
		return
	_burn_dps = maxf(_burn_dps, dps) if _burn_left > 0.0 else dps
	_burn_left = maxf(_burn_left, duration)


func _update_burn(delta: float) -> void:
	_burn_left -= delta
	_burn_tick_left -= delta
	if _flash_left <= 0.0:
		# Flickers so it reads as fire, not a colour change.
		var flicker: float = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
		_visual.modulate = Color.WHITE.lerp(BURN_TINT, flicker) if _burn_left > 0.0 else Color.WHITE
	if _burn_tick_left <= 0.0:
		_burn_tick_left = BURN_TICK
		take_damage(maxi(roundi(_burn_dps * BURN_TICK), 1))


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


## Visible and in the play area: anything behind the HUD console doesn't fire or get targeted.
func is_on_screen() -> bool:
	var area: Rect2 = get_viewport_rect()
	if play_area_bottom > 0.0:
		area.end.y = minf(area.end.y, play_area_bottom)
	if play_area_top > 0.0:
		area = Rect2(area.position.x, play_area_top, area.size.x, area.end.y - play_area_top)
	return area.has_point(global_position)


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
