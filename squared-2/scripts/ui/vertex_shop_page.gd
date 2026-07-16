extends Control
class_name VertexShopPage

signal vertex_upgrade_purchased(upgrade_id: String)

@onready var vertex_shop_description: RichTextLabel = %VertexShopDescription
@onready var vertex_upgrade_list: VBoxContainer = %VertexUpgradeList

var vertex_upgrade_card_scene: PackedScene = preload("res://scenes/ui/VertexUpgradeCard.tscn")
var vertex_upgrade_cards: Dictionary = {}


func _ready() -> void:
	refresh()


func refresh() -> void:
	_rebuild_vertex_upgrade_list()


func _rebuild_vertex_upgrade_list() -> void:
	for child: Node in vertex_upgrade_list.get_children():
		child.queue_free()

	vertex_upgrade_cards.clear()

	var visible_upgrades: Array[VertexUpgradeDefinition] = VertexUpgradeDatabase.get_visible_upgrades()

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
