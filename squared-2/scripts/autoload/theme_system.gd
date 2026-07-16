extends Node

signal theme_changed()

const DEFAULT_THEME_PATH := "res://data/themes/void_dark.tres"
const THEME_PATHS := {
	"void_dark": DEFAULT_THEME_PATH,
	"paper_light": "res://data/themes/paper_light.tres",
	"weird_pastel": "res://data/themes/weird_pastel.tres",
	"ember_glow": "res://data/themes/ember_glow.tres",
	"oceanic": "res://data/themes/oceanic.tres",
	"lavender_mist": "res://data/themes/lavender_mist.tres",
	"forest_moss": "res://data/themes/forest_moss.tres",
	"sunset_coral": "res://data/themes/sunset_coral.tres",
	"monochrome_ice": "res://data/themes/monochrome_ice.tres",
	"retro_terminal": "res://data/themes/retro_terminal.tres",
	"desert_dusk": "res://data/themes/desert_dusk.tres",
	"neon_arcade": "res://data/themes/neon_arcade.tres",
	"solarized_day": "res://data/themes/solarized_day.tres"
}
const THEME_DISPLAY_NAMES := {
	"void_dark": "Void Dark",
	"paper_light": "Paper Light",
	"weird_pastel": "Weird Pastel",
	"ember_glow": "Ember Glow",
	"oceanic": "Oceanic",
	"lavender_mist": "Lavender Mist",
	"forest_moss": "Forest Moss",
	"sunset_coral": "Sunset Coral",
	"monochrome_ice": "Monochrome Ice",
	"retro_terminal": "Retro Terminal",
	"desert_dusk": "Desert Dusk",
	"neon_arcade": "Neon Arcade",
	"solarized_day": "Solarized Day"
}

var active_theme: UIThemeDefinition


func _ready() -> void:
	load_theme(DEFAULT_THEME_PATH)


func load_theme(theme_path: String) -> bool:
	var resource: Resource = load(theme_path)

	if resource == null:
		push_error("Failed to load UI theme: %s" % theme_path)
		return false

	if not resource is UIThemeDefinition:
		push_error("Resource is not a UIThemeDefinition: %s" % theme_path)
		return false

	active_theme = resource as UIThemeDefinition
	theme_changed.emit()
	return true


func get_available_theme_ids() -> Array[String]:
	return [
		"void_dark",
		"paper_light",
		"weird_pastel",
		"ember_glow",
		"oceanic",
		"lavender_mist",
		"forest_moss",
		"sunset_coral",
		"monochrome_ice",
		"retro_terminal",
		"desert_dusk",
		"neon_arcade",
		"solarized_day"
	]


func get_theme_display_name(theme_id: String) -> String:
	return str(THEME_DISPLAY_NAMES.get(theme_id, theme_id))


func load_theme_by_id(theme_id: String) -> bool:
	if not THEME_PATHS.has(theme_id):
		return false

	var theme_path: String = str(THEME_PATHS[theme_id])
	return load_theme(theme_path)


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

	var inner_margin: int = get_spacing("inner_margin")

	style_box.content_margin_left = inner_margin
	style_box.content_margin_top = inner_margin
	style_box.content_margin_right = inner_margin
	style_box.content_margin_bottom = inner_margin

	return style_box

func get_spacing(spacing_id: String) -> int:
	if active_theme == null:
		return 0

	match spacing_id:
		"screen_margin":
			return active_theme.screen_margin
		"panel_gap":
			return active_theme.panel_gap
		"section_gap":
			return active_theme.section_gap
		"card_gap":
			return active_theme.card_gap
		"inner_margin":
			return active_theme.inner_margin
		"grid_gap":
			return active_theme.grid_gap
		"trait_purchase_gap":
			return active_theme.trait_purchase_gap
		_:
			push_warning("Unknown theme spacing id: %s" % spacing_id)
			return 0
func get_font_size(font_size_id: String) -> int:
	if active_theme == null:
		return 14

	match font_size_id:
		"resource":
			return active_theme.font_size_resource
		"page_title":
			return active_theme.font_size_page_title
		"panel_title":
			return active_theme.font_size_panel_title
		"card_title":
			return active_theme.font_size_card_title
		"body":
			return active_theme.font_size_body
		"detail":
			return active_theme.font_size_detail
		"button":
			return active_theme.font_size_button
		"tiny":
			return active_theme.font_size_tiny
		_:
			push_warning("Unknown theme font size id: %s" % font_size_id)
			return active_theme.font_size_body


func get_compact_font_size(font_size_id: String) -> int:
	if active_theme == null:
		return get_font_size(font_size_id)

	var base_size: int = get_font_size(font_size_id)
	return max(8, int(round(float(base_size) * active_theme.compact_text_scale)))
