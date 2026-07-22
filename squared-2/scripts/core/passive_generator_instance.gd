extends RefCounted
class_name PassiveGeneratorInstance

var definition: PassiveGeneratorDefinition

# Permanent unlock state.
var is_unlocked: bool = false

# Run-based level. Persists through Trait purchases and resets only on a new game.
var level: int = 0

# Local prestige is run-layer progression for this generator. It survives saves
# and normal resets, but is cleared by reset_to_new_game (Hard Reset).
var prestige_count: int = 0

# Future self-condensation state.
var self_condensation_level: int = 0
var can_self_condensation: bool = false

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
	can_self_condensation = false

	if definition != null and not definition.self_condensation_is_permanent:
		self_condensation_level = 0

func is_active() -> bool:
	return is_unlocked and level > 0

func get_max_level() -> int:
	if definition == null:
		return 0

	return definition.max_level

func get_current_interval_seconds() -> float:
	if definition == null:
		return 999.0

	var interval: float = definition.base_interval_seconds * pow(
		definition.interval_level_multiplier,
		float(max(0, level - 1))
	)

	interval *= RunUpgradeSystem.get_run_stat_multiplier(GameIds.STAT_RUN_PASSIVE_INTERVAL)
	interval += RunUpgradeSystem.get_run_stat_addition(GameIds.STAT_RUN_PASSIVE_INTERVAL)
	interval *= pow(5.0, float(prestige_count))

	return max(definition.minimum_interval_seconds, interval)

func get_current_extraction_rate(target_square: SquareData = null) -> float:
	if definition == null:
		return 0.0

	var extraction_rate: float = definition.base_extraction_rate
	extraction_rate += definition.extraction_per_level * float(max(0, level - 1))
	if target_square != null:
		extraction_rate += definition.extraction_per_target_trait * target_square.get_trait_count()

	extraction_rate += definition.extraction_per_grid_size * float(GameState.grid_size)

	extraction_rate *= RunUpgradeSystem.get_run_stat_multiplier(GameIds.STAT_RUN_PASSIVE_EXTRACTION)
	extraction_rate += RunUpgradeSystem.get_run_stat_addition(GameIds.STAT_RUN_PASSIVE_EXTRACTION)

	extraction_rate = min(definition.maximum_extraction_rate, extraction_rate)
	extraction_rate *= pow(10.0, float(prestige_count))
	return extraction_rate

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

func get_prestige_cost() -> int:
	if definition == null or not is_unlocked or level < get_max_level():
		return 0

	var max_level_cost: float = definition.base_level_cost * pow(
		definition.level_cost_multiplier,
		float(get_max_level())
	)
	return int(ceil(max_level_cost * definition.prestige_cost_multiplier))

func can_prestige(current_squares: float) -> bool:
	return get_prestige_cost() > 0 and current_squares >= float(get_prestige_cost())

func level_up() -> bool:
	if definition == null:
		return false

	if not is_unlocked:
		return false

	if level >= definition.max_level:
		return false

	level += 1

	if level >= definition.self_condensation_unlock_level:
		can_self_condensation = true

	return true

func prestige() -> bool:
	if definition == null or not is_unlocked or level < get_max_level():
		return false

	prestige_count += 1
	level = 1
	elapsed_seconds = 0.0
	last_target_square_id = ""
	last_payout = 0.0
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


func to_save_dict() -> Dictionary:
	var definition_id: String = ""

	if definition != null:
		definition_id = definition.id

	return {
		"definition_id": definition_id,
		"is_unlocked": is_unlocked,
		"level": level,
		"prestige_count": prestige_count,
		"self_condensation_level": self_condensation_level,
		"can_self_condensation": can_self_condensation,
		"elapsed_seconds": elapsed_seconds,
		"last_target_square_id": last_target_square_id,
		"last_payout": last_payout,
		"lifetime_squares_generated": lifetime_squares_generated,
		"lifetime_pulses": lifetime_pulses
	}

func apply_save_dict(data: Dictionary) -> void:
	is_unlocked = bool(data.get("is_unlocked", false))
	level = int(data.get("level", 0))
	prestige_count = max(0, int(data.get("prestige_count", 0)))
	level = clamp(level, 0, get_max_level())
	self_condensation_level = int(data.get("self_condensation_level", 0))
	can_self_condensation = bool(data.get("can_self_condensation", false))
	elapsed_seconds = float(data.get("elapsed_seconds", 0.0))
	last_target_square_id = str(data.get("last_target_square_id", ""))
	last_payout = float(data.get("last_payout", 0.0))
	lifetime_squares_generated = float(data.get("lifetime_squares_generated", 0.0))
	lifetime_pulses = int(data.get("lifetime_pulses", 0))

func reset_to_new_game() -> void:
	is_unlocked = false
	level = 0
	prestige_count = 0
	self_condensation_level = 0
	can_self_condensation = false
	elapsed_seconds = 0.0
	last_target_square_id = ""
	last_payout = 0.0
	lifetime_squares_generated = 0.0
	lifetime_pulses = 0
