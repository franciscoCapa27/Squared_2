extends RefCounted
class_name PassiveGeneratorData

enum TargetingMode {
	RANDOM_SQUARE,
	HIGHEST_PAYOUT,
	LOWEST_RESPAWN,
	SELECTED_SQUARE
}

var id: String = ""
var display_name: String = ""

# Permanent unlock, bought with Vertices.
var is_unlocked: bool = false

# Run-based level, bought with Squares.
# Resets to 0 on prestige.
var level: int = 0
var max_level: int = 100

# Future self-prestige support.
var self_prestige_level: int = 0
var can_self_prestige: bool = false

# If true later, self_prestige_level survives normal prestige.
# If false later, self_prestige_level resets with the run.
var self_prestige_is_permanent: bool = false

var base_interval_seconds: float = 2.5
var minimum_interval_seconds: float = 0.4
var interval_level_multiplier: float = 0.985

var base_extraction_rate: float = 0.25
var extraction_per_level: float = 0.01
var maximum_extraction_rate: float = 2.0

var base_level_cost: float = 10.0
var level_cost_multiplier: float = 1.18

var elapsed_seconds: float = 0.0
var targeting_mode: TargetingMode = TargetingMode.RANDOM_SQUARE

var last_target_square_id: String = ""
var last_payout: float = 0.0
var lifetime_squares_generated: float = 0.0
var lifetime_pulses: int = 0

func _init(
	p_id: String = "first_generator",
	p_display_name: String = "First Generator"
) -> void:
	id = p_id
	display_name = p_display_name

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

	if not self_prestige_is_permanent:
		self_prestige_level = 0

func is_active() -> bool:
	return is_unlocked and level > 0

func get_current_interval_seconds() -> float:
	if level <= 0:
		return base_interval_seconds

	var scaled_interval: float = base_interval_seconds * pow(interval_level_multiplier, level - 1)
	return max(minimum_interval_seconds, scaled_interval)

func get_current_extraction_rate() -> float:
	if level <= 0:
		return 0.0

	var scaled_extraction: float = base_extraction_rate + float(level - 1) * extraction_per_level
	return min(maximum_extraction_rate, scaled_extraction)

func get_next_level_cost() -> int:
	if not is_unlocked:
		return 0

	if level >= max_level:
		return 0

	# Level 0 -> 1 costs base_level_cost.
	var raw_cost: float = base_level_cost * pow(level_cost_multiplier, level)
	return int(ceil(raw_cost))

func can_level_up(current_squares: float) -> bool:
	if not is_unlocked:
		return false

	if level >= max_level:
		return false

	return current_squares >= float(get_next_level_cost())

func level_up() -> bool:
	if not is_unlocked:
		return false

	if level >= max_level:
		return false

	level += 1

	if level >= max_level:
		can_self_prestige = true

	return true

func get_progress_ratio() -> float:
	if not is_active():
		return 0.0

	var interval_seconds: float = get_current_interval_seconds()

	if interval_seconds <= 0.0:
		return 0.0

	return clamp(elapsed_seconds / interval_seconds, 0.0, 1.0)

func reset_progress() -> void:
	elapsed_seconds = 0.0

func record_pulse(target_square_id: String, payout: float) -> void:
	last_target_square_id = target_square_id
	last_payout = payout
	lifetime_squares_generated += payout
	lifetime_pulses += 1
