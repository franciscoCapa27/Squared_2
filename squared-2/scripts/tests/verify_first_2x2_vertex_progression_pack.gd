extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	_reset_systems()

	_verify_pre_expansion_vertex_choices()
	_verify_pre_expansion_purchases_do_not_unlock_automation()
	_verify_post_expansion_automation_path()

	if failures.is_empty():
		print("First 2x2 Vertex progression verification passed.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)

	quit(1)


func _reset_systems() -> void:
	VertexUpgradeDatabase.load_upgrades()
	PassiveGeneratorDatabase.load_generators()
	GameState.reset_to_new_game()
	VertexUpgradeSystem.reset_to_new_game()
	PassiveSystem.reset_to_new_game()


func _verify_pre_expansion_vertex_choices() -> void:
	GameState.prestige_count = 1
	GameState.vertices = 1
	GameState.grid_size = 1

	var visible_ids: Array[String] = _get_visible_upgrade_ids()

	_assert_true(
		visible_ids.has(GameIds.UPGRADE_SHARPENED_ORIGIN),
		"Pre-2x2 Vertex shop shows manual permanent power."
	)
	_assert_true(
		visible_ids.has(GameIds.UPGRADE_GEOMETRIC_INTUITION),
		"Pre-2x2 Vertex shop shows Trait curiosity."
	)
	_assert_true(
		not visible_ids.has(GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR),
		"Pre-2x2 Vertex shop hides passive automation unlock."
	)
	_assert_true(
		VertexUpgradeSystem.can_buy_vertex_upgrade(GameIds.UPGRADE_SHARPENED_ORIGIN),
		"Sharpened Origin is buyable with the first Vertex."
	)
	_assert_true(
		VertexUpgradeSystem.can_buy_vertex_upgrade(GameIds.UPGRADE_GEOMETRIC_INTUITION),
		"Geometric Intuition is buyable with the first Vertex."
	)


func _verify_pre_expansion_purchases_do_not_unlock_automation() -> void:
	GameState.vertices = 2

	var bought_power: bool = VertexUpgradeSystem.buy_vertex_upgrade(GameIds.UPGRADE_SHARPENED_ORIGIN)
	var bought_luck: bool = VertexUpgradeSystem.buy_vertex_upgrade(GameIds.UPGRADE_GEOMETRIC_INTUITION)

	_assert_true(bought_power, "Can buy Sharpened Origin before 2x2.")
	_assert_true(bought_luck, "Can buy Geometric Intuition before 2x2.")
	_assert_equal(
		1.1,
		GameState.get_permanent_stat_multiplier(GameIds.STAT_SQUARE_BASE_VALUE),
		"Sharpened Origin applies permanent square base value."
	)
	_assert_equal(
		10.0,
		GameState.get_permanent_stat_addition(GameIds.STAT_TRAIT_LUCK),
		"Geometric Intuition applies Trait Luck."
	)
	_assert_true(
		not PassiveSystem.has_any_unlocked_generator(),
		"Pre-2x2 Vertex purchases do not unlock passive generators."
	)


func _verify_post_expansion_automation_path() -> void:
	GameState.grid_size = 2
	GameState.vertices = 2

	var visible_ids: Array[String] = _get_visible_upgrade_ids()

	_assert_true(
		visible_ids.has(GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR),
		"2x2 Vertex shop reveals first automation unlock."
	)
	_assert_true(
		VertexUpgradeSystem.can_buy_vertex_upgrade(GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR),
		"First automation unlock is buyable at 2x2 with enough Vertices."
	)

	var bought_generator: bool = VertexUpgradeSystem.buy_vertex_upgrade(
		GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR
	)

	_assert_true(bought_generator, "Can buy first automation unlock after 2x2.")
	_assert_true(
		PassiveSystem.has_any_unlocked_generator(),
		"Post-2x2 automation purchase unlocks a passive generator."
	)

	GameState.vertices = 2
	visible_ids = _get_visible_upgrade_ids()

	_assert_true(
		visible_ids.has(GameIds.UPGRADE_UNLOCK_VALUE_HARVESTER),
		"Buying first automation reveals the next automation option."
	)


func _get_visible_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []

	for upgrade: VertexUpgradeDefinition in VertexUpgradeDatabase.get_visible_upgrades():
		ids.append(upgrade.id)

	return ids


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(expected: Variant, actual: Variant, message: String) -> void:
	if expected != actual:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
