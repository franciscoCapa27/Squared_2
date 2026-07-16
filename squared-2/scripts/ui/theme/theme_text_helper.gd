extends RefCounted
class_name ThemeTextHelper


static func apply_resource_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("resource")
	)


static func apply_page_title(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("page_title")
	)


static func apply_panel_title(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("panel_title")
	)


static func apply_card_title(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("card_title")
	)


static func apply_body_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_secondary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_detail_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_muted"),
		ThemeSystem.get_font_size("detail")
	)


static func apply_button_label(button: Button) -> void:
	if button == null:
		return

	var font_size: int = ThemeSystem.get_font_size("button")

	button.add_theme_font_size_override("font_size", font_size)


static func apply_tiny_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_muted"),
		ThemeSystem.get_font_size("tiny")
	)


static func apply_body_rich_text(label: RichTextLabel) -> void:
	_apply_rich_text(
		label,
		ThemeSystem.get_color("text_secondary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_detail_rich_text(label: RichTextLabel) -> void:
	_apply_rich_text(
		label,
		ThemeSystem.get_color("text_muted"),
		ThemeSystem.get_font_size("detail")
	)


static func get_rarity_color_hex(rarity: String) -> String:
	match rarity.to_lower():
		"uncommon":
			return "#7ee2b8"
		"rare":
			return "#c79aff"
		"epic":
			return "#ff9bd6"
		"legendary":
			return "#ffd37a"
		_:
			return "#d5dde7"


static func apply_primary_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_secondary_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_secondary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_muted_label(label: Label) -> void:
	_apply_label(
		label,
		ThemeSystem.get_color("text_muted"),
		ThemeSystem.get_font_size("detail")
	)


static func apply_primary_rich_text(label: RichTextLabel) -> void:
	_apply_rich_text(
		label,
		ThemeSystem.get_color("text_primary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_secondary_rich_text(label: RichTextLabel) -> void:
	_apply_rich_text(
		label,
		ThemeSystem.get_color("text_secondary"),
		ThemeSystem.get_font_size("body")
	)


static func apply_muted_rich_text(label: RichTextLabel) -> void:
	_apply_rich_text(
		label,
		ThemeSystem.get_color("text_muted"),
		ThemeSystem.get_font_size("detail")
	)


static func apply_auto_shrinking_title(
	label: Label,
	text: String,
	normal_size_id: String = "panel_title",
	medium_threshold: int = 26,
	small_threshold: int = 38,
	tiny_threshold: int = 52
) -> void:
	if label == null:
		return

	var font_size: int = ThemeSystem.get_font_size(normal_size_id)

	if text.length() > tiny_threshold:
		font_size = ThemeSystem.get_font_size("tiny")
	elif text.length() > small_threshold:
		font_size = ThemeSystem.get_compact_font_size("detail")
	elif text.length() > medium_threshold:
		font_size = ThemeSystem.get_compact_font_size(normal_size_id)

	label.text = text
	label.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
	label.add_theme_font_size_override("font_size", font_size)
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF


static func _apply_label(
	label: Label,
	color: Color,
	font_size: int
) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)


static func _apply_rich_text(
	label: RichTextLabel,
	color: Color,
	font_size: int
) -> void:
	if label == null:
		return

	label.add_theme_color_override("default_color", color)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_font_size_override("italics_font_size", font_size)
	label.add_theme_font_size_override("bold_italics_font_size", font_size)
