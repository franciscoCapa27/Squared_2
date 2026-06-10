extends Node

const DEBUG_VERTEX_UPGRADES := false
const DEBUG_PERMANENT_STATS := false

const INITIAL_GRID_SIZE := 1
const INITIAL_SQUARE_ID := "A1"

const PRESTIGE_REQUIRED_SQUARES := 10.0
const VERTEX_GAIN_DIVISOR := 100.0

const MAX_GRID_SIZE := 6
const GRID_UPGRADE_BASE_COST := 25.0
const GRID_UPGRADE_COST_MULTIPLIER := 6.0

var squares: float = 0.0
var vertices: int = 0
var prestige_count: int = 0

var grid_size: int = INITIAL_GRID_SIZE
var square_ids: Array[String] = [INITIAL_SQUARE_ID]
var squares_by_id: Dictionary = {}

var unlocked_vertex_upgrades: Dictionary = {}
var permanent_stat_multipliers: Dictionary = {}
var permanent_stat_additions: Dictionary = {}

func _ready() -> void:
	_create_initial_grid()


# ------------------------------------------------------------------------------
# Square Access
# ------------------------------------------------------------------------------

func get_square(square_id: String) -> SquareData:
	return squares_by_id.get(square_id) as SquareData


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


# ------------------------------------------------------------------------------
# Prestige
# ------------------------------------------------------------------------------

func can_prestige() -> bool:
	return squares >= PRESTIGE_REQUIRED_SQUARES


func calculate_vertices_gain() -> int:
	return int(floor(sqrt(squares / VERTEX_GAIN_DIVISOR)))


func prestige() -> void:
	if not can_prestige():
		return

	var gained_vertices: int = max(1, calculate_vertices_gain())

	vertices += gained_vertices
	prestige_count += 1
	squares = 0.0

	PassiveSystem.reset_run_state_on_prestige()
	RunUpgradeSystem.reset_run_state_on_prestige()

	_apply_random_trait_to_random_square(grid_size)

	_emit_core_state_changed()
	EventBus.grid_changed.emit()

	SaveSystem.save_game()


# ------------------------------------------------------------------------------
# Grid
# ------------------------------------------------------------------------------

func _create_initial_grid() -> void:
	grid_size = INITIAL_GRID_SIZE
	square_ids.clear()
	squares_by_id.clear()

	var square_data: SquareData = SquareData.new(INITIAL_SQUARE_ID, 0, 0)

	square_ids.append(INITIAL_SQUARE_ID)
	squares_by_id[INITIAL_SQUARE_ID] = square_data

func _set_grid_size(new_grid_size: int) -> void:
	var old_squares_by_id: Dictionary = squares_by_id.duplicate()

	grid_size = clamp(new_grid_size, INITIAL_GRID_SIZE, MAX_GRID_SIZE)
	square_ids.clear()
	squares_by_id.clear()

	for y: int in grid_size:
		for x: int in grid_size:
			var square_id: String = _get_square_id_from_position(x, y)
			square_ids.append(square_id)

			if old_squares_by_id.has(square_id):
				squares_by_id[square_id] = old_squares_by_id[square_id]
				continue

			var square_data: SquareData = SquareData.new(square_id, x, y)
			square_data.created_at_prestige = prestige_count
			square_data.created_at_grid_tier = grid_size
			squares_by_id[square_id] = square_data

func can_upgrade_grid() -> bool:
	if grid_size >= MAX_GRID_SIZE:
		return false

	return squares >= get_grid_upgrade_cost()


func get_grid_upgrade_cost() -> float:
	return GRID_UPGRADE_BASE_COST * pow(GRID_UPGRADE_COST_MULTIPLIER, float(grid_size - 1))


func get_next_grid_size() -> int:
	return min(grid_size + 1, MAX_GRID_SIZE)


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
		"The grid expands to %sx%s." % [
			grid_size,
			grid_size
		]
	)

	return true

# ------------------------------------------------------------------------------
# Traits
# ------------------------------------------------------------------------------

