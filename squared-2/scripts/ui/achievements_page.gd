extends Control
class_name AchievementsPage

const TILE_SIZE := 84.0
const GRID_GAP := 12.0

@onready var achievements_description: RichTextLabel = %AchievementsDescription
@onready var achievement_grid: GridContainer = %AchievementGrid
@onready var achievement_selection_detail: RichTextLabel = %AchievementSelectionDetail

var achievement_tile_scene: PackedScene = preload("res://scenes/ui/AchievementIconTile.tscn")
var achievement_tiles: Dictionary = {}
var visible_achievement_ids: Dictionary = {}
var selected_achievement_id: String = ""


func _ready() -> void:
	AchievementSystem.achievements_changed.connect(refresh)
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	achievement_grid.resized.connect(_update_grid_columns)
	resized.connect(_update_grid_columns)
	get_viewport().size_changed.connect(_update_grid_columns)
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
	_update_selection_detail()
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


func _update_selection_detail() -> void:
	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(selected_achievement_id)
	if achievement == null or not achievement_tiles.has(selected_achievement_id):
		achievement_selection_detail.text = "Select an achievement to inspect its current state."
		return

	var unlocked: bool = AchievementSystem.is_achievement_unlocked(achievement.id)
	achievement_selection_detail.text = "[b]%s[/b]\n%s\n\n%s • %s\n%s\n%s" % [
		achievement.display_name,
		achievement.description,
		achievement.get_category_name(),
		"Unlocked" if unlocked else "Locked",
		AchievementSystem.get_progress_text(achievement),
		_get_reward_text(achievement),
	]


func _get_icon_glyph(achievement: AchievementDefinition) -> String:
	match achievement.category:
		AchievementDefinition.AchievementCategory.CLICKS:
			return "✦"
		AchievementDefinition.AchievementCategory.TRAIT_PURCHASE:
			return "◇"
		AchievementDefinition.AchievementCategory.PASSIVE:
			return "◌"
		AchievementDefinition.AchievementCategory.VERTEX:
			return "△"
		AchievementDefinition.AchievementCategory.TRAITS:
			return "✧"
		_:
			return "□"


func _get_reward_text(achievement: AchievementDefinition) -> String:
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


func _on_achievement_unlocked(_achievement_id: String) -> void:
	refresh()
