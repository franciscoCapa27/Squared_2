extends PanelContainer
class_name GridPage

signal square_selected(square_id: String)

@onready var grid_root: GridContainer = %GridRoot

var square_button_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")
var square_buttons_by_id: Dictionary = {}


func _ready() -> void:
	EventBus.grid_changed.connect(rebuild)
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


func refresh_buttons() -> void:
	for square_id: String in square_buttons_by_id.keys():
		var square_button: SquareButton = square_buttons_by_id.get(square_id) as SquareButton
		var square_data: SquareData = GameState.get_square(square_id)

		if square_button == null or square_data == null:
			continue

		square_button.set_square_data(square_data)


func _on_square_button_clicked(square_id: String) -> void:
	GameState.click_square(square_id)
	square_selected.emit(square_id)
