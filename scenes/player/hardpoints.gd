class_name Hardpoints
extends Node2D
## XF-0's hardpoints (DESIGN.md §5.1). Mounts a weapon scene for each WeaponData and passes the
## Player's fire, form and damage state down to it. One system per hardpoint: equipping replaces it.

## What a fresh run starts with (the M20 Autocannon on the Nose).
@export var start_loadout: Array[WeaponData] = []

var _round_pool: RoundPool
var _missile_pool: MissilePool
var _weapons: Dictionary[int, Weapon] = {}
var _firing: bool = false
var _converged: bool = false
var _damage_multiplier: float = 1.0
var _enabled: bool = true

@onready var _slots: Dictionary[int, Node2D] = {
	WeaponData.Hardpoint.NOSE: $Nose,
	WeaponData.Hardpoint.WING_PYLONS: $WingPylons,
	WeaponData.Hardpoint.ENGINE: $Engine,
	WeaponData.Hardpoint.HULL: $Hull,
	WeaponData.Hardpoint.SALVAGE_MOUNT: $SalvageMount,
}
@onready var _nose: Node2D = $Nose
@onready var _salvage_mount: Node2D = $SalvageMount
@onready var _pylon_left: Node2D = $WingPylons/Left
@onready var _pylon_right: Node2D = $WingPylons/Right


## Called by the Player once its pools are known. A run in progress keeps its loadout across sectors.
func setup(round_pool: RoundPool, missile_pool: MissilePool) -> void:
	_round_pool = round_pool
	_missile_pool = missile_pool
	if GameState.weapons.is_empty():
		for weapon_data: WeaponData in start_loadout:
			GameState.weapons[weapon_data.hardpoint] = weapon_data
	for hardpoint: int in GameState.weapons:
		_mount(GameState.weapons[hardpoint])


func equip(weapon_data: WeaponData) -> void:
	GameState.weapons[weapon_data.hardpoint] = weapon_data
	_mount(weapon_data)


func unequip(hardpoint: WeaponData.Hardpoint) -> void:
	GameState.weapons.erase(hardpoint)
	if _weapons.has(hardpoint):
		_weapons[hardpoint].queue_free()
		_weapons.erase(hardpoint)


func equipped(hardpoint: WeaponData.Hardpoint) -> WeaponData:
	return GameState.weapons.get(hardpoint, null) as WeaponData


## Called every frame by the Player, so it only touches the weapons when something changed.
func set_firing(on: bool) -> void:
	if on == _firing:
		return
	_firing = on
	for weapon: Weapon in _weapons.values():
		weapon.firing = on


func set_converged(on: bool) -> void:
	_converged = on
	for weapon: Weapon in _weapons.values():
		weapon.converged = on


func set_damage_multiplier(multiplier: float) -> void:
	_damage_multiplier = multiplier
	for weapon: Weapon in _weapons.values():
		weapon.damage_multiplier = multiplier


## XF-0 is destroyed: everything stops, including systems that fire on their own.
func shut_down() -> void:
	_enabled = false
	set_firing(false)
	for weapon: Weapon in _weapons.values():
		weapon.enabled = false


## Weapons slide to the new nose and pylons as the airframe morphs (DESIGN.md §5.6).
func apply_shape(shape: AirframeShape, duration: float) -> void:
	var left: Vector2 = Vector2(-shape.pylon_offset.x, shape.pylon_offset.y)
	if duration <= 0.0:
		_nose.position = shape.muzzle_offset
		_pylon_left.position = left
		_pylon_right.position = shape.pylon_offset
		_salvage_mount.position = shape.mount_offset
		return
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_nose, "position", shape.muzzle_offset, duration)
	tween.tween_property(_pylon_left, "position", left, duration)
	tween.tween_property(_pylon_right, "position", shape.pylon_offset, duration)
	tween.tween_property(_salvage_mount, "position", shape.mount_offset, duration)


func _mount(weapon_data: WeaponData) -> void:
	var hardpoint: WeaponData.Hardpoint = weapon_data.hardpoint
	if _weapons.has(hardpoint):
		_weapons[hardpoint].queue_free()
	var weapon: Weapon = weapon_data.scene.instantiate() as Weapon
	weapon.data = weapon_data
	weapon.round_pool = _round_pool
	weapon.missile_pool = _missile_pool
	weapon.firing = _firing
	weapon.converged = _converged
	weapon.damage_multiplier = _damage_multiplier
	weapon.enabled = _enabled
	if hardpoint == WeaponData.Hardpoint.WING_PYLONS:
		weapon.launch_points.assign([_pylon_left, _pylon_right])
	else:
		weapon.launch_points.assign([_slots[hardpoint]])
	_slots[hardpoint].add_child(weapon)
	_weapons[hardpoint] = weapon
