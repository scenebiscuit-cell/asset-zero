extends SceneTree
## Every weight class x Propulsion x nose x pylon, in both forms: can every airframe part be drawn?
## Run after tools/gen_shapes.py:  Godot --headless --script tools/check_shapes.gd --path .
## Prints BAD lines for twisted polygons; the last line should say "bad combos: 0".
var _done: bool = false

func _process(_delta: float) -> bool:
	if _done: return true
	_done = true
	var gs: Node = root.get_node("GameState")
	var airframes = load("res://data/shapes/xf0_airframes.tres")
	var noses: Array = ["m20_autocannon", "m20d_twin_autocannon", "m40_flak_battery", "rg9_railgun", "hel1_beam_laser", "hel2_focused_beam", "hel3t_thermal_lance", "hel3s_split_array"]
	var pylons: Array = ["", "r1_rocket_pod", "mk1_seeker", "mk2_seeker_pod", "mk3_cluster_missile", "gbu_bunker_buster"]
	var props: Array = ["", "propulsion_1", "propulsion_2", "propulsion_3a", "propulsion_3b"]
	var seen: Dictionary = {}
	var checked: int = 0
	for c in 4:
		gs.set_refit_count([0, 3, 6, 9][c])
		for prop in props:
			gs.installed_systems.erase(4); gs.system_levels.erase(4)
			if prop != "": load("res://data/refits/" + prop + ".tres").apply()
			for nose in noses:
				gs.weapons[0] = load("res://data/weapons/" + nose + ".tres")
				for pylon in pylons:
					gs.weapons.erase(1)
					if pylon != "": gs.weapons[1] = load("res://data/weapons/" + pylon + ".tres")
					for thresher in [false, true]:
						var shape = airframes.build(thresher)
						for part in shape.parts:
							var pts: PackedVector2Array = shape.parts[part]
							if pts.size() < 3: continue
							checked += 1
							if Geometry2D.triangulate_polygon(pts).is_empty():
								var key: String = "class %d %s %s %s" % [c, "thresher" if thresher else "gunship", part, prop if part == "Hull" else (nose if part in ["Barrel", "Rail", "Lens"] else pylon)]
								if not seen.has(key):
									seen[key] = true
									print("BAD ", key, " ", pts)
	print("checked ", checked, " parts, bad combos: ", seen.size())
	return true
