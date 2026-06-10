extends PanelContainer
class_name SquareDetailsPanel

@onready var selected_square_title: Label = %SelectedSquareTitle
@onready var selected_square_details: RichTextLabel = %SelectedSquareDetails

var selected_square_id: String = ""


func show_square(square_id: String) -> void:
	selected_square_id = square_id
	refresh()


func refresh() -> void:
	if selected_square_id == "":
		clear()
		return

	var square_data: SquareData = GameState.get_square(selected_square_id)

	if square_data == null:
		clear()
		return

	selected_square_title.text = square_data.display_name
	selected_square_details.text = _build_square_details_text(square_data)


func refresh_if_selected(square_id: String) -> void:
	if selected_square_id != square_id:
		return

	refresh()


func clear() -> void:
	selected_square_id = ""
	selected_square_title.text = "No square selected"
	selected_square_details.text = "Click a square to inspect it."


func _build_square_details_text(square_data: SquareData) -> String:
	var manual_payout: float = SquareCalculator.calculate_manual_payout(square_data)
	var respawn_time: float = SquareCalculator.calculate_respawn_time(square_data)

	var trait_stack_text: String = square_data.get_trait_stack_display_text()

	if trait_stack_text == "":
		trait_stack_text = "None"

	var trait_effect_text: String = square_data.get_trait_effect_summary_text()

	if trait_effect_text == "":
		trait_effect_text = "No Trait effects."

	var permanent_base_value_multiplier: float = GameState.get_permanent_stat_multiplier("square_base_value")

	return (
		"ID: %s\n" % square_data.id
		+ "Coordinate: %s\n" % square_data.coordinate
		+ "Grid Position: %s, %s\n\n" % [
			square_data.grid_x,
			square_data.grid_y
		]
		+ "Traits:\n%s\n\n" % trait_stack_text
		+ "Trait Effects:\n%s\n\n" % trait_effect_text
		+ "Current Manual Payout: %.2f Squares\n" % manual_payout
		+ "Current Respawn Time: %.2fs\n\n" % respawn_time
		+ "Base Value: %.2f\n" % square_data.base_value
		+ "Permanent Base Value Multiplier: x%.3f\n" % permanent_base_value_multiplier
		+ "Base Respawn Time: %.2fs\n\n" % square_data.base_respawn_time
		+ "Run Squares Generated: %.2f\n" % square_data.run_squares_generated
		+ "Run Manual Clicks: %s\n" % square_data.run_manual_clicks
		+ "Run Passive Clicks: %s\n\n" % square_data.run_passive_clicks
		+ "Lifetime Squares Generated: %.2f\n" % square_data.lifetime_squares_generated
		+ "Lifetime Manual Clicks: %s\n" % square_data.lifetime_manual_clicks
		+ "Lifetime Passive Clicks: %s\n" % square_data.lifetime_passive_clicks
		+ "Times Traited: %s\n" % square_data.times_traited
		+ "Highest Single Payout: %.2f\n\n" % square_data.highest_single_payout
		+ "Permanent Tags: %s\n" % _format_string_array(square_data.permanent_tags)
		+ "Temporary Tags: %s" % _format_string_array(square_data.temporary_tags)
	)


func _format_string_array(values: Array[String]) -> String:
	if values.is_empty():
		return "None"

	return ", ".join(values)
