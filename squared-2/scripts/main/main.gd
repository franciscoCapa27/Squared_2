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

@onready var grid_page: Control = %GridPage
@onready var vertex_shop_page: Control = %VertexShopPage

@onready var vertex_shop_description: RichTextLabel = %VertexShopDescription
@onready var vertex_upgrade_list: VBoxContainer = %VertexUpgradeList
@onready var passive_generator_list: VBoxContainer = %PassiveGeneratorList

@onready var options_page: OptionsPage = %OptionsPage

var passive_generator_card_scene: PackedScene = preload("res://scenes/ui/PassiveGeneratorCard.tscn")
var passive_generator_cards: Dictionary = {}

var vertex_upgrade_card_scene: PackedScene = preload("res://scenes/ui/VertexUpgradeCard.tscn")
var vertex_upgrade_cards: Dictionary = {}

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

	PassiveSystem.passive_state_changed.connect(_refresh_passive_panel)
	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)
	
	options_tab_button.pressed.connect(_on_options_tab_pressed)

	options_page.save_imported.connect(_on_options_save_imported)
	options_page.hard_reset_completed.connect(_on_options_hard_reset_completed)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	
	_rebuild_grid()
	_refresh_labels()
	_show_center_page("grid")
	_refresh_vertex_shop()
	_refresh_passive_panel()
	_on_story_message("There is a square.")
	var loaded: bool = SaveSystem.load_game()

	if not loaded:
		_refresh_labels()
		_rebuild_grid()
		_refresh_vertex_shop()
		_refresh_passive_panel()
	options_page.refresh()

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
	var square_data : SquareData = GameState.get_square(square_id) as SquareData

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
	+ "Permanent Base Value Multiplier: x%.2f\n" % GameState.get_permanent_stat_multiplier("square_base_value")
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
	options_page.visible = page_id == "options"

	grid_tab_button.disabled = page_id == "grid"
	vertex_shop_tab_button.disabled = page_id == "vertex_shop"
	options_tab_button.disabled = page_id == "options"
	
func _on_options_tab_pressed() -> void:
	_show_center_page("options")
	options_page.refresh()

func _on_grid_tab_pressed() -> void:
	_show_center_page("grid")

func _on_vertex_shop_tab_pressed() -> void:
	_show_center_page("vertex_shop")

func _refresh_vertex_shop() -> void:
	_rebuild_vertex_upgrade_list()
	
func _rebuild_vertex_upgrade_list() -> void:
	for child in vertex_upgrade_list.get_children():
		child.queue_free()

	vertex_upgrade_cards.clear()

	var visible_upgrades: Array[VertexUpgradeDefinition] = VertexUpgradeDatabase.get_visible_upgrades()

	if visible_upgrades.is_empty():
		vertex_shop_description.text = "No Vertex upgrades available yet."
		return

	vertex_shop_description.text = "Spend Vertices on permanent systems."

	for upgrade: VertexUpgradeDefinition in visible_upgrades:
		var card : VertexUpgradeCard = vertex_upgrade_card_scene.instantiate() as VertexUpgradeCard 
		vertex_upgrade_list.add_child(card)

		card.setup(upgrade)
		card.buy_requested.connect(_on_vertex_upgrade_buy_requested)

		vertex_upgrade_cards[upgrade.id] = card

func _on_vertex_upgrade_buy_requested(upgrade_id: String) -> void:
	var bought: bool = GameState.buy_vertex_upgrade(upgrade_id)

	if bought:
		_refresh_vertex_shop()
		_refresh_passive_panel()
func _on_unlock_first_generator_pressed() -> void:
	var bought: bool = GameState.buy_vertex_upgrade("unlock_first_generator")

	if bought:
		_refresh_vertex_shop()
		_refresh_passive_panel()
		
func _refresh_passive_panel() -> void:
	var unlocked_generators: Array[PassiveGeneratorInstance] = PassiveSystem.get_unlocked_generator_instances()

	if unlocked_generators.is_empty():
		if passive_generator_cards.is_empty() and passive_generator_list.get_child_count() > 0:
			return

		_rebuild_passive_generator_list()
		return

	if unlocked_generators.size() != passive_generator_cards.size():
		_rebuild_passive_generator_list()
		return

	for generator_instance: PassiveGeneratorInstance in unlocked_generators:
		var card: PassiveGeneratorCard = passive_generator_cards.get(generator_instance.get_id())

		if card == null:
			_rebuild_passive_generator_list()
			return

		card.refresh()

func _on_passive_pulsed(generator_id: String, square_id: String, payout: float) -> void:
	_refresh_passive_panel()

	if selected_square_id != "":
		_show_square_details(selected_square_id)
func _rebuild_passive_generator_list() -> void:
	for child: Node in passive_generator_list.get_children():
		child.queue_free()

	passive_generator_cards.clear()

	var unlocked_generators: Array[PassiveGeneratorInstance] = PassiveSystem.get_unlocked_generator_instances()

	if unlocked_generators.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No passive systems unlocked.\n\nPrestige and spend Vertices to awaken automation."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive_generator_list.add_child(empty_label)
		return

	for generator_instance: PassiveGeneratorInstance in unlocked_generators:
		var card: PassiveGeneratorCard = passive_generator_card_scene.instantiate() as PassiveGeneratorCard
		passive_generator_list.add_child(card)

		card.setup(generator_instance.get_id())
		card.upgrade_requested.connect(_on_passive_generator_upgrade_requested)

		passive_generator_cards[generator_instance.get_id()] = card

func _on_passive_generator_upgrade_requested(generator_id: String) -> void:
	var upgraded: bool = PassiveSystem.upgrade_generator(generator_id)

	if upgraded:
		_refresh_passive_panel()

	if selected_square_id != "":
		_show_square_details(selected_square_id)
		
func _on_save_loaded() -> void:
	_refresh_all_ui()
	
func _on_options_save_imported() -> void:
	_refresh_all_ui()


func _on_options_hard_reset_completed() -> void:
	selected_square_id = ""
	_refresh_all_ui()

func _refresh_all_ui() -> void:
	_refresh_labels()
	_rebuild_grid()
	_refresh_vertex_shop()
	_refresh_passive_panel()
	options_page.refresh()

	if selected_square_id != "":
		_show_square_details(selected_square_id)
