extends Control

const COMPACT_LAYOUT_MAX_WIDTH := 900.0

@onready var squares_label: Label = %SquaresLabel
@onready var vertices_label: Label = %VerticesLabel
@onready var trait_purchase_button: Button = %BuyTraitButton
@onready var trait_purchase_description: Label = %BuyTraitDescription
@onready var trait_purchase_details: RichTextLabel = %BuyTraitDetails
@onready var trait_purchase_help: ContextualHelp = %BuyTraitHelp
@onready var story_label: Label = %StoryLabel
@onready var story_panel: PanelContainer = %StoryPanel
@onready var story_margin: MarginContainer = %StoryMargin
var has_discovered_trait_purchase_panel: bool = false
var grid_expansion_story_shown: bool = false
var vertex_shop_story_shown: bool = false
var passives_story_shown: bool = false


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
@onready var stats_page: StatsPage = %StatsPage

@onready var root_margin: MarginContainer = %RootMargin
@onready var main_v_box: VBoxContainer = %MainVBox
@onready var top_bar: PanelContainer = %TopBar
@onready var top_bar_margin: MarginContainer = %TopBarMargin
@onready var top_bar_hbox: HBoxContainer = %TopBarHBox
@onready var resource_cluster: HBoxContainer = %ResourceCluster
@onready var navigation_cluster: HBoxContainer = %NavigationCluster
@onready var body_h_box: HBoxContainer = %BodyHBox
@onready var left_panel: VBoxContainer = %LeftPanel
@onready var right_panel: VBoxContainer = %RightPanel
@onready var center_page_root: Control = %CenterPageRoot

@onready var trait_purchase_panel: PanelContainer = %BuyTraitPanel

@onready var achievement_summary_panel: PanelContainer = %AchievementSummaryPanel
@onready var achievement_summary_label: Label = %AchievementSummaryLabel
@onready var achievement_summary_button: Button = %AchievementSummaryButton

@onready var passive_feature_visibility: FeaturePanelVisibility = %PassiveFeatureVisibility
@onready var vertex_shop_feature_visibility: FeaturePanelVisibility = %VertexShopFeatureVisibility
@onready var trait_purchase_feature_visibility: FeaturePanelVisibility = %BuyTraitFeatureVisibility
@onready var run_upgrades_feature_visibility: FeaturePanelVisibility = %RunUpgradesFeatureVisibility
@onready var square_details_feature_visibility: FeaturePanelVisibility = %SquareDetailsFeatureVisibility
@onready var achievement_summary_feature_visibility: FeaturePanelVisibility = %AchievementSummaryFeatureVisibility

var _compact_layout_active: bool = false
var _compact_top_vbox: VBoxContainer = null
var _compact_navigation_vbox: VBoxContainer = null
var _compact_body_scroll: ScrollContainer = null
var _compact_body_vbox: VBoxContainer = null

func _ready() -> void:
	_connect_global_signals()
	_connect_ui_signals()
	_connect_page_signals()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_apply_theme()

	_show_center_page("grid")
	_on_story_message("There is only one square.")

	var loaded: bool = SaveSystem.load_game()

	if loaded:
		_refresh_all_ui()
	else:
		_initialize_new_game_ui()

	call_deferred("_apply_responsive_layout")


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
	trait_purchase_panel.add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
	achievement_summary_panel.add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())

	ThemeButtonHelper.apply_button_theme(trait_purchase_button)
	ThemeButtonHelper.apply_button_theme(grid_tab_button)
	ThemeButtonHelper.apply_button_theme(vertex_shop_tab_button)
	ThemeButtonHelper.apply_button_theme(stats_tab_button)
	ThemeButtonHelper.apply_button_theme(options_tab_button)
	ThemeButtonHelper.apply_button_theme(achievements_tab_button)
	ThemeButtonHelper.apply_button_theme(achievement_summary_button)

	ThemeTextHelper.apply_resource_label(squares_label)
	ThemeTextHelper.apply_resource_label(vertices_label)
	ThemeTextHelper.apply_body_label(story_label)
	ThemeTextHelper.apply_body_label(trait_purchase_description)
	ThemeTextHelper.apply_detail_rich_text(trait_purchase_details)
	ThemeTextHelper.apply_body_label(achievement_summary_label)
	story_panel.add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
	ThemeLayoutHelper.apply_margin(story_margin, "inner_margin")
	ThemeTextHelper.apply_detail_label(story_label)
	if _compact_layout_active:
		_apply_compact_spacing()

func _on_theme_changed() -> void:
	_apply_theme()


