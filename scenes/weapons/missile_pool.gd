class_name MissilePool
extends ObjectPool
## Pool of player Seeker missiles. It also finds their targets, since it's told where the enemies are.

## The Level's Enemies node.
@export var targets: Node2D


func launch(start: Vector2, direction: Vector2, missile_data: MissileData, damage: int, ahead_only: bool) -> void:
	var missile: Missile = acquire() as Missile
	if missile == null:
		return
	missile.activate(start, direction, missile_data, damage, ahead_only, self)


## Nearest living enemy on screen. With ahead_only, only those within cone_degrees of straight up.
func find_target(from: Vector2, ahead_only: bool, cone_degrees: float) -> Enemy:
	if targets == null:
		return null
	var best: Enemy = null
	var best_distance: float = INF
	var max_angle: float = deg_to_rad(cone_degrees)
	for child: Node in targets.get_children():
		var enemy: Enemy = child as Enemy
		if enemy == null or enemy.hp <= 0 or not enemy.is_on_screen():
			continue
		var offset: Vector2 = enemy.global_position - from
		if ahead_only and absf(Vector2.UP.angle_to(offset)) > max_angle:
			continue
		var distance: float = offset.length_squared()
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best
