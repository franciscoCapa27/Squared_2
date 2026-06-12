extends Control

@onready var squares_label: Label = %SquaresLabel
@onready var vertices_label: Label = %VerticesLabel
@onready var prestige_button: Button = %PrestigeButton
@onready var prestige_title: Label = %PrestigeTitle
@onready var prestige_description: Label = %PrestigeDescription
@onready var story_label: Label = %StoryLabel
@onready var story_panel: PanelContainer = %StoryPanel
@onready var story_margin: MarginContainer = %StoryMargin

@onready var grid_tab_button: Button = %GridTabButton
@onready var vertex_shop_tab_button: Button = %VertexShopTabButton
@onready var options_tab_button: Button = %OptionsTabButton
@onready var achievements_tab_button: Button = %AchievementsTabButton

@onready var grid_page: GridPage = %GridPage
@onready var vertex_shop_page: VertexShopPage = %VertexShopPage
@onready var options_page: OptionsPage = %OptionsPage
@onready var achievements_page: AchievementsPage = %AchievementsPage

@onready var passive_panel: PassivePanel = %PassivePanel
@onready var square_details_panel: SquareDetailsPanel = %SquareDetailsPanel

@onready var run_upgrades_panel: RunUpgradesPanel = %RunUpgradesPanel

@onready var stats_tab_button: Button = %StatsTabButton
@onready var stats_page: Control = %StatsPage

@onready var root_margin: MarginContainer = %RootMargin
@onready var main_v_box: VBoxContainer = %MainVBox
@onready var top_bar: PanelContainer = %TopBar
@onready var body_h_box: HBoxContainer = %BodyHBox
@onready var left_panel: VBoxContainer = %LeftPanel
@onready var right_panel: VBoxContainer = %RightPanel
@onready var center_page_root: Control = %CenterPageRoot

@onready var prestige_panel: PanelContainer = %PrestigePanel
@onready var prestige_details: Label = %PrestigeDetails

@onready var achievement_summary_panel: PanelContainer = %AchievementSummaryPanel
@onready var achievement_summary_label: Label = %AchievementSummaryLabel
@onready var achievement_summary_button: Button = %AchievementSummaryButton


func _ready() -> void:
	_connect_global_signals()
	_connect_ui_signals()
	_connect_page_signals()

	_apply_theme()

	_show_center_page("grid")
	_on_story_message("There is a square.")

	var loaded: bool = SaveSystem.load_game()

	if loaded:
		_refresh_all_ui()
	else:
		_initialize_new_game_ui()


# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
func _apply_theme() -> void:
	ThemeLayoutHelper.apply_margin(root_margin, "screen_margin")
	ThemeLayoutHelper.apply_box_separation(main_v_box, "panel_gap")
	ThemeLayoutHelper.apply_box_separation(body_h_box, "panel_gap")
	ThemeLayoutHelper.apply_box_separation(left_panel, "panel_gap")
	ThemeLayoutHelper.apply_box_separation(right_panel, "panel_gap")

	top_bar.add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())
	prestige_panel.add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
	achievement_summary_panel.add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())

	ThemeButtonHelper.apply_button_theme(prestige_button)
	ThemeButtonHelper.apply_button_theme(grid_tab_button)
	ThemeButtonHelper.apply_button_theme(vertex_shop_tab_button)
	ThemeButtonHelper.apply_button_theme(stats_tab_button)
	ThemeButtonHelper.apply_button_theme(options_tab_button)
	ThemeButtonHelper.apply_button_theme(achievements_tab_button)
	ThemeButtonHelper.apply_button_theme(achievement_summary_button)

	ThemeTextHelper.apply_resource_label(squares_label)
	ThemeTextHelper.apply_resource_label(vertices_label)
	ThemeTextHelper.apply_body_label(story_label)
	ThemeTextHelper.apply_panel_title(prestige_title)
	ThemeTextHelper.apply_body_label(prestige_description)
	ThemeTextHelper.apply_detail_label(prestige_details)
	ThemeTextHelper.apply_body_label(achievement_summary_label)
	story_panel.add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
	ThemeLayoutHelper.apply_margin(story_margin, "inner_margin")
	ThemeTextHelper.apply_detail_label(story_label)

func _on_theme_changed() -> void:
	_apply_theme()
func _connect_global_signals() -> void:
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.vertices_changed.connect(_on_vertices_changed)
	EventBus.story_message.connect(_on_story_message)

	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)
	AchievementSystem.achievements_changed.connect(_on_achievements_changed)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	ThemeSystem.theme_changed.connect(_on_theme_changed)



func _connect_ui_signals() -> void:
	prestige_button.pressed.connect(_on_prestige_pressed)

	grid_tab_button.pressed.connect(_on_grid_tab_pressed)
	vertex_shop_tab_button.pressed.connect(_on_vertex_shop_tab_pressed)
	stats_tab_button.pressed.connect(_on_stats_tab_pressed)
	options_tab_button.pressed.connect(_on_options_tab_pressed)
	achievements_tab_button.pressed.connect(_on_achievements_tab_pressed)

	achievement_summary_button.pressed.connect(_on_achievements_tab_pressed)

func _connect_page_signals() -> void:
	grid_page.square_selected.connect(_on_grid_square_selected)
	grid_page.grid_upgrade_requested.connect(_on_grid_upgrade_requested)

	vertex_shop_page.vertex_upgrade_purchased.connect(_on_vertex_upgrade_purchased)
	passive_panel.passive_generator_upgraded.connect(_on_passive_generator_upgraded)

	options_page.save_imported.connect(_on_options_save_imported)
	options_page.hard_reset_completed.connect(_on_options_hard_reset_completed)

