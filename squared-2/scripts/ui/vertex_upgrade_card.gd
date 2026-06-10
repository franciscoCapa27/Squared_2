extends PanelContainer
class_name VertexUpgradeCard

signal buy_requested(upgrade_id: String)

@onready var title_label: Label = %TitleLabel
@onready var category_cost_label: Label = %CategoryCostLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var requirement_label: RichTextLabel = %RequirementLabel
@onready var buy_button: Button = %BuyButton

var upgrade_definition: VertexUpgradeDefinition

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	buy_button.pressed.connect(_on_buy_button_pressed)

	_apply_theme()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())

	ThemeTextHelper.apply_primary_label(title_label)
	ThemeTextHelper.apply_muted_label(category_cost_label)
	ThemeTextHelper.apply_secondary_rich_text(description_label)
	ThemeTextHelper.apply_secondary_rich_text(requirement_label)

	ThemeButtonHelper.apply_button_theme(buy_button)


func _on_theme_changed() -> void:
	_apply_theme()

func setup(upgrade: VertexUpgradeDefinition) -> void:
	upgrade_definition = upgrade
	refresh()


func refresh() -> void:
	if upgrade_definition == null:
		return

	var purchase_count: int = GameState.get_vertex_upgrade_purchase_count(upgrade_definition.id)
	var is_purchased: bool = purchase_count > 0 and not upgrade_definition.is_repeatable
	var can_buy: bool = GameState.can_buy_vertex_upgrade(upgrade_definition.id)

	title_label.text = upgrade_definition.display_name
	category_cost_label.text = "%s • Cost: %s Vertices" % [
		upgrade_definition.get_category_name(),
		NumberFormatter.integer_amount(upgrade_definition.cost_vertices)
	]
	description_label.text = upgrade_definition.description
	requirement_label.text = _get_detail_text()

	if is_purchased:
		buy_button.text = "Unlocked"
		buy_button.disabled = true
	elif can_buy:
		buy_button.text = "Buy"
		buy_button.disabled = false
	else:
		buy_button.text = "Locked / Cannot Afford"
		buy_button.disabled = true


func _get_detail_text() -> String:
	var sections: Array[String] = []

	sections.append("[b]Requirements[/b]\n%s" % _get_requirement_text())
	sections.append("[b]Effects[/b]\n%s" % _get_effects_text())

	return "\n\n".join(sections)


func _get_requirement_text() -> String:
	if upgrade_definition == null:
		return ""

	var lines: Array[String] = []

	if upgrade_definition.required_prestige_count > 0:
		lines.append(
			"Requires Prestiges: %s" % NumberFormatter.integer_amount(
				upgrade_definition.required_prestige_count
			)
		)

	if upgrade_definition.required_grid_size > 1:
		lines.append("Requires Grid Size: %sx%s" % [
			upgrade_definition.required_grid_size,
			upgrade_definition.required_grid_size
		])

	for required_id: String in upgrade_definition.required_upgrade_ids:
		if GameState.has_vertex_upgrade(required_id):
			lines.append("Requires %s: met" % _format_upgrade_name(required_id))
		else:
			lines.append("Requires %s: missing" % _format_upgrade_name(required_id))

	if lines.is_empty():
		return "No requirements."

	return "\n".join(lines)


func _get_effects_text() -> String:
	if upgrade_definition == null:
		return ""

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


func _format_effect(effect_iter: VertexUpgradeEffect) -> String:
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


func _format_stat_name(stat_id: String) -> String:
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


func _format_upgrade_name(upgrade_id: String) -> String:
	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return upgrade_id

	return upgrade.display_name


func _format_passive_generator_name(generator_id: String) -> String:
	var generator_definition: PassiveGeneratorDefinition = PassiveGeneratorDatabase.get_generator(generator_id)

	if generator_definition == null:
		return generator_id

	return generator_definition.display_name


func _on_buy_button_pressed() -> void:
	if upgrade_definition == null:
		return

	buy_requested.emit(upgrade_definition.id)
