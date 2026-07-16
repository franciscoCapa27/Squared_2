extends RefCounted
class_name VertexUpgradeDetails


static func get_detail_text(upgrade_definition: VertexUpgradeDefinition) -> String:
	if upgrade_definition == null:
		return ""

	var sections: Array[String] = []
	sections.append(upgrade_definition.description)
	sections.append("Cost: %s Vertices" % NumberFormatter.integer_amount(upgrade_definition.cost_vertices))
	sections.append("Requirements:\n%s" % _get_requirement_text(upgrade_definition))
	sections.append("Effects:\n%s" % _get_effects_text(upgrade_definition))

	return "\n\n".join(sections)


static func _get_requirement_text(upgrade_definition: VertexUpgradeDefinition) -> String:
	var lines: Array[String] = []

	if upgrade_definition.required_trait_purchase_count > 0:
		lines.append(
			"Requires Trait Purchases: %s" % NumberFormatter.integer_amount(
				upgrade_definition.required_trait_purchase_count
			)
		)

	if upgrade_definition.required_grid_size > 1:
		lines.append("Requires Grid Size: %sx%s" % [
			upgrade_definition.required_grid_size,
			upgrade_definition.required_grid_size
		])

	for required_id: String in upgrade_definition.required_upgrade_ids:
		if VertexUpgradeSystem.has_vertex_upgrade(required_id):
			lines.append("Requires %s: met" % _format_upgrade_name(required_id))
		else:
			lines.append("Requires %s: missing" % _format_upgrade_name(required_id))

	if lines.is_empty():
		return "No requirements."

	return "\n".join(lines)


static func _get_effects_text(upgrade_definition: VertexUpgradeDefinition) -> String:
	if upgrade_definition.effects.is_empty():
		return "No effects."

	var lines: Array[String] = []
	for effect_iter: VertexUpgradeEffect in upgrade_definition.effects:
		if effect_iter == null:
			continue

		lines.append(_format_effect(effect_iter))

	if lines.is_empty():
		return "No effects."

	return "\n".join(lines)


static func _format_effect(effect_iter: VertexUpgradeEffect) -> String:
	match effect_iter.effect_type:
		VertexUpgradeEffect.EffectType.UNLOCK_PASSIVE_GENERATOR:
			return "Unlock passive generator: %s" % _format_passive_generator_name(effect_iter.target_id)

		VertexUpgradeEffect.EffectType.GLOBAL_STAT_MULTIPLIER:
			return "%s %s" % [
				_format_stat_name(effect_iter.target_stat),
				NumberFormatter.precise_percent_from_multiplier(effect_iter.value)
			]

		VertexUpgradeEffect.EffectType.ADD_PERMANENT_STAT:
			return "%s %s" % [
				_format_stat_name(effect_iter.target_stat),
				NumberFormatter.signed_amount(effect_iter.value)
			]

		VertexUpgradeEffect.EffectType.UNLOCK_MECHANIC:
			return "Unlock mechanic: %s" % effect_iter.mechanic_id

		VertexUpgradeEffect.EffectType.ADD_STARTING_SQUARES:
			return "+%s starting Squares" % NumberFormatter.amount(effect_iter.value)

		VertexUpgradeEffect.EffectType.UNLOCK_TAB:
			return "Unlock tab: %s" % effect_iter.target_id

		VertexUpgradeEffect.EffectType.SCRIPT_HOOK:
			return "Special effect"

		_:
			return "Unknown effect"


static func _format_stat_name(stat_id: String) -> String:
	match stat_id:
		GameIds.STAT_SQUARE_BASE_VALUE:
			return "Square base value"
		GameIds.STAT_SQUARE_RESPAWN_TIME:
			return "Square respawn time"
		GameIds.STAT_VERTEX_GAIN:
			return "Vertex gain"
		GameIds.STAT_TRAIT_LUCK:
			return "Trait luck"
		_:
			return stat_id


static func _format_upgrade_name(upgrade_id: String) -> String:
	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)
	if upgrade == null:
		return upgrade_id

	return upgrade.display_name


static func _format_passive_generator_name(generator_id: String) -> String:
	var generator_definition: PassiveGeneratorDefinition = PassiveGeneratorDatabase.get_generator(generator_id)
	if generator_definition == null:
		return generator_id

	return generator_definition.display_name
