extends Resource
class_name RunUpgradeEffect

enum EffectType {
	GLOBAL_RUN_STAT_MULTIPLIER,
	GLOBAL_RUN_STAT_ADDITION
}

@export var effect_type: EffectType = EffectType.GLOBAL_RUN_STAT_MULTIPLIER
@export var target_stat: String = ""
@export var value: float = 1.0


func get_debug_text() -> String:
	match effect_type:
		EffectType.GLOBAL_RUN_STAT_MULTIPLIER:
			return "Multiply %s by %.4f" % [target_stat, value]
		EffectType.GLOBAL_RUN_STAT_ADDITION:
			return "Add %.2f to %s" % [value, target_stat]
		_:
			return "Unknown run upgrade effect"
