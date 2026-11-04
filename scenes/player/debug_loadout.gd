class_name DebugLoadout
extends Node
## Debug builds only (ROADMAP Step 10): number keys swap weapons for testing.
## 1, 2, 3...: the nose weapons in nose_options order. The key after those cycles the pylons:
## empty, then each of pylon_options in order, then empty again. The key after that does the same
## for the Salvage Mount with module_options (skipping the absorb animation).
## Removes itself in release exports, so players never get these keys.

@export var hardpoints: Hardpoints
@export var nose_options: Array[WeaponData] = []
@export var pylon_options: Array[WeaponData] = []
@export var module_options: Array[ModuleData] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = _number(key)
	if index >= 0 and index < nose_options.size():
		hardpoints.equip(nose_options[index])
		print("Debug loadout: ", tr(nose_options[index].name_key))
	elif index == nose_options.size():
		_cycle(WeaponData.Hardpoint.WING_PYLONS, pylon_options)
	elif index == nose_options.size() + 1:
		_cycle(WeaponData.Hardpoint.SALVAGE_MOUNT, module_options)
	else:
		return
	get_viewport().set_input_as_handled()


func _cycle(hardpoint: WeaponData.Hardpoint, options: Array) -> void:
	if options.is_empty():
		return
	var next: int = options.find(hardpoints.equipped(hardpoint)) + 1
	if next >= options.size():
		hardpoints.unequip(hardpoint)
		print("Debug loadout: ", WeaponData.Hardpoint.keys()[hardpoint], " empty")
		return
	hardpoints.equip(options[next])
	print("Debug loadout: ", tr(options[next].name_key))


## 0 for the 1 key, 1 for the 2 key, and so on; -1 for anything else. Top row or number pad, read
## by position or by the character typed, so it works on any keyboard layout.
func _number(key: InputEventKey) -> int:
	for code: Key in [key.physical_keycode, key.keycode]:
		if code >= KEY_1 and code <= KEY_9:
			return code - KEY_1
		if code >= KEY_KP_1 and code <= KEY_KP_9:
			return code - KEY_KP_1
	return -1
