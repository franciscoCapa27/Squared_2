extends Control
class_name TriangleIndicator

@onready var polygon: Polygon2D = $Polygon2D

var expanded: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_visual_state()


func set_expanded(value: bool) -> void:
	expanded = value
	_apply_visual_state()


func _apply_visual_state() -> void:
	if polygon == null:
		return

	polygon.color = ThemeSystem.get_color("text_primary")
	if expanded:
		polygon.polygon = PackedVector2Array([
			Vector2(2, 3),
			Vector2(14, 3),
			Vector2(8, 13)
		])
	else:
		polygon.polygon = PackedVector2Array([
			Vector2(3, 2),
			Vector2(3, 14),
			Vector2(13, 8)
		])


func _on_theme_changed() -> void:
	_apply_visual_state()
