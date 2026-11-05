class_name FieldModData
extends RefitData
## Small filler offer (DESIGN.md §6 "Field mods"). Doesn't count toward weight class.
## Stat mods stack up to max_stacks; GameState keeps the totals and the systems read them.

enum Effect { REPAIR, MAX_ARMOR, DAMAGE, FIRE_RATE, MAGNET, HEAT_CAPACITOR, RETENTION }

@export var effect: Effect = Effect.REPAIR
## Armor for REPAIR and MAX_ARMOR.
@export var amount: int = 30
## Fraction for DAMAGE / FIRE_RATE / MAGNET (0.1 = +10%), seconds for HEAT_CAPACITOR.
@export var bonus: float = 0.0
## How many times one run can take this. 0 = no limit.
@export var max_stacks: int = 0


func counts_toward_weight() -> bool:
	return false


func is_available() -> bool:
	match effect:
		Effect.REPAIR:
			return GameState.armor < GameState.max_armor
		Effect.RETENTION:
			# One charge at a time: a second would do nothing until the first is used.
			return GameState.retention_charges == 0
	return max_stacks <= 0 or GameState.field_mod_count(effect) < max_stacks


func swaps_out() -> WeaponData:
	return null


func apply() -> void:
	GameState.field_mod_counts[effect] = GameState.field_mod_count(effect) + 1
	match effect:
		Effect.REPAIR:
			GameState.repair_armor(amount)
		Effect.MAX_ARMOR:
			GameState.max_armor += amount
			GameState.armor += amount
		Effect.DAMAGE:
			GameState.damage_bonus += bonus
		Effect.FIRE_RATE:
			GameState.fire_rate_bonus += bonus
		Effect.MAGNET:
			GameState.magnet_bonus += bonus
		Effect.HEAT_CAPACITOR:
			GameState.overclock_bonus_time += bonus
		Effect.RETENTION:
			GameState.retention_charges += 1
