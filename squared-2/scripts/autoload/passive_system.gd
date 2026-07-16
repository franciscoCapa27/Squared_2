extends Node
const PASSIVE_VISIBILITY_COST_RATIO := 0.60
signal passive_state_changed()
signal passive_pulsed(generator_id: String, square_id: String, payout: float)

var generators_by_id: Dictionary = {}
var generator_order: Array[String] = []
var discovered_visible_generators: Dictionary = {}

func _ready() -> void:
	_initialize_generators()

func _process(delta: float) -> void:
	# No passive generation before the player reaches a 2×2 grid.
	if GameState.grid_size < 2:
		return

	for generator_id: String in generator_order:
		var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

		if generator_instance == null:
			continue

		if not generator_instance.is_active():
			continue

		_tick_generator(generator_instance, delta)

	passive_state_changed.emit()

func _initialize_generators() -> void:
	discovered_visible_generators.clear()
	generators_by_id.clear()
	generator_order.clear()

	for generator_definition: PassiveGeneratorDefinition in PassiveGeneratorDatabase.get_all_generators():
		var generator_instance := PassiveGeneratorInstance.new(generator_definition)

		generators_by_id[generator_definition.id] = generator_instance
		generator_order.append(generator_definition.id)

	passive_state_changed.emit()

func get_generator_instance(generator_id: String) -> PassiveGeneratorInstance:
	return generators_by_id.get(generator_id)

func get_all_generator_instances() -> Array[PassiveGeneratorInstance]:
	var instances: Array[PassiveGeneratorInstance] = []

	for generator_id: String in generator_order:
		var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

		if generator_instance != null:
			instances.append(generator_instance)

	return instances

func get_unlocked_generator_instances() -> Array[PassiveGeneratorInstance]:
	var instances: Array[PassiveGeneratorInstance] = []

	for generator_instance: PassiveGeneratorInstance in get_all_generator_instances():
		if generator_instance.is_unlocked:
			instances.append(generator_instance)

	return instances

func unlock_generator(generator_id: String) -> void:
	var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

	if generator_instance == null:
		push_warning("Unknown passive generator id: %s" % generator_id)
		return

	if generator_instance.is_unlocked:
		return

	generator_instance.unlock_permanently()

	EventBus.story_message.emit("%s is now available." % generator_instance.get_display_name())
	passive_state_changed.emit()
	EventBus.passive_generator_unlocked.emit(generator_id)

func can_upgrade_generator(generator_id: String) -> bool:
	var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

	if generator_instance == null:
		return false

	return generator_instance.can_level_up(GameState.squares)
func refresh_visible_generator_discoveries() -> void:
	for generator_instance: PassiveGeneratorInstance in get_all_generator_instances():
		if generator_instance == null:
			continue

		if generator_instance.definition == null:
			continue

		if not generator_instance.is_unlocked:
			continue

		if generator_instance.level > 0:
			discovered_visible_generators[generator_instance.definition.id] = true
			continue

		var next_cost: float = generator_instance.get_next_level_cost()
		var visibility_cost: float = next_cost * PASSIVE_VISIBILITY_COST_RATIO

		if GameState.squares >= visibility_cost:
			discovered_visible_generators[generator_instance.definition.id] = true


func should_show_generator(generator_id: String) -> bool:
	var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

	if generator_instance == null:
		return false

	if not generator_instance.is_unlocked:
		return false

	if generator_instance.level > 0:
		return true

	return bool(discovered_visible_generators.get(generator_id, false))


func has_any_visible_generator() -> bool:
	refresh_visible_generator_discoveries()

	for generator_instance: PassiveGeneratorInstance in get_all_generator_instances():
		if generator_instance == null:
			continue

		if generator_instance.definition == null:
			continue

		if should_show_generator(generator_instance.definition.id):
			return true

	return false


func upgrade_generator(generator_id: String) -> bool:
	var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

	if generator_instance == null:
		return false

	if not generator_instance.can_level_up(GameState.squares):
		return false

	var cost: int = generator_instance.get_next_level_cost()
	if not GameState.spend_squares(float(cost)):
		return false

	var upgraded: bool = generator_instance.level_up()
	if not upgraded:
		GameState.add_squares(float(cost))
		return false

	if upgraded:
		EventBus.passive_generator_upgraded.emit(generator_id)

		if generator_instance.level == 1:
			EventBus.story_message.emit("%s awakens." % generator_instance.get_display_name())
		else:
			EventBus.story_message.emit(
				"%s reached Level %s." % [
					generator_instance.get_display_name(),
					generator_instance.level
				]
			)
	passive_state_changed.emit()
	return upgraded

