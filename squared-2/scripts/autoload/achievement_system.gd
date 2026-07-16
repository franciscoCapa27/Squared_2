extends Node

signal achievement_unlocked(achievement_id: String)
signal achievements_changed()

var achievement_levels: Dictionary = {}


func _ready() -> void:
	EventBus.squares_changed.connect(_on_any_progress_value_changed)
	EventBus.vertices_changed.connect(_on_any_progress_value_changed)
	EventBus.trait_purchase_changed.connect(_on_any_progress_value_changed)
	EventBus.grid_changed.connect(_on_any_progress_changed)
	EventBus.grid_upgraded.connect(_on_grid_upgraded)
	EventBus.vertex_upgrade_purchased.connect(_on_vertex_upgrade_purchased)
	EventBus.passive_generator_unlocked.connect(_on_passive_generator_unlocked)
	EventBus.passive_generator_upgraded.connect(_on_passive_generator_upgraded)

	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)

	call_deferred("check_all_achievements")


func is_achievement_unlocked(achievement_id: String) -> bool:
	return get_achievement_level(achievement_id) > 0


func get_achievement_level(achievement_id: String) -> int:
	return maxi(0, int(achievement_levels.get(achievement_id, 0)))


func get_unlocked_count() -> int:
	var unlocked_count: int = 0
	for achievement_id: Variant in achievement_levels.keys():
		if get_achievement_level(str(achievement_id)) > 0:
			unlocked_count += 1

	return unlocked_count


func check_all_achievements() -> void:
	var any_unlocked: bool = false

	for achievement: AchievementDefinition in AchievementDatabase.get_all_achievements():
		var current_level: int = get_achievement_level(achievement.id)
		while current_level < achievement.get_level_count():
			if not _is_level_condition_met(achievement, current_level):
				break

			_unlock_achievement_level(achievement, current_level)
			current_level += 1
			any_unlocked = true

	if any_unlocked:
		achievements_changed.emit()


func get_visible_achievements() -> Array[AchievementDefinition]:
	var visible_achievements: Array[AchievementDefinition] = []

	for achievement: AchievementDefinition in AchievementDatabase.get_all_achievements():
		if not achievement.is_visible_by_default:
			continue

		if achievement.hidden_until_unlocked and get_achievement_level(achievement.id) <= 0:
			continue

		visible_achievements.append(achievement)

	return visible_achievements


func get_progress_ratio(achievement: AchievementDefinition) -> float:
	if achievement == null:
		return 0.0

	var current_level: int = get_achievement_level(achievement.id)
	var level_count: int = achievement.get_level_count()
	if current_level >= level_count:
		return 1.0

	var next_threshold: float = achievement.get_threshold_for_level(current_level)
	if next_threshold <= 0.0:
		return 0.0

	var current_value: float = _get_condition_current_value(achievement)
	return clamp(current_value / next_threshold, 0.0, 1.0)


func get_progress_text(achievement: AchievementDefinition) -> String:
	if achievement == null:
		return ""

	var current_level: int = get_achievement_level(achievement.id)
	var level_count: int = achievement.get_level_count()
	if current_level >= level_count:
		return "Level %s / %s · Complete" % [
			NumberFormatter.integer_amount(level_count),
			NumberFormatter.integer_amount(level_count),
		]

	var current_value: float = _get_condition_current_value(achievement)
	var next_threshold: float = achievement.get_threshold_for_level(current_level)

	return "Level %s / %s · %s / %s to next" % [
		NumberFormatter.integer_amount(current_level),
		NumberFormatter.integer_amount(level_count),
		NumberFormatter.amount(current_value),
		NumberFormatter.amount(next_threshold),
	]


func get_level_text(achievement: AchievementDefinition) -> String:
	if achievement == null:
		return ""

	return "Level %s / %s" % [
		NumberFormatter.integer_amount(get_achievement_level(achievement.id)),
		NumberFormatter.integer_amount(achievement.get_level_count()),
	]

func to_save_dict() -> Dictionary:
	var legacy_unlocked_achievements: Dictionary = {}
	for achievement_id: Variant in achievement_levels.keys():
		if get_achievement_level(str(achievement_id)) > 0:
			legacy_unlocked_achievements[str(achievement_id)] = true

	return {
		"achievement_levels": achievement_levels.duplicate(),
		"unlocked_achievements": legacy_unlocked_achievements,
	}


