extends Control
class_name GridPage

signal square_selected(square_id: String)
signal grid_upgrade_requested()

@onready var grid_root: GridContainer = %GridRoot
@onready var upgrade_grid_button: Button = %UpgradeGridButton

var square_button_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")
var square_buttons_by_id: Dictionary = {}


func _ready() -> void:
	EventBus.grid_changed.connect(rebuild)
	EventBus.squares_changed.connect(_on_squares_changed)

	upgrade_grid_button.pressed.connect(_on_upgrade_grid_button_pressed)

	rebuild()


func rebuild() -> void:
	for child: Node in grid_root.get_children():
		child.queue_free()

	square_buttons_by_id.clear()
	grid_root.columns = GameState.grid_size

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)

		if square_data == null:
			continue

		var square_button: SquareButton = square_button_scene.instantiate() as SquareButton
		grid_root.add_child(square_button)

		square_button.setup(square_data.id, "■")
		square_button.set_square_data(square_data)
		square_button.square_clicked.connect(_on_square_button_clicked)

		square_buttons_by_id[square_data.id] = square_button

	_refresh_upgrade_button()


func refresh_buttons() -> void:
	for square_id: String in square_buttons_by_id.keys():
		var square_button: SquareButton = square_buttons_by_id.get(square_id) as SquareButton
		var square_data: SquareData = GameState.get_square(square_id)

		if square_button == null or square_data == null:
			continue

		square_button.set_square_data(square_data)

	_refresh_upgrade_button()


func _refresh_upgrade_button() -> void:
	if GameState.grid_size >= GameState.MAX_GRID_SIZE:
		upgrade_grid_button.text = "Grid Fully Expanded"
		upgrade_grid_button.disabled = true
		upgrade_grid_button.tooltip_text = "Maximum grid size reached."
		return

	var next_grid_size: int = GameState.get_next_grid_size()
	var cost: float = GameState.get_grid_upgrade_cost()

	upgrade_grid_button.text = "Expand Grid to %sx%s — %s Squares" % [
		next_grid_size,
		next_grid_size,
		NumberFormatter.cost(cost)
	]

	upgrade_grid_button.disabled = not GameState.can_upgrade_grid()
	upgrade_grid_button.tooltip_text = "Unlocks %s Trait rolls. Cost: %s Squares" % [
		_get_rarity_unlock_text(next_grid_size),
		NumberFormatter.cost(cost)
	]


func _get_rarity_unlock_text(next_grid_size: int) -> String:
	match next_grid_size:
		2:
			return "Uncommon"
		3:
			return "Rare"
		4:
			return "Epic"
		5:
			return "Legendary"
		6:
			return "Cosmic"
		_:
			return "higher-rarity"


func _on_square_button_clicked(square_id: String) -> void:
	GameState.click_square(square_id)
	square_selected.emit(square_id)


func _on_upgrade_grid_button_pressed() -> void:
	grid_upgrade_requested.emit()


func _on_squares_changed(_value: float) -> void:
	_refresh_upgrade_button()
