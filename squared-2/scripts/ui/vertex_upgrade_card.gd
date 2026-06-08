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
	buy_button.pressed.connect(_on_buy_button_pressed)

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
		upgrade_definition.cost_vertices
	]
	description_label.text = upgrade_definition.description

	requirement_label.text = _get_requirement_text()

	if is_purchased:
		buy_button.text = "Unlocked"
		buy_button.disabled = true
	elif can_buy:
		buy_button.text = "Buy"
		buy_button.disabled = false
	else:
		buy_button.text = "Locked / Cannot Afford"
		buy_button.disabled = true

func _get_requirement_text() -> String:
	if upgrade_definition == null:
		return ""

	var lines: Array[String] = []

	if upgrade_definition.required_prestige_count > 0:
		lines.append("Requires Prestiges: %s" % upgrade_definition.required_prestige_count)

	if upgrade_definition.required_grid_size > 1:
		lines.append("Requires Grid Size: %sx%s" % [
			upgrade_definition.required_grid_size,
			upgrade_definition.required_grid_size
		])

	for required_id: String in upgrade_definition.required_upgrade_ids:
		if GameState.has_vertex_upgrade(required_id):
			lines.append("Requires %s: met" % required_id)
		else:
			lines.append("Requires %s: missing" % required_id)

	if lines.is_empty():
		return "No requirements."

	return "\n".join(lines)

func _on_buy_button_pressed() -> void:
	if upgrade_definition == null:
		return

	buy_requested.emit(upgrade_definition.id)
