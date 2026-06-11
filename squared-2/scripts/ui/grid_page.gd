extends Control
class_name GridPage

signal square_selected(square_id: String)
signal grid_upgrade_requested()

const MAX_GRID_AREA_SIZE := 520.0
const MIN_SQUARE_SIZE := 12.0
const MAX_SQUARE_SIZE := 104.0
const MIN_GRID_GAP := 2
const MAX_GRID_GAP := 14

@onready var grid_root: GridContainer = %GridRoot
@onready var upgrade_grid_button: Button = %UpgradeGridButton
@onready var grid_v_box: VBoxContainer = %GridVBox
@onready var grid_area: Control = %GridArea

var square_button_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")
var square_buttons_by_id: Dictionary = {}


func _ready() -> void:
	EventBus.grid_changed.connect(rebuild)
	EventBus.squares_changed.connect(_on_squares_changed)
	ThemeSystem.theme_changed.connect(_on_theme_changed)

	upgrade_grid_button.pressed.connect(_on_upgrade_grid_button_pressed)

	grid_area.resized.connect(_on_grid_area_resized)

	_apply_theme()
	rebuild()

func _apply_theme() -> void:
	ThemeButtonHelper.apply_button_theme(upgrade_grid_button)
	ThemeLayoutHelper.apply_box_separation(grid_v_box, "section_gap")
	_apply_grid_sizing()

func _apply_grid_sizing() -> void:
	if grid_area == null or grid_root == null:
		return

	var grid_size: int = max(1, GameState.grid_size)
	var available_width: float = grid_area.size.x
	var available_height: float = grid_area.size.y

	if available_width <= 0.0 or available_height <= 0.0:
		return

	var target_grid_area: float = min(
		available_width,
		available_height,
		MAX_GRID_AREA_SIZE
	)

	var gap: int = _calculate_grid_gap(grid_size)
	var total_gap_size: float = float(max(0, grid_size - 1) * gap)
	var square_size: float = floor((target_grid_area - total_gap_size) / float(grid_size))

	square_size = clamp(square_size, MIN_SQUARE_SIZE, MAX_SQUARE_SIZE)

	grid_root.add_theme_constant_override("h_separation", gap)
	grid_root.add_theme_constant_override("v_separation", gap)

	for square_id: String in square_buttons_by_id.keys():
		var square_button: SquareButton = square_buttons_by_id.get(square_id) as SquareButton

		if square_button == null:
			continue

		square_button.custom_minimum_size = Vector2(square_size, square_size)
		square_button.size = Vector2(square_size, square_size)
		square_button.apply_responsive_visual_size(square_size)

func _calculate_grid_gap(grid_size: int) -> int:
	if grid_size <= 3:
		return MAX_GRID_GAP

	if grid_size <= 6:
		return 8

	if grid_size <= 12:
		return 4

	return MIN_GRID_GAP
		
func _on_grid_area_resized() -> void:
	_apply_grid_sizing()

func _on_theme_changed() -> void:
	_apply_theme()
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

	_apply_grid_sizing()
	_refresh_upgrade_button()

func refresh_buttons() -> void:
	for square_id: String in square_buttons_by_id.keys():
		var square_button: SquareButton = square_buttons_by_id.get(square_id) as SquareButton
		var square_data: SquareData = GameState.get_square(square_id)

		if square_button == null or square_data == null:
			continue

		square_button.set_square_data(square_data)

	_refresh_upgrade_button()
	_apply_grid_sizing()


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
