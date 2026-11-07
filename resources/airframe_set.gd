class_name AirframeSet
extends Resource
## XF-0's airframe for every loadout (DESIGN.md §5.2, §5.3): a Gunship and a Thresher base shape per
## weight class, plus the overlay each installed refit carries. Used by the ship and the Field
## Refit schematic, so both always show the same airframe.

## Indexed by GameState.WeightClass (Light, Medium, Heavy, Assault).
@export var gunship_shapes: Array[AirframeShape] = []
@export var thresher_shapes: Array[AirframeShape] = []


## The current loadout's shape for one form.
func build(thresher: bool) -> AirframeShape:
	var shapes: Array[AirframeShape] = thresher_shapes if thresher else gunship_shapes
	var base: AirframeShape = shapes[clampi(GameState.weight_class, 0, shapes.size() - 1)]
	var overlays: Array[AirframeShape] = []
	var propulsion: SystemRefitData = GameState.system_refit(RefitData.Line.PROPULSION)
	if propulsion != null:
		overlays.append(propulsion.airframe_thresher if thresher else propulsion.airframe_gunship)
	for hardpoint: int in [WeaponData.Hardpoint.NOSE, WeaponData.Hardpoint.WING_PYLONS]:
		var weapon: WeaponData = GameState.weapons.get(hardpoint)
		if weapon != null:
			overlays.append(weapon.airframe_thresher if thresher else weapon.airframe_gunship)
	return base.with_overlays(overlays)
