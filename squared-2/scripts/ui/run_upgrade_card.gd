extends PanelContainer
class_name RunUpgradeCard

signal buy_requested(upgrade_id: String)

@onready var title_label: Label = %TitleLabel
@onready var category_level_label: Label = %CategoryLevelLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var buy_button: Button = %BuyButton

var upgrade_definition: RunUpgradeDefinition


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)


func setup(upgrade: RunUpgradeDefinition) -> void:
	upgrade_definition = upgrade
	refresh()


func refresh() -> void:
	if upgrade_definition == null:
		return

	var current_level: int = RunUpgradeSystem.get_run_upgrade_level(upgrade_definition.id)
	var is_unlocked: bool = RunUpgradeSystem.is_run_upgrade_unlocked(upgrade_definition.id)
	var can_buy: bool = RunUpgradeSystem.can_buy_run_upgrade(upgrade_definition.id)
	var is_maxed: bool = current_level >= upgrade_definition.max_level
	var cost: float = upgrade_definition.get_cost_for_next_level(current_level)

	title_label.text = upgrade_definition.display_name
	category_level_label.text = "%s • Level %s / %s" % [
		upgrade_definition.get_category_name(),
		NumberFormatter.integer_amount(current_level),
		NumberFormatter.integer_amount(upgrade_definition.max_level)
	]

	description_label.text = upgrade_definition.description
	detail_label.text = _get_detail_text()

	if not is_unlocked:
		buy_button.text = "Locked"
		buy_button.disabled = true
	elif is_maxed:
		buy_button.text = "Maxed"
		buy_button.disabled = true
	elif can_buy:
		buy_button.text = "Buy — %s Squares" % NumberFormatter.cost(cost)
		buy_button.disabled = false
	else:
		buy_button.text = "Need %s Squares" % NumberFormatter.cost(cost)
		buy_button.disabled = true


func _get_detail_text() -> String:
	return "[b]Requirements[/b]\n%s\n\n[b]Effects per Level[/b]\n%s" % [
		_get_requirement_text(),
		_get_effect_text()
	]


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
