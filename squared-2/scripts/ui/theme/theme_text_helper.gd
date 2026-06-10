extends RefCounted
class_name ThemeTextHelper


static func apply_primary_label(label: Label) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))


static func apply_secondary_label(label: Label) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", ThemeSystem.get_color("text_secondary"))


static func apply_muted_label(label: Label) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))


static func apply_primary_rich_text(label: RichTextLabel) -> void:
	if label == null:
		return

	label.add_theme_color_override("default_color", ThemeSystem.get_color("text_primary"))


static func apply_secondary_rich_text(label: RichTextLabel) -> void:
	if label == null:
		return

	label.add_theme_color_override("default_color", ThemeSystem.get_color("text_secondary"))


static func apply_muted_rich_text(label: RichTextLabel) -> void:
	if label == null:
		return

	label.add_theme_color_override("default_color", ThemeSystem.get_color("text_muted"))
