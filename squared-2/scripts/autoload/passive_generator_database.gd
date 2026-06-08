extends Node

const GENERATOR_ROOT_PATH := "res://data/passive_generators"

var generators_by_id: Dictionary = {}
var all_generators: Array[PassiveGeneratorDefinition] = []

func _ready() -> void:
	load_generators()

func load_generators() -> void:
	generators_by_id.clear()
	all_generators.clear()

	_load_generators_recursive(GENERATOR_ROOT_PATH)

	all_generators.sort_custom(
		func(a: PassiveGeneratorDefinition, b: PassiveGeneratorDefinition) -> bool:
			if a.sort_order != b.sort_order:
				return a.sort_order < b.sort_order

			return a.id < b.id
	)

	print("Loaded %s passive generators." % all_generators.size())

func _load_generators_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		push_error("Could not open passive generator directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			_load_generators_recursive(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			_load_generator_resource(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _load_generator_resource(path: String) -> void:
	var resource: Resource = load(path)

	if resource == null:
		push_warning("Failed to load passive generator resource: %s" % path)
		return

	if not resource is PassiveGeneratorDefinition:
		push_warning("Resource is not a PassiveGeneratorDefinition: %s" % path)
		return

	var generator_definition: PassiveGeneratorDefinition = resource as PassiveGeneratorDefinition

	if not generator_definition.is_valid_definition():
		push_warning("Passive generator has empty id: %s" % path)
		return

	if generators_by_id.has(generator_definition.id):
		push_warning("Duplicate passive generator id '%s' at %s" % [generator_definition.id, path])
		return

	generators_by_id[generator_definition.id] = generator_definition
	all_generators.append(generator_definition)

func get_generator(generator_id: String) -> PassiveGeneratorDefinition:
	return generators_by_id.get(generator_id)

func get_all_generators() -> Array[PassiveGeneratorDefinition]:
	return all_generators
