extends Resource
class_name VertexUpgradeDefinition

enum UpgradeCategory {
	AUTOMATION,
	GRID,
	TRAITS,
	ECONOMY,
	QUALITY_OF_LIFE,
	META,
	DEBUG
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var category: UpgradeCategory = UpgradeCategory.META
@export var cost_vertices: int = 1

# Display / progression.
@export var is_visible_by_default: bool = true
@export var sort_order: int = 0

# Requirement fields.
@export var required_trait_purchase_count: int = 0
@export var required_grid_size: int = 1
@export var required_upgrade_ids: Array[String] = []
@export var hidden_until_requirements_met: bool = false

# Most Vertex upgrades are one-time permanent unlocks.
@export var is_repeatable: bool = false
@export var max_purchases: int = 1

@export var effects: Array[VertexUpgradeEffect] = []

func requirements_are_met(
	trait_purchase_count: int,
	grid_size: int,
	purchased_upgrade_ids: Dictionary
) -> bool:
	if trait_purchase_count < required_trait_purchase_count:
		return false

	if grid_size < required_grid_size:
		return false

	for required_id: String in required_upgrade_ids:
		if not bool(purchased_upgrade_ids.get(required_id, false)):
			return false

	return true

func get_category_name() -> String:
	match category:
		UpgradeCategory.AUTOMATION:
			return "Automation"
		UpgradeCategory.GRID:
			return "Grid"
		UpgradeCategory.TRAITS:
			return "Traits"
		UpgradeCategory.ECONOMY:
			return "Economy"
		UpgradeCategory.QUALITY_OF_LIFE:
			return "Quality of Life"
		UpgradeCategory.META:
			return "Meta"
		UpgradeCategory.DEBUG:
			return "Debug"
		_:
			return "Unknown"
