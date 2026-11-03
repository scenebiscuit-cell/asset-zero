extends Node
## Data for the current run. Cleared when a new run starts.

const START_MAX_ARMOR: int = 100

var salvage: int = 0
var max_armor: int = START_MAX_ARMOR
var armor: int = START_MAX_ARMOR


func reset_run() -> void:
	salvage = 0
	max_armor = START_MAX_ARMOR
	armor = max_armor


func add_salvage(amount: int) -> void:
	salvage += amount
	print("Salvage: ", salvage) # Temporary until the HUD exists (Step 8).


func repair_armor(amount: int) -> void:
	armor = mini(armor + amount, max_armor)
	print("Armor: ", armor) # Temporary until the HUD exists (Step 8).


## Returns true when Armor has run out.
func damage_armor(amount: int) -> bool:
	armor = maxi(armor - amount, 0)
	print("Armor: ", armor) # Temporary until the HUD exists (Step 8).
	return armor == 0
