extends Control
class_name StatsPage

const CONTEXTUAL_HELP_SCENE: PackedScene = preload("res://scenes/ui/ContextualHelp.tscn")

@onready var stats_title_label: Label = %StatsTitle
@onready var stats_description: RichTextLabel = %StatsDescription
@onready var stats_list: VBoxContainer = %StatsList

var _stat_value_labels: Dictionary = {}
var _stat_name_labels: Array[Label] = []
var _section_title_labels: Array[Label] = []
var _section_purpose_labels: Array[Label] = []


func _ready() -> void:
	_build_stat_list()
	EventBus.squares_changed.connect(_on_state_changed)
	EventBus.vertices_changed.connect(_on_state_changed)
	EventBus.trait_purchase_changed.connect(_on_trait_purchase_changed)
	EventBus.grid_changed.connect(_on_state_changed)
	PassiveSystem.passive_state_changed.connect(_on_state_changed)
	VertexUpgradeSystem.vertex_upgrades_changed.connect(_on_state_changed)
	AchievementSystem.achievements_changed.connect(_on_state_changed)
	ThemeSystem.theme_changed.connect(_apply_theme)
	_apply_theme()
	refresh()


func refresh() -> void:
	var run_manual_clicks: int = 0
	var run_passive_clicks: int = 0
	var run_squares_generated: float = 0.0
	var lifetime_manual_clicks: int = 0
	var lifetime_passive_clicks: int = 0
	var lifetime_squares_generated: float = 0.0
	var highest_single_payout: float = 0.0
	var traited_squares: int = 0

	for square_id: String in GameState.square_ids:
		var square_data: SquareData = GameState.get_square(square_id)
		if square_data == null:
			continue

		run_manual_clicks += square_data.run_manual_clicks
		run_passive_clicks += square_data.run_passive_clicks
		run_squares_generated += square_data.run_squares_generated
		lifetime_manual_clicks += square_data.lifetime_manual_clicks
		lifetime_passive_clicks += square_data.lifetime_passive_clicks
		lifetime_squares_generated += square_data.lifetime_squares_generated
		highest_single_payout = max(highest_single_payout, square_data.highest_single_payout)
		if square_data.has_traits():
			traited_squares += 1

	var passive_pulses: int = 0
	var passive_squares: float = 0.0
	for generator_instance: PassiveGeneratorInstance in PassiveSystem.get_all_generator_instances():
		if generator_instance == null:
			continue
		passive_pulses += generator_instance.lifetime_pulses
		passive_squares += generator_instance.lifetime_squares_generated

	_set_stat_value("run_squares_held", NumberFormatter.amount(GameState.squares))
	_set_stat_value("run_manual_clicks", NumberFormatter.integer_amount(run_manual_clicks))
	_set_stat_value("run_passive_clicks", NumberFormatter.integer_amount(run_passive_clicks))
	_set_stat_value("run_squares_generated", NumberFormatter.amount(run_squares_generated))
	_set_stat_value("run_grid", "%sx%s" % [GameState.grid_size, GameState.grid_size])
	_set_stat_value("run_traited_squares", NumberFormatter.integer_amount(traited_squares))

	_set_stat_value("lifetime_squares_generated", NumberFormatter.amount(lifetime_squares_generated))
	_set_stat_value("lifetime_manual_clicks", NumberFormatter.integer_amount(lifetime_manual_clicks))
	_set_stat_value("lifetime_passive_clicks", NumberFormatter.integer_amount(lifetime_passive_clicks))
	_set_stat_value("lifetime_passive_pulses", NumberFormatter.integer_amount(passive_pulses))
	_set_stat_value("lifetime_passive_squares", NumberFormatter.amount(passive_squares))
	_set_stat_value("lifetime_highest_single_payout", NumberFormatter.amount(highest_single_payout))
	_set_stat_value("lifetime_trait_purchases", NumberFormatter.integer_amount(GameState.trait_purchase_count))
	_set_stat_value("lifetime_vertices_held", NumberFormatter.integer_amount(GameState.vertices))
	_set_stat_value("lifetime_vertex_upgrades", NumberFormatter.integer_amount(_get_purchased_upgrade_count()))
	_set_stat_value("lifetime_achievements", "%s / %s" % [
		AchievementSystem.get_unlocked_count(),
		AchievementDatabase.get_all_achievements().size()
	])


