extends RefCounted
class_name SquareNaming

static func generate_name(coordinate: String, traits: Array[TraitInstance]) -> String:
	if traits.is_empty():
		return "Square %s" % coordinate

	var family_data: Dictionary = {}

	for i: int in range(traits.size()):
		var trait_iter: TraitInstance = traits[i]
		if trait_iter == null or trait_iter.definition == null:
			continue

		var family_key: String = _get_trait_family_key(trait_iter)
		if family_key == "":
			continue

		if not family_data.has(family_key):
			family_data[family_key] = {
				"stack_count": 0,
				"max_rarity": -1,
				"latest_index": -1,
				"first_definition": null,
			}

		var info: Dictionary = family_data[family_key]
		info.stack_count += 1
		var rarity: int = int(trait_iter.definition.rarity)
		if rarity > info.max_rarity:
			info.max_rarity = rarity
		if i > info.latest_index:
			info.latest_index = i

		if info.get("first_definition", null) == null and trait_iter.definition != null:
			info["first_definition"] = trait_iter.definition

	if family_data.is_empty():
		return "Square %s" % coordinate

	var family_keys: Array = family_data.keys()
	family_keys.sort_custom(
		func(a: String, b: String) -> bool:
			var info_a: Dictionary = family_data[a]
			var info_b: Dictionary = family_data[b]

			if info_a.stack_count != info_b.stack_count:
				return info_a.stack_count > info_b.stack_count

			if info_a.max_rarity != info_b.max_rarity:
				return info_a.max_rarity > info_b.max_rarity

			if info_a.latest_index != info_b.latest_index:
				return info_a.latest_index > info_b.latest_index

			return a < b
	)

	var prefix_family: String = family_keys[0]
	var prefix_info: Dictionary = family_data[prefix_family]
	var prefix_word: String = _get_family_prefix_word(prefix_family, prefix_info)

	var suffix_family: String = ""
	for key: String in family_keys:
		if key != prefix_family:
			suffix_family = key
			break

	if suffix_family == "":
		return "%s Square" % prefix_word

	var suffix_info: Dictionary = family_data[suffix_family]
	var suffix_word: String = _get_family_suffix_word(suffix_family, suffix_info)

	return "%s Square %s" % [prefix_word, suffix_word]

static func _get_trait_family_key(trait_iter: TraitInstance) -> String:
	if trait_iter == null or trait_iter.definition == null:
		return ""

	if trait_iter.definition.family_id.strip_edges() != "":
		return trait_iter.definition.family_id

	return trait_iter.definition.id

static func _get_family_prefix_word(family_key: String, family_info: Dictionary) -> String:
	var count: int = family_info.stack_count
	var def: TraitDefinition = family_info.get("first_definition", null)
	if def != null:
		var pool: Array = def.name_prefixes
		if pool.size() > 0:
			var idx: int = clampi(count - 1, 0, pool.size() - 1)
			return pool[idx]
		# Fallback: use the family's display name if present.
		var family_display := def.family_display_name.strip_edges()
		if family_display != "":
			return family_display
	# Ultimate safety fallback.
	return family_key

static func _get_family_suffix_word(family_key: String, family_info: Dictionary) -> String:
	var count: int = family_info.stack_count
	var def: TraitDefinition = family_info.get("first_definition", null)
	if def != null:
		var pool: Array = def.name_suffixes
		if pool.size() > 0:
			var idx: int = clampi(count - 1, 0, pool.size() - 1)
			return pool[idx]
		# Fallback: create a suffix from the family's display name.
		var family_display := def.family_display_name.strip_edges()
		if family_display != "":
			return "of " + family_display
	# Ultimate safety fallback.
	return "of " + family_key
