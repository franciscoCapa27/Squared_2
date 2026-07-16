extends Control
class_name VertexShopPage

signal vertex_upgrade_purchased(upgrade_id: String)

const ROOT_UPGRADE_ID := GameIds.UPGRADE_SHARPENED_ORIGIN
const TREE_CHILDREN := {
	GameIds.UPGRADE_SHARPENED_ORIGIN: [
		GameIds.UPGRADE_GEOMETRIC_INTUITION,
		GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR,
	],
	GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR: [
		GameIds.UPGRADE_UNLOCK_VALUE_HARVESTER,
	],
}
const TREE_PREREQUISITES := {
	GameIds.UPGRADE_GEOMETRIC_INTUITION: [GameIds.UPGRADE_SHARPENED_ORIGIN],
	GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR: [GameIds.UPGRADE_SHARPENED_ORIGIN],
	GameIds.UPGRADE_UNLOCK_VALUE_HARVESTER: [
		GameIds.UPGRADE_SHARPENED_ORIGIN,
		GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR,
	],
}
const TREE_POSITIONS := {
	GameIds.UPGRADE_SHARPENED_ORIGIN: Vector2(300, 32),
	GameIds.UPGRADE_GEOMETRIC_INTUITION: Vector2(32, 248),
	GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR: Vector2(368, 248),
	GameIds.UPGRADE_UNLOCK_VALUE_HARVESTER: Vector2(368, 464),
}
const NODE_ICONS := {
	GameIds.UPGRADE_SHARPENED_ORIGIN: "◇",
	GameIds.UPGRADE_GEOMETRIC_INTUITION: "✧",
	GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR: "◌",
	GameIds.UPGRADE_UNLOCK_VALUE_HARVESTER: "◎",
}
const NODE_SIZE := Vector2(220, 150)
const CANVAS_SIZE := Vector2(620, 660)

@onready var vertex_shop_description: RichTextLabel = %VertexShopDescription
@onready var vertex_upgrade_canvas: Control = %VertexUpgradeCanvas
@onready var vertex_shop_title: Label = %VertexShopTitle

var vertex_upgrade_node_scene: PackedScene = preload("res://scenes/ui/VertexUpgradeNode.tscn")
var vertex_upgrade_nodes: Dictionary = {}
var refresh_queued: bool = false


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	EventBus.vertices_changed.connect(_on_state_changed)
	EventBus.grid_changed.connect(_on_state_changed)
	EventBus.trait_purchase_changed.connect(_on_state_changed)
	VertexUpgradeSystem.vertex_upgrades_changed.connect(_on_state_changed)
	_apply_theme()
	refresh()
	call_deferred("refresh")


func refresh() -> void:
	if refresh_queued:
		return

	refresh_queued = true
	call_deferred("_rebuild_vertex_upgrade_tree")


func _apply_theme() -> void:
	if vertex_shop_title == null:
		return

	ThemeTextHelper.apply_page_title(vertex_shop_title)
	ThemeTextHelper.apply_body_rich_text(vertex_shop_description)


func _on_theme_changed() -> void:
	_apply_theme()


func _on_state_changed(_value: Variant = null) -> void:
	refresh()


func _rebuild_vertex_upgrade_tree() -> void:
	refresh_queued = false

	for child: Node in vertex_upgrade_canvas.get_children():
		child.queue_free()

	vertex_upgrade_nodes.clear()
	vertex_upgrade_canvas.custom_minimum_size = CANVAS_SIZE

	if VertexUpgradeDatabase.all_upgrades.is_empty():
		VertexUpgradeDatabase.load_upgrades()

	var root_upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(ROOT_UPGRADE_ID)
	if root_upgrade == null:
		vertex_shop_description.text = "No Vertex progression is available yet."
		return

	vertex_shop_description.text = "Spend Vertices along a permanent progression path. Select an i for details."

	for upgrade_id_variant: Variant in TREE_POSITIONS.keys():
		var upgrade_id: String = str(upgrade_id_variant)
		if not _is_node_revealed(upgrade_id):
			continue

		var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)
		if upgrade == null:
			continue

		var upgrade_node: VertexUpgradeNode = vertex_upgrade_node_scene.instantiate() as VertexUpgradeNode
		vertex_upgrade_canvas.add_child(upgrade_node)
		upgrade_node.position = TREE_POSITIONS[upgrade_id]
		upgrade_node.setup(upgrade, str(NODE_ICONS.get(upgrade_id, "◇")))
		upgrade_node.buy_requested.connect(_on_vertex_upgrade_buy_requested)
		vertex_upgrade_nodes[upgrade_id] = upgrade_node

	_add_visible_connections()


func _is_node_revealed(upgrade_id: String) -> bool:
	if upgrade_id == ROOT_UPGRADE_ID:
		return true

	var prerequisites: Array = TREE_PREREQUISITES.get(upgrade_id, [])
	if prerequisites.is_empty():
		return false

	for prerequisite_variant: Variant in prerequisites:
		if not VertexUpgradeSystem.has_vertex_upgrade(str(prerequisite_variant)):
			return false

	return true


func _add_visible_connections() -> void:
	for parent_id_variant: Variant in TREE_CHILDREN.keys():
		var parent_id: String = str(parent_id_variant)
		var child_ids: Array = TREE_CHILDREN[parent_id]
		if not vertex_upgrade_nodes.has(parent_id):
			continue

		for child_id_variant: Variant in child_ids:
			var child_id: String = str(child_id_variant)
			if not vertex_upgrade_nodes.has(child_id):
				continue

			var connection: Line2D = Line2D.new()
			connection.width = 2.0
			connection.default_color = ThemeSystem.get_color("border_soft")
			connection.antialiased = true
			connection.z_index = -1
			connection.points = PackedVector2Array([
				TREE_POSITIONS[parent_id] + Vector2(NODE_SIZE.x * 0.5, NODE_SIZE.y),
				TREE_POSITIONS[child_id] + Vector2(NODE_SIZE.x * 0.5, 0),
			])
			vertex_upgrade_canvas.add_child(connection)


func _on_vertex_upgrade_buy_requested(upgrade_id: String) -> void:
	var bought: bool = VertexUpgradeSystem.buy_vertex_upgrade(upgrade_id)

	if not bought:
		refresh()
		return

	refresh()
	vertex_upgrade_purchased.emit(upgrade_id)
