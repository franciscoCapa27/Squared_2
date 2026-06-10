extends Node

signal run_upgrades_changed()
signal run_upgrade_bought(upgrade_id: String)

var run_upgrade_levels: Dictionary = {}
var run_stat_multipliers: Dictionary = {}
var run_stat_additions: Dictionary = {}


func get_run_stat_multiplier(stat_id: String) -> float:
	return float(run_stat_multipliers.get(stat_id, 1.0))


func multiply_run_stat(stat_id: String, multiplier: float) -> void:
	var previous_multiplier: float = get_run_stat_multiplier(stat_id)
	var new_multiplier: float = previous_multiplier * multiplier

	run_stat_multipliers[stat_id] = new_multiplier


func get_run_stat_addition(stat_id: String) -> float:
	return float(run_stat_additions.get(stat_id, 0.0))


func add_run_stat(stat_id: String, amount: float) -> void:
	var previous_amount: float = get_run_stat_addition(stat_id)
	var new_amount: float = previous_amount + amount

	run_stat_additions[stat_id] = new_amount


func get_run_upgrade_level(upgrade_id: String) -> int:
	return int(run_upgrade_levels.get(upgrade_id, 0))


func is_run_upgrade_unlocked(upgrade_id: String) -> bool:
	var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	return upgrade.is_unlocked_by_conditions()


func can_buy_run_upgrade(upgrade_id: String) -> bool:
	var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	if not is_run_upgrade_unlocked(upgrade_id):
		return false

	var current_level: int = get_run_upgrade_level(upgrade_id)

	if current_level >= upgrade.max_level:
		return false

	var cost: float = upgrade.get_cost_for_next_level(current_level)

	return GameState.squares >= cost


func buy_run_upgrade(upgrade_id: String) -> bool:
	if not can_buy_run_upgrade(upgrade_id):
		return false

	var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	var current_level: int = get_run_upgrade_level(upgrade_id)
	var cost: float = upgrade.get_cost_for_next_level(current_level)

	if not GameState.spend_squares(cost):
		return false

	_apply_run_upgrade_effects(upgrade)

	run_upgrade_levels[upgrade.id] = current_level + 1

	EventBus.story_message.emit(
		"%s reached Level %s." % [
			upgrade.display_name,
			NumberFormatter.integer_amount(current_level + 1)
		]
	)

	run_upgrade_bought.emit(upgrade.id)
	run_upgrades_changed.emit()

	return true


func reset_run_state_on_prestige() -> void:
	run_upgrade_levels.clear()
	run_stat_multipliers.clear()
	run_stat_additions.clear()

	run_upgrades_changed.emit()


func reset_to_new_game() -> void:
	reset_run_state_on_prestige()


func to_save_dict() -> Dictionary:
	return {
		"run_upgrade_levels": run_upgrade_levels,
		"run_stat_multipliers": run_stat_multipliers,
		"run_stat_additions": run_stat_additions
	}


func from_save_dict(data: Dictionary) -> void:
	run_upgrade_levels = _dictionary_from_variant(data.get("run_upgrade_levels", {}))
	run_stat_multipliers = _dictionary_from_variant(data.get("run_stat_multipliers", {}))
	run_stat_additions = _dictionary_from_variant(data.get("run_stat_additions", {}))

	run_upgrades_changed.emit()


func _apply_run_upgrade_effects(upgrade: RunUpgradeDefinition) -> void:
	for effect_iter: RunUpgradeEffect in upgrade.effects_per_level:
		if effect_iter == null:
			continue

		_apply_run_upgrade_effect(effect_iter)


func _apply_run_upgrade_effect(effect_iter: RunUpgradeEffect) -> void:
	match effect_iter.effect_type:
		RunUpgradeEffect.EffectType.GLOBAL_RUN_STAT_MULTIPLIER:
			_apply_global_run_stat_multiplier_effect(effect_iter)
		RunUpgradeEffect.EffectType.GLOBAL_RUN_STAT_ADDITION:
			_apply_global_run_stat_addition_effect(effect_iter)
		_:
			push_warning("Unhandled run upgrade effect.")


func _apply_global_run_stat_multiplier_effect(effect_iter: RunUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("GLOBAL_RUN_STAT_MULTIPLIER missing target_stat.")
		return

	multiply_run_stat(effect_iter.target_stat, effect_iter.value)


func _apply_global_run_stat_addition_effect(effect_iter: RunUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("GLOBAL_RUN_STAT_ADDITION missing target_stat.")
		return

	add_run_stat(effect_iter.target_stat, effect_iter.value)


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}