func _apply_random_trait_to_random_square(trait_roll_grid_size: int) -> void:
	if square_ids.is_empty():
		return

	var trait_definition: TraitDefinition = TraitDatabase.get_random_trait(trait_roll_grid_size)

	if trait_definition == null:
		return

	var target_square_id: String = square_ids.pick_random() as String
	var target_square: SquareData = get_square(target_square_id)

	if target_square == null:
		return

	var trait_instance: TraitInstance = TraitInstance.new(
		trait_definition,
		prestige_count,
		trait_roll_grid_size
	)

	target_square.add_trait(trait_instance)

	EventBus.story_message.emit(
		"%s gained the %s Trait." % [
			target_square.display_name,
			trait_definition.display_name
		]
	)

# ------------------------------------------------------------------------------
# Vertex Upgrades
# ------------------------------------------------------------------------------

func has_vertex_upgrade(upgrade_id: String) -> bool:
	return get_vertex_upgrade_purchase_count(upgrade_id) > 0


func get_vertex_upgrade_purchase_count(upgrade_id: String) -> int:
	var value: Variant = unlocked_vertex_upgrades.get(upgrade_id, 0)

	if value is bool:
		return 1 if bool(value) else 0

	return int(value)


func can_buy_vertex_upgrade(upgrade_id: String) -> bool:
	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	if vertices < upgrade.cost_vertices:
		return false

	if not upgrade.requirements_are_met(
		prestige_count,
		grid_size,
		unlocked_vertex_upgrades
	):
		return false

	var purchase_count: int = get_vertex_upgrade_purchase_count(upgrade_id)

	if not upgrade.is_repeatable and purchase_count > 0:
		return false

	if upgrade.is_repeatable and upgrade.max_purchases > 0:
		if purchase_count >= upgrade.max_purchases:
			return false

	return true


func buy_vertex_upgrade(upgrade_id: String) -> bool:
	if DEBUG_VERTEX_UPGRADES:
		print("Trying to buy vertex upgrade: %s" % upgrade_id)

	if not can_buy_vertex_upgrade(upgrade_id):
		if DEBUG_VERTEX_UPGRADES:
			print("Cannot buy vertex upgrade: %s" % upgrade_id)

		return false

	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		if DEBUG_VERTEX_UPGRADES:
			print("Upgrade resource not found: %s" % upgrade_id)

		return false

	if DEBUG_VERTEX_UPGRADES:
		print("Buying upgrade: %s" % upgrade.display_name)
		print("Effect count: %s" % upgrade.effects.size())

		for effect_iter: VertexUpgradeEffect in upgrade.effects:
			if effect_iter == null:
				print("Effect is null.")
				continue

			print(
				"Effect type: %s | target_stat: %s | target_id: %s | value: %s" % [
					effect_iter.effect_type,
					effect_iter.target_stat,
					effect_iter.target_id,
					effect_iter.value
				]
			)

	vertices -= upgrade.cost_vertices

	_apply_vertex_upgrade_effects(upgrade)
	_record_vertex_upgrade_purchase(upgrade.id)

	EventBus.vertices_changed.emit(vertices)
	EventBus.vertex_upgrade_purchased.emit(upgrade.id)
	EventBus.story_message.emit("%s unlocked." % upgrade.display_name)

	return true


func _record_vertex_upgrade_purchase(upgrade_id: String) -> void:
	var purchase_count: int = get_vertex_upgrade_purchase_count(upgrade_id)
	unlocked_vertex_upgrades[upgrade_id] = purchase_count + 1


func _apply_vertex_upgrade_effects(upgrade: VertexUpgradeDefinition) -> void:
	if DEBUG_VERTEX_UPGRADES:
		print("Applying effects for upgrade: %s" % upgrade.id)

	for effect_iter: VertexUpgradeEffect in upgrade.effects:
		if effect_iter == null:
			if DEBUG_VERTEX_UPGRADES:
				print("Skipped null vertex upgrade effect.")

			continue

		if DEBUG_VERTEX_UPGRADES:
			print("Applying effect type: %s" % effect_iter.effect_type)

		_apply_vertex_upgrade_effect(effect_iter)


