extends SceneTree

const TraitDatabaseScript := preload("res://scripts/autoload/trait_database.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var trait_database = TraitDatabaseScript.new()
	trait_database.load_traits()

	_verify_one_by_one_stays_common_with_luck(trait_database)
	_verify_two_by_two_unlocks_uncommon_without_rare(trait_database)
	_verify_trait_luck_shifts_only_unlocked_rarity_buckets(trait_database)
	_verify_trait_weights_affect_deterministic_selection(trait_database)
	_verify_empty_selected_rarity_falls_back_to_eligible_traits(trait_database)

	if failures.is_empty():
		print("Trait roll foundation verification passed.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)

	quit(1)


func _verify_one_by_one_stays_common_with_luck(trait_database) -> void:
	var weights: Dictionary = trait_database.get_rarity_weights_for_grid_with_luck(1, 50.0)
	_assert_true(
		weights.has(TraitDefinition.Rarity.COMMON),
		"1x1 weights include Common."
	)
	_assert_true(
		not weights.has(TraitDefinition.Rarity.UNCOMMON),
		"1x1 Trait Luck does not unlock Uncommon."
	)
	_assert_true(
		not weights.has(TraitDefinition.Rarity.RARE),
		"1x1 Trait Luck does not unlock Rare."
	)

	var forced_uncommon_candidates: Array[TraitDefinition] = trait_database.get_roll_candidates_for_rarity(
		TraitDefinition.Rarity.UNCOMMON,
		1
	)

	_assert_true(
		not forced_uncommon_candidates.is_empty(),
		"1x1 fallback candidates exist when an unavailable rarity is selected."
	)

	for trait_definition: TraitDefinition in forced_uncommon_candidates:
		_assert_equal(
			int(TraitDefinition.Rarity.COMMON),
			int(trait_definition.rarity),
			"1x1 fallback candidates stay Common."
		)


func _verify_two_by_two_unlocks_uncommon_without_rare(trait_database) -> void:
	var uncommon_traits: Array[TraitDefinition] = trait_database.get_eligible_traits_for_rarity(
		TraitDefinition.Rarity.UNCOMMON,
		2
	)

	_assert_true(
		not uncommon_traits.is_empty(),
		"2x2 has at least one eligible Uncommon Trait."
	)

	var weights: Dictionary = trait_database.get_rarity_weights_for_grid_with_luck(2, 0.0)
	_assert_true(
		weights.has(TraitDefinition.Rarity.UNCOMMON),
		"2x2 weights include Uncommon."
	)
	_assert_true(
		not weights.has(TraitDefinition.Rarity.RARE),
		"2x2 base weights do not include Rare."
	)


func _verify_trait_luck_shifts_only_unlocked_rarity_buckets(trait_database) -> void:
	var base_weights: Dictionary = trait_database.get_rarity_weights_for_grid_with_luck(2, 0.0)
	var lucky_weights: Dictionary = trait_database.get_rarity_weights_for_grid_with_luck(2, 10.0)

	_assert_equal(
		85.0,
		float(base_weights[TraitDefinition.Rarity.COMMON]),
		"2x2 Common base weight is stable."
	)
	_assert_equal(
		15.0,
		float(base_weights[TraitDefinition.Rarity.UNCOMMON]),
		"2x2 Uncommon base weight is stable."
	)
	_assert_equal(
		75.0,
		float(lucky_weights[TraitDefinition.Rarity.COMMON]),
		"Trait Luck shifts weight away from 2x2 Common."
	)
	_assert_equal(
		25.0,
		float(lucky_weights[TraitDefinition.Rarity.UNCOMMON]),
		"Trait Luck shifts weight into 2x2 Uncommon."
	)
	_assert_true(
		not lucky_weights.has(TraitDefinition.Rarity.RARE),
		"Trait Luck does not unlock Rare at 2x2."
	)


func _verify_trait_weights_affect_deterministic_selection(trait_database) -> void:
	var low_weight_trait := TraitDefinition.new()
	low_weight_trait.id = "low_weight_trait"
	low_weight_trait.weight = 1.0

	var high_weight_trait := TraitDefinition.new()
	high_weight_trait.id = "high_weight_trait"
	high_weight_trait.weight = 3.0

	var zero_weight_trait := TraitDefinition.new()
	zero_weight_trait.id = "zero_weight_trait"
	zero_weight_trait.weight = 0.0

	var candidates: Array[TraitDefinition] = [low_weight_trait, high_weight_trait]
	var candidates_with_zero: Array[TraitDefinition] = [zero_weight_trait, low_weight_trait]

	_assert_equal(
		"low_weight_trait",
		trait_database.get_weighted_trait_for_roll(candidates, 0.10).id,
		"Low normalized roll selects the low-weight Trait."
	)
	_assert_equal(
		"high_weight_trait",
		trait_database.get_weighted_trait_for_roll(candidates, 0.50).id,
		"Higher normalized roll selects the high-weight Trait."
	)
	_assert_equal(
		"low_weight_trait",
		trait_database.get_weighted_trait_for_roll(candidates_with_zero, 0.0).id,
		"Zero-weight Traits are not selected when total candidate weight is positive."
	)


func _verify_empty_selected_rarity_falls_back_to_eligible_traits(trait_database) -> void:
	var candidates: Array[TraitDefinition] = trait_database.get_roll_candidates_for_rarity(
		TraitDefinition.Rarity.RARE,
		2
	)

	_assert_true(
		not candidates.is_empty(),
		"2x2 Rare fallback returns eligible candidates."
	)

	for trait_definition: TraitDefinition in candidates:
		_assert_true(
			int(trait_definition.rarity) <= int(TraitDefinition.Rarity.UNCOMMON),
			"2x2 Rare fallback does not include locked higher rarities."
		)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(expected: Variant, actual: Variant, message: String) -> void:
	if expected != actual:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
