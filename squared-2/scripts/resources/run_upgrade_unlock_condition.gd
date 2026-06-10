extends Resource
class_name RunUpgradeUnlockCondition

enum ConditionType {
	ALWAYS,
	CURRENT_SQUARES,
	PRESTIGE_COUNT,
	GRID_SIZE,
	ACHIEVEMENT_UNLOCKED,
	PASSIVE_GENERATOR_LEVEL,
	VERTEX_UPGRADE_PURCHASED,
	TOTAL_MANUAL_CLICKS,
	TOTAL_PASSIVE_CLICKS
}

@export var condition_type: ConditionType = ConditionType.ALWAYS
@export var threshold: float = 0.0
@export var target_id: String = ""


func is_met() -> bool:
	match condition_type:
		ConditionType.ALWAYS:
			return true
		ConditionType.CURRENT_SQUARES:
			return GameState.squares >= threshold
		ConditionType.PRESTIGE_COUNT:
			return float(GameState.prestige_count) >= threshold
		ConditionType.GRID_SIZE:
			return float(GameState.grid_size) >= threshold
		ConditionType.ACHIEVEMENT_UNLOCKED:
			return AchievementSystem.is_achievement_unlocked(target_id)
		ConditionType.PASSIVE_GENERATOR_LEVEL:
			return _is_passive_generator_level_met()
		ConditionType.VERTEX_UPGRADE_PURCHASED:
			return GameState.has_vertex_upgrade(target_id)
		ConditionType.TOTAL_MANUAL_CLICKS:
			return float(_get_total_manual_clicks()) >= threshold
		ConditionType.TOTAL_PASSIVE_CLICKS:
			return float(_get_total_passive_clicks()) >= threshold
		_:
			return false


func get_display_text() -> String:
	match condition_type:
		ConditionType.ALWAYS:
			return "Always available"
		ConditionType.CURRENT_SQUARES:
			return "Requires %s Squares" % NumberFormatter.amount(threshold)
		ConditionType.PRESTIGE_COUNT:
			return "Requires %s Prestiges" % NumberFormatter.integer_amount(int(threshold))
		ConditionType.GRID_SIZE:
			return "Requires Grid Size %sx%s" % [int(threshold), int(threshold)]
		ConditionType.ACHIEVEMENT_UNLOCKED:
			return "Requires Achievement: %s" % _format_achievement_name(target_id)
		ConditionType.PASSIVE_GENERATOR_LEVEL:
			return "Requires %s Level %s" % [
				_format_passive_generator_name(target_id),
				NumberFormatter.integer_amount(int(threshold))
			]
		ConditionType.VERTEX_UPGRADE_PURCHASED:
			return "Requires Vertex Upgrade: %s" % _format_vertex_upgrade_name(target_id)
		ConditionType.TOTAL_MANUAL_CLICKS:
			return "Requires %s lifetime manual clicks" % NumberFormatter.integer_amount(int(threshold))
		ConditionType.TOTAL_PASSIVE_CLICKS:
			return "Requires %s lifetime passive clicks" % NumberFormatter.integer_amount(int(threshold))
		_:
			return "Unknown requirement"


func _is_passive_generator_level_met() -> bool:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(target_id)

	if generator_instance == null:
		return false

	return float(generator_instance.level) >= threshold


func _get_total_manual_clicks() -> int:
	var total: int = 0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		total += square_data.lifetime_manual_clicks

	return total


func _get_total_passive_clicks() -> int:
	var total: int = 0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		total += square_data.lifetime_passive_clicks

	return total


func _format_achievement_name(achievement_id: String) -> String:
	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(achievement_id)

	if achievement == null:
		return achievement_id

	return achievement.display_name


func _format_passive_generator_name(generator_id: String) -> String:
	var generator_definition: PassiveGeneratorDefinition = PassiveGeneratorDatabase.get_generator(generator_id)

	if generator_definition == null:
		return generator_id

	return generator_definition.display_name


func _format_vertex_upgrade_name(upgrade_id: String) -> String:
	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return upgrade_id

	return upgrade.display_name
