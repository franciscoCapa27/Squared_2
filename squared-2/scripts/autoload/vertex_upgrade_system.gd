extends Node

signal vertex_upgrades_changed()
signal vertex_upgrade_purchased(upgrade_id: String)

const DEBUG_VERTEX_UPGRADES := false

var unlocked_vertex_upgrades: Dictionary = {}


func has_vertex_upgrade(upgrade_id: String) -> bool:
	return get_vertex_upgrade_purchase_count(upgrade_id) > 0


func get_vertex_upgrade_purchase_count(upgrade_id: String) -> int:
	var value: Variant = unlocked_vertex_upgrades.get(upgrade_id, 0)

	if value is bool:
		return 1 if bool(value) else 0

	return int(value)


func can_buy_vertex_upgrade(upgrade_id: String) -> bool:
	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	if GameState.vertices < upgrade.cost_vertices:
		return false

	if not upgrade.requirements_are_met(
		GameState.prestige_count,
		GameState.grid_size,
		unlocked_vertex_upgrades
	):
		return false

	var purchase_count: int = get_vertex_upgrade_purchase_count(upgrade_id)

	if not upgrade.is_repeatable and purchase_count > 0:
		return false

	if upgrade.is_repeatable and upgrade.max_purchases > 0:
		if purchase_count >= upgrade.max_purchases:
			return false

	return true


func buy_vertex_upgrade(upgrade_id: String) -> bool:
	if DEBUG_VERTEX_UPGRADES:
		print("Trying to buy vertex upgrade: %s" % upgrade_id)

	if not can_buy_vertex_upgrade(upgrade_id):
		if DEBUG_VERTEX_UPGRADES:
			print("Cannot buy vertex upgrade: %s" % upgrade_id)

		return false

	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		if DEBUG_VERTEX_UPGRADES:
			print("Upgrade resource not found: %s" % upgrade_id)

		return false

	if not GameState.spend_vertices(upgrade.cost_vertices):
		return false

	if DEBUG_VERTEX_UPGRADES:
		print("Buying upgrade: %s" % upgrade.display_name)
		print("Effect count: %s" % upgrade.effects.size())

	_apply_vertex_upgrade_effects(upgrade)
	_record_vertex_upgrade_purchase(upgrade.id)

	vertex_upgrade_purchased.emit(upgrade.id)
	vertex_upgrades_changed.emit()
	EventBus.vertex_upgrade_purchased.emit(upgrade.id)
	EventBus.story_message.emit("%s unlocked." % upgrade.display_name)

	return true


func reset_to_new_game() -> void:
	unlocked_vertex_upgrades.clear()
	vertex_upgrades_changed.emit()


func to_save_dict() -> Dictionary:
	return {
		"unlocked_vertex_upgrades": unlocked_vertex_upgrades
	}


func from_save_dict(data: Dictionary) -> void:
	unlocked_vertex_upgrades = _dictionary_from_variant(
		data.get("unlocked_vertex_upgrades", {})
	)

	vertex_upgrades_changed.emit()


func _record_vertex_upgrade_purchase(upgrade_id: String) -> void:
	var purchase_count: int = get_vertex_upgrade_purchase_count(upgrade_id)
	unlocked_vertex_upgrades[upgrade_id] = purchase_count + 1


func _apply_vertex_upgrade_effects(upgrade: VertexUpgradeDefinition) -> void:
	if DEBUG_VERTEX_UPGRADES:
		print("Applying effects for upgrade: %s" % upgrade.id)

	for effect_iter: VertexUpgradeEffect in upgrade.effects:
		if effect_iter == null:
			if DEBUG_VERTEX_UPGRADES:
				print("Skipped null vertex upgrade effect.")

			continue

		if DEBUG_VERTEX_UPGRADES:
			print("Applying effect type: %s" % effect_iter.effect_type)

		_apply_vertex_upgrade_effect(effect_iter)


func _apply_vertex_upgrade_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter == null:
		return

	match effect_iter.effect_type:
		VertexUpgradeEffect.EffectType.UNLOCK_PASSIVE_GENERATOR:
			_apply_unlock_passive_generator_effect(effect_iter)

		VertexUpgradeEffect.EffectType.GLOBAL_STAT_MULTIPLIER:
			_apply_global_stat_multiplier_effect(effect_iter)

		VertexUpgradeEffect.EffectType.ADD_PERMANENT_STAT:
			_apply_add_permanent_stat_effect(effect_iter)

		VertexUpgradeEffect.EffectType.UNLOCK_MECHANIC:
			_apply_unlock_mechanic_effect(effect_iter)

		VertexUpgradeEffect.EffectType.ADD_STARTING_SQUARES:
			_apply_add_starting_squares_effect(effect_iter)

		VertexUpgradeEffect.EffectType.UNLOCK_TAB:
			_apply_unlock_tab_effect(effect_iter)

		VertexUpgradeEffect.EffectType.SCRIPT_HOOK:
			_apply_script_hook_effect(effect_iter)

		_:
			push_warning("Unhandled vertex upgrade effect: %s" % effect_iter.effect_type)


func _apply_unlock_passive_generator_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_id.strip_edges() == "":
		push_warning("UNLOCK_PASSIVE_GENERATOR missing target_id.")
		return

	PassiveSystem.unlock_generator(effect_iter.target_id)


func _apply_global_stat_multiplier_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("GLOBAL_STAT_MULTIPLIER missing target_stat.")
		return

	GameState.multiply_permanent_stat(effect_iter.target_stat, effect_iter.value)


func _apply_add_permanent_stat_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("ADD_PERMANENT_STAT missing target_stat.")
		return

	GameState.add_permanent_stat(effect_iter.target_stat, effect_iter.value)


func _apply_unlock_mechanic_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("UNLOCK_MECHANIC effect not implemented yet: %s" % effect_iter.mechanic_id)


func _apply_add_starting_squares_effect(_effect_iter: VertexUpgradeEffect) -> void:
	push_warning("ADD_STARTING_SQUARES effect not implemented yet.")


func _apply_unlock_tab_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("UNLOCK_TAB effect not implemented yet: %s" % effect_iter.target_id)


func _apply_script_hook_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("SCRIPT_HOOK effect not implemented yet: %s" % effect_iter.script_hook_id)


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}
