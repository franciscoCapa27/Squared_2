extends Node

const UPGRADE_ROOT_PATH := "res://data/vertex_upgrades"

var upgrades_by_id: Dictionary = {}
var all_upgrades: Array[VertexUpgradeDefinition] = []


func _ready() -> void:
	load_upgrades()


func load_upgrades() -> void:
	upgrades_by_id.clear()
	all_upgrades.clear()

	_load_upgrades_recursive(UPGRADE_ROOT_PATH)

	all_upgrades.sort_custom(
		func(a: VertexUpgradeDefinition, b: VertexUpgradeDefinition) -> bool:
			if a.sort_order != b.sort_order:
				return a.sort_order < b.sort_order

			return a.id < b.id
	)

	print("Loaded %s vertex upgrades." % all_upgrades.size())


func _load_upgrades_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		push_error("Could not open vertex upgrade directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			_load_upgrades_recursive(full_path)
		else:
			var resource_path: String = _get_resource_path_from_scanned_file(path, file_name)

			if resource_path != "":
				_load_upgrade_resource(resource_path)

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


func _load_upgrade_resource(path: String) -> void:
	var resource: Resource = load(path)

	if resource == null:
		push_warning("Failed to load vertex upgrade resource: %s" % path)
		return

	if not resource is VertexUpgradeDefinition:
		push_warning("Resource is not a VertexUpgradeDefinition: %s" % path)
		return

	var upgrade: VertexUpgradeDefinition = resource as VertexUpgradeDefinition

	if upgrade.id.strip_edges() == "":
		push_warning("Vertex upgrade has empty id: %s" % path)
		return

	if upgrades_by_id.has(upgrade.id):
		push_warning("Duplicate vertex upgrade id '%s' at %s" % [upgrade.id, path])
		return

	upgrades_by_id[upgrade.id] = upgrade
	all_upgrades.append(upgrade)


func get_upgrade(upgrade_id: String) -> VertexUpgradeDefinition:
	return upgrades_by_id.get(upgrade_id)


func get_visible_upgrades() -> Array[VertexUpgradeDefinition]:
	var visible_upgrades: Array[VertexUpgradeDefinition] = []

	for upgrade: VertexUpgradeDefinition in all_upgrades:
		if not upgrade.is_visible_by_default:
			continue

		var requirements_met: bool = upgrade.requirements_are_met(
			GameState.trait_purchase_count,
			GameState.grid_size,
			VertexUpgradeSystem.unlocked_vertex_upgrades
		)

		if upgrade.hidden_until_requirements_met and not requirements_met:
			continue

		visible_upgrades.append(upgrade)

	return visible_upgrades
