extends RefCounted
class_name SquareData

var id: String = ""
var coordinate: String = ""
var display_name: String = ""

var grid_x: int = 0
var grid_y: int = 0

var created_at_trait_purchase: int = 0
var created_at_grid_tier: int = 0

var traits: Array[TraitInstance] = []

var permanent_tags: Array[String] = []
var temporary_tags: Array[String] = []
var status_effects: Array[String] = []

var base_value: float = 1.0
var base_respawn_time: float = 1.0
var base_manual_multiplier: float = 1.0
var base_passive_multiplier: float = 0.2
var base_crit_chance: float = 0.0
var base_crit_multiplier: float = 2.0

var current_cooldown: float = 0.0
var current_charge: float = 0.0
var temporary_value_multiplier: float = 1.0
var temporary_speed_multiplier: float = 1.0

var run_squares_generated: float = 0.0
var run_manual_clicks: int = 0
var run_passive_clicks: int = 0

var lifetime_squares_generated: float = 0.0
var lifetime_manual_clicks: int = 0
var lifetime_passive_clicks: int = 0
var times_traited: int = 0
var times_selected_for_trait_purchase: int = 0
var highest_single_payout: float = 0.0

var can_receive_traits: bool = true
var is_locked_from_random_trait: bool = false
var is_favored_for_trait: bool = false
var can_be_swapped: bool = false
var is_anchored: bool = false
var is_corrupted: bool = false

var visual_profile: VisualProfile = VisualProfile.new()

const LEGACY_CREATED_AT_KEY := "created_at_" + "pre" + "stige"
const LEGACY_SELECTED_FOR_KEY := "times_selected_for_" + "pre" + "stige"

func _init(p_id: String = "", p_grid_x: int = 0, p_grid_y: int = 0) -> void:
	id = p_id
	coordinate = p_id
	display_name = "Square %s" % p_id
	grid_x = p_grid_x
	grid_y = p_grid_y

func add_trait(trait_instance: TraitInstance) -> void:
	if trait_instance == null:
		return

	trait_instance.stack_index = _get_next_stack_index_for_trait(trait_instance)

	traits.append(trait_instance)
	times_traited += 1
	times_selected_for_trait_purchase += 1

	_rebuild_tags()
	_rebuild_visual_profile()

	display_name = generate_square_name()
	
func generate_square_name() -> String:
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

func has_traits() -> bool:
	return traits.size() > 0

func has_tag(tag: String) -> bool:
	return permanent_tags.has(tag) or temporary_tags.has(tag)

func get_trait_count() -> int:
	return traits.size()

func get_display_name() -> String:
	return display_name

func get_trait_names() -> Array[String]:
	var names: Array[String] = []
	for trait_iter in traits:
		names.append(trait_iter.get_display_name())
	return names

func record_manual_click(amount: float) -> void:
	run_manual_clicks += 1
	lifetime_manual_clicks += 1
	_record_squares_generated(amount)

func record_passive_click(amount: float) -> void:
	run_passive_clicks += 1
	lifetime_passive_clicks += 1
	_record_squares_generated(amount)

func _record_squares_generated(amount: float) -> void:
	run_squares_generated += amount
	lifetime_squares_generated += amount
	highest_single_payout = max(highest_single_payout, amount)

func _rebuild_tags() -> void:
	permanent_tags.clear()

	for trait_iter in traits:
		if trait_iter.definition == null:
			continue

		for tag in trait_iter.definition.tags:
			if not permanent_tags.has(tag):
				permanent_tags.append(tag)

