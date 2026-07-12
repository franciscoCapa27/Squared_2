extends Control
class_name GridPage

signal square_selected(square_id: String)
signal grid_upgrade_requested()

const MAX_GRID_AREA_SIZE := 430.0
const MIN_SQUARE_SIZE := 8.0
const MAX_SQUARE_SIZE := 82.0
const MIN_GRID_GAP := 1
const MAX_GRID_GAP := 10

@onready var grid_root: GridContainer = %GridRoot
@onready var upgrade_grid_button: Button = %UpgradeGridButton
@onready var grid_v_box: VBoxContainer = %GridVBox
@onready var grid_area: Control = %GridArea
@onready var grid_upgrade_feature_visibility: FeaturePanelVisibility = %GridUpgradeFeatureVisibility

var square_button_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")
var square_buttons_by_id: Dictionary = {}
var has_discovered_current_grid_upgrade: bool = false
var discovered_grid_size: int = GameState.INITIAL_GRID_SIZE

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

	var final_grid_pixel_size: float = square_size * float(grid_size) + total_gap_size

	grid_root.custom_minimum_size = Vector2(
		final_grid_pixel_size,
		final_grid_pixel_size
	)

	grid_root.add_theme_constant_override("h_separation", gap)
	grid_root.add_theme_constant_override("v_separation", gap)

	for square_id: String in square_buttons_by_id.keys():
		var square_button: SquareButton = square_buttons_by_id.get(square_id) as SquareButton

		if square_button == null:
			continue

		var button_size := Vector2(square_size, square_size)
		square_button.custom_minimum_size = button_size
		square_button.size = button_size
		square_button.apply_responsive_visual_size(square_size)

func refresh_feature_visibility(animated: bool = true) -> void:
	if GameState.grid_size >= GameState.MAX_GRID_SIZE:
		has_discovered_current_grid_upgrade = false
		discovered_grid_size = GameState.grid_size
		grid_upgrade_feature_visibility.set_feature_visible(false, animated)
		return

	if discovered_grid_size != GameState.grid_size:
		has_discovered_current_grid_upgrade = false
		discovered_grid_size = GameState.grid_size

	var should_discover: bool = FeatureVisibilityRules.should_show_grid_upgrade_button()

	if should_discover:
		has_discovered_current_grid_upgrade = true

	grid_upgrade_feature_visibility.set_feature_visible(
		has_discovered_current_grid_upgrade,
		animated
	)
	
func reset_feature_visibility_state() -> void:
	has_discovered_current_grid_upgrade = false
	discovered_grid_size = GameState.grid_size

	if grid_upgrade_feature_visibility != null:
		grid_upgrade_feature_visibility.set_feature_visible(false, false)
	
	
func _calculate_grid_gap(grid_size: int) -> int:
	if grid_size <= 2:
		return 10

	if grid_size <= 4:
		return 8

	if grid_size <= 6:
		return 6

	if grid_size <= 12:
		return 3

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

		square_button.setup(square_data.id)
		square_button.set_square_data(square_data)
		square_button.square_clicked.connect(_on_square_button_clicked)

		square_buttons_by_id[square_data.id] = square_button

	_apply_grid_sizing()
	call_deferred("_apply_grid_sizing")
	_refresh_upgrade_button()
	refresh_feature_visibility(false)

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

	upgrade_grid_button.text = "Open %sx%s Grid — %s Squares" % [
		next_grid_size,
		next_grid_size,
		NumberFormatter.cost(cost)
	]

	upgrade_grid_button.disabled = not GameState.can_upgrade_grid()
	upgrade_grid_button.tooltip_text = "%s Cost: %s Squares" % [
		_get_grid_upgrade_hint_text(next_grid_size),
		NumberFormatter.cost(cost)
	]
	refresh_feature_visibility(true)


func _get_grid_upgrade_hint_text(next_grid_size: int) -> String:
	match next_grid_size:
		2:
			return "More squares. Stranger Traits may begin to answer."
		3:
			return "The grid deepens again. Rarer patterns may wake."
		4:
			return "The shape grows wider, and stranger histories can form."
		5:
			return "The board is nearly a constellation of choices."
		6:
			return "The largest known grid waits beyond this price."
		_:
			return "A larger grid opens more possibilities."


func _on_square_button_clicked(square_id: String) -> void:
	GameState.click_square(square_id)
	square_selected.emit(square_id)
	


func _on_upgrade_grid_button_pressed() -> void:
	grid_upgrade_requested.emit()


func _on_squares_changed(_value: float) -> void:
	_refresh_upgrade_button()
	refresh_feature_visibility(false)
