extends Node

signal theme_changed()

const DEFAULT_THEME_PATH := "res://data/themes/void_dark.tres"

var active_theme: UIThemeDefinition


func _ready() -> void:
	load_theme(DEFAULT_THEME_PATH)


func load_theme(theme_path: String) -> void:
	var resource: Resource = load(theme_path)

	if resource == null:
		push_error("Failed to load UI theme: %s" % theme_path)
		return

	if not resource is UIThemeDefinition:
		push_error("Resource is not a UIThemeDefinition: %s" % theme_path)
		return

	active_theme = resource as UIThemeDefinition
	theme_changed.emit()


func get_theme_id() -> String:
	if active_theme == null:
		return ""

	return active_theme.id


func get_color(color_id: String) -> Color:
	if active_theme == null:
		return Color.WHITE

	match color_id:
		"background":
			return active_theme.background
		"background_subtle":
			return active_theme.background_subtle
		"surface":
			return active_theme.surface
		"surface_soft":
			return active_theme.surface_soft
		"surface_strong":
			return active_theme.surface_strong
		"border":
			return active_theme.border
		"border_soft":
			return active_theme.border_soft
		"border_strong":
			return active_theme.border_strong
		"text_primary":
			return active_theme.text_primary
		"text_secondary":
			return active_theme.text_secondary
		"text_muted":
			return active_theme.text_muted
		"accent_primary":
			return active_theme.accent_primary
		"accent_secondary":
			return active_theme.accent_secondary
		"success":
			return active_theme.success
		"warning":
			return active_theme.warning
		"danger":
			return active_theme.danger
		_:
			push_warning("Unknown theme color id: %s" % color_id)
			return Color.WHITE


func make_background_style() -> StyleBoxFlat:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()

	style_box.bg_color = get_color("background")
	style_box.border_width_left = 0
	style_box.border_width_top = 0
	style_box.border_width_right = 0
	style_box.border_width_bottom = 0

	return style_box


func make_panel_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface,
		active_theme.border_soft,
		active_theme.panel_corner_radius,
		active_theme.panel_border_width
	)


func make_elevated_panel_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_soft,
		active_theme.border,
		active_theme.panel_corner_radius,
		active_theme.panel_border_width
	)


func make_card_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_soft,
		active_theme.border_soft,
		active_theme.card_corner_radius,
		active_theme.card_border_width
	)


func make_selected_card_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_strong,
		active_theme.border_strong,
		active_theme.card_corner_radius,
		active_theme.card_border_width
	)


func make_button_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_soft,
		active_theme.border,
		active_theme.button_corner_radius,
		active_theme.button_border_width
	)


func make_button_hover_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_soft.lightened(active_theme.hover_brightness - 1.0),
		active_theme.border_strong,
		active_theme.button_corner_radius,
		active_theme.button_border_width
	)


func make_button_pressed_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	return make_style_box(
		active_theme.surface_soft.darkened(1.0 - active_theme.pressed_brightness),
		active_theme.accent_primary,
		active_theme.button_corner_radius,
		active_theme.button_border_width
	)


func make_button_disabled_style() -> StyleBoxFlat:
	if active_theme == null:
		return StyleBoxFlat.new()

	var bg_color: Color = active_theme.surface_soft
	var border_color: Color = active_theme.border_soft

	bg_color.a *= active_theme.disabled_opacity
	border_color.a *= active_theme.disabled_opacity

	return make_style_box(
		bg_color,
		border_color,
		active_theme.button_corner_radius,
		active_theme.button_border_width
	)


func make_style_box(
	background_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int
) -> StyleBoxFlat:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()

	style_box.bg_color = background_color
	style_box.border_color = border_color

	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius

	style_box.border_width_left = border_width
	style_box.border_width_top = border_width
	style_box.border_width_right = border_width
	style_box.border_width_bottom = border_width

	style_box.content_margin_left = 12
	style_box.content_margin_top = 12
	style_box.content_margin_right = 12
	style_box.content_margin_bottom = 12

	return style_box
