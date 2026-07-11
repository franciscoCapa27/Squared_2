extends SceneTree

const TraitDatabaseScript := preload("res://scripts/autoload/trait_database.gd")
const TRAIT_ROOT_PATH := "res://data/traits"

var failures: Array[String] = []


func _initialize() -> void:
	var raw_traits: Array[TraitDefinition] = _load_raw_trait_resources(TRAIT_ROOT_PATH)
	var trait_database = TraitDatabaseScript.new()
	trait_database.load_traits()

	_verify_all_resources_are_loaded(raw_traits, trait_database)
	_verify_trait_ids(raw_traits)
	_verify_trait_content_shape(raw_traits)
	_verify_one_by_one_pool_stays_common(trait_database)
	_verify_two_by_two_pool_has_uncommon_family_variety(trait_database)
	_verify_families_repeat_across_rarities(trait_database)
	_verify_no_grid_synergy_effects(raw_traits)

	if failures.is_empty():
		print("First 2x2 Trait content pack verification passed.")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)

	quit(1)


func _load_raw_trait_resources(path: String) -> Array[TraitDefinition]:
	var traits: Array[TraitDefinition] = []
	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		failures.append("Could not open Trait directory: %s" % path)
		return traits

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path: String = path.path_join(file_name)

		if dir.current_is_dir():
			traits.append_array(_load_raw_trait_resources(full_path))
		elif _is_resource_file(file_name):
			var resource: Resource = load(full_path)

			if resource == null:
				failures.append("Trait resource did not load: %s" % full_path)
			elif not resource is TraitDefinition:
				failures.append("Resource is not a TraitDefinition: %s" % full_path)
			else:
				traits.append(resource as TraitDefinition)

		file_name = dir.get_next()

	dir.list_dir_end()

	return traits


func _is_resource_file(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res")


func _verify_all_resources_are_loaded(
	raw_traits: Array[TraitDefinition],
	trait_database
) -> void:
	_assert_equal(
		raw_traits.size(),
		trait_database.all_traits.size(),
		"TraitDatabase loads every raw Trait resource."
	)


func _verify_trait_ids(raw_traits: Array[TraitDefinition]) -> void:
	var ids: Dictionary = {}

	for trait_definition: TraitDefinition in raw_traits:
		_assert_true(
			trait_definition.id.strip_edges() != "",
			"Trait id is not empty."
		)
		_assert_equal(
			trait_definition.id,
			trait_definition.id.strip_edges(),
			"Trait id has no surrounding whitespace."
		)
		_assert_true(
			not ids.has(trait_definition.id),
			"Trait id is unique: %s." % trait_definition.id
		)

		ids[trait_definition.id] = true


func _verify_trait_content_shape(raw_traits: Array[TraitDefinition]) -> void:
	for trait_definition: TraitDefinition in raw_traits:
		_assert_true(
			trait_definition.display_name.strip_edges() != "",
			"Trait %s has a display name." % trait_definition.id
		)
		_assert_true(
			trait_definition.family_id.strip_edges() != "",
			"Trait %s has a family id." % trait_definition.id
		)
		_assert_true(
			trait_definition.family_display_name.strip_edges() != "",
			"Trait %s has a family display name." % trait_definition.id
		)
		_assert_true(
			trait_definition.display_name.contains(trait_definition.family_display_name),
			"Trait %s display name includes its family." % trait_definition.id
		)
		_assert_true(
			trait_definition.description.contains(trait_definition.family_display_name),
			"Trait %s description names its family." % trait_definition.id
		)
		_assert_true(
			trait_definition.tags.has(trait_definition.family_id),
			"Trait %s tags include its family id." % trait_definition.id
		)
		_assert_true(
			trait_definition.weight > 0.0,
			"Trait %s has positive roll weight." % trait_definition.id
		)
		_assert_true(
			trait_definition.min_grid_tier >= 1,
			"Trait %s has a valid minimum grid tier." % trait_definition.id
		)

		if trait_definition.max_grid_tier > 0:
			_assert_true(
				trait_definition.max_grid_tier >= trait_definition.min_grid_tier,
				"Trait %s max grid tier does not precede min grid tier." % trait_definition.id
			)


func _verify_one_by_one_pool_stays_common(trait_database) -> void:
	var eligible_traits: Array[TraitDefinition] = trait_database.get_eligible_traits(1)

	_assert_true(
		not eligible_traits.is_empty(),
		"1x1 Trait pool is not empty."
	)

	for trait_definition: TraitDefinition in eligible_traits:
		_assert_equal(
			int(TraitDefinition.Rarity.COMMON),
			int(trait_definition.rarity),
			"1x1 Trait pool contains only Common Traits."
		)


func _verify_two_by_two_pool_has_uncommon_family_variety(trait_database) -> void:
	var uncommon_traits: Array[TraitDefinition] = trait_database.get_eligible_traits_for_rarity(
		TraitDefinition.Rarity.UNCOMMON,
		2
	)
	var eligible_traits: Array[TraitDefinition] = trait_database.get_eligible_traits(2)
	var families: Dictionary = {}

	for trait_definition: TraitDefinition in eligible_traits:
		families[trait_definition.family_id] = true

	_assert_true(
		uncommon_traits.size() >= 4,
		"2x2 Trait pool includes several Uncommon variants."
	)
	_assert_true(
		families.size() >= 4,
		"2x2 Trait pool includes appropriate early family variety."
	)

	for trait_definition: TraitDefinition in uncommon_traits:
		_assert_true(
			trait_definition.min_grid_tier <= 2,
			"2x2 Uncommon Trait %s is eligible at 2x2." % trait_definition.id
		)


func _verify_families_repeat_across_rarities(trait_database) -> void:
	var rarities_by_family: Dictionary = {}

	for trait_definition: TraitDefinition in trait_database.get_eligible_traits(2):
		var rarities: Dictionary = rarities_by_family.get(trait_definition.family_id, {})
		rarities[int(trait_definition.rarity)] = true
		rarities_by_family[trait_definition.family_id] = rarities

	var families_with_multiple_rarities: int = 0

	for family_id: Variant in rarities_by_family.keys():
		var rarities: Dictionary = rarities_by_family[family_id]

		if rarities.size() >= 2:
			families_with_multiple_rarities += 1

	_assert_true(
		families_with_multiple_rarities >= 3,
		"At least a few Trait Families appear across rarities."
	)


func _verify_no_grid_synergy_effects(raw_traits: Array[TraitDefinition]) -> void:
	for trait_definition: TraitDefinition in raw_traits:
		for effect_iter: EffectComponent in trait_definition.effect_components:
			if effect_iter == null:
				failures.append("Trait %s has a null effect component." % trait_definition.id)
				continue

			_assert_equal(
				int(EffectComponent.EffectType.STAT_MODIFIER),
				int(effect_iter.effect_type),
				"Trait %s uses only direct stat modifiers." % trait_definition.id
			)
			_assert_equal(
				int(EffectComponent.Scope.SELF),
				int(effect_iter.scope),
				"Trait %s does not introduce grid or adjacency scope." % trait_definition.id
			)
			_assert_true(
				effect_iter.target_stat == "square_value" or effect_iter.target_stat == "respawn_time",
				"Trait %s affects only early square stats." % trait_definition.id
			)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(expected: Variant, actual: Variant, message: String) -> void:
	if expected != actual:
		failures.append("%s Expected %s, got %s." % [message, str(expected), str(actual)])
