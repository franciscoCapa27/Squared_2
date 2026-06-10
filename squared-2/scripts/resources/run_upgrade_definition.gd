extends Resource
class_name RunUpgradeDefinition

enum UpgradeCategory {
	GENERAL,
	MANUAL,
	PASSIVE,
	RESPAWN,
	UNLOCKED,
	SPECIAL
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var category: UpgradeCategory = UpgradeCategory.GENERAL
@export var sort_order: int = 0

@export var base_cost: float = 10.0
@export var cost_multiplier: float = 1.25
@export var max_level: int = 10

@export var is_visible_by_default: bool = true
@export var hidden_until_unlocked: bool = false

@export var unlock_conditions: Array[RunUpgradeUnlockCondition] = []
@export var effects_per_level: Array[RunUpgradeEffect] = []


func is_valid_definition() -> bool:
	return id.strip_edges() != ""


func get_category_name() -> String:
	match category:
		UpgradeCategory.GENERAL:
			return "General"
		UpgradeCategory.MANUAL:
			return "Manual"
		UpgradeCategory.PASSIVE:
			return "Passive"
		UpgradeCategory.RESPAWN:
			return "Respawn"
		UpgradeCategory.UNLOCKED:
			return "Unlocked"
		UpgradeCategory.SPECIAL:
			return "Special"
		_:
			return "Unknown"


func get_cost_for_next_level(current_level: int) -> float:
	return base_cost * pow(cost_multiplier, float(current_level))


func is_unlocked_by_conditions() -> bool:
	for condition: RunUpgradeUnlockCondition in unlock_conditions:
		if condition == null:
			continue

		if not condition.is_met():
			return false

	return true
