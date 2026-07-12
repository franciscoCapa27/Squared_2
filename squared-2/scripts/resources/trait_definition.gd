extends Resource
class_name TraitDefinition

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	COSMIC
}

@export var id: String = ""
@export var display_name: String = ""
@export var family_id: String = ""
@export var family_display_name: String = ""

@export_multiline var description: String = ""


@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[String] = []

@export var weight: float = 1.0
@export var min_grid_tier: int = 1
@export var max_grid_tier: int = -1
@export var max_stack_count: int = -1
@export var can_duplicate: bool = true

@export var effect_components: Array[EffectComponent] = []

@export var name_prefixes: Array[String] = []
@export var name_suffixes: Array[String] = []

@export var visual_base_color_weight: Color = Color.WHITE
@export var visual_accent_color_weight: Color = Color.WHITE
@export var visual_glow_weight: int = 0
@export var visual_edge_complexity_weight: int = 0
@export var visual_gloss_weight: int = 0
@export var visual_distortion_weight: int = 0

@export var script_hook_id: String = ""

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func get_stack_display_name() -> String:
	if display_name.strip_edges() != "":
		return display_name

	if family_display_name.strip_edges() != "":
		return "%s %s" % [get_rarity_name(), family_display_name]

	return "%s %s" % [get_rarity_name(), id]

func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		Rarity.COSMIC:
			return "Cosmic"
		_:
			return "Unknown"


static func rarity_name_from_value(value: int) -> String:
	match value:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		Rarity.COSMIC:
			return "Cosmic"
		_:
			return "Unknown"
