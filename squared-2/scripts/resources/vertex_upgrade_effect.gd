extends Resource
class_name VertexUpgradeEffect

enum EffectType {
	UNLOCK_PASSIVE_GENERATOR,
	GLOBAL_STAT_MULTIPLIER,
	UNLOCK_MECHANIC,
	ADD_STARTING_SQUARES,
	UNLOCK_TAB,
	SCRIPT_HOOK
}

@export var effect_type: EffectType = EffectType.UNLOCK_MECHANIC

# Generic effect fields.
@export var target_id: String = ""
@export var target_stat: String = ""
@export var value: float = 1.0
@export var mechanic_id: String = ""
@export var script_hook_id: String = ""

func get_effect_debug_text() -> String:
	match effect_type:
		EffectType.UNLOCK_PASSIVE_GENERATOR:
			return "Unlock passive generator: %s" % target_id
		EffectType.GLOBAL_STAT_MULTIPLIER:
			return "Multiply %s by %.2f" % [target_stat, value]
		EffectType.UNLOCK_MECHANIC:
			return "Unlock mechanic: %s" % mechanic_id
		EffectType.ADD_STARTING_SQUARES:
			return "Add starting Squares: %.2f" % value
		EffectType.UNLOCK_TAB:
			return "Unlock tab: %s" % target_id
		EffectType.SCRIPT_HOOK:
			return "Run script hook: %s" % script_hook_id
		_:
			return "Unknown effect"
