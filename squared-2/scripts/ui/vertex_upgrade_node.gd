extends PanelContainer
class_name VertexUpgradeNode

signal buy_requested(upgrade_id: String)

@onready var icon_label: Label = %IconLabel
@onready var title_label: Label = %TitleLabel
@onready var category_cost_label: Label = %CategoryCostLabel
@onready var state_label: Label = %StateLabel
@onready var detail_help: ContextualHelp = %DetailHelp
@onready var buy_button: Button = %BuyButton

var upgrade_definition: VertexUpgradeDefinition
var icon_glyph: String = "◇"


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	buy_button.pressed.connect(_on_buy_button_pressed)
	_apply_theme()


func setup(upgrade: VertexUpgradeDefinition, authored_icon_glyph: String) -> void:
	upgrade_definition = upgrade
	icon_glyph = authored_icon_glyph
	refresh()


func refresh() -> void:
	if upgrade_definition == null:
		return

	var purchase_count: int = VertexUpgradeSystem.get_vertex_upgrade_purchase_count(upgrade_definition.id)
	var is_purchased: bool = purchase_count > 0 and not upgrade_definition.is_repeatable
	var can_buy: bool = VertexUpgradeSystem.can_buy_vertex_upgrade(upgrade_definition.id)

	icon_label.text = "✓" if is_purchased else icon_glyph
	title_label.text = upgrade_definition.display_name
	category_cost_label.text = "%s • %s Vertices" % [
		upgrade_definition.get_category_name(),
		NumberFormatter.integer_amount(upgrade_definition.cost_vertices),
	]
	detail_help.help_title = upgrade_definition.display_name
	detail_help.help_detail = VertexUpgradeDetails.get_detail_text(upgrade_definition)
	detail_help.tooltip_text = "%s\n%s" % [detail_help.help_title, detail_help.help_detail]

	if is_purchased:
		state_label.text = "Unlocked"
		buy_button.text = "Unlocked"
		buy_button.disabled = true
	elif can_buy:
		state_label.text = "Ready"
		buy_button.text = "Buy"
		buy_button.disabled = false
	else:
		state_label.text = "Locked"
		buy_button.text = "Locked"
		buy_button.disabled = true


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
	ThemeTextHelper.apply_card_title(title_label)
	ThemeTextHelper.apply_detail_label(category_cost_label)
	ThemeTextHelper.apply_detail_label(state_label)
	ThemeTextHelper.apply_primary_label(icon_label)
	icon_label.add_theme_font_size_override("font_size", ThemeSystem.get_font_size("panel_title"))
	ThemeButtonHelper.apply_button_theme(buy_button)


func _on_theme_changed() -> void:
	_apply_theme()


func _on_buy_button_pressed() -> void:
	if upgrade_definition == null:
		return

	buy_requested.emit(upgrade_definition.id)
