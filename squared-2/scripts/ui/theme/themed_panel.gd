extends PanelContainer
class_name ThemedPanel

enum PanelStyle {
	NORMAL,
	ELEVATED,
	CARD,
	SELECTED_CARD
}

@export var panel_style: PanelStyle = PanelStyle.NORMAL
@export var apply_on_ready: bool = true


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)

	if apply_on_ready:
		apply_theme()


func apply_theme() -> void:
	match panel_style:
		PanelStyle.NORMAL:
			add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())
		PanelStyle.ELEVATED:
			add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())
		PanelStyle.CARD:
			add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
		PanelStyle.SELECTED_CARD:
			add_theme_stylebox_override("panel", ThemeSystem.make_selected_card_style())


func _on_theme_changed() -> void:
	apply_theme()