func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var should_use_compact_layout: bool = get_viewport_rect().size.x < COMPACT_LAYOUT_MAX_WIDTH
	if should_use_compact_layout == _compact_layout_active:
		return

	_compact_layout_active = should_use_compact_layout
	if _compact_layout_active:
		_enter_compact_layout()
	else:
		_exit_compact_layout()


func _enter_compact_layout() -> void:
	_apply_compact_spacing()

	_compact_top_vbox = VBoxContainer.new()
	_compact_top_vbox.name = "CompactTopVBox"
	_compact_top_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeLayoutHelper.apply_box_separation(_compact_top_vbox, "card_gap")
	top_bar_margin.add_child(_compact_top_vbox)
	top_bar_margin.move_child(_compact_top_vbox, 0)

	top_bar_hbox.remove_child(resource_cluster)
	top_bar_hbox.remove_child(story_panel)
	top_bar_hbox.remove_child(navigation_cluster)
	_compact_top_vbox.add_child(resource_cluster)
	_compact_top_vbox.add_child(story_panel)

	resource_cluster.custom_minimum_size = Vector2(0.0, resource_cluster.custom_minimum_size.y)
	story_panel.custom_minimum_size = Vector2(0.0, story_panel.custom_minimum_size.y)
	navigation_cluster.custom_minimum_size = Vector2(0.0, navigation_cluster.custom_minimum_size.y)

	_compact_navigation_vbox = VBoxContainer.new()
	_compact_navigation_vbox.name = "CompactNavigationVBox"
	_compact_navigation_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeLayoutHelper.apply_box_separation(_compact_navigation_vbox, "card_gap")
	_compact_top_vbox.add_child(_compact_navigation_vbox)
	for button: Button in _get_navigation_buttons():
		navigation_cluster.remove_child(button)
		button.custom_minimum_size = Vector2(0.0, button.custom_minimum_size.y)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_compact_navigation_vbox.add_child(button)

	top_bar_hbox.visible = false

	body_h_box.visible = false
	_compact_body_scroll = ScrollContainer.new()
	_compact_body_scroll.name = "CompactBodyScroll"
	_compact_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_compact_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_compact_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_v_box.add_child(_compact_body_scroll)
	main_v_box.move_child(_compact_body_scroll, body_h_box.get_index())

	_compact_body_vbox = VBoxContainer.new()
	_compact_body_vbox.name = "CompactBodyVBox"
	_compact_body_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeLayoutHelper.apply_box_separation(_compact_body_vbox, "panel_gap")
	_compact_body_scroll.add_child(_compact_body_vbox)
	for panel: Control in [left_panel, center_page_root, right_panel]:
		body_h_box.remove_child(panel)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_compact_body_vbox.add_child(panel)


func _exit_compact_layout() -> void:
	body_h_box.visible = true
	for panel: Control in [left_panel, center_page_root, right_panel]:
		_compact_body_vbox.remove_child(panel)
		body_h_box.add_child(panel)

	if _compact_body_scroll != null and is_instance_valid(_compact_body_scroll):
		main_v_box.remove_child(_compact_body_scroll)
		_compact_body_scroll.queue_free()
	_compact_body_scroll = null
	_compact_body_vbox = null

	for button: Button in _get_navigation_buttons():
		_compact_navigation_vbox.remove_child(button)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		navigation_cluster.add_child(button)
	_restore_navigation_button_minimums()

	_compact_top_vbox.remove_child(resource_cluster)
	_compact_top_vbox.remove_child(story_panel)
	_compact_top_vbox.remove_child(_compact_navigation_vbox)
	top_bar_hbox.add_child(resource_cluster)
	top_bar_hbox.add_child(story_panel)
	top_bar_hbox.add_child(navigation_cluster)
	resource_cluster.custom_minimum_size = Vector2(340.0, resource_cluster.custom_minimum_size.y)
	story_panel.custom_minimum_size = Vector2(420.0, story_panel.custom_minimum_size.y)
	navigation_cluster.custom_minimum_size = Vector2(340.0, navigation_cluster.custom_minimum_size.y)
	top_bar_hbox.visible = true

	_compact_navigation_vbox.queue_free()
	_compact_navigation_vbox = null
	_compact_top_vbox.queue_free()
	_compact_top_vbox = null
	_apply_theme()


func _apply_compact_spacing() -> void:
	var compact_margin: int = ThemeSystem.get_spacing("card_gap")
	root_margin.add_theme_constant_override("margin_left", compact_margin)
	root_margin.add_theme_constant_override("margin_top", compact_margin)
	root_margin.add_theme_constant_override("margin_right", compact_margin)
	root_margin.add_theme_constant_override("margin_bottom", compact_margin)


