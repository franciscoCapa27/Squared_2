extends Resource
class_name AchievementDefinition

enum AchievementCategory {
	GENERAL,
	CLICKS,
	TRAIT_PURCHASE,
	VERTEX,
	PASSIVE,
	TRAITS,
	ECONOMY,
	SECRET
}

enum ConditionType {
	TOTAL_MANUAL_CLICKS,
	TOTAL_PASSIVE_CLICKS,
	TOTAL_SQUARES_GENERATED,
	CURRENT_SQUARES,
	TRAIT_PURCHASE_COUNT,
	VERTICES_EARNED,
	VERTEX_UPGRADE_PURCHASED,
	PASSIVE_GENERATOR_UNLOCKED,
	PASSIVE_GENERATOR_LEVEL,
	TRAITS_ACQUIRED,
	PERMANENT_STAT_MULTIPLIER,
	SCRIPT_HOOK,
	SQUARE_CLICK_STREAK
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var category: AchievementCategory = AchievementCategory.GENERAL
@export var condition_type: ConditionType = ConditionType.TOTAL_MANUAL_CLICKS

@export var threshold: float = 1.0
@export var target_id: String = ""
@export var target_stat: String = ""

# Optional multi-level progression. Empty levels preserve the legacy single-level fields above.
@export var levels: Array[AchievementLevel] = []

@export var is_visible_by_default: bool = true
@export var hidden_until_unlocked: bool = false
@export var sort_order: int = 0

@export var rewards: Array[AchievementReward] = []

func is_valid_definition() -> bool:
	return id.strip_edges() != ""


func get_level_count() -> int:
	return maxi(1, levels.size())


func get_threshold_for_level(level_index: int) -> float:
	if levels.is_empty():
		return threshold

	if level_index < 0 or level_index >= levels.size():
		return threshold

	var level: AchievementLevel = levels[level_index]
	return threshold if level == null else level.threshold


func get_rewards_for_level(level_index: int) -> Array[AchievementReward]:
	if levels.is_empty():
		return rewards

	if level_index < 0 or level_index >= levels.size():
		return []

	var level: AchievementLevel = levels[level_index]
	return [] if level == null else level.rewards

func get_category_name() -> String:
	match category:
		AchievementCategory.GENERAL:
			return "General"
		AchievementCategory.CLICKS:
			return "Clicks"
		AchievementCategory.TRAIT_PURCHASE:
			return "Trait Purchases"
		AchievementCategory.VERTEX:
			return "Vertex"
		AchievementCategory.PASSIVE:
			return "Passive"
		AchievementCategory.TRAITS:
			return "Traits"
		AchievementCategory.ECONOMY:
			return "Economy"
		AchievementCategory.SECRET:
			return "Secret"
		_:
			return "Unknown"
