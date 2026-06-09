extends Node

var squares: float = 0.0
var vertices: int = 0
var prestige_count: int = 0

var grid_size: int = 1
var square_ids: Array[String] = ["A1"]
var squares_by_id: Dictionary = {}

var unlocked_vertex_upgrades: Dictionary = {}
var permanent_stat_multipliers: Dictionary = {}

func _ready() -> void:
	_create_initial_grid()

func _create_initial_grid() -> void:
	squares_by_id.clear()
	grid_size = 1
	square_ids = ["A1"]

	var square_data := SquareData.new("A1", 0, 0)
	squares_by_id["A1"] = square_data

func get_square(square_id: String) -> SquareData:
	return squares_by_id.get(square_id)

func add_squares(amount: float) -> void:
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

func click_square(square_id: String) -> void:
	var square_data := get_square(square_id)

	if square_data == null:
		return

	var payout := SquareCalculator.calculate_manual_payout(square_data)

	square_data.record_manual_click(payout)
	add_squares(payout)

	EventBus.square_selected.emit(square_id)

func can_prestige() -> bool:
	return squares >= 10.0

func calculate_vertices_gain() -> int:
	return int(floor(sqrt(squares / 100.0)))

func prestige() -> void:
	if not can_prestige():
		return

	var gain: int = max(1, calculate_vertices_gain())

	vertices += gain
	prestige_count += 1
	squares = 0.0
	
	PassiveSystem.reset_run_state_on_prestige()

	if prestige_count == 1:
		_unlock_grid_size_2()
		EventBus.story_message.emit("One became four. The void has corners now.")

	_apply_random_trait_to_random_square()

	EventBus.vertices_changed.emit(vertices)
	EventBus.prestige_changed.emit(prestige_count)
	EventBus.squares_changed.emit(squares)
	EventBus.grid_changed.emit()
	SaveSystem.save_game()

func _unlock_grid_size_2() -> void:
	grid_size = 2
	square_ids = ["A1", "A2", "B1", "B2"]
	squares_by_id.clear()

	var coordinates := {
		"A1": Vector2i(0, 0),
		"A2": Vector2i(1, 0),
		"B1": Vector2i(0, 1),
		"B2": Vector2i(1, 1)
	}

	for square_id in square_ids:
		var pos: Vector2i = coordinates[square_id]
		var square_data := SquareData.new(square_id, pos.x, pos.y)
		square_data.created_at_prestige = prestige_count
		square_data.created_at_grid_tier = 1
		squares_by_id[square_id] = square_data
		
func _apply_random_trait_to_random_square() -> void:
	if square_ids.is_empty():
		return

	var trait_definition : TraitDefinition = TraitDatabase.get_random_trait(grid_size) as TraitDefinition

	if trait_definition == null:
		return

	var target_square_id: String = square_ids.pick_random() as String
	var target_square : SquareData = get_square(target_square_id) as SquareData

	if target_square == null:
		return

	var trait_instance := TraitInstance.new(
		trait_definition,
		prestige_count,
		grid_size
	)

	target_square.add_trait(trait_instance)

	EventBus.story_message.emit(
		"%s gained the %s Trait." % [
			target_square.display_name,
			trait_definition.display_name
		]
	)

func has_vertex_upgrade(upgrade_id: String) -> bool:
	return bool(unlocked_vertex_upgrades.get(upgrade_id, false))

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
	if not can_buy_vertex_upgrade(upgrade_id):
		return false

	var upgrade: VertexUpgradeDefinition = VertexUpgradeDatabase.get_upgrade(upgrade_id)

	if upgrade == null:
		return false

	vertices -= upgrade.cost_vertices

	_apply_vertex_upgrade_effects(upgrade)

	var purchase_count: int = get_vertex_upgrade_purchase_count(upgrade_id)
	unlocked_vertex_upgrades[upgrade_id] = purchase_count + 1

	EventBus.vertices_changed.emit(vertices)
	EventBus.story_message.emit("%s unlocked." % upgrade.display_name)

	return true

func _apply_vertex_upgrade_effects(upgrade: VertexUpgradeDefinition) -> void:
	for effect_iter: VertexUpgradeEffect in upgrade.effects:
		_apply_vertex_upgrade_effect(effect_iter)

