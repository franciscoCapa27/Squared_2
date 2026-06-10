extends Panel
class_name ThemedBackground


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	apply_theme()


func apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_background_style())


func _on_theme_changed() -> void:
	apply_theme()
