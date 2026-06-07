extends RefCounted
class_name SquareData

var id: String = ""
var coordinate: String = ""
var display_name: String = ""

var grid_x: int = 0
var grid_y: int = 0

var created_at_prestige: int = 0
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
var times_selected_for_prestige: int = 0
var highest_single_payout: float = 0.0

var can_receive_traits: bool = true
var is_locked_from_random_trait: bool = false
var is_favored_for_trait: bool = false
var can_be_swapped: bool = false
var is_anchored: bool = false
var is_corrupted: bool = false

var visual_profile: VisualProfile = VisualProfile.new()

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
	times_selected_for_prestige += 1

	_rebuild_tags()
	_rebuild_visual_profile()

	display_name = generate_square_name()
	
func generate_square_name() -> String:
	if traits.is_empty():
		return "Square %s" % coordinate

	var primary_trait := _get_primary_title_trait()

	if primary_trait == null:
		return "Square %s" % coordinate

	var primary_text := _get_trait_title_text(primary_trait)
	var suffix_trait := _get_suffix_title_trait(primary_trait)

	if suffix_trait == null:
		return "%s Square" % primary_text

	var suffix_text := _get_trait_title_text(suffix_trait)

	if suffix_text == "":
		return "%s Square" % primary_text

	return "%s Square of %s" % [primary_text, suffix_text]

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

	profile.dominant_tag = _get_most_common_tag(tag_counts, 0)
	profile.secondary_tag = _get_most_common_tag(tag_counts, 1)
	profile.base_color = _get_color_for_dominant_tag(profile.dominant_tag)
	profile.accent_color = _get_color_for_dominant_tag(profile.secondary_tag)
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
