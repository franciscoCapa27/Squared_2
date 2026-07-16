extends PanelContainer
class_name SquareDetailsPanel

@onready var selected_square_title: CollapsiblePanelHeader = %SelectedSquareTitle
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

	selected_square_title.set_title(square_data.display_name)
	selected_square_details.text = _build_square_details_text(square_data)


func refresh_if_selected(square_id: String) -> void:
	if selected_square_id != square_id:
		return

	refresh()


func clear() -> void:
	selected_square_id = ""
	selected_square_title.set_title("No square selected")
	selected_square_details.text = "Click a square to inspect it."


func _build_square_details_text(square_data: SquareData) -> String:
	var manual_payout: float = SquareCalculator.calculate_manual_payout(square_data)
	var respawn_time: float = SquareCalculator.calculate_respawn_time(square_data)

	return (
		"Position: (%s, %s)\n" % [square_data.grid_x, square_data.grid_y]
		+ "Trait count: %s\n" % NumberFormatter.integer_amount(square_data.get_trait_count())
		+ "Current payout: %s\n" % NumberFormatter.amount(manual_payout)
		+ "Respawn: %s\n\n" % NumberFormatter.seconds(respawn_time)
		+ "Trait Families\n%s" % _build_family_summary_text(square_data)
	)


func _build_family_summary_text(square_data: SquareData) -> String:
	if square_data.traits.is_empty():
		return "None"

	var family_groups: Dictionary = {}
	for trait_iter: TraitInstance in square_data.traits:
		if trait_iter == null or trait_iter.definition == null:
			continue

		var family_key: String = trait_iter.definition.family_id.strip_edges()
		if family_key == "":
			family_key = trait_iter.definition.id

		if not family_groups.has(family_key):
			family_groups[family_key] = {
				"display_name": _get_family_display_name(trait_iter),
				"count": 0,
				"max_rarity": -1,
				"effects": []
			}

		var family_info: Dictionary = family_groups[family_key]
		family_info["count"] = int(family_info["count"]) + 1
		family_info["max_rarity"] = maxi(
			int(family_info["max_rarity"]),
			int(trait_iter.definition.rarity)
		)
		var effects: Array[String] = family_info["effects"] as Array[String]
		for effect_line: String in trait_iter.get_effect_summary_lines():
			if not effects.has(effect_line):
				effects.append(effect_line)
		family_info["effects"] = effects
		family_groups[family_key] = family_info

	var lines: Array[String] = []
	for family_key: String in family_groups.keys():
		var family_info: Dictionary = family_groups[family_key]
		var rarity_name: String = TraitDefinition.rarity_name_from_value(
			int(family_info["max_rarity"])
		)
		lines.append(
			"%s %s (%s)" % [
				family_info["display_name"],
				_to_roman(int(family_info["count"])),
				rarity_name
			]
		)

		var effects: Array[String] = family_info["effects"] as Array[String]
		if effects.is_empty():
			lines.append("  No active effects.")
			continue

		for effect_line: String in effects:
			lines.append("  %s" % effect_line)

	return "\n".join(lines)


func _get_family_display_name(trait_iter: TraitInstance) -> String:
	var family_display_name: String = trait_iter.definition.family_display_name.strip_edges()
	if family_display_name != "":
		return family_display_name

	if trait_iter.definition.family_id.strip_edges() != "":
		return trait_iter.definition.family_id

	return trait_iter.definition.id


func _to_roman(value: int) -> String:
	var remaining: int = maxi(1, value)
	var result: String = ""
	var numerals: Array[Array] = [
		[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
		[100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
		[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]
	]

	for numeral: Array in numerals:
		while remaining >= int(numeral[0]):
			result += numeral[1]
			remaining -= int(numeral[0])

	return result
