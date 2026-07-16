extends Control
class_name StatsPage

@onready var stats_label: RichTextLabel = %StatsLabel


func _ready() -> void:
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

	stats_label.text = "[font_size=%d][color=%s]Run[/color][/font_size]\n" % [
		ThemeSystem.get_font_size("panel_title"),
		ThemeSystem.get_color("text_primary").to_html(false)
	]
	stats_label.text += _format_stat_lines([
		["Squares held", NumberFormatter.amount(GameState.squares)],
		["Manual clicks", NumberFormatter.integer_amount(run_manual_clicks)],
		["Passive clicks", NumberFormatter.integer_amount(run_passive_clicks)],
		["Squares generated", NumberFormatter.amount(run_squares_generated)],
		["Grid", "%sx%s" % [GameState.grid_size, GameState.grid_size]],
		["Traits on squares", NumberFormatter.integer_amount(traited_squares)]
	])
	stats_label.text += "\n[font_size=%d][color=%s]Lifetime[/color][/font_size]\n" % [
		ThemeSystem.get_font_size("panel_title"),
		ThemeSystem.get_color("text_primary").to_html(false)
	]
	stats_label.text += _format_stat_lines([
		["Squares generated", NumberFormatter.amount(lifetime_squares_generated)],
		["Manual clicks", NumberFormatter.integer_amount(lifetime_manual_clicks)],
		["Passive clicks", NumberFormatter.integer_amount(lifetime_passive_clicks)],
		["Passive pulses", NumberFormatter.integer_amount(passive_pulses)],
		["Passive Squares generated", NumberFormatter.amount(passive_squares)],
		["Highest single payout", NumberFormatter.amount(highest_single_payout)],
		["Buy Trait purchases", NumberFormatter.integer_amount(GameState.trait_purchase_count)],
		["Vertices held", NumberFormatter.integer_amount(GameState.vertices)],
		["Vertex upgrades", NumberFormatter.integer_amount(_get_purchased_upgrade_count())],
		["Achievements", "%s / %s" % [
			AchievementSystem.get_unlocked_count(),
			AchievementDatabase.get_all_achievements().size()
		]]
	])


func _format_stat_lines(lines: Array) -> String:
	var result: Array[String] = []
	for line: Array in lines:
		result.append("[color=%s]%s:[/color] %s" % [
			ThemeSystem.get_color("text_secondary").to_html(false),
			line[0],
			line[1]
		])
	return "\n".join(result) + "\n"


func _get_purchased_upgrade_count() -> int:
	var total: int = 0
	for upgrade_id: String in VertexUpgradeSystem.unlocked_vertex_upgrades:
		total += VertexUpgradeSystem.get_vertex_upgrade_purchase_count(upgrade_id)
	return total


func _apply_theme() -> void:
	if stats_label == null:
		return
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())
	ThemeTextHelper.apply_body_rich_text(stats_label)
	refresh()


func _on_state_changed(_value: Variant = null) -> void:
	refresh()


func _on_trait_purchase_changed(_value: int) -> void:
	refresh()
