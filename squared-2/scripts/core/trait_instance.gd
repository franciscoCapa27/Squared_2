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
	roll_effect_values()

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

func roll_effect_values() -> void:
	rolled_values.clear()

	if definition == null:
		return

	for effect_iter: EffectComponent in definition.effect_components:
		if effect_iter == null:
			continue

		if not effect_iter.use_value_range:
			continue

		var key: String = effect_iter.roll_key.strip_edges()

		if key == "":
			key = "%s_%s" % [effect_iter.target_stat, int(effect_iter.operation)]

		var rolled_value: float = randf_range(effect_iter.value_min, effect_iter.value_max)
		rolled_value = _round_to_decimals(rolled_value, effect_iter.roll_decimals)

		rolled_values[key] = rolled_value


func get_effect_value(effect_iter: EffectComponent) -> float:
	if effect_iter == null:
		return 1.0

	if not effect_iter.use_value_range:
		return effect_iter.value

	var key: String = effect_iter.roll_key.strip_edges()

	if key == "":
		key = "%s_%s" % [effect_iter.target_stat, int(effect_iter.operation)]

	if rolled_values.has(key):
		return float(rolled_values[key])

	return effect_iter.value


func _round_to_decimals(value: float, decimals: int) -> float:
	var safe_decimals: int = clamp(decimals, 0, 6)
	var multiplier: float = pow(10.0, safe_decimals)
	return round(value * multiplier) / multiplier

func get_effect_summary_lines() -> Array[String]:
	var lines: Array[String] = []

	if definition == null:
		return lines

	for effect_iter: EffectComponent in definition.effect_components:
		if effect_iter == null:
			continue

		if effect_iter.effect_type != EffectComponent.EffectType.STAT_MODIFIER:
			continue

		var effect_value: float = get_effect_value(effect_iter)
		var line := ""

		if effect_iter.operation == EffectComponent.Operation.MULTIPLY:
			var percent_change: float = (effect_value - 1.0) * 100.0

			if percent_change >= 0.0:
				line = "+%.1f%% %s" % [percent_change, _format_target_stat(effect_iter.target_stat)]
			else:
				line = "%.1f%% %s" % [percent_change, _format_target_stat(effect_iter.target_stat)]
		else:
			line = "%s %s %s" % [
				_format_operation(effect_iter.operation),
				effect_value,
				_format_target_stat(effect_iter.target_stat)
			]

		lines.append(line)

	return lines


func _format_target_stat(target_stat: String) -> String:
	match target_stat:
		"square_value":
			return "Squares"
		"respawn_time":
			return "Respawn Time"
		_:
			return target_stat


func _format_operation(operation: EffectComponent.Operation) -> String:
	match operation:
		EffectComponent.Operation.ADD:
			return "+"
		EffectComponent.Operation.SUBTRACT:
			return "-"
		EffectComponent.Operation.MULTIPLY:
			return "x"
		EffectComponent.Operation.DIVIDE:
			return "/"
		EffectComponent.Operation.OVERRIDE:
			return "="
		_:
			return "?"

func to_save_dict() -> Dictionary:
	var definition_id: String = ""

	if definition != null:
		definition_id = definition.id

	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"rolled_values": rolled_values,
		"source": source,
		"acquired_at_prestige": acquired_at_prestige,
		"acquired_at_grid_tier": acquired_at_grid_tier,
		"stack_index": stack_index,
		"is_absorbed_copy": is_absorbed_copy,
		"copied_from_square_id": copied_from_square_id,
		"copied_from_trait_instance_id": copied_from_trait_instance_id,
		"effectiveness_multiplier": effectiveness_multiplier
	}

static func from_save_dict(data: Dictionary) -> TraitInstance:
	var definition_id: String = str(data.get("definition_id", ""))
	var trait_definition: TraitDefinition = TraitDatabase.get_trait(definition_id)

	var trait_instance := TraitInstance.new(
		trait_definition,
		int(data.get("acquired_at_prestige", 0)),
		int(data.get("acquired_at_grid_tier", 0))
	)

	trait_instance.instance_id = str(data.get("instance_id", trait_instance.instance_id))
	trait_instance.rolled_values = data.get("rolled_values", {})
	trait_instance.source = str(data.get("source", "prestige"))
	trait_instance.stack_index = int(data.get("stack_index", 1))
	trait_instance.is_absorbed_copy = bool(data.get("is_absorbed_copy", false))
	trait_instance.copied_from_square_id = str(data.get("copied_from_square_id", ""))
	trait_instance.copied_from_trait_instance_id = str(data.get("copied_from_trait_instance_id", ""))
	trait_instance.effectiveness_multiplier = float(data.get("effectiveness_multiplier", 1.0))

	return trait_instance
