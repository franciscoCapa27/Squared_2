extends Control
class_name AchievementsPage

@onready var achievements_description: RichTextLabel = %AchievementsDescription
@onready var achievement_list: VBoxContainer = %AchievementList

var achievement_card_scene: PackedScene = preload("res://scenes/ui/AchievementCard.tscn")
var achievement_cards: Dictionary = {}


func _ready() -> void:
	AchievementSystem.achievements_changed.connect(refresh)
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	refresh()


func refresh() -> void:
	_rebuild_if_needed()

	for achievement_id: String in achievement_cards.keys():
		var card: AchievementCard = achievement_cards.get(achievement_id) as AchievementCard

		if card == null:
			continue

		card.refresh()

	_update_description()


func _rebuild_if_needed() -> void:
	var visible_achievements: Array[AchievementDefinition] = AchievementSystem.get_visible_achievements()

	if visible_achievements.size() == achievement_cards.size():
		return

	_rebuild_list()


func _rebuild_list() -> void:
	for child: Node in achievement_list.get_children():
		child.queue_free()

	achievement_cards.clear()

	var visible_achievements: Array[AchievementDefinition] = AchievementSystem.get_visible_achievements()

	for achievement: AchievementDefinition in visible_achievements:
		var card: AchievementCard = achievement_card_scene.instantiate() as AchievementCard
		achievement_list.add_child(card)

		card.setup(achievement)
		achievement_cards[achievement.id] = card


func _update_description() -> void:
	var unlocked_count: int = AchievementSystem.get_unlocked_count()
	var total_count: int = AchievementDatabase.get_all_achievements().size()

	achievements_description.text = "Unlocked: %s / %s" % [
		unlocked_count,
		total_count
	]


func _on_achievement_unlocked(_achievement_id: String) -> void:
	refresh()
