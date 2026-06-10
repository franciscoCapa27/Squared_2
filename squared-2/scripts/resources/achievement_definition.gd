extends Resource
class_name AchievementDefinition

enum AchievementCategory {
	GENERAL,
	CLICKS,
	PRESTIGE,
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
	PRESTIGE_COUNT,
	VERTICES_EARNED,
	VERTEX_UPGRADE_PURCHASED,
	PASSIVE_GENERATOR_UNLOCKED,
	PASSIVE_GENERATOR_LEVEL,
	TRAITS_ACQUIRED,
	PERMANENT_STAT_MULTIPLIER,
	SCRIPT_HOOK
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var category: AchievementCategory = AchievementCategory.GENERAL
@export var condition_type: ConditionType = ConditionType.TOTAL_MANUAL_CLICKS

@export var threshold: float = 1.0
@export var target_id: String = ""
@export var target_stat: String = ""

@export var is_visible_by_default: bool = true
@export var hidden_until_unlocked: bool = false
@export var sort_order: int = 0

@export var rewards: Array[AchievementReward] = []

func is_valid_definition() -> bool:
	return id.strip_edges() != ""

func get_category_name() -> String:
	match category:
		AchievementCategory.GENERAL:
			return "General"
		AchievementCategory.CLICKS:
			return "Clicks"
		AchievementCategory.PRESTIGE:
			return "Prestige"
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
