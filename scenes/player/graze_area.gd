class_name GrazeArea
extends Area2D
## Near-miss detector (DESIGN.md §5.4/§5.7). Watches the enemy_bullets layer: a round that leaves
## this ring while still flying (so it didn't hit) counts as one graze. Each round counts only once.

signal grazed(at: Vector2)

var enabled: bool = true

@onready var _shape: CollisionShape2D = $Shape


func _ready() -> void:
	area_exited.connect(_on_area_exited)


func set_radius(radius: float, duration: float) -> void:
	var circle: CircleShape2D = _shape.shape as CircleShape2D
	if duration <= 0.0:
		circle.radius = radius
	else:
		create_tween().tween_property(circle, "radius", radius, duration)


func _on_area_exited(area: Area2D) -> void:
	if not enabled:
		return
	var enemy_round: EnemyRound = area as EnemyRound
	# A round that hit XF-0 (or was destroyed) is no longer active, so it doesn't count.
	if enemy_round == null or not enemy_round.is_active() or enemy_round.grazed:
		return
	enemy_round.grazed = true
	grazed.emit(enemy_round.global_position)