func _initialize_new_game_ui() -> void:
	_refresh_labels()
	_refresh_prestige_panel()
	_refresh_achievement_summary()

	grid_page.rebuild()
	_refresh_vertex_shop()
	_refresh_passive_panel()

	options_page.refresh()
	achievements_page.refresh()
	square_details_panel.clear()
	run_upgrades_panel.refresh()


# ------------------------------------------------------------------------------
# Global UI Refresh
# ------------------------------------------------------------------------------

func _refresh_all_ui() -> void:
	_refresh_labels()
	_refresh_prestige_panel()
	_refresh_achievement_summary()

	grid_page.rebuild()
	_refresh_vertex_shop()
	_refresh_passive_panel()

	options_page.refresh()
	achievements_page.refresh()
	square_details_panel.refresh()
	run_upgrades_panel.refresh()


func _refresh_labels() -> void:
	_on_squares_changed(GameState.squares)
	_on_vertices_changed(GameState.vertices)


func _refresh_vertex_shop() -> void:
	vertex_shop_page.refresh()


func _refresh_passive_panel() -> void:
	passive_panel.refresh()


# ------------------------------------------------------------------------------
# Tabs
# ------------------------------------------------------------------------------

func _show_center_page(page_id: String) -> void:
	grid_page.visible = page_id == "grid"
	vertex_shop_page.visible = page_id == "vertex_shop"
	options_page.visible = page_id == "options"
	achievements_page.visible = page_id == "achievements"
	stats_page.visible = page_id == "stats"

	grid_tab_button.disabled = page_id == "grid"
	vertex_shop_tab_button.disabled = page_id == "vertex_shop"
	options_tab_button.disabled = page_id == "options"
	achievements_tab_button.disabled = page_id == "achievements"
	stats_tab_button.disabled = page_id == "stats"

	if page_id == "achievements":
		achievements_page.refresh()
	elif page_id == "options":
		options_page.refresh()
	elif page_id == "vertex_shop":
		_refresh_vertex_shop()


func _on_grid_tab_pressed() -> void:
	_show_center_page("grid")


func _on_vertex_shop_tab_pressed() -> void:
	_show_center_page("vertex_shop")
	vertex_shop_page.refresh()


func _on_options_tab_pressed() -> void:
	_show_center_page("options")
	options_page.refresh()


func _on_achievements_tab_pressed() -> void:
	_show_center_page("achievements")
	achievements_page.refresh()

func _on_stats_tab_pressed() -> void:
	_show_center_page("stats")
# ------------------------------------------------------------------------------
# Resource Labels / Story
# ------------------------------------------------------------------------------

func _on_squares_changed(value: float) -> void:
	squares_label.text = "Squares: %s" % NumberFormatter.amount(value)
	prestige_button.disabled = not GameState.can_prestige()

	_refresh_prestige_panel()
	_refresh_passive_panel()


func _on_vertices_changed(value: int) -> void:
	vertices_label.text = "Vertices: %s" % NumberFormatter.integer_amount(value)
	_refresh_vertex_shop()
	_refresh_prestige_panel()





func _on_story_message(message: String) -> void:
	story_label.text = message

func _refresh_prestige_panel() -> void:
	var vertices_gain: int = max(1, GameState.calculate_vertices_gain())

	if GameState.can_prestige():
		prestige_button.text = "Prestige"
		prestige_details.text = "Gain %s Vertices • Roll 1 Trait • Reset run upgrades & passives" % [
			NumberFormatter.integer_amount(vertices_gain)
		]
	else:
		prestige_button.text = "Prestige"
		prestige_details.text = "Requires %s Squares • Roll 1 Trait • Reset run upgrades & passives" % [
			NumberFormatter.amount(GameState.PRESTIGE_REQUIRED_SQUARES)
		]
		
func _refresh_achievement_summary() -> void:
	var unlocked_count: int = AchievementSystem.get_unlocked_count()
	var total_count: int = AchievementDatabase.get_all_achievements().size()

	achievement_summary_label.text = "%s / %s unlocked" % [
		NumberFormatter.integer_amount(unlocked_count),
		NumberFormatter.integer_amount(total_count)
	]
# ------------------------------------------------------------------------------
# Player Actions
# ------------------------------------------------------------------------------

func _on_prestige_pressed() -> void:
	GameState.prestige()


func _on_grid_square_selected(square_id: String) -> void:
	square_details_panel.show_square(square_id)

func _on_grid_upgrade_requested() -> void:
	var upgraded: bool = GameState.upgrade_grid()

	if not upgraded:
		return

	square_details_panel.clear()
	_refresh_labels()
# ------------------------------------------------------------------------------
# Page Events
# ------------------------------------------------------------------------------

func _on_vertex_upgrade_purchased(_upgrade_id: String) -> void:
	_refresh_vertex_shop()
	_refresh_passive_panel()
	grid_page.refresh_buttons()
	square_details_panel.refresh()


func _on_passive_generator_upgraded(_generator_id: String) -> void:
	_refresh_passive_panel()
	square_details_panel.refresh()
	run_upgrades_panel.refresh()


func _on_options_save_imported() -> void:
	_refresh_all_ui()


func _on_options_hard_reset_completed() -> void:
	square_details_panel.clear()
	_refresh_all_ui()


# ------------------------------------------------------------------------------
# System Events
# ------------------------------------------------------------------------------

func _on_passive_pulsed(_generator_id: String, square_id: String, _payout: float) -> void:
	square_details_panel.refresh_if_selected(square_id)


func _on_achievements_changed() -> void:
	achievements_page.refresh()
	square_details_panel.refresh()
	grid_page.refresh_buttons()
	run_upgrades_panel.refresh()
	_refresh_achievement_summary()


func _on_save_loaded() -> void:
	_refresh_all_ui()
