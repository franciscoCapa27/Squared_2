extends RefCounted
class_name ThemeButtonHelper


static func apply_button_theme(button: Button) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", ThemeSystem.make_button_style())
	button.add_theme_stylebox_override("hover", ThemeSystem.make_button_hover_style())
	button.add_theme_stylebox_override("pressed", ThemeSystem.make_button_pressed_style())
	button.add_theme_stylebox_override("disabled", ThemeSystem.make_button_disabled_style())

	button.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
	button.add_theme_color_override("font_hover_color", ThemeSystem.get_color("text_primary"))
	button.add_theme_color_override("font_pressed_color", ThemeSystem.get_color("text_primary"))
	button.add_theme_color_override("font_disabled_color", ThemeSystem.get_color("text_muted"))

	ThemeTextHelper.apply_button_label(button)


static func apply_compact_button_theme(button: Button) -> void:
	if button == null:
		return

	apply_button_theme(button)

	for state_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		ThemeLayoutHelper.compact_stylebox(
			button.get_theme_stylebox(state_name),
			5.0,
			2.0
		)

	button.add_theme_font_size_override(
		"font_size",
		ThemeSystem.get_compact_font_size("button")
	)
