extends Button
class_name AchievementIconTile

signal selected(achievement_id: String)

var achievement_definition: AchievementDefinition
@onready var polygon_icon: PolygonIcon = %Icon
var icon_kind: String = "spark"
var is_selected: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_theme()


func setup(achievement: AchievementDefinition, authored_icon_glyph: String) -> void:
	achievement_definition = achievement
	icon_kind = authored_icon_glyph
	polygon_icon.set_icon_kind(icon_kind)
	refresh()


func refresh() -> void:
	if achievement_definition == null:
		return

	text = ""
	polygon_icon.set_icon_kind(icon_kind)
	polygon_icon.set_icon_color(ThemeSystem.get_color("accent_primary") if AchievementSystem.is_achievement_unlocked(achievement_definition.id) else ThemeSystem.get_color("text_muted"))
	tooltip_text = "%s\n%s" % [
		achievement_definition.display_name,
		"Unlocked" if AchievementSystem.is_achievement_unlocked(achievement_definition.id) else "Locked",
	]
	_apply_state_theme()


func set_selected(selected_state: bool) -> void:
	is_selected = selected_state
	_apply_state_theme()


func _apply_theme() -> void:
	ThemeButtonHelper.apply_button_theme(self)
	add_theme_font_size_override("font_size", ThemeSystem.get_font_size("panel_title"))
	_apply_state_theme()


func _apply_state_theme() -> void:
	if achievement_definition == null:
		return

	var unlocked: bool = AchievementSystem.is_achievement_unlocked(achievement_definition.id)
	if is_selected or unlocked:
		add_theme_stylebox_override("normal", ThemeSystem.make_selected_card_style())
		add_theme_stylebox_override("hover", ThemeSystem.make_selected_card_style())
		add_theme_color_override("font_color", ThemeSystem.get_color("accent_primary"))
	else:
		add_theme_stylebox_override("normal", ThemeSystem.make_card_style())
		add_theme_stylebox_override("hover", ThemeSystem.make_selected_card_style())
		add_theme_color_override("font_color", ThemeSystem.get_color("text_muted"))


func _on_pressed() -> void:
	if achievement_definition == null:
		return

	selected.emit(achievement_definition.id)
