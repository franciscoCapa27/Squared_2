extends Resource
class_name PassiveGeneratorDefinition

enum TargetingMode {
	RANDOM_SQUARE,
	HIGHEST_PAYOUT,
	LOWEST_RESPAWN,
	SELECTED_SQUARE,
	MOST_TRAITS,
	RAREST_TRAIT,
	WHOLE_GRID
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var sort_order: int = 0

@export var max_level: int = 100

@export var base_interval_seconds: float = 2.5
@export var minimum_interval_seconds: float = 0.4
@export var interval_level_multiplier: float = 0.985

@export var base_extraction_rate: float = 0.25
@export var extraction_per_level: float = 0.01
@export var maximum_extraction_rate: float = 2.0

@export var extraction_per_target_trait: float = 0.0
@export var extraction_per_grid_size: float = 0.0

@export var base_level_cost: float = 10.0
@export var level_cost_multiplier: float = 1.18
@export var prestige_cost_multiplier: float = 25.0

@export var targeting_mode: TargetingMode = TargetingMode.RANDOM_SQUARE

# Future self-condensation support.
@export var self_condensation_is_permanent: bool = false
@export var self_condensation_unlock_level: int = 100

func is_valid_definition() -> bool:
	return id.strip_edges() != ""
