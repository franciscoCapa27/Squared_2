extends Control

@onready var squares_label: Label = %SquaresLabel
@onready var vertices_label: Label = %VerticesLabel
@onready var prestige_label: Label = %PrestigeLabel
@onready var grid_root: GridContainer = %GridRoot
@onready var prestige_button: Button = %PrestigeButton
@onready var story_label: Label = %StoryLabel
@onready var selected_square_title: Label = %SelectedSquareTitle
@onready var selected_square_details: RichTextLabel = %SelectedSquareDetails
@onready var grid_tab_button: Button = %GridTabButton
@onready var vertex_shop_tab_button: Button = %VertexShopTabButton
@onready var options_tab_button: Button = %OptionsTabButton
@onready var achievements_tab_button: Button = %AchievementsTabButton

@onready var passive_status_label: RichTextLabel = %PassiveStatusLabel
@onready var passive_progress_bar: ProgressBar = %PassiveProgressBar
@onready var upgrade_first_generator_button: Button = %UpgradeFirstGeneratorButton

@onready var grid_page: Control = %GridPage
@onready var vertex_shop_page: Control = %VertexShopPage

@onready var unlock_first_generator_button: Button = %UnlockFirstGeneratorButton
@onready var vertex_shop_description: RichTextLabel = %VertexShopDescription

var square_scene: PackedScene = preload("res://scenes/squares/SquareButton.tscn")
var selected_square_id: String = ""

func _ready() -> void:
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.vertices_changed.connect(_on_vertices_changed)
	EventBus.prestige_changed.connect(_on_prestige_changed)
	EventBus.grid_changed.connect(_rebuild_grid)
	EventBus.story_message.connect(_on_story_message)

	prestige_button.pressed.connect(_on_prestige_pressed)
	grid_tab_button.pressed.connect(_on_grid_tab_pressed)
	vertex_shop_tab_button.pressed.connect(_on_vertex_shop_tab_pressed)

	unlock_first_generator_button.pressed.connect(_on_unlock_first_generator_pressed)
	upgrade_first_generator_button.pressed.connect(_on_upgrade_first_generator_pressed)

	PassiveSystem.passive_state_changed.connect(_refresh_passive_panel)
	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)

	_rebuild_grid()
	_refresh_labels()
	_show_center_page("grid")
	_refresh_vertex_shop()
	_refresh_passive_panel()
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
	selected_square_id = square_id
	GameState.click_square(square_id)
	_show_square_details(square_id)
	
