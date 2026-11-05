extends Node
## Data for the current run. Cleared when a new run starts.

const START_MAX_ARMOR: int = 100
const OVERCLOCK_MAX: float = 100.0
## Overclock gained per salvage pickup (DESIGN.md §5.7).
const OVERCLOCK_PER_SALVAGE: float = 2.0
const OVERCLOCK_PER_GRAZE: float = 1.0
const OVERCLOCK_PER_ELITE: float = 10.0

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
## What's mounted on each hardpoint (WeaponData.Hardpoint -> WeaponData). Empty = stock loadout.
var weapons: Dictionary[int, WeaponData] = {}
var overclock: float = 0.0
## Fire Control pickups collected but not yet activated (DESIGN.md §7.3).
var fire_control_charges: int = 0
## Level reached in each system line (RefitData.Line -> level). The run starts with Autocannon 1.
var system_levels: Dictionary[int, int] = {}
## Refits installed this run that count toward weight class (field mods don't).
var refit_count: int = 0
## Field Refit rerolls bought this run; each one makes the next cost more.
var rerolls_bought: int = 0
## Kills toward the next Saturation Strike charge (§7.4), and charges stored. Both carry over.
var strike_progress: int = 0
var strike_charges: int = 0
## Enemies destroyed since the last kill-count repair kit dropped.
var kills_toward_repair: int = 0
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
	weapons.clear()
	overclock = 0.0
	fire_control_charges = 0
	system_levels = {RefitData.Line.AUTOCANNON: 1}
	refit_count = 0
	rerolls_bought = 0
	kills_toward_repair = 0
	strike_progress = 0
	strike_charges = 0
	sector_index = 0
	run_active = true


func system_level(line: RefitData.Line) -> int:
	return system_levels.get(line, 0)


func install_refit(refit: RefitData) -> void:
	refit.apply()
	if refit.counts_toward_weight():
		refit_count += 1


## Called on death: the next level load starts a fresh run.
func end_run() -> void:
	run_active = false


## Called on SECTOR CLEAR: Armor, salvage and Overclock carry over.
func advance_sector() -> void:
	sector_index += 1
	# The assimilated module dissolves at the end of the sector (§5.8).
	weapons.erase(WeaponData.Hardpoint.SALVAGE_MOUNT)


## The weapon module on the Salvage Mount (§5.8), or null.
func assimilated_module() -> ModuleData:
	return weapons.get(WeaponData.Hardpoint.SALVAGE_MOUNT, null) as ModuleData


func add_salvage(amount: int) -> void:
	salvage += amount
	add_overclock(OVERCLOCK_PER_SALVAGE)
	Events.salvage_collected.emit()


## Rewards paid out by the game (not picked up), so they don't charge Overclock.
func award_salvage(amount: int) -> void:
	salvage += amount


## Pays for something (Field Refit reroll, Armory). Returns false, and pays nothing, if short.
func spend_salvage(amount: int) -> bool:
	if amount > salvage:
		return false
	salvage -= amount
	return true


## Returns how much was actually lost (salvage never goes below 0).
func lose_salvage(amount: int) -> int:
	var lost: int = mini(amount, salvage)
	salvage -= lost
	return lost


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
