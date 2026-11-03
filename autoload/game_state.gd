extends Node
## Data for the current run. Cleared when a new run starts.

const START_MAX_ARMOR: int = 100

var salvage: int = 0
var max_armor: int = START_MAX_ARMOR
var armor: int = START_MAX_ARMOR
## Which sector of the run we're on (0 = Sector 1).
var sector_index: int = 0
## False until a level starts a run; the Level resets everything when it finds no run in progress.
var run_active: bool = false


func reset_run() -> void:
	salvage = 0
	max_armor = START_MAX_ARMOR
	armor = max_armor
	sector_index = 0
	run_active = true


## Called on death: the next level load starts a fresh run.
func end_run() -> void:
	run_active = false


## Called on SECTOR CLEAR: Armor and salvage carry over.
func advance_sector() -> void:
	sector_index += 1


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