func from_save_dict(data: Dictionary) -> void:
	achievement_levels.clear()
	var levels_variant: Variant = data.get("achievement_levels", null)
	if levels_variant is Dictionary:
		for achievement_id: Variant in (levels_variant as Dictionary).keys():
			var level: int = int((levels_variant as Dictionary).get(achievement_id, 0))
			if level > 0:
				achievement_levels[str(achievement_id)] = level
	else:
		var unlocked_variant: Variant = data.get("unlocked_achievements", {})
		if unlocked_variant is Dictionary:
			for achievement_id: Variant in (unlocked_variant as Dictionary).keys():
				var unlocked_value: Variant = (unlocked_variant as Dictionary).get(achievement_id, false)
				if bool(unlocked_value):
					achievement_levels[str(achievement_id)] = 1

	achievements_changed.emit()


func reset_to_new_game() -> void:
	achievement_levels.clear()
	achievements_changed.emit()


func _unlock_achievement_level(achievement: AchievementDefinition, level_index: int) -> void:
	var unlocked_level: int = level_index + 1
	achievement_levels[achievement.id] = unlocked_level
	_apply_rewards(achievement, level_index)

	EventBus.story_message.emit("Achievement unlocked: %s — Level %s" % [
		achievement.display_name,
		NumberFormatter.integer_amount(unlocked_level),
	])
	achievement_unlocked.emit(achievement.id)


func _is_level_condition_met(achievement: AchievementDefinition, level_index: int) -> bool:
	return _get_condition_current_value(achievement) >= achievement.get_threshold_for_level(level_index)


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
		AchievementDefinition.ConditionType.TRAIT_PURCHASE_COUNT:
			return float(GameState.trait_purchase_count)
		AchievementDefinition.ConditionType.VERTICES_EARNED:
			return float(_get_total_vertex_upgrade_currency_earned_approximation())
		AchievementDefinition.ConditionType.VERTEX_UPGRADE_PURCHASED:
			return 1.0 if VertexUpgradeSystem.has_vertex_upgrade(achievement.target_id) else 0.0
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


func _apply_rewards(achievement: AchievementDefinition, level_index: int) -> void:
	for reward: AchievementReward in achievement.get_rewards_for_level(level_index):
		if reward == null:
			continue

		_apply_reward(reward)


func _apply_reward(reward: AchievementReward) -> void:
	match reward.reward_type:
		AchievementReward.RewardType.GLOBAL_STAT_MULTIPLIER:
			_apply_global_stat_multiplier_reward(reward)
		AchievementReward.RewardType.ADD_PERMANENT_STAT:
			_apply_add_permanent_stat_reward(reward)
		AchievementReward.RewardType.UNLOCK_MECHANIC:
			push_warning("Achievement UNLOCK_MECHANIC reward not implemented: %s" % reward.mechanic_id)
		AchievementReward.RewardType.ADD_STARTING_SQUARES:
			push_warning("Achievement ADD_STARTING_SQUARES reward not implemented.")
		AchievementReward.RewardType.SCRIPT_HOOK:
			push_warning("Achievement SCRIPT_HOOK reward not implemented: %s" % reward.script_hook_id)
		_:
			push_warning("Unhandled achievement reward.")

func _apply_add_permanent_stat_reward(reward: AchievementReward) -> void:
	if reward.target_stat.strip_edges() == "":
		push_warning("Achievement ADD_PERMANENT_STAT reward missing target_stat.")
		return

	GameState.add_permanent_stat(reward.target_stat, reward.value)
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

	for upgrade_id: String in VertexUpgradeSystem.unlocked_vertex_upgrades.keys():
		var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

		if upgrade == null:
			continue

		var purchase_count: int = VertexUpgradeSystem.get_vertex_upgrade_purchase_count(upgrade_id)
		spent_vertices += upgrade.cost_vertices * purchase_count

	return GameState.vertices + spent_vertices


func _get_script_hook_condition_value(achievement: AchievementDefinition) -> float:
	push_warning("Achievement SCRIPT_HOOK condition not implemented: %s" % achievement.id)
	return 0.0


func _on_progress_signal(_value: Variant = null) -> void:
	check_all_achievements()


func _on_passive_pulsed(_generator_id: String, _square_id: String, _payout: float) -> void:
	check_all_achievements()

func _on_any_progress_changed() -> void:
	check_all_achievements()


func _on_any_progress_value_changed(_value: Variant) -> void:
	check_all_achievements()


func _on_vertex_upgrade_purchased(_upgrade_id: String) -> void:
	check_all_achievements()


func _on_passive_generator_unlocked(_generator_id: String) -> void:
	check_all_achievements()


func _on_passive_generator_upgraded(_generator_id: String) -> void:
	check_all_achievements()
func _on_grid_upgraded(_new_grid_size: int) -> void:
	check_all_achievements()
