extends Node

var squares: float = 0.0
var vertices: int = 0
var prestige_count: int = 0

var grid_size: int = 1
var square_ids: Array[String] = ["A1"]
var squares_by_id: Dictionary = {}

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

	if prestige_count == 1:
		_unlock_grid_size_2()
		EventBus.story_message.emit("One became four. The void has corners now.")

	_apply_random_trait_to_random_square()

	EventBus.vertices_changed.emit(vertices)
	EventBus.prestige_changed.emit(prestige_count)
	EventBus.squares_changed.emit(squares)
	EventBus.grid_changed.emit()

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

	var trait_definition := TraitDatabase.get_random_trait(grid_size)

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