func _rebuild_visual_profile() -> void:
	var profile := VisualProfile.new()

	# Start with per‑trait material contributions.
	profile.edge_complexity = min(10, traits.size())

	var rarity_score := 0
	var tag_counts: Dictionary = {}

	for trait_iter in traits:
		if trait_iter.definition == null:
			continue

		rarity_score += int(trait_iter.definition.rarity)

		profile.glow_level += trait_iter.definition.visual_glow_weight
		profile.gloss_level += trait_iter.definition.visual_gloss_weight
		profile.distortion_level += trait_iter.definition.visual_distortion_weight
		profile.edge_complexity += trait_iter.definition.visual_edge_complexity_weight

		for tag in trait_iter.definition.tags:
			tag_counts[tag] = tag_counts.get(tag, 0) + 1

	profile.glow_level = clamp(profile.glow_level + rarity_score, 0, 10)
	profile.gloss_level = clamp(profile.gloss_level, 0, 10)
	profile.edge_complexity = clamp(profile.edge_complexity, 0, 10)
	profile.distortion_level = clamp(profile.distortion_level, 0, 10)

	# --------------------------------------------------------------------
	# Family‑material identity overlay (issue #68).
	# --------------------------------------------------------------------
	var family_groups := {}
	for trait_iter in traits:
		if trait_iter.definition == null:
			continue
		var fid: String = trait_iter.definition.family_id.strip_edges()
		if fid == "":
			continue

		var info: Dictionary = family_groups.get(fid, {"stack": 0, "max_rarity": -1})
		info.stack += 1
		var r: int = int(trait_iter.definition.rarity)
		if r > info.max_rarity:
			info.max_rarity = r
		family_groups[fid] = info

	var primary_family := ""
	var best_stack := -1
	for fid in family_groups:
		if family_groups[fid].stack > best_stack:
			best_stack = family_groups[fid].stack
			primary_family = fid

	var fam_stack := 0
	var fam_rarity := 0
	if family_groups.has(primary_family):
		fam_stack = family_groups[primary_family].stack
		fam_rarity = family_groups[primary_family].max_rarity

	var family_profile := VisualProfile.get_family_profile(primary_family, fam_stack, fam_rarity)

	profile.base_color = family_profile.base_color
	profile.accent_color = family_profile.accent_color

	profile.glow_level = clampi(profile.glow_level + family_profile.glow_level, 0, 10)
	profile.edge_complexity = clampi(profile.edge_complexity + family_profile.edge_complexity, 0, 10)
	profile.gloss_level = clampi(profile.gloss_level + family_profile.gloss_level, 0, 10)
	profile.distortion_level = clampi(profile.distortion_level + family_profile.distortion_level, 0, 10)

	if family_profile.pulse_style != "none":
		profile.pulse_style = family_profile.pulse_style
	if family_profile.particle_style != "none":
		profile.particle_style = family_profile.particle_style
	if family_profile.pattern_style != "none":
		profile.pattern_style = family_profile.pattern_style

	profile.dominant_tag = _get_most_common_tag(tag_counts, 0)
	profile.secondary_tag = _get_most_common_tag(tag_counts, 1)

	visual_profile = profile
	
func _get_color_for_dominant_tag(tag: String) -> Color:
	match tag:
		"speed":
			return Color(0.55, 0.75, 1.0, 1.0)
		"value":
			return Color(1.0, 0.75, 0.45, 1.0)
		"heavy":
			return Color(1.0, 0.65, 0.45, 1.0)
		"passive":
			return Color(0.75, 0.85, 1.0, 1.0)
		"chance":
			return Color(0.85, 0.65, 1.0, 1.0)
		"corruption":
			return Color(0.65, 1.0, 0.65, 1.0)
		# --------------------------------------------------------------------
		# Family‑tag colours (issue #68).
		# --------------------------------------------------------------------
		"quick":
			return Color(0.2, 0.6, 1.0, 1.0)       # bright electric blue
		"dense":
			return Color(0.9, 0.4, 0.15, 1.0)     # warm heavy orange‑brown
		"glimmer":
			return Color(1.0, 0.85, 0.4, 1.0)     # luminous gold
		"patient":
			return Color(0.5, 0.5, 1.0, 1.0)      # soft purple‑blue
		_:
			if traits.size() > 0:
				return Color(0.85, 0.85, 1.0, 1.0)

			return Color.WHITE
func _get_most_common_tag(tag_counts: Dictionary, index: int) -> String:
	if tag_counts.is_empty():
		return ""

	var sorted_tags := tag_counts.keys()
	sorted_tags.sort_custom(func(a, b): return tag_counts[a] > tag_counts[b])

	if index >= sorted_tags.size():
		return ""

	return sorted_tags[index]

func _get_rarity_score(trait_iter: TraitInstance) -> int:
	if trait_iter == null or trait_iter.definition == null:
		return -1

	return int(trait_iter.definition.rarity)

func _to_roman(value: int) -> String:
	match value:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
		6:
			return "VI"
		7:
			return "VII"
		8:
			return "VIII"
		9:
			return "IX"
		10:
			return "X"
		_:
			return str(value)
			
func _get_trait_stack_key(trait_iter: TraitInstance) -> String:
	if trait_iter == null or trait_iter.definition == null:
		return ""

	return trait_iter.definition.id
	
