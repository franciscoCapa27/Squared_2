extends Node

const RUN_UPGRADE_ROOT_PATH := "res://data/run_upgrades"

var upgrades_by_id: Dictionary = {}
var all_upgrades: Array[RunUpgradeDefinition] = []


func _ready() -> void:
	load_run_upgrades()


func load_run_upgrades() -> void:
	upgrades_by_id.clear()
	all_upgrades.clear()

	_load_run_upgrades_recursive(RUN_UPGRADE_ROOT_PATH)

	all_upgrades.sort_custom(
		func(a: RunUpgradeDefinition, b: RunUpgradeDefinition) -> bool:
			if a.sort_order != b.sort_order:
				return a.sort_order < b.sort_order

			return a.id < b.id
	)

	print("Loaded %s run upgrades." % all_upgrades.size())


func get_upgrade(upgrade_id: String) -> RunUpgradeDefinition:
	return upgrades_by_id.get(upgrade_id) as RunUpgradeDefinition


func get_all_upgrades() -> Array[RunUpgradeDefinition]:
	return all_upgrades


func _load_run_upgrades_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		push_error("Could not open run upgrade directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			_load_run_upgrades_recursive(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			_load_run_upgrade_resource(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _load_run_upgrade_resource(path: String) -> void:
	var resource: Resource = load(path)

	if resource == null:
		push_warning("Failed to load run upgrade resource: %s" % path)
		return

	if not resource is RunUpgradeDefinition:
		push_warning("Resource is not a RunUpgradeDefinition: %s" % path)
		return

	var upgrade: RunUpgradeDefinition = resource as RunUpgradeDefinition

	if not upgrade.is_valid_definition():
		push_warning("Run upgrade has empty id: %s" % path)
		return

	if upgrades_by_id.has(upgrade.id):
		push_warning("Duplicate run upgrade id '%s' at %s" % [upgrade.id, path])
		return

	upgrades_by_id[upgrade.id] = upgrade
	all_upgrades.append(upgrade)
