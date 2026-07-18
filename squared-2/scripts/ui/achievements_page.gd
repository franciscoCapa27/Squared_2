extends Control
class_name AchievementsPage

signal tracked_achievement_changed(achievement_id: String)

const TILE_SIZE := 72.0
const GRID_GAP := 8.0

@onready var achievements_description: RichTextLabel = %AchievementsDescription
@onready var achievement_grid: GridContainer = %AchievementGrid
@onready var achievements_margin: MarginContainer = %AchievementsMargin
@onready var achievements_v_box: VBoxContainer = %AchievementsVBox

var achievement_tile_scene: PackedScene = preload("res://scenes/ui/AchievementIconTile.tscn")
var achievement_tiles: Dictionary = {}
var visible_achievement_ids: Dictionary = {}
var selected_achievement_id: String = ""
var tracked_achievement_id: String = ""
var achievement_popup_layer: CanvasLayer
var achievement_popup: PanelContainer


func _ready() -> void:
	AchievementSystem.achievements_changed.connect(refresh)
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	achievement_grid.resized.connect(_update_grid_columns)
	resized.connect(_update_grid_columns)
	get_viewport().size_changed.connect(_update_grid_columns)
	ThemeLayoutHelper.apply_dense_margin(achievements_margin, "inner_margin")
	ThemeLayoutHelper.apply_dense_box_separation(achievements_v_box, "section_gap")
	refresh()
	call_deferred("_update_grid_columns")


func refresh() -> void:
	_rebuild_if_needed()

	for achievement_id: String in achievement_tiles.keys():
		var tile: AchievementIconTile = achievement_tiles.get(achievement_id) as AchievementIconTile
		if tile == null:
			continue

		tile.refresh()
		tile.set_selected(achievement_id == selected_achievement_id)

	_update_description()
	_update_grid_columns()


func _rebuild_if_needed() -> void:
	var visible_achievements: Array[AchievementDefinition] = AchievementSystem.get_visible_achievements()
	var current_visible_ids: Dictionary = {}
	for achievement: AchievementDefinition in visible_achievements:
		current_visible_ids[achievement.id] = true

	if current_visible_ids == visible_achievement_ids:
		return

	_rebuild_grid(visible_achievements)
	visible_achievement_ids = current_visible_ids


func _rebuild_grid(visible_achievements: Array[AchievementDefinition]) -> void:
	for child: Node in achievement_grid.get_children():
		child.queue_free()

	achievement_tiles.clear()

	for achievement: AchievementDefinition in visible_achievements:
		var tile: AchievementIconTile = achievement_tile_scene.instantiate() as AchievementIconTile
		achievement_grid.add_child(tile)
		tile.setup(achievement, _get_icon_glyph(achievement))
		tile.selected.connect(_on_achievement_selected)
		achievement_tiles[achievement.id] = tile

	if not achievement_tiles.has(selected_achievement_id):
		selected_achievement_id = ""


func _update_grid_columns() -> void:
	if achievement_grid == null:
		return

	var available_width: float = achievement_grid.size.x
	if available_width <= 0.0 and achievement_grid.get_parent() is Control:
		available_width = (achievement_grid.get_parent() as Control).size.x

	var column_count: int = maxi(1, floori((available_width + GRID_GAP) / (TILE_SIZE + GRID_GAP)))
	if achievement_grid.columns != column_count:
		achievement_grid.columns = column_count


func _update_description() -> void:
	var unlocked_count: int = AchievementSystem.get_unlocked_count()
	var total_count: int = AchievementDatabase.get_all_achievements().size()
	achievements_description.text = "Unlocked: %s / %s" % [
		unlocked_count,
		total_count,
	]

func _get_icon_glyph(achievement: AchievementDefinition) -> String:
	match achievement.category:
		AchievementDefinition.AchievementCategory.CLICKS:
			return "spark"
		AchievementDefinition.AchievementCategory.TRAIT_PURCHASE:
			return "diamond"
		AchievementDefinition.AchievementCategory.PASSIVE:
			return "passive"
		AchievementDefinition.AchievementCategory.VERTEX:
			return "triangle"
		AchievementDefinition.AchievementCategory.TRAITS:
			return "spark"
		_:
			return "square"


func _get_reward_text(achievement: AchievementDefinition) -> String:
	if not achievement.levels.is_empty():
		var level_reward_lines: Array[String] = []
		for level_index: int in achievement.levels.size():
			var level_rewards: Array[AchievementReward] = achievement.get_rewards_for_level(level_index)
			for reward: AchievementReward in level_rewards:
				if reward == null:
					continue

				level_reward_lines.append("Level %s reward: %s" % [
					NumberFormatter.integer_amount(level_index + 1),
					_format_reward(reward),
				])

		return "\n".join(level_reward_lines) if not level_reward_lines.is_empty() else "Reward: None"

	if achievement.rewards.is_empty():
		return "Reward: None"

	var reward_lines: Array[String] = []
	for reward: AchievementReward in achievement.rewards:
		if reward == null:
			continue

		reward_lines.append("Reward: %s" % _format_reward(reward))

	return "\n".join(reward_lines) if not reward_lines.is_empty() else "Reward: None"


