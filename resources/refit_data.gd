class_name RefitData
extends Resource
## One Field Refit offer (DESIGN.md §6, §7.1): the next level of a system line. Field mods extend this.
## Stored as .tres files in data/refits/ and listed in data/refits/catalog.tres.

enum Line { NONE, AUTOCANNON, BEAM, MISSILE, PROPULSION, ARMOR }

## Shown on the card. Weapon refits can leave this empty and use the weapon's own name.
@export var name_key: String = ""
@export var desc_key: String = ""
@export var line: Line = Line.NONE
## Level in its line (1 = first). Offered only when the line is exactly one level below this.
@export var level: int = 1
## "" for a normal level; "A" or "B" for the two choices at a line's last level.
@export var variant: String = ""
@export var hardpoint: WeaponData.Hardpoint = WeaponData.Hardpoint.NOSE
## The system this refit mounts. Empty for refits that only change stats.
@export var weapon: WeaponData
## Higher = offered more often.
@export var offer_weight: float = 1.0


func display_name() -> String:
	if name_key == "" and weapon != null:
		return weapon.name_key
	return name_key


## Field mods don't count toward weight class (§6).
func counts_toward_weight() -> bool:
	return true


## True if the player can be offered this right now.
func is_available() -> bool:
	return GameState.system_level(line) == level - 1


## The nose weapon this would replace (nose rule, §6), or null if it doesn't swap anything.
func swaps_out() -> WeaponData:
	if hardpoint != WeaponData.Hardpoint.NOSE or level != 1:
		return null
	return GameState.weapons.get(WeaponData.Hardpoint.NOSE)


func apply() -> void:
	if line == Line.BEAM or line == Line.AUTOCANNON:
		# Nose rule: one primary weapon line at a time.
		GameState.system_levels.erase(Line.AUTOCANNON if line == Line.BEAM else Line.BEAM)
	GameState.system_levels[line] = level
	if weapon != null:
		GameState.weapons[weapon.hardpoint] = weapon