func _apply_vertex_upgrade_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter == null:
		return

	match effect_iter.effect_type:
		VertexUpgradeEffect.EffectType.UNLOCK_PASSIVE_GENERATOR:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: UNLOCK_PASSIVE_GENERATOR")

			_apply_unlock_passive_generator_effect(effect_iter)

		VertexUpgradeEffect.EffectType.GLOBAL_STAT_MULTIPLIER:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: GLOBAL_STAT_MULTIPLIER")

			_apply_global_stat_multiplier_effect(effect_iter)

		VertexUpgradeEffect.EffectType.ADD_PERMANENT_STAT:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: ADD_PERMANENT_STAT")

			_apply_add_permanent_stat_effect(effect_iter)

		VertexUpgradeEffect.EffectType.UNLOCK_MECHANIC:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: UNLOCK_MECHANIC")

			_apply_unlock_mechanic_effect(effect_iter)

		VertexUpgradeEffect.EffectType.ADD_STARTING_SQUARES:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: ADD_STARTING_SQUARES")

			_apply_add_starting_squares_effect(effect_iter)

		VertexUpgradeEffect.EffectType.UNLOCK_TAB:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: UNLOCK_TAB")

			_apply_unlock_tab_effect(effect_iter)

		VertexUpgradeEffect.EffectType.SCRIPT_HOOK:
			if DEBUG_VERTEX_UPGRADES:
				print("Matched effect: SCRIPT_HOOK")

			_apply_script_hook_effect(effect_iter)

		_:
			push_warning("Unhandled vertex upgrade effect: %s" % effect_iter.effect_type)
func _apply_add_permanent_stat_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("ADD_PERMANENT_STAT missing target_stat.")
		return

	add_permanent_stat(effect_iter.target_stat, effect_iter.value)
func _apply_unlock_passive_generator_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_id.strip_edges() == "":
		push_warning("UNLOCK_PASSIVE_GENERATOR missing target_id.")
		return

	PassiveSystem.unlock_generator(effect_iter.target_id)


func _apply_global_stat_multiplier_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter.target_stat.strip_edges() == "":
		push_warning("GLOBAL_STAT_MULTIPLIER missing target_stat.")
		return

	multiply_permanent_stat(effect_iter.target_stat, effect_iter.value)


func _apply_unlock_mechanic_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("UNLOCK_MECHANIC effect not implemented yet: %s" % effect_iter.mechanic_id)


func _apply_add_starting_squares_effect(_effect_iter: VertexUpgradeEffect) -> void:
	push_warning("ADD_STARTING_SQUARES effect not implemented yet.")


func _apply_unlock_tab_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("UNLOCK_TAB effect not implemented yet: %s" % effect_iter.target_id)


func _apply_script_hook_effect(effect_iter: VertexUpgradeEffect) -> void:
	push_warning("SCRIPT_HOOK effect not implemented yet: %s" % effect_iter.script_hook_id)


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
		"prestige_count": prestige_count,
		"grid_size": grid_size,
		"square_ids": square_ids,
		"squares_by_id": square_save_data,
		"unlocked_vertex_upgrades": unlocked_vertex_upgrades,
		"permanent_stat_multipliers": permanent_stat_multipliers,
		"permanent_stat_additions": permanent_stat_additions,
	}


func from_save_dict(data: Dictionary) -> void:
	squares = float(data.get("squares", 0.0))
	vertices = int(data.get("vertices", 0))
	prestige_count = int(data.get("prestige_count", 0))
	grid_size = int(data.get("grid_size", INITIAL_GRID_SIZE))

	square_ids = _string_array_from_variant(data.get("square_ids", [INITIAL_SQUARE_ID]))

	_load_squares_from_save_data(data)
	unlocked_vertex_upgrades = _dictionary_from_variant(data.get("unlocked_vertex_upgrades", {}))
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
	prestige_count = 0
	unlocked_vertex_upgrades.clear()
	permanent_stat_multipliers.clear()
	permanent_stat_additions.clear()

	_create_initial_grid()
	_emit_full_state_changed()

	EventBus.story_message.emit("There is a square.")


# ------------------------------------------------------------------------------
# Event Helpers
# ------------------------------------------------------------------------------

func _emit_core_state_changed() -> void:
	EventBus.squares_changed.emit(squares)
	EventBus.vertices_changed.emit(vertices)
	EventBus.prestige_changed.emit(prestige_count)


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

func _get_square_id_from_position(x: int, y: int) -> String:
	var row_letter: String = char(65 + y)
	return "%s%s" % [row_letter, x + 1]
