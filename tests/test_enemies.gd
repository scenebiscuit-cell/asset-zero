extends Node2D
## Test only: number keys spawn one enemy of each type at the top of the screen.
## Hold Shift with the key for the elite version. Drone lines are switched off in this scene.

const SPAWNS: Dictionary[int, String] = {
	KEY_1: "res://scenes/enemies/recon_drone/recon_drone.tscn",
	KEY_2: "res://scenes/enemies/interceptor_drone/interceptor_drone.tscn",
	KEY_3: "res://scenes/enemies/aa_emplacement/aa_emplacement.tscn",
	KEY_4: "res://scenes/enemies/mining_platform/mining_platform.tscn",
	KEY_5: "res://scenes/enemies/armored_transport/armored_transport.tscn",
	KEY_6: "res://scenes/enemies/hg7_gunship/hg7_gunship.tscn",
}
## The transport enters from a side edge, not the top.
const SIDE_ENTRY: Array[int] = [KEY_5]

@onready var _level: Level = $Level


func _ready() -> void:
	print("Enemy test: 1 RD-2  2 ID-4  3 AA Emplacement  4 Mining Platform  5 Armored Transport  6 HG-7 Gunship  (hold Shift for elite)")


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# physical_keycode ignores Shift, so Shift+1 still reads as KEY_1.
	if not SPAWNS.has(key.physical_keycode):
		return
	var scene: PackedScene = load(SPAWNS[key.physical_keycode])
	var size: Vector2 = get_viewport_rect().size
	var at: Vector2 = Vector2(randf_range(80.0, size.x - 80.0), -50.0)
	if SIDE_ENTRY.has(key.physical_keycode):
		at = Vector2(-50.0 if randf() < 0.5 else size.x + 50.0, randf_range(120.0, 320.0))
	var enemy: Enemy = _level.spawn_enemy(scene, at, key.shift_pressed)
	print("Spawned ", enemy.name, " elite=", enemy.elite, " hp=", enemy.hp, " salvage=", enemy.salvage_value())
