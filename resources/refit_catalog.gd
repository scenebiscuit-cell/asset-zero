class_name RefitCatalog
extends Resource
## Every refit that can be offered (data/refits/catalog.tres), and the rules for rolling an offer.

@export var refits: Array[RefitData] = []


## Up to `count` offers. Each offer is one refit, or both variants of a line's last level
## (Variant A / Variant B), which the player picks between on one card. Refits in `exclude` are skipped.
func roll_offers(count: int, exclude: Array[RefitData] = []) -> Array[Array]:
	var groups: Array[Array] = []
	var weights: PackedFloat32Array = PackedFloat32Array()
	var by_key: Dictionary[String, int] = {}
	for refit: RefitData in refits:
		if not refit.is_available() or exclude.has(refit):
			continue
		# Variants of the same line and level share one card.
		var key: String = "%d:%d" % [refit.line, refit.level] if refit.variant != "" else str(refit.get_instance_id())
		if by_key.has(key):
			groups[by_key[key]].append(refit)
			continue
		by_key[key] = groups.size()
		groups.append([refit])
		weights.append(refit.offer_weight)
	var offers: Array[Array] = []
	while offers.size() < count and not groups.is_empty():
		var pick: int = _weighted_pick(weights)
		offers.append(groups[pick])
		groups.remove_at(pick)
		weights.remove_at(pick)
	for offer: Array in offers:
		offer.sort_custom(func(a: RefitData, b: RefitData) -> bool: return a.variant < b.variant)
	return offers


func _weighted_pick(weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll: float = randf() * total
	for i: int in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return weights.size() - 1
