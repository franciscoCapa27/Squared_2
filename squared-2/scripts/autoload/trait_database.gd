extends Node

const TRAIT_ROOT_PATH := "res://data/traits"
const DEBUG_TRAIT_ROLLS := false

var traits_by_id: Dictionary = {}
var all_traits: Array[TraitDefinition] = []
var traits_by_rarity: Dictionary = {}


func _ready() -> void:
	load_traits()


func load_traits() -> void:
	traits_by_id.clear()
	all_traits.clear()
	traits_by_rarity.clear()

	_load_traits_recursive(TRAIT_ROOT_PATH)
	_rebuild_traits_by_rarity()

	print("Loaded %s traits." % all_traits.size())


func get_trait(trait_id: String) -> TraitDefinition:
	return traits_by_id.get(trait_id) as TraitDefinition


func get_random_trait(current_grid_size: int) -> TraitDefinition:
	var rarity_weights: Dictionary = get_rarity_weights_for_grid(current_grid_size)
	var selected_rarity: int = _roll_rarity(current_grid_size)

	if DEBUG_TRAIT_ROLLS:
		print("Trait roll grid size: %s" % current_grid_size)
		print("Trait luck: %s" % GameState.get_permanent_stat_addition(GameIds.STAT_TRAIT_LUCK))
		print("Rarity weights: %s" % str(rarity_weights))
		print("Selected rarity: %s" % _get_rarity_debug_name(selected_rarity))

	var candidates: Array[TraitDefinition] = get_roll_candidates_for_rarity(
		selected_rarity,
		current_grid_size
	)

	if DEBUG_TRAIT_ROLLS:
		print("Roll candidates: %s" % str(_get_trait_id_list(candidates)))

	if candidates.is_empty():
		if DEBUG_TRAIT_ROLLS:
			print("No eligible traits found.")

		return null

	var selected_trait: TraitDefinition = get_weighted_trait_for_roll(candidates, randf())

	if DEBUG_TRAIT_ROLLS:
		print("Selected trait: %s" % selected_trait.id)

	return selected_trait


func _get_trait_id_list(traits: Array[TraitDefinition]) -> Array[String]:
	var ids: Array[String] = []

	for trait_definition: TraitDefinition in traits:
		if trait_definition == null:
			continue

		ids.append(trait_definition.id)

	return ids


func _get_rarity_debug_name(rarity: int) -> String:
	match rarity:
		TraitDefinition.Rarity.COMMON:
			return "Common"
		TraitDefinition.Rarity.UNCOMMON:
			return "Uncommon"
		TraitDefinition.Rarity.RARE:
			return "Rare"
		TraitDefinition.Rarity.EPIC:
			return "Epic"
		TraitDefinition.Rarity.LEGENDARY:
			return "Legendary"
		TraitDefinition.Rarity.COSMIC:
			return "Cosmic"
		_:
			return "Unknown"


func get_eligible_traits(current_grid_size: int) -> Array[TraitDefinition]:
	return _get_eligible_traits(current_grid_size)


func get_eligible_traits_for_rarity(
	rarity: int,
	current_grid_size: int
) -> Array[TraitDefinition]:
	return _get_eligible_traits_for_rarity(rarity, current_grid_size)


func get_rarity_weights_for_grid(current_grid_size: int) -> Dictionary:
	var trait_luck: float = GameState.get_permanent_stat_addition(GameIds.STAT_TRAIT_LUCK)

	return get_rarity_weights_for_grid_with_luck(current_grid_size, trait_luck)


func get_rarity_weights_for_grid_with_luck(
	current_grid_size: int,
	trait_luck: float
) -> Dictionary:
	var base_weights: Dictionary = _get_base_rarity_weights(current_grid_size)

	return _apply_luck_to_rarity_weights(base_weights, trait_luck)


func get_roll_candidates_for_rarity(
	selected_rarity: int,
	current_grid_size: int
) -> Array[TraitDefinition]:
	var candidates: Array[TraitDefinition] = _get_eligible_traits_for_rarity(
		selected_rarity,
		current_grid_size
	)

	if not candidates.is_empty():
		return candidates

	candidates = _get_eligible_traits(current_grid_size)

	if DEBUG_TRAIT_ROLLS:
		print("Fallback candidates: %s" % str(_get_trait_id_list(candidates)))

	return candidates