func _show_square_details(square_id: String) -> void:
	var square_data := GameState.get_square(square_id)

	if square_data == null:
		selected_square_title.text = "Unknown Square"
		selected_square_details.text = "No data found."
		return

	selected_square_title.text = square_data.get_display_name()

	var trait_text: String = square_data.get_trait_stack_display_text()
	var trait_effect_text: String = square_data.get_trait_effect_summary_text()

	var manual_payout := SquareCalculator.calculate_manual_payout(square_data)
	var respawn_time := SquareCalculator.calculate_respawn_time(square_data)

	selected_square_details.text = (
	"Coordinate: %s\n\n" % square_data.coordinate
	+ "Trait Stacks: %s\n\n" % trait_text
	+ "Trait Rolls:\n%s\n\n" % trait_effect_text
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
	_refresh_passive_panel()

func _on_vertices_changed(value: int) -> void:
	vertices_label.text = "Vertices: %s" % value
	_refresh_vertex_shop()

func _on_prestige_changed(value: int) -> void:
	prestige_label.text = "Prestiges: %s" % value

func _on_story_message(message: String) -> void:
	story_label.text = message
	
func _show_center_page(page_id: String) -> void:
	grid_page.visible = page_id == "grid"
	vertex_shop_page.visible = page_id == "vertex_shop"

	grid_tab_button.disabled = page_id == "grid"
	vertex_shop_tab_button.disabled = page_id == "vertex_shop"

func _on_grid_tab_pressed() -> void:
	_show_center_page("grid")

func _on_vertex_shop_tab_pressed() -> void:
	_show_center_page("vertex_shop")

func _refresh_vertex_shop() -> void:
	var can_unlock_generator: bool = GameState.can_buy_vertex_upgrade("unlock_first_generator")
	var has_generator: bool = GameState.has_vertex_upgrade("unlock_first_generator")

	unlock_first_generator_button.disabled = not can_unlock_generator

	if has_generator:
		unlock_first_generator_button.text = "First Generator Unlocked"
		vertex_shop_description.text = "The first generator is active. It extracts Squares automatically."
	else:
		unlock_first_generator_button.text = "Unlock First Generator — 1 Vertex"
		vertex_shop_description.text = (
			"Spend 1 Vertex to awaken the first passive generator.\n\n"
			+ "It pulses every 2.5 seconds and extracts 25% of a random square's current manual payout.\n"
			+ "Passive extraction does not trigger square respawn."
		)

func _on_unlock_first_generator_pressed() -> void:
	var bought: bool = GameState.buy_vertex_upgrade("unlock_first_generator")

	if bought:
		_refresh_vertex_shop()
		_refresh_passive_panel()
		
func _refresh_passive_panel() -> void:
	var generator_data: PassiveGeneratorData = PassiveSystem.first_generator

	if not generator_data.is_unlocked:
		passive_status_label.visible = true
		passive_status_label.text = (
			"No passive systems unlocked.\n\n"
			+ "Prestige and spend Vertices to awaken automation."
		)
		passive_progress_bar.value = 0.0
		passive_progress_bar.visible = false
		upgrade_first_generator_button.visible = false
		return

	upgrade_first_generator_button.visible = true
	upgrade_first_generator_button.disabled = not PassiveSystem.can_upgrade_first_generator()

	if generator_data.level >= generator_data.max_level:
		upgrade_first_generator_button.text = "Max Level"
	else:
		upgrade_first_generator_button.text = "Buy Level %s — %s Squares" % [
			generator_data.level + 1,
			generator_data.get_next_level_cost()
		]

	if not generator_data.is_active():
		passive_progress_bar.value = 0.0
		passive_progress_bar.visible = false

		passive_status_label.text = (
			"%s\n" % generator_data.display_name
			+ "Unlocked, inactive this run.\n\n"
			+ "Level: 0 / %s\n" % generator_data.max_level
			+ "Buy Level 1 to start passive generation.\n\n"
			+ "Level 1:\n"
			+ "- Interval: %.2fs\n" % generator_data.base_interval_seconds
			+ "- Extraction: %.0f%%\n\n" % (generator_data.base_extraction_rate * 100.0)
			+ "Run levels reset on prestige."
		)
		return

	passive_progress_bar.visible = true
	passive_progress_bar.value = generator_data.get_progress_ratio()

	var last_pulse_text: String = "None"

	if generator_data.last_target_square_id != "":
		last_pulse_text = "+%.2f Squares from %s" % [
			generator_data.last_payout,
			generator_data.last_target_square_id
		]

	var upgrade_text: String = "Max level reached"

	if generator_data.level < generator_data.max_level:
		upgrade_text = "Next Level Cost: %s Squares" % generator_data.get_next_level_cost()

	passive_status_label.text = (
		"%s\n" % generator_data.display_name
		+ "Level: %s / %s\n\n" % [
			generator_data.level,
			generator_data.max_level
		]
		+ "Interval: %.2fs\n" % generator_data.get_current_interval_seconds()
		+ "Extraction: %.0f%%\n" % (generator_data.get_current_extraction_rate() * 100.0)
		+ "Targeting: Random square\n\n"
		+ "Last Pulse: %s\n" % last_pulse_text
		+ "Lifetime Pulses This Run: %s\n" % generator_data.lifetime_pulses
		+ "Squares This Run: %.2f\n\n" % generator_data.lifetime_squares_generated
		+ upgrade_text
	)

func _on_passive_pulsed(generator_id: String, square_id: String, payout: float) -> void:
	_refresh_passive_panel()

	if selected_square_id != "":
		_show_square_details(selected_square_id)

func _on_upgrade_first_generator_pressed() -> void:
	var upgraded: bool = PassiveSystem.upgrade_first_generator()

	if upgraded:
		_refresh_passive_panel()

	if selected_square_id != "":
		_show_square_details(selected_square_id)
