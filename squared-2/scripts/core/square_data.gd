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

	traits.append(trait_instance)
	times_traited += 1
	times_selected_for_prestige += 1
	_rebuild_tags()
	_rebuild_visual_profile()

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
