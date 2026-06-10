extends Node

signal achievement_unlocked(achievement_id: String)
signal achievements_changed()

var unlocked_achievements: Dictionary = {}


func _ready() -> void:
	EventBus.squares_changed.connect(_on_progress_signal)
	EventBus.vertices_changed.connect(_on_progress_signal)
	EventBus.prestige_changed.connect(_on_progress_signal)
	EventBus.grid_changed.connect(_on_progress_signal)

	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)

	call_deferred("check_all_achievements")


func is_achievement_unlocked(achievement_id: String) -> bool:
	return bool(unlocked_achievements.get(achievement_id, false))


func get_unlocked_count() -> int:
	return unlocked_achievements.size()


func check_all_achievements() -> void:
	var any_unlocked: bool = false

	for achievement: AchievementDefinition in AchievementDatabase.get_all_achievements():
		if is_achievement_unlocked(achievement.id):
			continue

		if _is_condition_met(achievement):
			_unlock_achievement(achievement)
			any_unlocked = true

	if any_unlocked:
		achievements_changed.emit()


func get_visible_achievements() -> Array[AchievementDefinition]:
	var visible_achievements: Array[AchievementDefinition] = []

	for achievement: AchievementDefinition in AchievementDatabase.get_all_achievements():
		if not achievement.is_visible_by_default:
			continue

		if achievement.hidden_until_unlocked and not is_achievement_unlocked(achievement.id):
			continue

		visible_achievements.append(achievement)

	return visible_achievements


func get_progress_ratio(achievement: AchievementDefinition) -> float:
	if achievement == null:
		return 0.0

	if is_achievement_unlocked(achievement.id):
		return 1.0

	if achievement.threshold <= 0.0:
		return 0.0

	var current_value: float = _get_condition_current_value(achievement)
	return clamp(current_value / achievement.threshold, 0.0, 1.0)


func get_progress_text(achievement: AchievementDefinition) -> String:
	if achievement == null:
		return ""

	if is_achievement_unlocked(achievement.id):
		return "Unlocked"

	var current_value: float = _get_condition_current_value(achievement)

	return "%.0f / %.0f" % [
		current_value,
		achievement.threshold
	]


func to_save_dict() -> Dictionary:
	return {
		"unlocked_achievements": unlocked_achievements
	}


func from_save_dict(data: Dictionary) -> void:
	var unlocked_variant: Variant = data.get("unlocked_achievements", {})

	if unlocked_variant is Dictionary:
		unlocked_achievements = unlocked_variant as Dictionary
	else:
		unlocked_achievements = {}

	achievements_changed.emit()


func reset_to_new_game() -> void:
	unlocked_achievements.clear()
	achievements_changed.emit()


func _unlock_achievement(achievement: AchievementDefinition) -> void:
	unlocked_achievements[achievement.id] = true
	_apply_rewards(achievement)

	EventBus.story_message.emit("Achievement unlocked: %s" % achievement.display_name)
	achievement_unlocked.emit(achievement.id)


func _is_condition_met(achievement: AchievementDefinition) -> bool:
	return _get_condition_current_value(achievement) >= achievement.threshold


func _get_condition_current_value(achievement: AchievementDefinition) -> float:
	match achievement.condition_type:
		AchievementDefinition.ConditionType.TOTAL_MANUAL_CLICKS:
			return float(_get_total_manual_clicks())
		AchievementDefinition.ConditionType.TOTAL_PASSIVE_CLICKS:
			return float(_get_total_passive_clicks())
		AchievementDefinition.ConditionType.TOTAL_SQUARES_GENERATED:
			return _get_total_squares_generated()
		AchievementDefinition.ConditionType.CURRENT_SQUARES:
			return GameState.squares
		AchievementDefinition.ConditionType.PRESTIGE_COUNT:
			return float(GameState.prestige_count)
		AchievementDefinition.ConditionType.VERTICES_EARNED:
			return float(_get_total_vertex_upgrade_currency_earned_approximation())
		AchievementDefinition.ConditionType.VERTEX_UPGRADE_PURCHASED:
			return 1.0 if GameState.has_vertex_upgrade(achievement.target_id) else 0.0
		AchievementDefinition.ConditionType.PASSIVE_GENERATOR_UNLOCKED:
			return _get_passive_generator_unlocked_value(achievement.target_id)
		AchievementDefinition.ConditionType.PASSIVE_GENERATOR_LEVEL:
			return _get_passive_generator_level_value(achievement.target_id)
		AchievementDefinition.ConditionType.TRAITS_ACQUIRED:
			return float(_get_total_traits_acquired())
		AchievementDefinition.ConditionType.PERMANENT_STAT_MULTIPLIER:
			return GameState.get_permanent_stat_multiplier(achievement.target_stat)
		AchievementDefinition.ConditionType.SCRIPT_HOOK:
			return _get_script_hook_condition_value(achievement)
		_:
			return 0.0


func _apply_rewards(achievement: AchievementDefinition) -> void:
	for reward: AchievementReward in achievement.rewards:
		if reward == null:
			continue

		_apply_reward(reward)


func _apply_reward(reward: AchievementReward) -> void:
	match reward.reward_type:
		AchievementReward.RewardType.GLOBAL_STAT_MULTIPLIER:
			_apply_global_stat_multiplier_reward(reward)
		AchievementReward.RewardType.UNLOCK_MECHANIC:
			push_warning("Achievement UNLOCK_MECHANIC reward not implemented: %s" % reward.mechanic_id)
		AchievementReward.RewardType.ADD_STARTING_SQUARES:
			push_warning("Achievement ADD_STARTING_SQUARES reward not implemented.")
		AchievementReward.RewardType.SCRIPT_HOOK:
			push_warning("Achievement SCRIPT_HOOK reward not implemented: %s" % reward.script_hook_id)
		_:
			push_warning("Unhandled achievement reward.")


func _apply_global_stat_multiplier_reward(reward: AchievementReward) -> void:
	if reward.target_stat.strip_edges() == "":
		push_warning("Achievement GLOBAL_STAT_MULTIPLIER missing target_stat.")
		return

	GameState.multiply_permanent_stat(reward.target_stat, reward.value)


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


func _get_total_squares_generated() -> float:
	var total: float = 0.0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		total += square_data.lifetime_squares_generated

	return total


func _get_total_traits_acquired() -> int:
	var total: int = 0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		total += square_data.traits.size()

	return total


func _get_passive_generator_unlocked_value(generator_id: String) -> float:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(generator_id)

	if generator_instance == null:
		return 0.0

	return 1.0 if generator_instance.is_unlocked else 0.0


func _get_passive_generator_level_value(generator_id: String) -> float:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(generator_id)

	if generator_instance == null:
		return 0.0

	return float(generator_instance.level)


func _get_total_vertex_upgrade_currency_earned_approximation() -> int:
	var spent_vertices: int = 0

	for upgrade_id: String in GameState.unlocked_vertex_upgrades.keys():
		var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

		if upgrade == null:
			continue

		var purchase_count: int = GameState.get_vertex_upgrade_purchase_count(upgrade_id)
		spent_vertices += upgrade.cost_vertices * purchase_count

	return GameState.vertices + spent_vertices


func _get_script_hook_condition_value(achievement: AchievementDefinition) -> float:
	push_warning("Achievement SCRIPT_HOOK condition not implemented: %s" % achievement.id)
	return 0.0


func _on_progress_signal(_value: Variant = null) -> void:
	check_all_achievements()


func _on_passive_pulsed(_generator_id: String, _square_id: String, _payout: float) -> void:
	check_all_achievements()
