extends Control

@onready var squares_label: Label = %SquaresLabel
@onready var vertices_label: Label = %VerticesLabel
@onready var prestige_label: Label = %PrestigeLabel
@onready var grid_root: GridContainer = %GridRoot
@onready var prestige_button: Button = %PrestigeButton
@onready var story_label: Label = %StoryLabel
@onready var selected_square_title: Label = %SelectedSquareTitle
@onready var selected_square_details: RichTextLabel = %SelectedSquareDetails

var square_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")

func _ready() -> void:
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.vertices_changed.connect(_on_vertices_changed)
	EventBus.prestige_changed.connect(_on_prestige_changed)
	EventBus.grid_changed.connect(_rebuild_grid)
	EventBus.story_message.connect(_on_story_message)

	prestige_button.pressed.connect(_on_prestige_pressed)

	_rebuild_grid()
	_refresh_labels()
	_on_story_message("There is a square.")

func _refresh_labels() -> void:
	_on_squares_changed(GameState.squares)
	_on_vertices_changed(GameState.vertices)
	_on_prestige_changed(GameState.prestige_count)

func _rebuild_grid() -> void:
	for child in grid_root.get_children():
		child.queue_free()

	grid_root.columns = GameState.grid_size

	for square_id in GameState.square_ids:
		var square_button = square_scene.instantiate()
		square_button.setup(square_id, "■")
		square_button.square_clicked.connect(_on_square_clicked)
		grid_root.add_child(square_button)
		square_button.refresh_visuals()

func _on_square_clicked(square_id: String) -> void:
	GameState.click_square(square_id)
	_show_square_details(square_id)
	
func _show_square_details(square_id: String) -> void:
	var square_data := GameState.get_square(square_id)

	if square_data == null:
		selected_square_title.text = "Unknown Square"
		selected_square_details.text = "No data found."
		return

	selected_square_title.text = square_data.get_display_name()

	var trait_text := square_data.get_trait_stack_display_text()

	var manual_payout := SquareCalculator.calculate_manual_payout(square_data)
	var respawn_time := SquareCalculator.calculate_respawn_time(square_data)

	selected_square_details.text = (
		"Coordinate: %s\n\n" % square_data.coordinate
		+ "Traits: %s\n" % trait_text
		+ "Current Manual Payout: %.2f Squares\n" % manual_payout
		+ "Current Respawn Time: %.2fs\n\n" % respawn_time
		+ "Lifetime Squares: %.2f\n" % square_data.lifetime_squares_generated
		+ "Manual Clicks: %s\n" % square_data.lifetime_manual_clicks
		+ "Base Value: %.2f\n" % square_data.base_value
		+ "Base Respawn Time: %.2fs\n\n" % square_data.base_respawn_time
		+ "Dominant Tag: %s\n" % square_data.visual_profile.dominant_tag
		+ "Secondary Tag: %s\n" % square_data.visual_profile.secondary_tag
		+ "Glow Level: %s\n" % square_data.visual_profile.glow_level
		+ "Edge Complexity: %s\n" % square_data.visual_profile.edge_complexity
	)

func _on_prestige_pressed() -> void:
	GameState.prestige()

func _on_squares_changed(value: float) -> void:
	squares_label.text = "Squares: %s" % int(value)
	prestige_button.disabled = not GameState.can_prestige()

func _on_vertices_changed(value: int) -> void:
	vertices_label.text = "Vertices: %s" % value

func _on_prestige_changed(value: int) -> void:
	prestige_label.text = "Prestiges: %s" % value

func _on_story_message(message: String) -> void:
	story_label.text = message
