extends Node

const TRAIT_ROOT_PATH := "res://data/traits"

var traits_by_id: Dictionary = {}
var all_traits: Array[TraitDefinition] = []

func _ready() -> void:
	load_traits()

func load_traits() -> void:
	traits_by_id.clear()
	all_traits.clear()

	_load_traits_recursive(TRAIT_ROOT_PATH)

	print("Loaded %s traits." % all_traits.size())

func _load_traits_recursive(path: String) -> void:
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Could not open trait directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			_load_traits_recursive(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			_load_trait_resource(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _load_trait_resource(path: String) -> void:
	var resource := load(path)

	if resource == null:
		push_warning("Failed to load trait resource: %s" % path)
		return

	if not resource is TraitDefinition:
		push_warning("Resource is not a TraitDefinition: %s" % path)
		return

	var trait_iter := resource as TraitDefinition

	if trait_iter.id.strip_edges() == "":
		push_warning("Trait has empty id: %s" % path)
		return

	if traits_by_id.has(trait_iter.id):
		push_warning("Duplicate trait id '%s' at %s" % [trait_iter.id, path])
		return

	traits_by_id[trait_iter.id] = trait_iter
	all_traits.append(trait_iter)

func get_trait(trait_id: String) -> TraitDefinition:
	return traits_by_id.get(trait_id)

func get_available_traits(grid_tier: int) -> Array[TraitDefinition]:
	var available: Array[TraitDefinition] = []

	for trait_iter in all_traits:
		if trait_iter.min_grid_tier <= grid_tier:
			available.append(trait_iter)

	return available

func get_random_trait(grid_tier: int) -> TraitDefinition:
	var available := get_available_traits(grid_tier)

	if available.is_empty():
		push_warning("No available traits for grid tier %s." % grid_tier)
		return null

	var total_weight := 0.0

	for trait_iter in available:
		total_weight += trait_iter.weight

	if total_weight <= 0.0:
		return available.pick_random() as TraitDefinition

	var roll := randf() * total_weight
	var running_total := 0.0

	for trait_iter in available:
		running_total += trait_iter.weight
		if roll <= running_total:
			return trait_iter

	return available.back()
