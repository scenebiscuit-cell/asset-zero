class_name PlayerRound
extends Round
## Player tracer round. Damages the first enemy it touches. Guns can make it pierce (Railgun) or
## burst into fragments on hit (Flak Battery); fire() resets those, so set them after firing.

var pierce: bool = false
var fragments: int = 0
var fragment_damage: int = 0
var fragment_speed: float = 0.0
var fragment_range: float = 0.0
## A fragment ignores the enemy its parent round just hit, or it would hit it again at once.
var ignore: Enemy
var _hit: Array[Enemy] = []

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func activate(start: Vector2, velocity: Vector2, round_damage: int) -> void:
	pierce = false
	fragments = 0
	ignore = null
	_hit.clear()
	set_length(1.0)
	super.activate(start, velocity, round_damage)


func set_length(length: float) -> void:
	_visual.scale = Vector2(maxf(length * 0.6, 1.0) if length > 1.0 else length, length)


func _on_area_entered(area: Area2D) -> void:
	if not is_active() or not area is Enemy:
		return
	var enemy: Enemy = area as Enemy
	if enemy == ignore or _hit.has(enemy):
		return
	enemy.take_damage(damage)
	if fragments > 0:
		_burst_fragments(enemy)
	if pierce:
		_hit.append(enemy)
	else:
		deactivate()


func _burst_fragments(enemy: Enemy) -> void:
	var pool: RoundPool = get_parent() as RoundPool
	if pool == null:
		return
	var offset: float = randf() * TAU
	for i: int in fragments:
		var direction: Vector2 = Vector2.from_angle(offset + TAU * i / fragments)
		var fragment: PlayerRound = pool.fire(global_position, direction * fragment_speed, fragment_damage, modulate) as PlayerRound
		if fragment == null:
			return
		fragment.ignore = enemy
		fragment.range_left = fragment_range
		fragment.set_length(0.45)
