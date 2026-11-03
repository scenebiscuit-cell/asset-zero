extends Node
## Data for the current run. Cleared when a new run starts.

const START_MAX_ARMOR: int = 100
const OVERCLOCK_MAX: float = 100.0
## Overclock gained per salvage pickup (DESIGN.md §5.7).
const OVERCLOCK_PER_SALVAGE: float = 2.0

enum WeightClass { LIGHT, MEDIUM, HEAVY, ASSAULT }

var salvage: int = 0
var max_armor: int = START_MAX_ARMOR
var armor: int = START_MAX_ARMOR
## Regenerating shield (§5.4). Starts at 0 until Armor refits exist (Milestone C).
var plating: int = 0
var max_plating: int = 0
var weight_class: WeightClass = WeightClass.LIGHT
## HSD Threat Level 1-4 (§9.1). Follows weight class from Step 15.
var threat_level: int = 1
## The assimilated weapon module on the Salvage Mount (§5.8), or null. Filled in Step 11.
var assimilated_module: Resource = null
var overclock: float = 0.0
## Which sector of the run we're on (0 = Sector 1).
var sector_index: int = 0
## False until a level starts a run; the Level resets everything when it finds no run in progress.
var run_active: bool = false


func reset_run() -> void:
	salvage = 0
	max_armor = START_MAX_ARMOR
	armor = max_armor
	plating = 0
	max_plating = 0
	weight_class = WeightClass.LIGHT
	threat_level = 1
	assimilated_module = null
	overclock = 0.0
	sector_index = 0
	run_active = true


## Called on death: the next level load starts a fresh run.
func end_run() -> void:
	run_active = false


## Called on SECTOR CLEAR: Armor, salvage and Overclock carry over.
func advance_sector() -> void:
	sector_index += 1


func add_salvage(amount: int) -> void:
	salvage += amount
	add_overclock(OVERCLOCK_PER_SALVAGE)
	Events.salvage_collected.emit()


func add_overclock(amount: float) -> void:
	overclock = minf(overclock + amount, OVERCLOCK_MAX)


func is_overclock_full() -> bool:
	return overclock >= OVERCLOCK_MAX


func repair_armor(amount: int) -> void:
	armor = mini(armor + amount, max_armor)


## Returns true when Armor has run out.
func damage_armor(amount: int) -> bool:
	armor = maxi(armor - amount, 0)
	return armor == 0
