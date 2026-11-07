class_name DebugLoadout
extends Node
## Debug builds only (ROADMAP Step 10): number keys swap weapons for testing.
## 1: next nose weapon in nose_options. 2: cycles the pylons: empty, then each of pylon_options in
## order, then empty again. 3: the same for the Salvage Mount with module_options (skipping the
## absorb animation). 4 and 5: cycle the Propulsion and Armor lines (stock, then each level).
## 6: next weight class (sets the refit count to the next class's minimum, back to Light after Assault).
## Removes itself in release exports, so players never get these keys.

@export var hardpoints: Hardpoints
@export var nose_options: Array[WeaponData] = []
@export var pylon_options: Array[WeaponData] = []
@export var module_options: Array[ModuleData] = []
@export var propulsion_options: Array[SystemRefitData] = []
@export var armor_options: Array[SystemRefitData] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = _number(key)
	if index == 0 and not nose_options.is_empty():
		var next: int = (nose_options.find(hardpoints.equipped(WeaponData.Hardpoint.NOSE)) + 1) % nose_options.size()
		hardpoints.equip(nose_options[next])
		print("Debug loadout: ", tr(nose_options[next].name_key))
	elif index == 1:
		_cycle(WeaponData.Hardpoint.WING_PYLONS, pylon_options)
	elif index == 2:
		_cycle(WeaponData.Hardpoint.SALVAGE_MOUNT, module_options)
	elif index == 3:
		_cycle_system(RefitData.Line.PROPULSION, propulsion_options)
	elif index == 4:
		_cycle_system(RefitData.Line.ARMOR, armor_options)
	elif index == 5:
		var next: int = (GameState.weight_class + 1) % GameState.CLASS_MIN_REFITS.size()
		GameState.set_refit_count(GameState.CLASS_MIN_REFITS[next])
		print("Debug loadout: ", GameState.WeightClass.keys()[next], " (", GameState.refit_count, " refits)")
	else:
		return
	(get_parent() as Player).refresh_airframe()
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


func _cycle_system(line: RefitData.Line, options: Array[SystemRefitData]) -> void:
	if options.is_empty():
		return
	var next: int = options.find(GameState.system_refit(line)) + 1
	if next >= options.size():
		GameState.installed_systems.erase(line)
		GameState.system_levels.erase(line)
		if line == RefitData.Line.ARMOR:
			GameState.max_plating = 0
			GameState.plating = 0
		print("Debug loadout: ", RefitData.Line.keys()[line], " stock")
	else:
		options[next].apply()
		print("Debug loadout: ", tr(options[next].display_name()))
	(get_parent() as Player).refresh_systems()


## 0 for the 1 key, 1 for the 2 key, and so on; -1 for anything else. Top row or number pad, read
## by position or by the character typed, so it works on any keyboard layout.
func _number(key: InputEventKey) -> int:
	for code: Key in [key.physical_keycode, key.keycode]:
		if code >= KEY_1 and code <= KEY_9:
			return code - KEY_1
		if code >= KEY_KP_1 and code <= KEY_KP_9:
			return code - KEY_KP_1
	return -1
