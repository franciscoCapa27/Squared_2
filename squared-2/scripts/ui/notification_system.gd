extends Control
class_name NotificationSystem

const NOTIFICATION_DURATION := 3.2
const FADE_DURATION := 0.18
const TITLE_PATH := NodePath("NotificationMargin/NotificationVBox/TitleRow/NotificationTitle")
const MESSAGE_PATH := NodePath("NotificationMargin/NotificationVBox/NotificationMessage")
const CLOSE_BUTTON_PATH := NodePath("NotificationMargin/NotificationVBox/TitleRow/CloseButton")

@onready var notification_stack: VBoxContainer = %NotificationStack
@onready var notification_template: PanelContainer = %NotificationTemplate

var _notification_queue: Array[Dictionary] = []
var _active_tweens: Dictionary = {}
var _dismissing_panels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.trait_purchase_reveal.connect(_on_trait_purchase_reveal)
	EventBus.passive_generator_unlocked.connect(_on_passive_generator_unlocked)
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	notification_template.visible = false
	_apply_theme()


func _on_theme_changed() -> void:
	_apply_theme()


func _apply_theme() -> void:
	_apply_notification_theme(notification_template)

	for child: Node in notification_stack.get_children():
		if child is PanelContainer and child != notification_template:
			_apply_notification_theme(child as PanelContainer)


func _apply_notification_theme(notification_panel: PanelContainer) -> void:
	var title_label: Label = notification_panel.get_node(TITLE_PATH) as Label
	var message_label: RichTextLabel = notification_panel.get_node(MESSAGE_PATH) as RichTextLabel
	var close_button: Button = notification_panel.get_node(CLOSE_BUTTON_PATH) as Button

	notification_panel.add_theme_stylebox_override(
		"panel",
		ThemeLayoutHelper.compact_stylebox(
			ThemeSystem.make_elevated_panel_style(),
			2.0,
			1.0
		)
	)
	ThemeTextHelper.apply_card_title(title_label)
	title_label.add_theme_font_size_override(
		"font_size",
		ThemeSystem.get_compact_font_size("detail")
	)
	ThemeTextHelper.apply_detail_rich_text(message_label)
	title_label.add_theme_color_override(
		"font_color",
		_get_kind_color(str(notification_panel.get_meta("notification_kind", "")))
	)
	_apply_close_button_theme(close_button)


func _apply_close_button_theme(close_button: Button) -> void:
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()

	for state: String in ["normal", "hover", "pressed", "focus"]:
		close_button.add_theme_stylebox_override(state, empty_style)

	close_button.add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))
	close_button.add_theme_color_override("font_hover_color", ThemeSystem.get_color("text_primary"))
	close_button.add_theme_color_override("font_pressed_color", ThemeSystem.get_color("text_primary"))
	close_button.add_theme_font_size_override("font_size", ThemeSystem.get_font_size("detail"))


func _on_achievement_unlocked(achievement_id: String) -> void:
	var achievement: AchievementDefinition = AchievementDatabase.get_achievement(achievement_id)
	if achievement == null:
		return

	var level: int = AchievementSystem.get_achievement_level(achievement_id)
	_enqueue_notification(
		"Achievement unlocked",
		"[b]%s[/b] - Level %s" % [achievement.display_name, NumberFormatter.integer_amount(level)],
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
	var rarity_color: String = ThemeTextHelper.get_rarity_color_hex(trait_rarity_display)
	var family_color: String = ThemeTextHelper.get_trait_family_color_hex(trait_family_display)
	_enqueue_notification(
		"Trait acquired",
		"[color=%s][b]%s[/b][/color] [color=%s]%s[/color] on %s" % [
			rarity_color,
			trait_rarity_display.capitalize(),
			family_color,
			trait_family_display,
			square_title,
		],
		"trait"
	)


func _on_passive_generator_unlocked(generator_id: String) -> void:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(generator_id)
	if generator_instance == null:
		return

	_enqueue_notification(
		"Passive generator unlocked",
		"[b]%s[/b]" % generator_instance.get_display_name(),
		"passive"
	)


func _enqueue_notification(notification_title: String, notification_message: String, notification_kind: String) -> void:
	_notification_queue.append({
		"title": notification_title,
		"message": notification_message,
		"kind": notification_kind,
	})
	_show_queued_notifications()


func _show_queued_notifications() -> void:
	while not _notification_queue.is_empty():
		_show_notification(_notification_queue.pop_front())


func _show_notification(notification: Dictionary) -> void:
	var notification_panel: PanelContainer = notification_template.duplicate() as PanelContainer
	var title_label: Label = notification_panel.get_node(TITLE_PATH) as Label
	var message_label: RichTextLabel = notification_panel.get_node(MESSAGE_PATH) as RichTextLabel
	var close_button: Button = notification_panel.get_node(CLOSE_BUTTON_PATH) as Button
	var notification_kind: String = str(notification.get("kind", ""))

	notification_panel.set_meta("notification_kind", notification_kind)
	title_label.text = str(notification.get("title", ""))
	message_label.text = str(notification.get("message", ""))
	close_button.pressed.connect(_dismiss_notification.bind(notification_panel))
	notification_stack.add_child(notification_panel)
	_apply_notification_theme(notification_panel)

	notification_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	notification_panel.visible = true
	var fade_in_tween: Tween = create_tween()
	_active_tweens[notification_panel] = fade_in_tween
	fade_in_tween.tween_property(notification_panel, "modulate:a", 1.0, FADE_DURATION)
	fade_in_tween.tween_callback(_clear_active_tween.bind(notification_panel, fade_in_tween))

	var dismiss_timer: Timer = Timer.new()
	dismiss_timer.name = "DismissTimer"
	dismiss_timer.one_shot = true
	dismiss_timer.wait_time = NOTIFICATION_DURATION
	notification_panel.add_child(dismiss_timer)
	dismiss_timer.timeout.connect(_dismiss_notification.bind(notification_panel))
	dismiss_timer.start()


func _dismiss_notification(notification_panel: PanelContainer) -> void:
	if not is_instance_valid(notification_panel) or _dismissing_panels.has(notification_panel):
		return

	_dismissing_panels[notification_panel] = true
	var dismiss_timer: Timer = notification_panel.get_node_or_null("DismissTimer") as Timer
	if dismiss_timer != null:
		dismiss_timer.stop()

	_kill_active_tween(notification_panel)
	var fade_out_tween: Tween = create_tween()
	_active_tweens[notification_panel] = fade_out_tween
	fade_out_tween.tween_property(notification_panel, "modulate:a", 0.0, FADE_DURATION)
	fade_out_tween.tween_callback(_finish_notification.bind(notification_panel))


func _finish_notification(notification_panel: PanelContainer) -> void:
	_active_tweens.erase(notification_panel)
	_dismissing_panels.erase(notification_panel)
	if is_instance_valid(notification_panel):
		notification_panel.queue_free()


func _clear_active_tween(notification_panel: PanelContainer, completed_tween: Tween) -> void:
	if _active_tweens.get(notification_panel) == completed_tween:
		_active_tweens.erase(notification_panel)


func _kill_active_tween(notification_panel: PanelContainer) -> void:
	var active_tween: Tween = _active_tweens.get(notification_panel) as Tween
	if active_tween != null:
		active_tween.kill()
	_active_tweens.erase(notification_panel)


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
