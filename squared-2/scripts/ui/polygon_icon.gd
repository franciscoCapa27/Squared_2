extends Control
class_name PolygonIcon

@export_enum("diamond", "passive", "triangle", "spark", "square", "check") var icon_kind: String = "diamond"
@export var icon_color: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func set_icon_kind(next_kind: String) -> void:
	icon_kind = next_kind
	queue_redraw()


func set_icon_color(next_color: Color) -> void:
	icon_color = next_color
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.38
	var points: PackedVector2Array = PackedVector2Array()

	match icon_kind:
		"passive":
			draw_circle(center, radius * 0.75, icon_color, false, maxf(1.0, radius * 0.12))
			draw_circle(center, radius * 0.18, icon_color)
		"triangle":
			points = PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius, radius),
				center + Vector2(-radius, radius),
			])
			draw_colored_polygon(points, icon_color)
		"spark":
			points = PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius * 0.35, -radius * 0.35),
				center + Vector2(radius, 0.0),
				center + Vector2(radius * 0.35, radius * 0.35),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.35, radius * 0.35),
				center + Vector2(-radius, 0.0),
				center + Vector2(-radius * 0.35, -radius * 0.35),
			])
			draw_colored_polygon(points, icon_color)
		"square":
			points = PackedVector2Array([
				center + Vector2(-radius, -radius),
				center + Vector2(radius, -radius),
				center + Vector2(radius, radius),
				center + Vector2(-radius, radius),
			])
			draw_colored_polygon(points, icon_color)
		"check":
			draw_line(center + Vector2(-radius, 0.0), center + Vector2(-radius * 0.2, radius * 0.7), icon_color, maxf(1.0, radius * 0.2), true)
			draw_line(center + Vector2(-radius * 0.2, radius * 0.7), center + Vector2(radius, -radius * 0.8), icon_color, maxf(1.0, radius * 0.2), true)
		_:
			points = PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius, 0.0),
				center + Vector2(0.0, radius),
				center + Vector2(-radius, 0.0),
			])
			draw_colored_polygon(points, icon_color)
