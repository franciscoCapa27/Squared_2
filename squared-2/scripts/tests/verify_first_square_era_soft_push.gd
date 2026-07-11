extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	_reset_systems_for_opening_loop()

	_verify_fresh_player_reaches_first_prestige_quickly()
	_verify_prestige_applies_trait_and_resets_run_layer()
	_verify_repeated_one_by_one_prestige_remains_possible()
	_verify_two_by_two_expansion_is_visible_desirable_and_optional()

	if failures.is_empty():
		print("First Square Era Soft Push verification passed.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)

	quit(1)


func _reset_systems_for_opening_loop() -> void:
	TraitDatabase.load_traits()
	GameState.reset_to_new_game()
	PassiveSystem.reset_to_new_game()
	RunUpgradeSystem.reset_to_new_game()


func _verify_fresh_player_reaches_first_prestige_quickly() -> void:
	var clicks_needed: int = _click_until_prestige_ready(20)

	_assert_true(
		GameState.can_prestige(),
		"Fresh manual clicking reaches prestige readiness."
	)
	_assert_true(
		clicks_needed <= 10,
		"Fresh first prestige is reachable in about ten manual clicks."
	)


func _verify_prestige_applies_trait_and_resets_run_layer() -> void:
	var origin_square: SquareData = GameState.get_square(GameState.INITIAL_SQUARE_ID)

	_assert_true(
		origin_square != null,
		"Fresh save has the origin square."
	)
	_assert_true(
		origin_square.run_manual_clicks > 0,
		"Origin square has run manual clicks before prestige."
	)

	GameState.prestige(false)

	_assert_equal(1, GameState.prestige_count, "First prestige increments prestige count.")
	_assert_equal(1, GameState.vertices, "First prestige grants at least one Vertex.")
	_assert_equal(0.0, GameState.squares, "Prestige resets current Squares.")
	_assert_equal(1, origin_square.get_trait_count(), "Prestige applies one permanent Trait.")
	_assert_equal(0, origin_square.run_manual_clicks, "Prestige resets square run manual clicks.")
	_assert_true(
		origin_square.lifetime_manual_clicks > 0,
		"Prestige preserves lifetime manual click history."
	)
	_assert_true(
		origin_square.display_name != "Square A1",
		"Prestige visibly changes the origin square identity."
	)


func _verify_repeated_one_by_one_prestige_remains_possible() -> void:
	var origin_square: SquareData = GameState.get_square(GameState.INITIAL_SQUARE_ID)
	var previous_trait_count: int = origin_square.get_trait_count()

	_click_until_prestige_ready(20)
	GameState.prestige(false)

	_assert_equal(2, GameState.prestige_count, "A second 1x1 prestige is allowed.")
	_assert_equal(GameState.INITIAL_GRID_SIZE, GameState.grid_size, "Repeated 1x1 prestige does not force grid expansion.")
	_assert_equal(
		previous_trait_count + 1,
		origin_square.get_trait_count(),
		"Repeated 1x1 prestige stacks another permanent Trait."
	)


func _verify_two_by_two_expansion_is_visible_desirable_and_optional() -> void:
	_assert_true(
		GameState.should_soft_push_grid_upgrade(),
		"After a 1x1 prestige, the game enters the grid-upgrade Soft Push."
	)
	_assert_true(
		FeatureVisibilityRules.should_show_grid_upgrade_button(),
		"2x2 expansion opportunity is visible during the First Square Era."
	)
	_assert_true(
		not GameState.can_upgrade_grid(),
		"2x2 expansion is visible before it is affordable."
	)
	_assert_equal(
		GameState.INITIAL_GRID_SIZE,
		GameState.grid_size,
		"2x2 expansion is not automatic."
	)

	GameState.add_squares(GameState.get_grid_upgrade_cost())

	_assert_true(
		GameState.can_upgrade_grid(),
		"2x2 expansion becomes available as a player choice after saving enough Squares."
	)
	_assert_equal(
		GameState.INITIAL_GRID_SIZE,
		GameState.grid_size,
		"Affordable 2x2 expansion still waits for the player's choice."
	)


func _click_until_prestige_ready(max_clicks: int) -> int:
	var clicks: int = 0

	while not GameState.can_prestige() and clicks < max_clicks:
		GameState.click_square(GameState.INITIAL_SQUARE_ID)
		clicks += 1

	return clicks


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(expected: Variant, actual: Variant, message: String) -> void:
	if expected != actual:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
