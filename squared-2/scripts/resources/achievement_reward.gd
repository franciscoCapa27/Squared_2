extends Resource
class_name AchievementReward

enum RewardType {
	GLOBAL_STAT_MULTIPLIER,
	ADD_PERMANENT_STAT,
	UNLOCK_MECHANIC,
	ADD_STARTING_SQUARES,
	SCRIPT_HOOK
}

@export var reward_type: RewardType = RewardType.GLOBAL_STAT_MULTIPLIER

@export var target_stat: String = ""
@export var target_id: String = ""
@export var value: float = 1.0
@export var mechanic_id: String = ""
@export var script_hook_id: String = ""

func get_debug_text() -> String:
	match reward_type:
		RewardType.GLOBAL_STAT_MULTIPLIER:
			return "Multiply %s by %.4f" % [target_stat, value]
		RewardType.UNLOCK_MECHANIC:
			return "Unlock mechanic: %s" % mechanic_id
		RewardType.ADD_STARTING_SQUARES:
			return "Add starting Squares: %.2f" % value
		RewardType.SCRIPT_HOOK:
			return "Run script hook: %s" % script_hook_id
		_:
			return "Unknown reward"
