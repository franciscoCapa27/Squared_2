extends Node

const DEBUG_PERMANENT_STATS := false

const INITIAL_GRID_SIZE := GridState.INITIAL_GRID_SIZE
const INITIAL_SQUARE_ID := GridState.INITIAL_SQUARE_ID

const VERTEX_GAIN_DIVISOR := 100.0

const MAX_GRID_SIZE := GridState.MAX_GRID_SIZE
const GRID_UPGRADE_COSTS: Array[float] = GridState.GRID_UPGRADE_COSTS
const LEGACY_TRAIT_PURCHASE_COUNT_KEY := "pre" + "stige_count"

var squares: float = 0.0
var vertices: int = 0
var trait_purchase_count: int = 0
var cheat_square_value_enabled: bool = false

var _grid_state: GridState = GridState.new()

var grid_size: int:
	get:
		return _grid_state.grid_size
	set(value):
		_grid_state.grid_size = value

var square_ids: Array[String]:
	get:
		return _grid_state.square_ids
	set(value):
		_grid_state.square_ids = value

var squares_by_id: Dictionary:
	get:
		return _grid_state.squares_by_id
	set(value):
		_grid_state.squares_by_id = value

var permanent_stat_multipliers: Dictionary = {}
var permanent_stat_additions: Dictionary = {}

func _ready() -> void:
	_create_initial_grid()


# ------------------------------------------------------------------------------
# Square Access
# ------------------------------------------------------------------------------

func get_square(square_id: String) -> SquareData:
	return _grid_state.get_square(square_id)


func click_square(square_id: String) -> void:
	var square_data: SquareData = get_square(square_id)

	if square_data == null:
		return

	var payout: float = SquareCalculator.calculate_manual_payout(square_data)

	square_data.record_manual_click(payout)
	add_squares(payout)

	EventBus.square_selected.emit(square_id)


# ------------------------------------------------------------------------------
# Currency
# ------------------------------------------------------------------------------

func add_squares(amount: float) -> void:
	if amount <= 0.0:
		return

	squares += amount
	EventBus.squares_changed.emit(squares)


