class_name FieldModData
extends RefitData
## Small filler offer (DESIGN.md §6 "Field mods"). Doesn't count toward weight class.
## Only Field Repair and Armor Kit exist so far; the rest arrive in Step 14.

enum Effect { REPAIR, MAX_ARMOR }

@export var effect: Effect = Effect.REPAIR
@export var amount: int = 30


func counts_toward_weight() -> bool:
	return false


func is_available() -> bool:
	if effect == Effect.REPAIR:
		return GameState.armor < GameState.max_armor
	return true


func swaps_out() -> WeaponData:
	return null


func apply() -> void:
	match effect:
		Effect.REPAIR:
			GameState.repair_armor(amount)
		Effect.MAX_ARMOR:
			GameState.max_armor += amount
			GameState.armor += amount
