class_name TraitPurchasePresenter
extends RefCounted


static func build_details_text(
	cost: float,
	vertices_gain: int,
	rarity_weights: Dictionary
) -> String:
	return "Cost: %s Squares - Gain: %s Vertices\nPossible rarities: %s" % [
		NumberFormatter.amount(cost),
		NumberFormatter.integer_amount(vertices_gain),
		_build_possible_rarities_text(rarity_weights),
	]


static func _build_possible_rarities_text(rarity_weights: Dictionary) -> String:
	var rarity_parts: Array[String] = []

	for rarity_variant: Variant in rarity_weights.keys():
		var rarity: int = int(rarity_variant)
		if float(rarity_weights[rarity_variant]) <= 0.0:
			continue

		var rarity_name: String = TraitDefinition.rarity_name_from_value(rarity)
		var rarity_color: String = ThemeTextHelper.get_rarity_color_hex(rarity_name)
		rarity_parts.append("[color=%s]%s[/color]" % [rarity_color, rarity_name])

	if rarity_parts.is_empty():
		rarity_parts.append(
		TraitDefinition.rarity_name_from_value(TraitDefinition.Rarity.COMMON)
	)

	return ", ".join(rarity_parts)
