extends Control

@onready var squares_label: Label = %SquaresLabel
@onready var vertices_label: Label = %VerticesLabel
@onready var prestige_label: Label = %PrestigeLabel
@onready var prestige_button: Button = %PrestigeButton
@onready var story_label: Label = %StoryLabel
@onready var grid_tab_button: Button = %GridTabButton
@onready var vertex_shop_tab_button: Button = %VertexShopTabButton
@onready var options_tab_button: Button = %OptionsTabButton
@onready var achievements_tab_button: Button = %AchievementsTabButton
@onready var achievements_page: AchievementsPage = %AchievementsPage
@onready var grid_page: Control = %GridPage

@onready var options_page: OptionsPage = %OptionsPage
@onready var passive_panel: PassivePanel = %PassivePanel
@onready var vertex_shop_page: VertexShopPage = %VertexShopPage

@onready var square_details_panel: SquareDetailsPanel = %SquareDetailsPanel


func _ready() -> void:
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.vertices_changed.connect(_on_vertices_changed)
	EventBus.prestige_changed.connect(_on_prestige_changed)
	EventBus.story_message.connect(_on_story_message)

	prestige_button.pressed.connect(_on_prestige_pressed)
	grid_tab_button.pressed.connect(_on_grid_tab_pressed)
	vertex_shop_tab_button.pressed.connect(_on_vertex_shop_tab_pressed)
	vertex_shop_page.vertex_upgrade_purchased.connect(_on_vertex_upgrade_purchased)
	passive_panel.passive_generator_upgraded.connect(_on_passive_generator_upgraded)
	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)
	
	options_tab_button.pressed.connect(_on_options_tab_pressed)
	achievements_tab_button.pressed.connect(_on_achievements_tab_pressed)
	AchievementSystem.achievements_changed.connect(_on_achievements_changed)
	options_page.save_imported.connect(_on_options_save_imported)
	options_page.hard_reset_completed.connect(_on_options_hard_reset_completed)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	grid_page.square_selected.connect(_on_grid_square_selected)
	grid_page.rebuild()
	_refresh_labels()
	_show_center_page("grid")
	_refresh_vertex_shop()
	_refresh_passive_panel()
	_on_story_message("There is a square.")
	var loaded: bool = SaveSystem.load_game()

	if not loaded:
		_refresh_labels()
		grid_page.rebuild()
		_refresh_vertex_shop()
		_refresh_passive_panel()
	options_page.refresh()

func _refresh_labels() -> void:
	_on_squares_changed(GameState.squares)
	_on_vertices_changed(GameState.vertices)
	_on_prestige_changed(GameState.prestige_count)


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
	
func _on_achievements_tab_pressed() -> void:
	_show_center_page("achievements")
	achievements_page.refresh()
func _on_achievements_changed() -> void:
	achievements_page.refresh()
	square_details_panel.refresh()
	grid_page.refresh_buttons()
	
func _show_center_page(page_id: String) -> void:
	grid_page.visible = page_id == "grid"
	vertex_shop_page.visible = page_id == "vertex_shop"
	options_page.visible = page_id == "options"
	achievements_page.visible = page_id == "achievements"

	grid_tab_button.disabled = page_id == "grid"
	vertex_shop_tab_button.disabled = page_id == "vertex_shop"
	options_tab_button.disabled = page_id == "options"
	achievements_tab_button.disabled = page_id == "achievements"
	
func _on_options_tab_pressed() -> void:
	_show_center_page("options")
	options_page.refresh()

func _on_grid_tab_pressed() -> void:
	_show_center_page("grid")

func _on_vertex_shop_tab_pressed() -> void:
	_show_center_page("vertex_shop")

func _refresh_vertex_shop() -> void:
	vertex_shop_page.refresh()
	
func _on_unlock_first_generator_pressed() -> void:
	var bought: bool = GameState.buy_vertex_upgrade(GameIds.UPGRADE_UNLOCK_FIRST_GENERATOR)

	if bought:
		_refresh_vertex_shop()
		_refresh_passive_panel()
		
func _refresh_passive_panel() -> void:
	passive_panel.refresh()

func _on_passive_pulsed(generator_id: String, square_id: String, payout: float) -> void:
	square_details_panel.refresh_if_selected(square_id)
		
func _on_save_loaded() -> void:
	_refresh_all_ui()
	
func _on_options_save_imported() -> void:
	_refresh_all_ui()

func _on_options_hard_reset_completed() -> void:
	square_details_panel.clear()
	_refresh_all_ui()

func _refresh_all_ui() -> void:
	_refresh_labels()
	grid_page.rebuild()
	_refresh_vertex_shop()
	_refresh_passive_panel()
	options_page.refresh()
	achievements_page.refresh()
	square_details_panel.refresh()

func _on_vertex_upgrade_purchased(upgrade_id: String) -> void:
	_refresh_vertex_shop()
	_refresh_passive_panel()
	grid_page.refresh_buttons()
	square_details_panel.refresh()


func _on_passive_generator_upgraded(generator_id: String) -> void:
	_refresh_passive_panel()
	square_details_panel.refresh()
		
func _on_grid_square_selected(square_id: String) -> void:
	square_details_panel.show_square(square_id)	