func _get_next_stack_index_for_trait(trait_instance: TraitInstance) -> int:
	var new_stack_key := _get_trait_stack_key(trait_instance)

	if new_stack_key == "":
		return 1

	var count := 0

	for existing_trait: TraitInstance in traits:
		if _get_trait_stack_key(existing_trait) == new_stack_key:
			count += 1

	return count + 1

func _get_trait_family_key(trait_iter: TraitInstance) -> String:
	if trait_iter == null or trait_iter.definition == null:
		return ""

	if trait_iter.definition.family_id.strip_edges() != "":
		return trait_iter.definition.family_id

	return trait_iter.definition.id

func _get_family_prefix_word(family_key: String, family_info: Dictionary) -> String:
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

func _get_family_suffix_word(family_key: String, family_info: Dictionary) -> String:
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

func get_trait_stack_counts() -> Dictionary:
	var counts: Dictionary = {}

	for trait_iter: TraitInstance in traits:
		var stack_key: String = _get_trait_stack_key(trait_iter)

		if stack_key == "":
			continue

		counts[stack_key] = int(counts.get(stack_key, 0)) + 1

	return counts
	
func _get_first_trait_by_stack_key(stack_key: String) -> TraitInstance:
	for trait_iter: TraitInstance in traits:
		if _get_trait_stack_key(trait_iter) == stack_key:
			return trait_iter

	return null
	
func get_trait_stack_display_text() -> String:
	var counts := get_trait_stack_counts()

	if counts.is_empty():
		return "None"

	var stack_keys: Array = counts.keys()

	stack_keys.sort_custom(
		func(a, b):
			var trait_a: TraitInstance = _get_first_trait_by_stack_key(a as String)
			var trait_b: TraitInstance = _get_first_trait_by_stack_key(b as String)

			var rarity_a := _get_rarity_score(trait_a)
			var rarity_b := _get_rarity_score(trait_b)

			if rarity_a != rarity_b:
				return rarity_a > rarity_b

			var count_a: int = counts[a]
			var count_b: int = counts[b]

			if count_a != count_b:
				return count_a > count_b

			return str(a) < str(b)
	)

	var parts: Array[String] = []

	for stack_key_variant in stack_keys:
		var stack_key := stack_key_variant as String
		var trait_iter: TraitInstance = _get_first_trait_by_stack_key(stack_key)

		if trait_iter == null or trait_iter.definition == null:
			continue

		var count: int = counts[stack_key]
		var display := trait_iter.definition.get_stack_display_name()

		if count > 1:
			display = "%s %s" % [display, _to_roman(count)]

		parts.append(display)

	return ", ".join(parts)


func get_family_stack_summary() -> String:
	if traits.is_empty():
		return "None"
	
	var family_groups: Dictionary = {}
	
	for trait_iter in traits:
		if trait_iter.definition == null:
			continue
		
		var family_key := _get_trait_family_key(trait_iter)
		if family_key == "":
			continue
		
		var info: Dictionary = family_groups.get(family_key, {
			"stack_count": 0,
			"max_rarity": -1,
			"first_definition": null
		})
		info.stack_count += 1
		var rarity_val := int(trait_iter.definition.rarity)
		if rarity_val > info.max_rarity:
			info.max_rarity = rarity_val
		if info.first_definition == null:
			info.first_definition = trait_iter.definition
		family_groups[family_key] = info
	
	if family_groups.is_empty():
		return "None"
	
	var sorted_families := family_groups.keys()
	sorted_families.sort_custom(
		func(a, b):
			var info_a: Dictionary = family_groups[a]
			var info_b: Dictionary = family_groups[b]
			if info_a.max_rarity != info_b.max_rarity:
				return info_a.max_rarity > info_b.max_rarity
			if info_a.stack_count != info_b.stack_count:
				return info_a.stack_count > info_b.stack_count
			return a < b
	)
	
	var lines: Array[String] = []
	for family_key: String in sorted_families:
		var info: Dictionary = family_groups[family_key]
		var def: TraitDefinition = info.first_definition
		
		var family_display: String
		if def != null and def.family_display_name.strip_edges() != "":
			family_display = def.family_display_name
		else:
			family_display = family_key
		
		var roman: String = _to_roman(info.stack_count)
		var rarity_name: String = ""
		if info.max_rarity >= 0:
			rarity_name = TraitDefinition.rarity_name_from_value(info.max_rarity)
		
		if rarity_name == "":
			lines.append("%s %s" % [family_display, roman])
		else:
			lines.append("%s %s (%s)" % [family_display, roman, rarity_name])
	
	return "\n".join(lines)


