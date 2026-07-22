class_name GridState
extends RefCounted

const INITIAL_GRID_SIZE := 1
const INITIAL_SQUARE_ID := "A1"
const MAX_GRID_SIZE := 6
const GRID_UPGRADE_COSTS: Array[float] = [
	90.0,
	15000.0,
	1000000.0,
	150000000.0,
	25000000000.0,
]

var grid_size: int = INITIAL_GRID_SIZE
var square_ids: Array[String] = []
var squares_by_id: Dictionary = {}


func create_initial_grid() -> void:
	grid_size = INITIAL_GRID_SIZE
	square_ids.clear()
	squares_by_id.clear()

	var square_data: SquareData = SquareData.new(INITIAL_SQUARE_ID, 0, 0)
	square_ids.append(INITIAL_SQUARE_ID)
	squares_by_id[INITIAL_SQUARE_ID] = square_data


func get_square(square_id: String) -> SquareData:
	return squares_by_id.get(square_id) as SquareData


func get_upgrade_cost() -> float:
	var cost_index: int = grid_size - INITIAL_GRID_SIZE
	if cost_index < 0 or cost_index >= GRID_UPGRADE_COSTS.size():
		return INF

	return GRID_UPGRADE_COSTS[cost_index]


func get_next_size() -> int:
	return mini(grid_size + 1, MAX_GRID_SIZE)


func can_upgrade(currency: float) -> bool:
	return grid_size < MAX_GRID_SIZE and currency >= get_upgrade_cost()


func resize(new_grid_size: int, trait_purchase_count: int) -> void:
	var old_squares_by_id: Dictionary = squares_by_id.duplicate()
	grid_size = clampi(new_grid_size, INITIAL_GRID_SIZE, MAX_GRID_SIZE)
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
			square_data.created_at_trait_purchase = trait_purchase_count
			square_data.created_at_grid_tier = grid_size
			squares_by_id[square_id] = square_data


func _get_square_id_from_position(x: int, y: int) -> String:
	var row_letter: String = char(65 + y)
	return "%s%s" % [row_letter, x + 1]
