extends PanelContainer
class_name RunUpgradeCard

signal buy_requested(upgrade_id: String)

@onready var title_label: Label = %TitleLabel
@onready var icon_label: PolygonIcon = %IconLabel
@onready var category_level_label: Label = %CategoryLevelLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var buy_button: Button = %BuyButton
@onready var detail_help: ContextualHelp = %DetailHelp

var upgrade_definition: RunUpgradeDefinition


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	buy_button.pressed.connect(_on_buy_button_pressed)

	_apply_theme()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())

	ThemeTextHelper.apply_card_title(title_label)
	icon_label.set_icon_color(ThemeSystem.get_color("text_primary"))
	ThemeTextHelper.apply_detail_label(category_level_label)
	ThemeTextHelper.apply_body_rich_text(description_label)
	ThemeButtonHelper.apply_button_theme(buy_button)



func _on_theme_changed() -> void:
	_apply_theme()

func setup(upgrade: RunUpgradeDefinition) -> void:
	upgrade_definition = upgrade
	refresh()


func refresh() -> void:
	if upgrade_definition == null:
		detail_help.visible = false
		return

	var current_level: int = RunUpgradeSystem.get_run_upgrade_level(upgrade_definition.id)
	var is_unlocked: bool = RunUpgradeSystem.is_run_upgrade_unlocked(upgrade_definition.id)
	var can_buy: bool = RunUpgradeSystem.can_buy_run_upgrade(upgrade_definition.id)
	var is_maxed: bool = current_level >= upgrade_definition.max_level
	var cost: float = upgrade_definition.get_cost_for_next_level(current_level)

	title_label.text = upgrade_definition.display_name
	icon_label.set_icon_kind(_get_icon_kind())
	icon_label.set_icon_color(ThemeSystem.get_color("text_primary"))
	detail_help.visible = true
	detail_help.help_title = upgrade_definition.display_name
	detail_help.help_detail = _get_detail_text(current_level)
	detail_help.tooltip_text = "%s\n%s" % [
		detail_help.help_title,
		detail_help.help_detail
	]
	category_level_label.text = "%s/%s" % [
		NumberFormatter.integer_amount(current_level),
		NumberFormatter.integer_amount(upgrade_definition.max_level),
	]
	description_label.text = "[b]%s[/b]\n%s" % [
		upgrade_definition.get_category_name(),
		upgrade_definition.description,
	]
	progress_bar.value = float(current_level) / float(maxi(1, upgrade_definition.max_level))
	progress_bar.visible = true
	# Keep the category in the tooltip-friendly detail content while the card stays compact.
	category_level_label.tooltip_text = "%s - Level %s / %s" % [
		upgrade_definition.get_category_name(),
		NumberFormatter.integer_amount(current_level),
		NumberFormatter.integer_amount(upgrade_definition.max_level)
	]

	if not is_unlocked:
		buy_button.text = "Locked"
		buy_button.disabled = true
	elif is_maxed:
		buy_button.text = "Maxed"
		buy_button.disabled = true
	elif can_buy:
		buy_button.text = "Buy - %s Squares" % NumberFormatter.cost(cost)
		buy_button.disabled = false
	else:
		buy_button.text = "Need %s Squares" % NumberFormatter.cost(cost)
		buy_button.disabled = true


func _get_icon_kind() -> String:
	match upgrade_definition.category:
		RunUpgradeDefinition.UpgradeCategory.PASSIVE:
			return "passive"
		RunUpgradeDefinition.UpgradeCategory.RESPAWN:
			return "diamond"
		RunUpgradeDefinition.UpgradeCategory.MANUAL:
			return "spark"
		_:
			return "diamond"


func _get_detail_text(current_level: int) -> String:
	var cost_text: String = "Max level reached."
	if current_level < upgrade_definition.max_level:
		cost_text = "Next level cost: %s Squares." % NumberFormatter.cost(
			upgrade_definition.get_cost_for_next_level(current_level)
		)

	return (
		"Current level: %s / %s\n\n" % [
			NumberFormatter.integer_amount(current_level),
			NumberFormatter.integer_amount(upgrade_definition.max_level)
		]
		+ "Requirements\n%s\n\n" % _get_requirement_text()
		+ "Effects per level\n%s\n\n" % _get_effect_text()
		+ "Cost progression\n%s Each level scales by %s from the previous level.\n\n" % [
			cost_text,
			NumberFormatter.multiplier(upgrade_definition.cost_multiplier)
		]
		+ "Upgrade levels reset when starting a new game."
	)

func _get_requirement_text() -> String:
	if upgrade_definition == null:
		return ""

	if upgrade_definition.unlock_conditions.is_empty():
		return "Always available."

	var lines: Array[String] = []

	for condition: RunUpgradeUnlockCondition in upgrade_definition.unlock_conditions:
		if condition == null:
			continue

		var status: String = "met" if condition.is_met() else "missing"
		lines.append("%s: %s" % [condition.get_display_text(), status])

	if lines.is_empty():
		return "Always available."

	return "\n".join(lines)


func _get_effect_text() -> String:
	if upgrade_definition == null:
		return ""

	if upgrade_definition.effects_per_level.is_empty():
		return "No effects."

	var lines: Array[String] = []

	for effect_iter: RunUpgradeEffect in upgrade_definition.effects_per_level:
		if effect_iter == null:
			continue

		lines.append(_format_effect(effect_iter))

	if lines.is_empty():
		return "No effects."

	return "\n".join(lines)


func _format_effect(effect_iter: RunUpgradeEffect) -> String:
	match effect_iter.effect_type:
		RunUpgradeEffect.EffectType.GLOBAL_RUN_STAT_MULTIPLIER:
			return "%s %s" % [
				_format_stat_name(effect_iter.target_stat),
				NumberFormatter.precise_percent_from_multiplier(effect_iter.value)
			]
		RunUpgradeEffect.EffectType.GLOBAL_RUN_STAT_ADDITION:
			return "%s %s" % [
				_format_stat_name(effect_iter.target_stat),
				NumberFormatter.signed_amount(effect_iter.value)
			]
		_:
			return "Unknown effect"


func _format_stat_name(stat_id: String) -> String:
	match stat_id:
		GameIds.STAT_RUN_SQUARE_BASE_VALUE:
			return "Square base value"
		GameIds.STAT_RUN_MANUAL_CLICK_VALUE:
			return "Manual click value"
		GameIds.STAT_RUN_PASSIVE_CLICK_VALUE:
			return "Passive click value"
		GameIds.STAT_RUN_SQUARE_RESPAWN_TIME:
			return "Square respawn time"
		GameIds.STAT_RUN_PASSIVE_INTERVAL:
			return "Passive interval"
		GameIds.STAT_RUN_PASSIVE_EXTRACTION:
			return "Passive extraction"
		_:
			return stat_id


func _on_buy_button_pressed() -> void:
	if upgrade_definition == null:
		return

	buy_requested.emit(upgrade_definition.id)