func _get_primary_title_trait() -> TraitInstance:
	if traits.is_empty():
		return null

	var best_trait: TraitInstance = null
	var best_score := -999999

	for i in range(traits.size()):
		var trait_iter: TraitInstance = traits[i]

		if trait_iter == null or trait_iter.definition == null:
			continue

		var stack_key := _get_trait_stack_key(trait_iter)
		var stack_count: int = get_trait_stack_counts().get(stack_key, 1)

		var rarity_score := _get_rarity_score(trait_iter)

		# Rarity dominates. Stack count matters. Latest Trait breaks ties.
		var score := rarity_score * 10000 + stack_count * 100 + i

		if score > best_score:
			best_score = score
			best_trait = trait_iter

	return best_trait
	
func _get_suffix_title_trait(primary_trait: TraitInstance) -> TraitInstance:
	if primary_trait == null or primary_trait.definition == null:
		return null

	var primary_stack_key := _get_trait_stack_key(primary_trait)
	var primary_family_key := _get_trait_family_key(primary_trait)

	var best_trait: TraitInstance = null
	var best_score := -999999

	for i in range(traits.size()):
		var trait_iter: TraitInstance = traits[i]

		if trait_iter == null or trait_iter.definition == null:
			continue

		var stack_key := _get_trait_stack_key(trait_iter)

		if stack_key == primary_stack_key:
			continue

		var family_key := _get_trait_family_key(trait_iter)
		var stack_count: int = get_trait_stack_counts().get(stack_key, 1)
		var rarity_score := _get_rarity_score(trait_iter)

		# Prefer different families for the suffix.
		var different_family_bonus := 0
		if family_key != primary_family_key:
			different_family_bonus = 100000

		var score := different_family_bonus + rarity_score * 10000 + stack_count * 100 + i

		if score > best_score:
			best_score = score
			best_trait = trait_iter

	return best_trait


func _get_trait_title_text(trait_iter: TraitInstance) -> String:
	if trait_iter == null or trait_iter.definition == null:
		return ""

	var stack_key := _get_trait_stack_key(trait_iter)
	var count: int = get_trait_stack_counts().get(stack_key, 1)

	var display := trait_iter.definition.get_stack_display_name()

	if count > 1:
		display = "%s %s" % [display, _to_roman(count)]

	return display

func get_trait_effect_summary_text() -> String:
	if traits.is_empty():
		return "None"

	var lines: Array[String] = []

	for trait_iter: TraitInstance in traits:
		if trait_iter == null or trait_iter.definition == null:
			continue

		var title: String = trait_iter.definition.get_stack_display_name()

		if trait_iter.stack_index > 1:
			title = "%s #%s" % [title, trait_iter.stack_index]

		lines.append(title)

		var effect_lines: Array[String] = trait_iter.get_effect_summary_lines()

		for effect_line: String in effect_lines:
			lines.append("  - %s" % effect_line)

	return "\n".join(lines)


func to_save_dict() -> Dictionary:
	var trait_save_data: Array[Dictionary] = []

	for trait_iter: TraitInstance in traits:
		trait_save_data.append(trait_iter.to_save_dict())

	return {
		"id": id,
		"coordinate": coordinate,
		"display_name": display_name,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"created_at_trait_purchase": created_at_trait_purchase,
		"created_at_grid_tier": created_at_grid_tier,
		"traits": trait_save_data,
		"permanent_tags": permanent_tags,
		"temporary_tags": temporary_tags,
		"status_effects": status_effects,
		"base_value": base_value,
		"base_respawn_time": base_respawn_time,
		"base_manual_multiplier": base_manual_multiplier,
		"base_passive_multiplier": base_passive_multiplier,
		"base_crit_chance": base_crit_chance,
		"base_crit_multiplier": base_crit_multiplier,
		"current_cooldown": current_cooldown,
		"current_charge": current_charge,
		"temporary_value_multiplier": temporary_value_multiplier,
		"temporary_speed_multiplier": temporary_speed_multiplier,
		"run_squares_generated": run_squares_generated,
		"run_manual_clicks": run_manual_clicks,
		"run_passive_clicks": run_passive_clicks,
		"lifetime_squares_generated": lifetime_squares_generated,
		"lifetime_manual_clicks": lifetime_manual_clicks,
		"lifetime_passive_clicks": lifetime_passive_clicks,
		"times_traited": times_traited,
		"times_selected_for_trait_purchase": times_selected_for_trait_purchase,
		"highest_single_payout": highest_single_payout,
		"can_receive_traits": can_receive_traits,
		"is_locked_from_random_trait": is_locked_from_random_trait,
		"is_favored_for_trait": is_favored_for_trait,
		"can_be_swapped": can_be_swapped,
		"is_anchored": is_anchored,
		"is_corrupted": is_corrupted
	}

