extends Control
class_name VertexShopPage

signal vertex_upgrade_purchased(upgrade_id: String)

@onready var vertex_shop_description: RichTextLabel = %VertexShopDescription
@onready var vertex_upgrade_list: VBoxContainer = %VertexUpgradeList
@onready var vertex_shop_title: Label = %VertexShopTitle

var vertex_upgrade_card_scene: PackedScene = preload("res://scenes/ui/VertexUpgradeCard.tscn")
var vertex_upgrade_cards: Dictionary = {}


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	refresh()
	call_deferred("refresh")


func refresh() -> void:
	_rebuild_vertex_upgrade_list()
	for card: VertexUpgradeCard in vertex_upgrade_cards.values():
		card.refresh()


func _apply_theme() -> void:
	if vertex_shop_title == null:
		return
	ThemeTextHelper.apply_page_title(vertex_shop_title)
	ThemeTextHelper.apply_body_rich_text(vertex_shop_description)


func _on_theme_changed() -> void:
	_apply_theme()


func _rebuild_vertex_upgrade_list() -> void:
	for child: Node in vertex_upgrade_list.get_children():
		child.free()

	vertex_upgrade_cards.clear()

	var visible_upgrades: Array[VertexUpgradeDefinition] = VertexUpgradeDatabase.get_visible_upgrades()
	if visible_upgrades.is_empty() and VertexUpgradeDatabase.all_upgrades.is_empty():
		VertexUpgradeDatabase.load_upgrades()
		visible_upgrades = VertexUpgradeDatabase.get_visible_upgrades()

	if visible_upgrades.is_empty():
		vertex_shop_description.text = "No Vertex upgrades available yet."
		return

	vertex_shop_description.text = "Spend Vertices on permanent systems."

	for upgrade: VertexUpgradeDefinition in visible_upgrades:
		var card: VertexUpgradeCard = vertex_upgrade_card_scene.instantiate() as VertexUpgradeCard
		vertex_upgrade_list.add_child(card)

		card.setup(upgrade)
		card.buy_requested.connect(_on_vertex_upgrade_buy_requested)

		vertex_upgrade_cards[upgrade.id] = card


func _on_vertex_upgrade_buy_requested(upgrade_id: String) -> void:
	var bought: bool = VertexUpgradeSystem.buy_vertex_upgrade(upgrade_id)

	if not bought:
		refresh()
		return

	refresh()
	vertex_upgrade_purchased.emit(upgrade_id)