func spend_squares(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if squares < amount:
		return false

	squares -= amount
	EventBus.squares_changed.emit(squares)
	return true

func add_vertices(amount: int) -> void:
	if amount <= 0:
		return

	vertices += amount
	EventBus.vertices_changed.emit(vertices)


func spend_vertices(amount: int) -> bool:
	if amount <= 0:
		return true

	if vertices < amount:
		return false

	vertices -= amount
	EventBus.vertices_changed.emit(vertices)
	return true

# ------------------------------------------------------------------------------
# Buy Trait
# ------------------------------------------------------------------------------

func get_trait_purchase_cost() -> float:
	var cost_multiplier: float = RunUpgradeSystem.get_run_stat_multiplier(
		GameIds.STAT_RUN_TRAIT_PURCHASE_COST
	)
	return TraitPurchaseService.calculate_cost(trait_purchase_count, cost_multiplier)


func can_buy_trait() -> bool:
	return squares >= get_trait_purchase_cost()


func calculate_trait_purchase_vertices_gain() -> int:
	return TraitPurchaseService.calculate_vertices_gain(get_trait_purchase_cost())


func buy_trait(save_after_buy: bool = true) -> void:
	if not can_buy_trait():
		return

	var trait_cost: float = get_trait_purchase_cost()
	var gained_vertices: int = calculate_trait_purchase_vertices_gain()

	if not spend_squares(trait_cost):
		return

	vertices += gained_vertices
	trait_purchase_count += 1

	var trait_message: String = _apply_random_trait_to_random_square(grid_size)

	_emit_core_state_changed()
	EventBus.grid_changed.emit()
	EventBus.story_message.emit(_get_trait_purchase_story_message(gained_vertices, trait_message))

	if save_after_buy:
		EventBus.save_requested.emit()


# ------------------------------------------------------------------------------
# Grid
# ------------------------------------------------------------------------------

func _create_initial_grid() -> void:
	_grid_state.create_initial_grid()

func _set_grid_size(new_grid_size: int) -> void:
	_grid_state.resize(new_grid_size, trait_purchase_count)

func can_upgrade_grid() -> bool:
	return _grid_state.can_upgrade(squares)


func get_grid_upgrade_cost() -> float:
	return _grid_state.get_upgrade_cost()


func get_next_grid_size() -> int:
	return _grid_state.get_next_size()


func upgrade_grid() -> bool:
	if not can_upgrade_grid():
		return false

	var cost: float = get_grid_upgrade_cost()

	if not spend_squares(cost):
		return false

	var next_grid_size: int = get_next_grid_size()
	_set_grid_size(next_grid_size)

	EventBus.grid_upgraded.emit(grid_size)
	EventBus.grid_changed.emit()
	EventBus.story_message.emit(
		"The grid opens into %sx%s. More squares answer the click." % [
			grid_size,
			grid_size
		]
	)

	return true

# ------------------------------------------------------------------------------
# Traits
# ------------------------------------------------------------------------------

func _apply_random_trait_to_random_square(trait_roll_grid_size: int) -> String:
	if square_ids.is_empty():
		return ""

	var trait_definition: TraitDefinition = TraitDatabase.get_random_trait(trait_roll_grid_size)

	if trait_definition == null:
		return ""

	var target_square_id: String = square_ids.pick_random() as String
	var target_square: SquareData = get_square(target_square_id)

	if target_square == null:
		return ""

	var previous_square_title: String = target_square.display_name
	var trait_instance: TraitInstance = TraitInstance.new(
		trait_definition,
		trait_purchase_count,
		trait_roll_grid_size
	)

	target_square.add_trait(trait_instance)

	var rarity_value: int = trait_definition.get("rarity")
	var rarity_display: String = trait_definition.Rarity.keys()[rarity_value] # Converts 0 to "COMMON"
	var family_display: String = trait_definition.family_display_name.strip_edges()
	if family_display == "":
		family_display = trait_definition.display_name
	var roman_stack: String = trait_instance.get_display_name()
	var square_title: String = target_square.display_name

	EventBus.trait_purchase_reveal.emit(
		target_square_id,
		family_display,
		rarity_display,
		roman_stack,
		square_title,
		previous_square_title
	)

	return "%s gained the %s Trait" % [
		target_square.display_name,
		trait_definition.display_name
	]

func _get_trait_purchase_story_message(gained_vertices: int, trait_message: String) -> String:
	var parts: Array[String] = [
		"Trait purchased",
		"+%s Vertices" % NumberFormatter.integer_amount(gained_vertices)
	]

	if trait_message.strip_edges() != "":
		parts.append("%s permanently" % trait_message)

	return ". ".join(parts) + "."

# ------------------------------------------------------------------------------
# Permanent Stats
# ------------------------------------------------------------------------------
func get_permanent_stat_multiplier(stat_id: String) -> float:
	return float(permanent_stat_multipliers.get(stat_id, 1.0))


func multiply_permanent_stat(stat_id: String, multiplier: float) -> void:
	var previous_multiplier: float = get_permanent_stat_multiplier(stat_id)
	var new_multiplier: float = previous_multiplier * multiplier

	permanent_stat_multipliers[stat_id] = new_multiplier

	if DEBUG_PERMANENT_STATS:
		print(
			"Permanent stat multiplied: %s %s -> %s" % [
				stat_id,
				NumberFormatter.multiplier(previous_multiplier),
				NumberFormatter.multiplier(new_multiplier)
			]
		)

func get_permanent_stat_addition(stat_id: String) -> float:
	return float(permanent_stat_additions.get(stat_id, 0.0))


func add_permanent_stat(stat_id: String, amount: float) -> void:
	var previous_amount: float = get_permanent_stat_addition(stat_id)
	var new_amount: float = previous_amount + amount

	permanent_stat_additions[stat_id] = new_amount

	if DEBUG_PERMANENT_STATS:
		print(
			"Permanent stat added: %s %s -> %s" % [
				stat_id,
				NumberFormatter.amount(previous_amount),
				NumberFormatter.amount(new_amount)
			]
		)
		
# ------------------------------------------------------------------------------
# Save / Load
# ------------------------------------------------------------------------------

func to_save_dict() -> Dictionary:
	var square_save_data: Dictionary = {}

	for square_id: String in square_ids:
		var square_data: SquareData = get_square(square_id)

		if square_data == null:
			continue

		square_save_data[square_id] = square_data.to_save_dict()

	return {
		"squares": squares,
		"vertices": vertices,
		"trait_purchase_count": trait_purchase_count,
		"grid_size": grid_size,
		"square_ids": square_ids,
		"squares_by_id": square_save_data,
		"permanent_stat_multipliers": permanent_stat_multipliers,
		"permanent_stat_additions": permanent_stat_additions,
	}


func from_save_dict(data: Dictionary) -> void:
	squares = float(data.get("squares", 0.0))
	vertices = int(data.get("vertices", 0))
	trait_purchase_count = int(data.get(
		"trait_purchase_count",
		data.get(LEGACY_TRAIT_PURCHASE_COUNT_KEY, 0)
	))
	grid_size = int(data.get("grid_size", INITIAL_GRID_SIZE))

	square_ids = _string_array_from_variant(data.get("square_ids", [INITIAL_SQUARE_ID]))

	_load_squares_from_save_data(data)
	permanent_stat_multipliers = _dictionary_from_variant(data.get("permanent_stat_multipliers", {}))
	permanent_stat_additions = _dictionary_from_variant(data.get("permanent_stat_additions", {}))

func _load_squares_from_save_data(data: Dictionary) -> void:
	squares_by_id.clear()

	var square_save_data: Dictionary = _dictionary_from_variant(data.get("squares_by_id", {}))

	for square_id: String in square_ids:
		var square_data_variant: Variant = square_save_data.get(square_id)

		if square_data_variant is Dictionary:
			var square_data: SquareData = SquareData.from_save_dict(square_data_variant as Dictionary)
			squares_by_id[square_id] = square_data
		else:
			squares_by_id[square_id] = SquareData.new(square_id, 0, 0)


func reset_to_new_game() -> void:
	squares = 0.0
	vertices = 0
	trait_purchase_count = 0
	permanent_stat_multipliers.clear()
	permanent_stat_additions.clear()

	_create_initial_grid()
	_emit_full_state_changed()

	EventBus.story_message.emit("There is only one square.")


# ------------------------------------------------------------------------------
# Event Helpers
# ------------------------------------------------------------------------------

func _emit_core_state_changed() -> void:
	EventBus.squares_changed.emit(squares)
	EventBus.vertices_changed.emit(vertices)
	EventBus.trait_purchase_changed.emit(trait_purchase_count)


func _emit_full_state_changed() -> void:
	_emit_core_state_changed()
	EventBus.grid_changed.emit()


# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []

	if not value is Array:
		return result

	for item: Variant in value:
		result.append(str(item))

	return result


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}
