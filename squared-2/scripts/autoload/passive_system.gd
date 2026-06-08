extends Node

signal passive_state_changed()
signal passive_pulsed(generator_id: String, square_id: String, payout: float)

var first_generator: PassiveGeneratorData = PassiveGeneratorData.new()

func _process(delta: float) -> void:
	if not first_generator.is_active():
		return

	first_generator.elapsed_seconds += delta

	var interval_seconds: float = first_generator.get_current_interval_seconds()

	if first_generator.elapsed_seconds >= interval_seconds:
		first_generator.elapsed_seconds -= interval_seconds
		_pulse_generator(first_generator)

	passive_state_changed.emit()

func unlock_first_generator() -> void:
	if first_generator.is_unlocked:
		return

	first_generator.unlock_permanently()

	EventBus.story_message.emit("The first generator is now available.")
	passive_state_changed.emit()

func reset_run_state_on_prestige() -> void:
	if first_generator.is_unlocked:
		first_generator.reset_run_state()

	passive_state_changed.emit()

func can_upgrade_first_generator() -> bool:
	return first_generator.can_level_up(GameState.squares)

func upgrade_first_generator() -> bool:
	if not can_upgrade_first_generator():
		return false

	var cost: int = first_generator.get_next_level_cost()
	var spent: bool = GameState.spend_squares(float(cost))

	if not spent:
		return false

	var upgraded: bool = first_generator.level_up()

	if upgraded:
		if first_generator.level == 1:
			EventBus.story_message.emit("The first generator awakens.")
		else:
			EventBus.story_message.emit(
				"%s reached Level %s." % [
					first_generator.display_name,
					first_generator.level
				]
			)

	passive_state_changed.emit()
	return upgraded

func _pulse_generator(generator_data: PassiveGeneratorData) -> void:
	var square_data: SquareData = _select_target_square(generator_data)

	if square_data == null:
		return

	var manual_payout: float = SquareCalculator.calculate_manual_payout(square_data)
	var passive_payout: float = manual_payout * generator_data.get_current_extraction_rate()

	square_data.record_passive_click(passive_payout)
	GameState.add_squares(passive_payout)

	generator_data.record_pulse(square_data.id, passive_payout)

	passive_pulsed.emit(generator_data.id, square_data.id, passive_payout)

func _select_target_square(generator_data: PassiveGeneratorData) -> SquareData:
	match generator_data.targeting_mode:
		PassiveGeneratorData.TargetingMode.RANDOM_SQUARE:
			return _select_random_square()
		PassiveGeneratorData.TargetingMode.HIGHEST_PAYOUT:
			return _select_highest_payout_square()
		PassiveGeneratorData.TargetingMode.LOWEST_RESPAWN:
			return _select_lowest_respawn_square()
		PassiveGeneratorData.TargetingMode.SELECTED_SQUARE:
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
