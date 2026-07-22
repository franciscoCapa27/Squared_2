extends Control
class_name NotificationSystem

const NOTIFICATION_DURATION := 3.2
const FADE_DURATION := 0.18

@onready var panel: PanelContainer = %NotificationPanel
@onready var title_label: Label = %NotificationTitle
@onready var message_label: Label = %NotificationMessage
@onready var dismiss_timer: Timer = %DismissTimer

var _notification_queue: Array[Dictionary] = []
var _is_showing: bool = false
var _active_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dismiss_timer.timeout.connect(_on_dismiss_timer_timeout)
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.trait_purchase_reveal.connect(_on_trait_purchase_reveal)
	EventBus.passive_generator_unlocked.connect(_on_passive_generator_unlocked)
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	panel.visible = false


func _on_theme_changed() -> void:
	_apply_theme()


func _apply_theme() -> void:
	panel.add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
	ThemeTextHelper.apply_card_title(title_label)
	ThemeTextHelper.apply_body_label(message_label)


func _on_achievement_unlocked(achievement_id: String) -> void:
	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(achievement_id)
	if achievement == null:
		return

	var level: int = AchievementSystem.get_achievement_level(achievement_id)
	_enqueue_notification(
		"Achievement unlocked",
		"%s — Level %s" % [achievement.display_name, NumberFormatter.integer_amount(level)],
		"achievement"
	)


func _on_trait_purchase_reveal(
	_target_square_id: String,
	trait_family_display: String,
	trait_rarity_display: String,
	_trait_roman_stack: String,
	square_title: String,
	_previous_square_title: String
) -> void:
	_enqueue_notification(
		"Trait acquired",
		"%s — %s on %s" % [trait_rarity_display.capitalize(), trait_family_display, square_title],
		"trait"
	)


func _on_passive_generator_unlocked(generator_id: String) -> void:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(generator_id)
	if generator_instance == null:
		return

	_enqueue_notification(
		"Passive generator unlocked",
		generator_instance.get_display_name(),
		"passive"
	)


func _enqueue_notification(notification_title: String, notification_message: String, notification_kind: String) -> void:
	_notification_queue.append({
		"title": notification_title,
		"message": notification_message,
		"kind": notification_kind,
	})
	_show_next_notification()


func _show_next_notification() -> void:
	if _is_showing or _notification_queue.is_empty():
		return

	var notification: Dictionary = _notification_queue.pop_front()
	_is_showing = true
	title_label.text = str(notification.get("title", ""))
	message_label.text = str(notification.get("message", ""))
	title_label.add_theme_color_override("font_color", _get_kind_color(str(notification.get("kind", ""))))
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.visible = true

	if _active_tween != null:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(panel, "modulate:a", 1.0, FADE_DURATION)
	dismiss_timer.start(NOTIFICATION_DURATION)


func _on_dismiss_timer_timeout() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = create_tween()
		_active_tween.tween_property(panel, "modulate:a", 0.0, FADE_DURATION)
		_active_tween.tween_callback(_finish_notification)
	else:
		_finish_notification()


func _finish_notification() -> void:
	panel.visible = false
	_is_showing = false
	_show_next_notification()


func _get_kind_color(notification_kind: String) -> Color:
	match notification_kind:
		"achievement":
			return ThemeSystem.get_color("accent_primary")
		"trait":
			return ThemeSystem.get_color("accent_secondary")
		"passive":
			return ThemeSystem.get_color("success")
		_:
			return ThemeSystem.get_color("text_primary")
