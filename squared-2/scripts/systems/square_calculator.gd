extends Node
class_name SquareCalculator

static func calculate_manual_payout(square_data: SquareData) -> float:
	if square_data == null:
		return 0.0

	var value := square_data.base_value
	value *= square_data.base_manual_multiplier
	value *= square_data.temporary_value_multiplier

	for trait_iter in square_data.traits:
		value = _apply_trait_to_stat(
			value,
			trait_iter,
			"square_value"
		)

	return max(0.0, value)

static func calculate_respawn_time(square_data: SquareData) -> float:
	if square_data == null:
		return 1.0

	var respawn_time := square_data.base_respawn_time
	respawn_time *= square_data.temporary_speed_multiplier

	for trait_iter in square_data.traits:
		respawn_time = _apply_trait_to_stat(
			respawn_time,
			trait_iter,
			"respawn_time"
		)

	return max(0.05, respawn_time)

static func _apply_trait_to_stat(
	current_value: float,
	trait_iter: TraitInstance,
	target_stat: String
) -> float:
	if trait_iter == null or trait_iter.definition == null:
		return current_value

	var result := current_value

	for effect in trait_iter.get_effective_components():
		if effect.effect_type != EffectComponent.EffectType.STAT_MODIFIER:
			continue

		if effect.target_stat != target_stat:
			continue

		var effect_value := effect.value

		if trait_iter.effectiveness_multiplier != 1.0:
			if effect.operation == EffectComponent.Operation.MULTIPLY:
				effect_value = lerp(1.0, effect.value, trait_iter.effectiveness_multiplier)
			else:
				effect_value = effect.value * trait_iter.effectiveness_multiplier

		match effect.operation:
			EffectComponent.Operation.ADD:
				result += effect_value
			EffectComponent.Operation.SUBTRACT:
				result -= effect_value
			EffectComponent.Operation.MULTIPLY:
				result *= effect_value
			EffectComponent.Operation.DIVIDE:
				if effect_value != 0.0:
					result /= effect_value
			EffectComponent.Operation.OVERRIDE:
				result = effect_value

	return result
