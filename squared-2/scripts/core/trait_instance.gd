extends RefCounted
class_name TraitInstance

var instance_id: String = ""
var definition: TraitDefinition

var rolled_values: Dictionary = {}

var source: String = "prestige"
var acquired_at_prestige: int = 0
var acquired_at_grid_tier: int = 0
var stack_index: int = 1

var is_absorbed_copy: bool = false
var copied_from_square_id: String = ""
var copied_from_trait_instance_id: String = ""

var effectiveness_multiplier: float = 1.0

func _init(
	p_definition: TraitDefinition = null,
	p_acquired_at_prestige: int = 0,
	p_acquired_at_grid_tier: int = 0
) -> void:
	definition = p_definition
	acquired_at_prestige = p_acquired_at_prestige
	acquired_at_grid_tier = p_acquired_at_grid_tier
	instance_id = _generate_instance_id()

func _generate_instance_id() -> String:
	return "%s_%s" % [Time.get_unix_time_from_system(), randi()]

func get_display_name() -> String:
	if definition == null:
		return "Unknown Trait"
	return definition.display_name

func has_tag(tag: String) -> bool:
	if definition == null:
		return false
	return definition.has_tag(tag)

func get_effective_components() -> Array[EffectComponent]:
	if definition == null:
		return []
	return definition.effect_components
