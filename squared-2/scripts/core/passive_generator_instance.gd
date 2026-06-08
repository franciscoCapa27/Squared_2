extends RefCounted
class_name PassiveGeneratorInstance

var definition: PassiveGeneratorDefinition

# Permanent unlock state.
var is_unlocked: bool = false

# Run-based level. Resets to 0 on normal prestige.
var level: int = 0

# Future self-prestige state.
var self_prestige_level: int = 0
var can_self_prestige: bool = false

var elapsed_seconds: float = 0.0

var last_target_square_id: String = ""
var last_payout: float = 0.0
var lifetime_squares_generated: float = 0.0
var lifetime_pulses: int = 0

func _init(p_definition: PassiveGeneratorDefinition = null) -> void:
	definition = p_definition

func get_id() -> String:
	if definition == null:
		return ""

	return definition.id

func get_display_name() -> String:
	if definition == null:
		return "Unknown Generator"

	return definition.display_name

func unlock_permanently() -> void:
	is_unlocked = true
	reset_run_state()

func reset_run_state() -> void:
	level = 0
	elapsed_seconds = 0.0
	last_target_square_id = ""
	last_payout = 0.0
	lifetime_squares_generated = 0.0
	lifetime_pulses = 0
	can_self_prestige = false

	if definition != null and not definition.self_prestige_is_permanent:
		self_prestige_level = 0

func is_active() -> bool:
	return is_unlocked and level > 0

func get_max_level() -> int:
	if definition == null:
		return 0

	return definition.max_level

func get_current_interval_seconds() -> float:
	if definition == null:
		return 1.0

	if level <= 0:
		return definition.base_interval_seconds

	var scaled_interval: float = definition.base_interval_seconds * pow(
		definition.interval_level_multiplier,
		level - 1
	)

	return max(definition.minimum_interval_seconds, scaled_interval)

func get_current_extraction_rate() -> float:
	if definition == null:
		return 0.0

	if level <= 0:
		return 0.0

	var scaled_extraction: float = definition.base_extraction_rate + float(level - 1) * definition.extraction_per_level
	return min(definition.maximum_extraction_rate, scaled_extraction)

func get_next_level_cost() -> int:
	if definition == null:
		return 0

	if not is_unlocked:
		return 0

	if level >= definition.max_level:
		return 0

	var raw_cost: float = definition.base_level_cost * pow(definition.level_cost_multiplier, level)
	return int(ceil(raw_cost))

func can_level_up(current_squares: float) -> bool:
	if definition == null:
		return false

	if not is_unlocked:
		return false

	if level >= definition.max_level:
		return false

	return current_squares >= float(get_next_level_cost())

func level_up() -> bool:
	if definition == null:
		return false

	if not is_unlocked:
		return false

	if level >= definition.max_level:
		return false

	level += 1

	if level >= definition.self_prestige_unlock_level:
		can_self_prestige = true

	return true

func get_progress_ratio() -> float:
	if not is_active():
		return 0.0

	var interval_seconds: float = get_current_interval_seconds()

	if interval_seconds <= 0.0:
		return 0.0

	return clamp(elapsed_seconds / interval_seconds, 0.0, 1.0)

func record_pulse(target_square_id: String, payout: float) -> void:
	last_target_square_id = target_square_id
	last_payout = payout
	lifetime_squares_generated += payout
	lifetime_pulses += 1
