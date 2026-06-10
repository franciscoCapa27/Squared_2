extends RefCounted
class_name ThemeLayoutHelper


static func apply_margin(
	margin_container: MarginContainer,
	margin_id: String = "inner_margin"
) -> void:
	if margin_container == null:
		return

	var margin: int = ThemeSystem.get_spacing(margin_id)

	margin_container.add_theme_constant_override("margin_left", margin)
	margin_container.add_theme_constant_override("margin_top", margin)
	margin_container.add_theme_constant_override("margin_right", margin)
	margin_container.add_theme_constant_override("margin_bottom", margin)


static func apply_box_separation(
	box_container: BoxContainer,
	spacing_id: String = "section_gap"
) -> void:
	if box_container == null:
		return

	box_container.add_theme_constant_override(
		"separation",
		ThemeSystem.get_spacing(spacing_id)
	)


static func apply_grid_separation(grid_container: GridContainer) -> void:
	if grid_container == null:
		return

	var gap: int = ThemeSystem.get_spacing("grid_gap")

	grid_container.add_theme_constant_override("h_separation", gap)
	grid_container.add_theme_constant_override("v_separation", gap)