func _get_navigation_buttons() -> Array[Button]:
	return [
		grid_tab_button,
		stats_tab_button,
		options_tab_button,
		achievements_tab_button,
	]


func _restore_navigation_button_minimums() -> void:
	grid_tab_button.custom_minimum_size = Vector2(120, 36)
	stats_tab_button.custom_minimum_size = Vector2.ZERO
	options_tab_button.custom_minimum_size = Vector2(120, 36)
	achievements_tab_button.custom_minimum_size = Vector2(120, 36)


func _connect_global_signals() -> void:
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.vertices_changed.connect(_on_vertices_changed)
	EventBus.grid_changed.connect(_on_grid_changed)
	EventBus.story_message.connect(_on_story_message)

	PassiveSystem.passive_pulsed.connect(_on_passive_pulsed)
	AchievementSystem.achievements_changed.connect(_on_achievements_changed)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	VertexUpgradeSystem.vertex_upgrades_changed.connect(_on_vertex_upgrades_changed)



func _connect_ui_signals() -> void:
	trait_purchase_button.pressed.connect(_on_trait_purchase_pressed)

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
	_refresh_trait_purchase_panel()
	_refresh_achievement_summary()

	grid_page.rebuild()
	_refresh_vertex_shop()
	_refresh_passive_panel()

	options_page.refresh()
	achievements_page.refresh()
	square_details_panel.clear()
	run_upgrades_panel.refresh()
	has_discovered_trait_purchase_panel = false
	grid_expansion_story_shown = false
	vertex_shop_story_shown = false
	passives_story_shown = false
	_refresh_feature_visibility(false)


# ------------------------------------------------------------------------------
# Global UI Refresh
# ------------------------------------------------------------------------------

func _refresh_all_ui() -> void:
	_refresh_labels()
	_refresh_trait_purchase_panel()
	_refresh_achievement_summary()

	grid_page.rebuild()
	_refresh_vertex_shop()
	_refresh_passive_panel()

	options_page.refresh()
	achievements_page.refresh()
	square_details_panel.refresh()
	run_upgrades_panel.refresh()

	_refresh_feature_visibility(false)

func _refresh_feature_visibility(animated: bool = true) -> void:
	var show_passives: bool = FeatureVisibilityRules.should_show_passive_panel()
	var show_vertex_shop: bool = FeatureVisibilityRules.should_show_vertex_shop_access()
	var show_trait_purchase: bool = FeatureVisibilityRules.should_show_trait_purchase_panel()
	var show_run_upgrades: bool = FeatureVisibilityRules.should_show_run_upgrades_panel()
	var show_square_details: bool = FeatureVisibilityRules.should_show_square_details_panel(
		square_details_panel.selected_square_id
	)
	var show_achievement_summary: bool = FeatureVisibilityRules.should_show_achievement_summary_panel()

	if show_trait_purchase and not has_discovered_trait_purchase_panel:
		_on_story_message("Buy Trait is now available — spend Squares to gain Vertices and roll a random Trait.")
		has_discovered_trait_purchase_panel = true

	if show_vertex_shop and not vertex_shop_story_shown:
		vertex_shop_story_shown = true
		_on_story_message("The Vertex Shop has opened! Spend vertices on powerful permanent upgrades.")

	if show_passives and not passives_story_shown:
		passives_story_shown = true
		_on_story_message("Your board awakens — passive generators produce squares automatically.")

	passive_feature_visibility.set_feature_visible(show_passives, animated)
	vertex_shop_feature_visibility.set_feature_visible(show_vertex_shop, animated)
	trait_purchase_feature_visibility.set_feature_visible(has_discovered_trait_purchase_panel, animated)
	run_upgrades_feature_visibility.set_feature_visible(show_run_upgrades, animated)
	square_details_feature_visibility.set_feature_visible(show_square_details, animated)
	achievement_summary_feature_visibility.set_feature_visible(show_achievement_summary, animated)

	grid_page.refresh_feature_visibility(animated)

	if not show_vertex_shop and vertex_shop_page.visible:
		_show_center_page("grid")
	
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
	stats_page.refresh()
# ------------------------------------------------------------------------------
# Resource Labels / Story
# ------------------------------------------------------------------------------

func _on_squares_changed(value: float) -> void:
	squares_label.text = "Squares: %s" % NumberFormatter.amount(value)
	trait_purchase_button.disabled = not GameState.can_buy_trait()

	_refresh_trait_purchase_panel()
	_refresh_passive_panel()
	_refresh_feature_visibility(true)


