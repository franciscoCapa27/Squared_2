extends Resource
class_name EffectComponent

enum EffectType {
	STAT_MODIFIER,
	POSITIONAL_MODIFIER,
	TRIGGER_EFFECT,
	RESOURCE_CONVERSION,
	TRAIT_COPY,
	TRAIT_ABSORB,
	STATUS_APPLIER,
	VISUAL_INFLUENCE
}

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	OVERRIDE
}

enum Scope {
	SELF,
	ADJACENT_ORTHOGONAL,
	ADJACENT_DIAGONAL,
	ALL_ADJACENT,
	SAME_ROW,
	SAME_COLUMN,
	SAME_DIAGONAL,
	ENTIRE_GRID,
	CORNERS,
	EDGES,
	CENTER,
	RANDOM_SQUARE,
	RANDOM_TRAITED_SQUARE,
	RANDOM_UNTRAITED_SQUARE,
	STRONGEST_SQUARE,
	WEAKEST_SQUARE
}

@export var effect_type: EffectType = EffectType.STAT_MODIFIER
@export var operation: Operation = Operation.MULTIPLY
@export var scope: Scope = Scope.SELF

@export var target_stat: String = ""
@export var value: float = 1.0

@export var chance: float = 1.0
@export var cooldown_seconds: float = 0.0

@export var trigger_event: String = ""
@export var condition_tags: Array[String] = []

@export var source_scope: Scope = Scope.SELF
@export var trait_filter_tags: Array[String] = []
@export var effect_limit: int = 1
@export_range(0.0, 1.0) var effectiveness_multiplier: float = 1.0

@export var include_tags: bool = true
@export var include_visual_influence: bool = false

func applies_to_tag(tag: String) -> bool:
	return condition_tags.is_empty() or condition_tags.has(tag)
