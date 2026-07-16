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
var node_is_purchased: bool = false
var node_can_buy: bool = false


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	buy_button.pressed.connect(_on_buy_button_pressed)
	gui_input.connect(_on_gui_input)
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
	node_is_purchased = is_purchased
	node_can_buy = can_buy

	icon_label.text = "✓" if is_purchased else icon_glyph
	title_label.text = upgrade_definition.display_name
	category_cost_label.text = "%s • %s Vertices" % [
		upgrade_definition.get_category_name(),
		NumberFormatter.integer_amount(upgrade_definition.cost_vertices),
	]
	detail_help.help_title = upgrade_definition.display_name
	detail_help.help_detail = "%s\n\n%s" % [
		_get_buy_state_detail(is_purchased, can_buy),
		VertexUpgradeDetails.get_detail_text(upgrade_definition),
	]
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

	_apply_state_theme()


func play_reveal(delay_seconds: float) -> void:
	modulate.a = 0.0
	scale = Vector2(0.96, 0.96)
	var reveal_tween: Tween = create_tween()
	reveal_tween.tween_interval(delay_seconds)
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	reveal_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func show_immediately() -> void:
	modulate.a = 1.0
	scale = Vector2.ONE


func _get_buy_state_detail(is_purchased: bool, can_buy: bool) -> String:
	if is_purchased:
		return "Buy state: Owned. This upgrade's effects are active."

	if can_buy:
		return "Buy state: Ready. Buy is available."

	var state_lines: Array[String] = []
	var requirements_met: bool = upgrade_definition.requirements_are_met(
		GameState.trait_purchase_count,
		GameState.grid_size,
		VertexUpgradeSystem.unlocked_vertex_upgrades
	)
	if not requirements_met:
		state_lines.append("Buy state: Locked. Requirements are not met.")

	if GameState.vertices < upgrade_definition.cost_vertices:
		var shortfall: int = upgrade_definition.cost_vertices - GameState.vertices
		state_lines.append("Need %s more Vertices (have %s / %s)." % [
			NumberFormatter.integer_amount(shortfall),
			NumberFormatter.integer_amount(GameState.vertices),
			NumberFormatter.integer_amount(upgrade_definition.cost_vertices),
		])

	if state_lines.is_empty():
		state_lines.append("Buy state: Locked. Another requirement is not met.")

	return "\n".join(state_lines)


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
	ThemeTextHelper.apply_card_title(title_label)
	ThemeTextHelper.apply_detail_label(category_cost_label)
	ThemeTextHelper.apply_detail_label(state_label)
	ThemeTextHelper.apply_primary_label(icon_label)
	icon_label.add_theme_font_size_override("font_size", ThemeSystem.get_font_size("panel_title"))
	ThemeButtonHelper.apply_button_theme(buy_button)
	_apply_state_theme()


func _apply_state_theme() -> void:
	if node_is_purchased:
		add_theme_stylebox_override("panel", ThemeSystem.make_selected_card_style())
		title_label.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
		icon_label.add_theme_color_override("font_color", ThemeSystem.get_color("accent_primary"))
		state_label.add_theme_color_override("font_color", ThemeSystem.get_color("success"))
	elif node_can_buy:
		add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
		title_label.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
		icon_label.add_theme_color_override("font_color", ThemeSystem.get_color("accent_secondary"))
		state_label.add_theme_color_override("font_color", ThemeSystem.get_color("accent_secondary"))
	else:
		add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
		title_label.add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))
		icon_label.add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))
		state_label.add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))


func _on_theme_changed() -> void:
	_apply_theme()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		detail_help.open_help()
		accept_event()


func _on_buy_button_pressed() -> void:
	if upgrade_definition == null:
		return

	buy_requested.emit(upgrade_definition.id)
