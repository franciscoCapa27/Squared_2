extends Node

const ACHIEVEMENT_ROOT_PATH := "res://data/achievements"

var achievements_by_id: Dictionary = {}
var all_achievements: Array[AchievementDefinition] = []

func _ready() -> void:
	load_achievements()

func load_achievements() -> void:
	achievements_by_id.clear()
	all_achievements.clear()

	_load_achievements_recursive(ACHIEVEMENT_ROOT_PATH)

	all_achievements.sort_custom(
		func(a: AchievementDefinition, b: AchievementDefinition) -> bool:
			if a.sort_order != b.sort_order:
				return a.sort_order < b.sort_order

			return a.id < b.id
	)

	print("Loaded %s achievements." % all_achievements.size())

func _load_achievements_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		push_error("Could not open achievement directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			_load_achievements_recursive(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			_load_achievement_resource(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _load_achievement_resource(path: String) -> void:
	var resource: Resource = load(path)

	if resource == null:
		push_warning("Failed to load achievement resource: %s" % path)
		return

	if not resource is AchievementDefinition:
		push_warning("Resource is not an AchievementDefinition: %s" % path)
		return

	var achievement: AchievementDefinition = resource as AchievementDefinition

	if not achievement.is_valid_definition():
		push_warning("Achievement has empty id: %s" % path)
		return

	if achievements_by_id.has(achievement.id):
		push_warning("Duplicate achievement id '%s' at %s" % [achievement.id, path])
		return

	achievements_by_id[achievement.id] = achievement
	all_achievements.append(achievement)

func get_achievement(achievement_id: String) -> AchievementDefinition:
	return achievements_by_id.get(achievement_id)

func get_all_achievements() -> Array[AchievementDefinition]:
	return all_achievements