func _tick_generator(generator_instance: PassiveGeneratorInstance, delta: float) -> void:
	generator_instance.elapsed_seconds += delta

	var interval_seconds: float = generator_instance.get_current_interval_seconds()

	if generator_instance.elapsed_seconds >= interval_seconds:
		generator_instance.elapsed_seconds -= interval_seconds
		_pulse_generator(generator_instance)

func _pulse_generator(generator_instance: PassiveGeneratorInstance) -> void:
	var target_square: SquareData = _select_target_square(generator_instance)

	if target_square == null:
		return

	var payout: float = SquareCalculator.calculate_manual_payout(target_square)
	payout *= generator_instance.get_current_extraction_rate()
	payout *= RunUpgradeSystem.get_run_stat_multiplier(GameIds.STAT_RUN_PASSIVE_CLICK_VALUE)
	payout += RunUpgradeSystem.get_run_stat_addition(GameIds.STAT_RUN_PASSIVE_CLICK_VALUE)
	payout = max(0.0, payout)

	target_square.record_passive_click(payout)
	GameState.add_squares(payout)
	generator_instance.record_pulse(target_square.id, payout)

	passive_pulsed.emit(generator_instance.get_id(), target_square.id, payout)
	passive_state_changed.emit()

func _select_target_square(generator_instance: PassiveGeneratorInstance) -> SquareData:
	if generator_instance == null or generator_instance.definition == null:
		return null

	match generator_instance.definition.targeting_mode:
		PassiveGeneratorDefinition.TargetingMode.RANDOM_SQUARE:
			return _select_random_square()
		PassiveGeneratorDefinition.TargetingMode.HIGHEST_PAYOUT:
			return _select_highest_payout_square()
		PassiveGeneratorDefinition.TargetingMode.LOWEST_RESPAWN:
			return _select_lowest_respawn_square()
		PassiveGeneratorDefinition.TargetingMode.SELECTED_SQUARE:
			return _select_random_square()
		_:
			return _select_random_square()

func _select_random_square() -> SquareData:
	if GameState.square_ids.is_empty():
		return null

	var square_id: String = GameState.square_ids.pick_random() as String
	return GameState.get_square(square_id)

func _select_highest_payout_square() -> SquareData:
	var best_square: SquareData = null
	var best_payout: float = -1.0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		var payout: float = SquareCalculator.calculate_manual_payout(square_data)

		if payout > best_payout:
			best_payout = payout
			best_square = square_data

	return best_square

func _select_lowest_respawn_square() -> SquareData:
	var best_square: SquareData = null
	var best_respawn: float = INF

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		var respawn_time: float = SquareCalculator.calculate_respawn_time(square_data)

		if respawn_time < best_respawn:
			best_respawn = respawn_time
			best_square = square_data

	return best_square
	

func has_any_unlocked_generator() -> bool:
	for generator_instance: PassiveGeneratorInstance in get_all_generator_instances():
		if generator_instance == null:
			continue

		if generator_instance.is_unlocked:
			return true

	return false

func to_save_dict() -> Dictionary:
	var generator_save_data: Dictionary = {}

	for generator_id: String in generator_order:
		var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

		if generator_instance == null:
			continue

		generator_save_data[generator_id] = generator_instance.to_save_dict()

	return {
		"generators": generator_save_data,
		"discovered_visible_generators": discovered_visible_generators,
		
		
	}

func from_save_dict(data: Dictionary) -> void:
	_initialize_generators()

	var generator_save_data: Dictionary = data.get("generators", {})
	discovered_visible_generators = data.get("discovered_visible_generators", {})
	for generator_id: String in generator_save_data.keys():
		var generator_instance: PassiveGeneratorInstance = get_generator_instance(generator_id)

		if generator_instance == null:
			continue

		var instance_data_variant: Variant = generator_save_data.get(generator_id)

		if not instance_data_variant is Dictionary:
			continue

		generator_instance.apply_save_dict(instance_data_variant as Dictionary)

	passive_state_changed.emit()

func reset_to_new_game() -> void:
	_initialize_generators()

	for generator_instance: PassiveGeneratorInstance in get_all_generator_instances():
		generator_instance.reset_to_new_game()

	passive_state_changed.emit()