func get_weighted_trait_for_roll(
	candidates: Array[TraitDefinition],
	roll_normalized: float
) -> TraitDefinition:
	if candidates.is_empty():
		return null

	var total_weight: float = 0.0

	for trait_definition: TraitDefinition in candidates:
		total_weight += max(0.0, trait_definition.weight)

	if total_weight <= 0.0:
		var fallback_index: int = clampi(
			int(floor(clampf(roll_normalized, 0.0, 0.999999) * candidates.size())),
			0,
			candidates.size() - 1
		)

		return candidates[fallback_index]

	var roll: float = clampf(roll_normalized, 0.0, 0.999999) * total_weight
	var cumulative_weight: float = 0.0

	for trait_definition: TraitDefinition in candidates:
		cumulative_weight += max(0.0, trait_definition.weight)

		if roll < cumulative_weight:
			return trait_definition

	return candidates.back()


func _load_traits_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		push_error("Could not open trait directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			_load_traits_recursive(full_path)
		else:
			var resource_path: String = _get_resource_path_from_scanned_file(path, file_name)

			if resource_path != "":
				_load_trait_resource(resource_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _get_resource_path_from_scanned_file(folder_path: String, file_name: String) -> String:
	var resource_file_name: String = _get_resource_file_name(file_name)

	if resource_file_name == "":
		return ""

	return folder_path.path_join(resource_file_name)


func _get_resource_file_name(file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return file_name

	if file_name.ends_with(".res"):
		return file_name

	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")

	if file_name.ends_with(".res.remap"):
		return file_name.trim_suffix(".remap")

	return ""


func _load_trait_resource(path: String) -> void:
	var resource: Resource = load(path)

	if resource == null:
		push_warning("Failed to load trait resource: %s" % path)
		return

	if not resource is TraitDefinition:
		push_warning("Resource is not a TraitDefinition: %s" % path)
		return

	var trait_definition: TraitDefinition = resource as TraitDefinition

	if trait_definition.id.strip_edges() == "":
		push_warning("Trait has empty id: %s" % path)
		return

	if traits_by_id.has(trait_definition.id):
		push_warning("Duplicate trait id '%s' at %s" % [trait_definition.id, path])
		return

	traits_by_id[trait_definition.id] = trait_definition
	all_traits.append(trait_definition)


func _rebuild_traits_by_rarity() -> void:
	for trait_definition: TraitDefinition in all_traits:
		var rarity: int = int(trait_definition.rarity)

		if not traits_by_rarity.has(rarity):
			traits_by_rarity[rarity] = []

		var rarity_traits: Array = traits_by_rarity[rarity] as Array
		rarity_traits.append(trait_definition)


func _get_eligible_traits(current_grid_size: int) -> Array[TraitDefinition]:
	var eligible_traits: Array[TraitDefinition] = []

	for trait_definition: TraitDefinition in all_traits:
		if _is_trait_eligible(trait_definition, current_grid_size):
			eligible_traits.append(trait_definition)

	return eligible_traits


func _get_eligible_traits_for_rarity(
	rarity: int,
	current_grid_size: int
) -> Array[TraitDefinition]:
	var eligible_traits: Array[TraitDefinition] = []
	var rarity_traits_variant: Variant = traits_by_rarity.get(rarity, [])

	if not rarity_traits_variant is Array:
		return eligible_traits

	for trait_variant: Variant in rarity_traits_variant:
		var trait_definition: TraitDefinition = trait_variant as TraitDefinition

		if trait_definition == null:
			continue

		if _is_trait_eligible(trait_definition, current_grid_size):
			eligible_traits.append(trait_definition)

	return eligible_traits


func _is_trait_eligible(
	trait_definition: TraitDefinition,
	current_grid_size: int
) -> bool:
	if trait_definition == null:
		return false

	if current_grid_size < trait_definition.min_grid_tier:
		return false

	if trait_definition.max_grid_tier > 0:
		if current_grid_size > trait_definition.max_grid_tier:
			return false

	if not _is_rarity_unlocked_for_grid(int(trait_definition.rarity), current_grid_size):
		return false

	return true


func _is_rarity_unlocked_for_grid(rarity: int, current_grid_size: int) -> bool:
	return current_grid_size >= _get_min_grid_size_for_rarity(rarity)


func _get_min_grid_size_for_rarity(rarity: int) -> int:
	match rarity:
		TraitDefinition.Rarity.COMMON:
			return 1
		TraitDefinition.Rarity.UNCOMMON:
			return 2
		TraitDefinition.Rarity.RARE:
			return 3
		TraitDefinition.Rarity.EPIC:
			return 4
		TraitDefinition.Rarity.LEGENDARY:
			return 5
		TraitDefinition.Rarity.COSMIC:
			return 6
		_:
			return 1


func _roll_rarity(current_grid_size: int) -> int:
	var rarity_weights: Dictionary = get_rarity_weights_for_grid(current_grid_size)
	var total_weight: float = 0.0

	for rarity_variant: Variant in rarity_weights.keys():
		total_weight += max(0.0, float(rarity_weights[rarity_variant]))

	if total_weight <= 0.0:
		return TraitDefinition.Rarity.COMMON

	var roll: float = randf() * total_weight
	var cumulative_weight: float = 0.0

	for rarity_variant: Variant in rarity_weights.keys():
		var rarity: int = int(rarity_variant)
		cumulative_weight += max(0.0, float(rarity_weights[rarity_variant]))

		if roll <= cumulative_weight:
			return rarity

	return TraitDefinition.Rarity.COMMON


func _get_base_rarity_weights(current_grid_size: int) -> Dictionary:
	match current_grid_size:
		1:
			return {
				TraitDefinition.Rarity.COMMON: 100.0
			}
		2:
			return {
				TraitDefinition.Rarity.COMMON: 85.0,
				TraitDefinition.Rarity.UNCOMMON: 15.0
			}
		3:
			return {
				TraitDefinition.Rarity.COMMON: 70.0,
				TraitDefinition.Rarity.UNCOMMON: 25.0,
				TraitDefinition.Rarity.RARE: 5.0
			}
		4:
			return {
				TraitDefinition.Rarity.COMMON: 55.0,
				TraitDefinition.Rarity.UNCOMMON: 30.0,
				TraitDefinition.Rarity.RARE: 12.0,
				TraitDefinition.Rarity.EPIC: 3.0
			}
		5:
			return {
				TraitDefinition.Rarity.COMMON: 42.0,
				TraitDefinition.Rarity.UNCOMMON: 32.0,
				TraitDefinition.Rarity.RARE: 18.0,
				TraitDefinition.Rarity.EPIC: 7.0,
				TraitDefinition.Rarity.LEGENDARY: 1.0
			}
		_:
			return {
				TraitDefinition.Rarity.COMMON: 35.0,
				TraitDefinition.Rarity.UNCOMMON: 30.0,
				TraitDefinition.Rarity.RARE: 22.0,
				TraitDefinition.Rarity.EPIC: 10.0,
				TraitDefinition.Rarity.LEGENDARY: 2.5,
				TraitDefinition.Rarity.COSMIC: 0.5
			}


func _apply_luck_to_rarity_weights(
	base_weights: Dictionary,
	trait_luck: float
) -> Dictionary:
	var adjusted_weights: Dictionary = base_weights.duplicate()

	if trait_luck <= 0.0:
		return adjusted_weights

	var luck_steps: int = int(floor(trait_luck))
	var fractional_luck: float = trait_luck - floor(trait_luck)

	for step_index: int in luck_steps:
		_apply_cascading_luck_step(adjusted_weights, 1.0)

	if fractional_luck > 0.0:
		_apply_cascading_luck_step(adjusted_weights, fractional_luck)

	return adjusted_weights


func _apply_cascading_luck_step(weights: Dictionary, scale: float) -> void:
	var transfers: Array[Dictionary] = [
		{
			"from": TraitDefinition.Rarity.COMMON,
			"to": TraitDefinition.Rarity.UNCOMMON,
			"amount": 1.00
		},
		{
			"from": TraitDefinition.Rarity.UNCOMMON,
			"to": TraitDefinition.Rarity.RARE,
			"amount": 0.25
		},
		{
			"from": TraitDefinition.Rarity.RARE,
			"to": TraitDefinition.Rarity.EPIC,
			"amount": 0.05
		},
		{
			"from": TraitDefinition.Rarity.EPIC,
			"to": TraitDefinition.Rarity.LEGENDARY,
			"amount": 0.01
		},
		{
			"from": TraitDefinition.Rarity.LEGENDARY,
			"to": TraitDefinition.Rarity.COSMIC,
			"amount": 0.002
		}
	]

	for transfer: Dictionary in transfers:
		_apply_luck_transfer(weights, transfer, scale)


func _apply_luck_transfer(
	weights: Dictionary,
	transfer: Dictionary,
	scale: float
) -> void:
	var from_rarity: int = int(transfer["from"])
	var to_rarity: int = int(transfer["to"])
	var transfer_amount: float = float(transfer["amount"]) * scale

	if not weights.has(from_rarity):
		return

	if not weights.has(to_rarity):
		return

	var current_from_weight: float = float(weights.get(from_rarity, 0.0))
	var actual_transfer: float = min(transfer_amount, current_from_weight)

	weights[from_rarity] = current_from_weight - actual_transfer
	weights[to_rarity] = float(weights.get(to_rarity, 0.0)) + actual_transfer
