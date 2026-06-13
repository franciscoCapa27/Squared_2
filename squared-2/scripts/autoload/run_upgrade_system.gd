extends Node

signal run_upgrades_changed()
signal run_upgrade_bought(upgrade_id: String)

const RUN_UPGRADE_VISIBILITY_COST_RATIO := 0.60

var run_upgrade_levels: Dictionary = {}
var run_stat_multipliers: Dictionary = {}
var run_stat_additions: Dictionary = {}
var discovered_visible_run_upgrades: Dictionary = {}

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
	var next_cost: float = upgrade.get_cost_for_next_level(current_level)

	# Important:
	# Record the level before spending Squares.
	# spend_squares() emits squares_changed immediately, and UI visibility depends on level > 0.
	run_upgrade_levels[upgrade_id] = current_level + 1

	_apply_run_upgrade_effects(upgrade)

	var spent: bool = GameState.spend_squares(next_cost)

	if not spent:
		# Defensive rollback. This should not happen because can_buy_run_upgrade()
		# already checked affordability, but keep it safe.
		run_upgrade_levels[upgrade_id] = current_level
		_recalculate_run_stats()
		return false

	run_upgrade_bought.emit(upgrade_id)
	run_upgrades_changed.emit()

	return true
func _recalculate_run_stats() -> void:
	run_stat_multipliers.clear()
	run_stat_additions.clear()

	for upgrade_id: String in run_upgrade_levels.keys():
		var level: int = get_run_upgrade_level(upgrade_id)

		if level <= 0:
			continue

		var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

		if upgrade == null:
			continue

		for index: int in level:
			_apply_run_upgrade_effects(upgrade)
func refresh_visible_run_upgrade_discoveries() -> void:
	for upgrade: RunUpgradeDefinition in RunUpgradeDatabase.get_all_upgrades():
		if upgrade == null:
			continue

		if not is_run_upgrade_unlocked(upgrade.id):
			continue

		if is_run_upgrade_maxed(upgrade.id):
			continue

		var current_level: int = get_run_upgrade_level(upgrade.id)

		if current_level > 0:
			discovered_visible_run_upgrades[upgrade.id] = true
			continue

		var next_cost: float = upgrade.get_cost_for_next_level(current_level)
		var visibility_cost: float = next_cost * RUN_UPGRADE_VISIBILITY_COST_RATIO

		if GameState.squares >= visibility_cost:
			discovered_visible_run_upgrades[upgrade.id] = true


func should_show_run_upgrade(upgrade_id: String) -> bool:
	var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	if not is_run_upgrade_unlocked(upgrade_id):
		return false

	if is_run_upgrade_maxed(upgrade_id):
		return false

	if get_run_upgrade_level(upgrade_id) > 0:
		return true

	return bool(discovered_visible_run_upgrades.get(upgrade_id, false))


func has_any_visible_run_upgrade() -> bool:
	refresh_visible_run_upgrade_discoveries()

	for upgrade: RunUpgradeDefinition in RunUpgradeDatabase.get_all_upgrades():
		if upgrade == null:
			continue

		if should_show_run_upgrade(upgrade.id):
			return true

	return false

func _mark_run_upgrade_as_discovered(upgrade_id: String) -> void:
	discovered_visible_run_upgrades[upgrade_id] = true

func is_run_upgrade_maxed(upgrade_id: String) -> bool:
	var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return true

	if upgrade.max_level <= 0:
		return false

	return get_run_upgrade_level(upgrade_id) >= upgrade.max_level



func reset_run_state_on_prestige() -> void:
	run_upgrade_levels.clear()
	run_stat_multipliers.clear()
	run_stat_additions.clear()
	discovered_visible_run_upgrades.clear()

	run_upgrades_changed.emit()


func reset_to_new_game() -> void:
	reset_run_state_on_prestige()


func to_save_dict() -> Dictionary:
	return {
		"run_upgrade_levels": run_upgrade_levels,
		"run_stat_multipliers": run_stat_multipliers,
		"run_stat_additions": run_stat_additions,
		"discovered_visible_run_upgrades": discovered_visible_run_upgrades,
	}


func from_save_dict(data: Dictionary) -> void:
	run_upgrade_levels = _dictionary_from_variant(data.get("run_upgrade_levels", {}))
	run_stat_multipliers = _dictionary_from_variant(data.get("run_stat_multipliers", {}))
	run_stat_additions = _dictionary_from_variant(data.get("run_stat_additions", {}))
	discovered_visible_run_upgrades = _dictionary_from_variant(data.get("discovered_visible_run_upgrades", {}))
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