func _on_vertices_changed(value: int) -> void:
	vertices_label.text = "Vertices: %s" % NumberFormatter.integer_amount(value)
	_refresh_vertex_shop()
	_refresh_trait_purchase_panel()
	_refresh_feature_visibility(true)





func _on_grid_changed() -> void:
	_refresh_trait_purchase_panel()


func _on_story_message(message: String) -> void:
	story_label.text = message

func _refresh_trait_purchase_panel() -> void:
	var vertices_gain: int = max(1, GameState.calculate_trait_purchase_vertices_gain())
	var cost_value: float = GameState.get_trait_purchase_cost()
	var cost_text: String = NumberFormatter.amount(cost_value)
	var vertex_text: String = NumberFormatter.integer_amount(vertices_gain)

	trait_purchase_button.text = "Buy Trait"
	trait_purchase_details.text = "Cost: %s Squares • Gain: %s Vertices\nPossible rarities: %s" % [
		cost_text,
		vertex_text,
		_get_possible_rarities_rich_text(),
	]
	trait_purchase_description.text = "Spend Squares to permanently add a random Trait and gain Vertices."
	trait_purchase_help.help_title = "Buy Trait"
	trait_purchase_help.help_detail = _get_trait_purchase_help_detail(cost_text, vertex_text)
	trait_purchase_help.tooltip_text = "%s\n%s" % [
		trait_purchase_help.help_title,
		trait_purchase_help.help_detail,
	]


func _get_possible_rarities_rich_text() -> String:
	var rarity_parts: Array[String] = []

	for rarity_name: String in _get_possible_rarity_names():
		var rarity_color: String = ThemeTextHelper.get_rarity_color_hex(rarity_name)
		rarity_parts.append("[color=%s]%s[/color]" % [rarity_color, rarity_name])

	return ", ".join(rarity_parts)


func _get_possible_rarity_names() -> Array[String]:
	var rarity_names: Array[String] = []
	var rarity_weights: Dictionary = TraitDatabase.get_rarity_weights_for_grid(GameState.grid_size)

	for rarity_variant: Variant in rarity_weights.keys():
		var rarity: int = int(rarity_variant)
		if float(rarity_weights[rarity_variant]) <= 0.0:
			continue

		rarity_names.append(TraitDefinition.rarity_name_from_value(rarity))

	if rarity_names.is_empty():
		rarity_names.append(TraitDefinition.rarity_name_from_value(TraitDefinition.Rarity.COMMON))

	return rarity_names


func _get_trait_purchase_help_detail(cost_text: String, vertex_text: String) -> String:
	return "Current cost: %s Squares. The cost rises after each purchase.\n\nGain: %s Vertices and permanently add one random Trait to a random square.\n\nPossible rarities for the current grid: %s." % [
		cost_text,
		vertex_text,
		", ".join(_get_possible_rarity_names()),
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

func _on_trait_purchase_pressed() -> void:
	GameState.buy_trait()


func _on_grid_square_selected(square_id: String) -> void:
	square_details_panel.show_square(square_id)
	_refresh_feature_visibility(true)

func _on_grid_upgrade_requested() -> void:
	var upgraded: bool = GameState.upgrade_grid()

	if not upgraded:
		return

	if not grid_expansion_story_shown:
		grid_expansion_story_shown = true
		_on_story_message("The grid expands, making room for more squares — and stranger Traits.")

	square_details_panel.clear()
	grid_page.reset_feature_visibility_state()
	_refresh_labels()
	_refresh_feature_visibility(true)
# ------------------------------------------------------------------------------
# Page Events
# ------------------------------------------------------------------------------

func _on_vertex_upgrade_purchased(_upgrade_id: String) -> void:
	_on_vertex_upgrades_changed()

func _on_vertex_upgrades_changed() -> void:
	_refresh_vertex_shop()
	_refresh_trait_purchase_panel()
	_refresh_passive_panel()
	grid_page.refresh_buttons()
	square_details_panel.refresh()
	run_upgrades_panel.refresh()
	_refresh_feature_visibility(true)
	
func _on_passive_generator_upgraded(_generator_id: String) -> void:
	_refresh_passive_panel()
	square_details_panel.refresh()
	run_upgrades_panel.refresh()
	_refresh_feature_visibility(true)


func _on_options_save_imported() -> void:
	_refresh_all_ui()


func _on_options_hard_reset_completed() -> void:
	has_discovered_trait_purchase_panel = false
	grid_expansion_story_shown = false
	vertex_shop_story_shown = false
	passives_story_shown = false
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
	_refresh_feature_visibility(true)


func _on_save_loaded() -> void:
	_refresh_all_ui()