static func from_save_dict(data: Dictionary) -> SquareData:
	var square_data := SquareData.new(
		str(data.get("id", "")),
		int(data.get("grid_x", 0)),
		int(data.get("grid_y", 0))
	)

	square_data.coordinate = str(data.get("coordinate", square_data.id))
	square_data.display_name = str(data.get("display_name", "Square %s" % square_data.coordinate))
	square_data.created_at_trait_purchase = int(data.get(
		"created_at_trait_purchase",
		data.get(LEGACY_CREATED_AT_KEY, 0)
	))
	square_data.created_at_grid_tier = int(data.get("created_at_grid_tier", 0))

	square_data.traits.clear()

	var trait_save_data: Array = data.get("traits", [])

	for trait_data_variant: Variant in trait_save_data:
		if not trait_data_variant is Dictionary:
			continue

		var trait_instance: TraitInstance = TraitInstance.from_save_dict(trait_data_variant as Dictionary)
		square_data.traits.append(trait_instance)

	square_data.permanent_tags = _string_array_from_variant(data.get("permanent_tags", []))
	square_data.temporary_tags = _string_array_from_variant(data.get("temporary_tags", []))
	square_data.status_effects = _string_array_from_variant(data.get("status_effects", []))

	square_data.base_value = float(data.get("base_value", 1.0))
	square_data.base_respawn_time = float(data.get("base_respawn_time", 1.0))
	square_data.base_manual_multiplier = float(data.get("base_manual_multiplier", 1.0))
	square_data.base_passive_multiplier = float(data.get("base_passive_multiplier", 0.2))
	square_data.base_crit_chance = float(data.get("base_crit_chance", 0.0))
	square_data.base_crit_multiplier = float(data.get("base_crit_multiplier", 2.0))

	square_data.current_cooldown = float(data.get("current_cooldown", 0.0))
	square_data.current_charge = float(data.get("current_charge", 0.0))
	square_data.temporary_value_multiplier = float(data.get("temporary_value_multiplier", 1.0))
	square_data.temporary_speed_multiplier = float(data.get("temporary_speed_multiplier", 1.0))

	square_data.run_squares_generated = float(data.get("run_squares_generated", 0.0))
	square_data.run_manual_clicks = int(data.get("run_manual_clicks", 0))
	square_data.run_passive_clicks = int(data.get("run_passive_clicks", 0))

	square_data.lifetime_squares_generated = float(data.get("lifetime_squares_generated", 0.0))
	square_data.lifetime_manual_clicks = int(data.get("lifetime_manual_clicks", 0))
	square_data.lifetime_passive_clicks = int(data.get("lifetime_passive_clicks", 0))
	square_data.times_traited = int(data.get("times_traited", 0))
	square_data.times_selected_for_trait_purchase = int(data.get(
		"times_selected_for_trait_purchase",
		data.get(LEGACY_SELECTED_FOR_KEY, 0)
	))
	square_data.highest_single_payout = float(data.get("highest_single_payout", 0.0))

	square_data.can_receive_traits = bool(data.get("can_receive_traits", true))
	square_data.is_locked_from_random_trait = bool(data.get("is_locked_from_random_trait", false))
	square_data.is_favored_for_trait = bool(data.get("is_favored_for_trait", false))
	square_data.can_be_swapped = bool(data.get("can_be_swapped", false))
	square_data.is_anchored = bool(data.get("is_anchored", false))
	square_data.is_corrupted = bool(data.get("is_corrupted", false))

	square_data._rebuild_tags()
	square_data._rebuild_visual_profile()

	return square_data

static func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []

	if not value is Array:
		return result

	for item: Variant in value:
		result.append(str(item))

	return result