func _apply_vertex_upgrade_effect(effect_iter: VertexUpgradeEffect) -> void:
	if effect_iter == null:
		return

	match effect_iter.effect_type:
		VertexUpgradeEffect.EffectType.UNLOCK_PASSIVE_GENERATOR:
			_apply_unlock_passive_generator_effect(effect_iter)
		VertexUpgradeEffect.EffectType.GLOBAL_STAT_MULTIPLIER:
			_apply_global_stat_multiplier_effect(effect_iter)
		VertexUpgradeEffect.EffectType.UNLOCK_MECHANIC:
			_apply_unlock_mechanic_effect(effect_iter)
		VertexUpgradeEffect.EffectType.ADD_STARTING_SQUARES:
			_apply_add_starting_squares_effect(effect_iter)
		VertexUpgradeEffect.EffectType.UNLOCK_TAB:
			_apply_unlock_tab_effect(effect_iter)
		VertexUpgradeEffect.EffectType.SCRIPT_HOOK:
			_apply_script_hook_effect(effect_iter)
		_:
			push_warning("Unhandled vertex upgrade effect.")

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
	# Placeholder for future mechanics.
	push_warning("UNLOCK_MECHANIC effect not implemented yet: %s" % effect_iter.mechanic_id)

func _apply_add_starting_squares_effect(effect_iter: VertexUpgradeEffect) -> void:
	# Placeholder. Later this should affect run initialization.
	push_warning("ADD_STARTING_SQUARES effect not implemented yet.")

func _apply_unlock_tab_effect(effect_iter: VertexUpgradeEffect) -> void:
	# Placeholder. Later tabs can be unlocked dynamically.
	push_warning("UNLOCK_TAB effect not implemented yet: %s" % effect_iter.target_id)

func _apply_script_hook_effect(effect_iter: VertexUpgradeEffect) -> void:
	# Escape hatch for weird one-off effects.
	push_warning("SCRIPT_HOOK effect not implemented yet: %s" % effect_iter.script_hook_id)

func get_permanent_stat_multiplier(stat_id: String) -> float:
	return float(permanent_stat_multipliers.get(stat_id, 1.0))


func multiply_permanent_stat(stat_id: String, multiplier: float) -> void:
	var current_multiplier: float = get_permanent_stat_multiplier(stat_id)
	permanent_stat_multipliers[stat_id] = current_multiplier * multiplier


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
		"permanent_stat_multipliers": permanent_stat_multipliers
	}

func from_save_dict(data: Dictionary) -> void:
	squares = float(data.get("squares", 0.0))
	vertices = int(data.get("vertices", 0))
	prestige_count = int(data.get("prestige_count", 0))
	grid_size = int(data.get("grid_size", 1))

	square_ids = _string_array_from_variant(data.get("square_ids", ["A1"]))

	squares_by_id.clear()

	var square_save_data: Dictionary = data.get("squares_by_id", {})

	for square_id: String in square_ids:
		var square_data_variant: Variant = square_save_data.get(square_id)

		if square_data_variant is Dictionary:
			var square_data: SquareData = SquareData.from_save_dict(square_data_variant as Dictionary)
			squares_by_id[square_id] = square_data
		else:
			squares_by_id[square_id] = SquareData.new(square_id, 0, 0)

	unlocked_vertex_upgrades = data.get("unlocked_vertex_upgrades", {})
	permanent_stat_multipliers = data.get("permanent_stat_multipliers", {})

func reset_to_new_game() -> void:
	squares = 0.0
	vertices = 0
	prestige_count = 0
	grid_size = 1
	square_ids = ["A1"]
	squares_by_id.clear()
	unlocked_vertex_upgrades.clear()
	permanent_stat_multipliers.clear()

	var square_data := SquareData.new("A1", 0, 0)
	squares_by_id["A1"] = square_data

	EventBus.squares_changed.emit(squares)
	EventBus.vertices_changed.emit(vertices)
	EventBus.prestige_changed.emit(prestige_count)
	EventBus.grid_changed.emit()
	EventBus.story_message.emit("There is a square.")

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []

	if not value is Array:
		return result

	for item: Variant in value:
		result.append(str(item))

	return result