func _format_reward(reward: AchievementReward) -> String:
	match reward.reward_type:
		AchievementReward.RewardType.GLOBAL_STAT_MULTIPLIER:
			return "%s %s" % [
				_format_stat_name(reward.target_stat),
				NumberFormatter.precise_percent_from_multiplier(reward.value),
			]
		AchievementReward.RewardType.ADD_PERMANENT_STAT:
			return "%s +%s" % [
				_format_stat_name(reward.target_stat),
				NumberFormatter.amount(reward.value),
			]
		AchievementReward.RewardType.UNLOCK_MECHANIC:
			return "Unlock mechanic: %s" % reward.mechanic_id
		AchievementReward.RewardType.ADD_STARTING_SQUARES:
			return "+%s starting Squares" % NumberFormatter.amount(reward.value)
		AchievementReward.RewardType.SCRIPT_HOOK:
			return "Special effect"
		_:
			return "Unknown reward"


func _format_stat_name(stat_id: String) -> String:
	match stat_id:
		GameIds.STAT_SQUARE_BASE_VALUE:
			return "Square base value"
		GameIds.STAT_SQUARE_RESPAWN_TIME:
			return "Square respawn time"
		GameIds.STAT_VERTEX_GAIN:
			return "Vertex gain"
		GameIds.STAT_TRAIT_LUCK:
			return "Trait luck"
		_:
			return stat_id


func _on_achievement_selected(achievement_id: String) -> void:
	selected_achievement_id = achievement_id
	refresh()
	_open_achievement_popup()


func get_tracked_summary() -> String:
	if tracked_achievement_id == "":
		return ""

	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(tracked_achievement_id)
	if achievement == null:
		return ""

	return "Tracked: %s\n%s" % [
		achievement.display_name,
		AchievementSystem.get_progress_text(achievement),
	]


func _open_achievement_popup() -> void:
	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(selected_achievement_id)
	if achievement == null:
		return

	_close_achievement_popup()
	achievement_popup_layer = CanvasLayer.new()
	achievement_popup_layer.layer = 100
	get_tree().root.add_child(achievement_popup_layer)

	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_achievement_popup_overlay_input)
	achievement_popup_layer.add_child(overlay)

	achievement_popup = PanelContainer.new()
	achievement_popup.custom_minimum_size = Vector2(340.0, 240.0)
	achievement_popup.size = achievement_popup.custom_minimum_size
	achievement_popup.position = (get_viewport().get_visible_rect().size - achievement_popup.size) * 0.5
	achievement_popup.add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
	overlay.add_child(achievement_popup)

	var margin: MarginContainer = MarginContainer.new()
	ThemeLayoutHelper.apply_dense_margin(margin, "inner_margin")
	achievement_popup.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	ThemeLayoutHelper.apply_dense_box_separation(content, "section_gap")
	margin.add_child(content)

	var title_label: Label = Label.new()
	title_label.text = achievement.display_name
	ThemeTextHelper.apply_panel_title(title_label)
	content.add_child(title_label)

	var detail_label: RichTextLabel = RichTextLabel.new()
	detail_label.bbcode_enabled = true
	detail_label.fit_content = true
	detail_label.text = "[b]%s[/b]\n%s\n\n%s - %s\n%s\n%s" % [
		achievement.get_category_name(),
		achievement.description,
		"Unlocked" if AchievementSystem.is_achievement_unlocked(achievement.id) else "Locked",
		AchievementSystem.get_level_text(achievement),
		AchievementSystem.get_progress_text(achievement),
		_get_reward_text(achievement),
	]
	ThemeTextHelper.apply_body_rich_text(detail_label)
	content.add_child(detail_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(action_row)

	var track_button: Button = Button.new()
	track_button.text = "Untrack" if tracked_achievement_id == achievement.id else "Track achievement"
	track_button.pressed.connect(_on_track_button_pressed.bind(achievement.id))
	ThemeButtonHelper.apply_button_theme(track_button)
	action_row.add_child(track_button)

	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_close_achievement_popup)
	ThemeButtonHelper.apply_button_theme(close_button)
	action_row.add_child(close_button)


func _on_track_button_pressed(achievement_id: String) -> void:
	tracked_achievement_id = "" if tracked_achievement_id == achievement_id else achievement_id
	tracked_achievement_changed.emit(tracked_achievement_id)
	_close_achievement_popup()


func _on_achievement_popup_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_achievement_popup()


func _close_achievement_popup() -> void:
	if achievement_popup_layer != null and is_instance_valid(achievement_popup_layer):
		achievement_popup_layer.queue_free()
	achievement_popup_layer = null
	achievement_popup = null


func _on_achievement_unlocked(_achievement_id: String) -> void:
	refresh()
