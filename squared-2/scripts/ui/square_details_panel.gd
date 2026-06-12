extends PanelContainer
class_name SquareDetailsPanel

@onready var selected_square_title: Label = %SelectedSquareTitle
@onready var selected_square_details: RichTextLabel = %SelectedSquareDetails
@onready var side_margin: MarginContainer = %RunUpgradesMargin
@onready var side_v_box: VBoxContainer = %RunUpgradesVBox


var selected_square_id: String = ""

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	
func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())

	ThemeLayoutHelper.apply_margin(side_margin, "inner_margin")
	ThemeLayoutHelper.apply_box_separation(side_v_box, "section_gap")
	ThemeTextHelper.apply_auto_shrinking_title(
		selected_square_title,
		selected_square_title.text,
		"panel_title"
	)
	ThemeTextHelper.apply_detail_rich_text(selected_square_details)


func _on_theme_changed() -> void:
	_apply_theme()
	
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

	ThemeTextHelper.apply_auto_shrinking_title(
		selected_square_title,
		square_data.display_name,
		"panel_title"
	)
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
		trait_effect_text = "No active trait effects."

	return (
		"Base Value                                      %s\n" % NumberFormatter.amount(square_data.base_value)
		+ "Manual Value                                  %s\n" % NumberFormatter.amount(manual_payout)
		+ "Respawn Time                                  %s\n\n" % NumberFormatter.seconds(respawn_time)
		+ "Traits\n%s\n\n" % trait_stack_text
		+ "Main Effects\n%s" % trait_effect_text
	)

func _format_string_array(values: Array[String]) -> String:
	if values.is_empty():
		return "None"

	return ", ".join(values)
	