func _build_stat_list() -> void:
	for child: Node in stats_list.get_children():
		child.queue_free()

	_stat_value_labels.clear()
	_stat_name_labels.clear()
	_section_title_labels.clear()
	_section_purpose_labels.clear()

	_add_stat_section(
		"Run",
		"Current run activity and current-board values.",
		[
			["run_squares_held", "Squares held", "Current Squares total for this run.", "Current Squares"],
			["run_manual_clicks", "Manual clicks", "Manual clicks recorded during this run.", "Manual clicks"],
			["run_passive_clicks", "Passive clicks", "Passive generator clicks recorded during this run.", "Passive clicks"],
			["run_squares_generated", "Squares generated", "Squares produced by manual and passive clicks during this run.", "Squares generated"],
			["run_grid", "Grid", "The current grid width and height.", "Grid size"],
			["run_traited_squares", "Traits on squares", "How many current squares have at least one Trait.", "Traits on squares"]
		]
	)
	_add_stat_section(
		"Lifetime",
		"Cumulative totals and progression kept for this universe.",
		[
			["lifetime_squares_generated", "Squares generated", "Total Squares produced across all runs.", "Lifetime Squares generated"],
			["lifetime_manual_clicks", "Manual clicks", "Total manual clicks recorded across all runs.", "Lifetime manual clicks"],
			["lifetime_passive_clicks", "Passive clicks", "Total passive generator clicks recorded across all runs.", "Lifetime passive clicks"],
			["lifetime_passive_pulses", "Passive pulses", "Total times passive generators have paid out.", "Passive pulses"],
			["lifetime_passive_squares", "Passive Squares generated", "Total Squares produced by passive generators.", "Passive Squares generated"],
			["lifetime_highest_single_payout", "Highest single payout", "The largest one-time Squares payout recorded from any click.", "Highest single payout"],
			["lifetime_trait_purchases", "Buy Trait purchases", "The total number of Buy Trait purchases made.", "Buy Trait purchases"],
			["lifetime_vertices_held", "Vertices held", "Current Vertices total.", "Current Vertices"],
			["lifetime_vertex_upgrades", "Vertex upgrades", "The total number of Vertex upgrade purchases made.", "Vertex upgrades"],
			["lifetime_achievements", "Achievements", "Unlocked achievements compared with the total available.", "Achievements"]
		]
	)


func _add_stat_section(
	title: String,
	purpose: String,
	definitions: Array[Array]
) -> void:
	var section: VBoxContainer = VBoxContainer.new()
	ThemeLayoutHelper.apply_box_separation(section, "section_gap")
	stats_list.add_child(section)

	var section_title: Label = Label.new()
	section_title.text = title
	_section_title_labels.append(section_title)
	section.add_child(section_title)

	var section_purpose: Label = Label.new()
	section_purpose.text = purpose
	section_purpose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_section_purpose_labels.append(section_purpose)
	section.add_child(section_purpose)

	var rows: VBoxContainer = VBoxContainer.new()
	ThemeLayoutHelper.apply_box_separation(rows, "card_gap")
	section.add_child(rows)

	for definition: Array in definitions:
		_add_stat_row(rows, definition)


func _add_stat_row(rows: VBoxContainer, definition: Array) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 28.0
	rows.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = "%s:" % definition[1]
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stat_name_labels.append(name_label)
	row.add_child(name_label)

	var value_label: Label = Label.new()
	value_label.text = "0"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stat_value_labels[definition[0]] = value_label
	row.add_child(value_label)

	var help_button: ContextualHelp = CONTEXTUAL_HELP_SCENE.instantiate() as ContextualHelp
	help_button.help_title = definition[3]
	help_button.help_detail = definition[2]
	help_button.tooltip_text = "%s\n%s" % [definition[3], definition[2]]
	row.add_child(help_button)


func _set_stat_value(stat_id: String, value: String) -> void:
	var value_label: Label = _stat_value_labels.get(stat_id) as Label
	if value_label == null:
		return
	value_label.text = value


func _get_purchased_upgrade_count() -> int:
	var total: int = 0
	for upgrade_id: String in VertexUpgradeSystem.unlocked_vertex_upgrades:
		total += VertexUpgradeSystem.get_vertex_upgrade_purchase_count(upgrade_id)
	return total


func _apply_theme() -> void:
	if stats_title_label == null:
		return
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())
	ThemeTextHelper.apply_page_title(stats_title_label)
	ThemeTextHelper.apply_body_rich_text(stats_description)
	for label: Label in _section_title_labels:
		ThemeTextHelper.apply_panel_title(label)
	for label: Label in _section_purpose_labels:
		ThemeTextHelper.apply_detail_label(label)
	for label: Label in _stat_name_labels:
		ThemeTextHelper.apply_body_label(label)
	for value_label: Label in _stat_value_labels.values():
		ThemeTextHelper.apply_primary_label(value_label)
	refresh()


func _on_state_changed(_value: Variant = null) -> void:
	refresh()


func _on_trait_purchase_changed(_value: int) -> void:
	refresh()
