class_name Enemy
extends Area2D
## Shared enemy logic: health, hit flash and death. Each enemy's own script adds movement.

signal destroyed(enemy: Enemy)

const FLASH_TIME: float = 0.06
## Multiplying every colour this hard pushes it to white.
const FLASH_MODULATE: Color = Color(10.0, 10.0, 10.0)
## How far below the screen an enemy can go before it's removed.
const OFFSCREEN_MARGIN: float = 40.0

@export var data: EnemyData

var hp: int = 0
var _flash_left: float = 0.0
var _dead: bool = false

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	hp = data.max_hp


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_visual.modulate = Color.WHITE


func take_damage(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	_flash_left = FLASH_TIME
	_visual.modulate = FLASH_MODULATE


func is_below_screen() -> bool:
	return global_position.y > get_viewport_rect().size.y + OFFSCREEN_MARGIN


func _die() -> void:
	_dead = true
	destroyed.emit(self)
	queue_free()
