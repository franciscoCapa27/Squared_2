extends PanelContainer
class_name AchievementCard

@onready var title_label: Label = %TitleLabel
@onready var category_status_label: Label = %CategoryStatusLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var reward_label: RichTextLabel = %RewardLabel

var achievement_definition: AchievementDefinition


func setup(achievement: AchievementDefinition) -> void:
	achievement_definition = achievement
	refresh()


func refresh() -> void:
	if achievement_definition == null:
		return

	var unlocked: bool = AchievementSystem.is_achievement_unlocked(achievement_definition.id)

	title_label.text = achievement_definition.display_name

	if unlocked:
		category_status_label.text = "%s • Unlocked" % achievement_definition.get_category_name()
	else:
		category_status_label.text = "%s • Locked" % achievement_definition.get_category_name()

	description_label.text = achievement_definition.description

	progress_bar.value = AchievementSystem.get_progress_ratio(achievement_definition)
	progress_label.text = AchievementSystem.get_progress_text(achievement_definition)

	reward_label.text = _get_reward_text()


func _get_reward_text() -> String:
	if achievement_definition == null:
		return ""

	if achievement_definition.rewards.is_empty():
		return "Reward: None"

	var lines: Array[String] = []

	for reward: AchievementReward in achievement_definition.rewards:
		if reward == null:
			continue

		lines.append("Reward: %s" % reward.get_debug_text())

	return "\n".join(lines)
