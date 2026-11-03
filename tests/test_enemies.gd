extends Node2D
## Test only: number keys spawn one enemy of each type at the top of the screen.
## Hold Shift with the key for the elite version. Drone lines are switched off in this scene.

const SPAWNS: Dictionary[int, String] = {
	KEY_1: "res://scenes/enemies/recon_drone/recon_drone.tscn",
	KEY_2: "res://scenes/enemies/interceptor_drone/interceptor_drone.tscn",
	KEY_3: "res://scenes/enemies/aa_emplacement/aa_emplacement.tscn",
}

@onready var _level: Level = $Level


func _ready() -> void:
	print("Enemy test: 1 RD-2 Recon  2 ID-4 Interceptor  3 AA Emplacement  (hold Shift for elite)")


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# physical_keycode ignores Shift, so Shift+1 still reads as KEY_1.
	if not SPAWNS.has(key.physical_keycode):
		return
	var scene: PackedScene = load(SPAWNS[key.physical_keycode])
	var at: Vector2 = Vector2(randf_range(80.0, get_viewport_rect().size.x - 80.0), -50.0)
	var enemy: Enemy = _level.spawn_enemy(scene, at, key.shift_pressed)
	print("Spawned ", enemy.name, " elite=", enemy.elite, " hp=", enemy.hp, " salvage=", enemy.salvage_value())
