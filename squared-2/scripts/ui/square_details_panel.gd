extends PanelContainer
class_name SquareDetailsPanel

@onready var selected_square_title: CollapsiblePanelHeader = %SelectedSquareTitle
@onready var selected_square_details: ScrollContainer = %SelectedSquareDetails
@onready var details_content: VBoxContainer = %SquareDetailsContent
@onready var side_margin: MarginContainer = %SideMargin
@onready var side_v_box: VBoxContainer = %SideVbox
@onready var selected_square_help: ContextualHelp = %SelectedSquareHelp

var selected_square_id: String = ""


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	clear()


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())
	ThemeLayoutHelper.apply_dense_margin(side_margin, "inner_margin")
	ThemeLayoutHelper.apply_dense_box_separation(side_v_box, "section_gap")
	details_content.add_theme_constant_override("separation", 1)


func _on_theme_changed() -> void:
	_apply_theme()
	refresh()


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
	selected_square_help.help_detail = _get_square_help_detail(square_data)
	selected_square_help.tooltip_text = "%s\n%s" % [
		selected_square_help.help_title,
		selected_square_help.help_detail,
	]
	_rebuild_details(square_data)


func refresh_if_selected(square_id: String) -> void:
	if selected_square_id != square_id:
		return

	refresh()


func clear() -> void:
	selected_square_id = ""
	selected_square_title.set_title("No square selected")
	selected_square_help.help_detail = "Select a square to inspect every Trait and modifier on it."
	_rebuild_empty_details()


func _rebuild_empty_details() -> void:
	_clear_details_content()
	var empty_label: Label = Label.new()
	empty_label.text = "Click a square to inspect it."
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeTextHelper.apply_body_label(empty_label)
	details_content.add_child(empty_label)


func _rebuild_details(square_data: SquareData) -> void:
	_clear_details_content()
	_add_detail_pair_row(
		"Trait count",
		NumberFormatter.integer_amount(square_data.get_trait_count()),
		"Position",
		square_data.coordinate
	)
	_add_detail_pair_row(
		"Current payout",
		NumberFormatter.amount(SquareCalculator.calculate_manual_payout(square_data)),
		"Respawn",
		NumberFormatter.seconds(SquareCalculator.calculate_respawn_time(square_data))
	)

	_add_section_title("Trait Families")
	var family_groups: Array[Dictionary] = _get_family_groups(square_data)
	if family_groups.is_empty():
		var no_traits_label: Label = Label.new()
		no_traits_label.text = "None"
		ThemeTextHelper.apply_body_label(no_traits_label)
		details_content.add_child(no_traits_label)
		return

	for family_info: Dictionary in family_groups:
		_add_family_summary(family_info)


func _clear_details_content() -> void:
	for child: Node in details_content.get_children():
		child.queue_free()


func _add_section_title(title_text: String) -> void:
	var section_title: Label = Label.new()
	section_title.text = title_text
	ThemeTextHelper.apply_panel_title(section_title)
	section_title.add_theme_font_size_override(
		"font_size",
		ThemeSystem.get_compact_font_size("panel_title")
	)
	section_title.custom_minimum_size.y = 18.0
	details_content.add_child(section_title)


func _add_detail_pair_row(
	left_label_text: String,
	left_value_text: String,
	right_label_text: String,
	right_value_text: String
) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 16.0
	row.add_theme_constant_override("separation", 4)
	details_content.add_child(row)

	_add_detail_pair(row, left_label_text, left_value_text)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_add_detail_pair(row, right_label_text, right_value_text)


func _add_detail_pair(row: HBoxContainer, label_text: String, value_text: String) -> void:
	var name_label: Label = Label.new()
	name_label.text = "%s:" % label_text
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ThemeTextHelper.apply_body_label(name_label)
	row.add_child(name_label)

	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ThemeTextHelper.apply_primary_label(value_label)
	row.add_child(value_label)


func _add_family_summary(family_info: Dictionary) -> void:
	var family_label: RichTextLabel = RichTextLabel.new()
	family_label.bbcode_enabled = true
	family_label.fit_content = true
	family_label.scroll_active = false
	family_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	family_label.custom_minimum_size.y = 16.0
	ThemeTextHelper.apply_detail_rich_text(family_label)
	family_label.add_theme_font_size_override(
		"normal_font_size",
		ThemeSystem.get_compact_font_size("detail")
	)
	family_label.add_theme_font_size_override(
		"bold_font_size",
		ThemeSystem.get_compact_font_size("detail")
	)
	family_label.text = _build_family_summary_text(family_info)
	details_content.add_child(family_label)


func _get_family_groups(square_data: SquareData) -> Array[Dictionary]:
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
		var effects: Array[Dictionary] = []
		for effect_variant: Variant in family_info["effects"] as Array:
			effects.append(effect_variant as Dictionary)
		for effect_entry: Dictionary in _get_effect_entries(trait_iter):
			var is_duplicate: bool = false
			for existing_effect: Dictionary in effects:
				if str(existing_effect["text"]) == str(effect_entry["text"]):
					is_duplicate = true
					break
			if not is_duplicate:
				effects.append(effect_entry)
		family_info["effects"] = effects
		family_groups[family_key] = family_info

	var result: Array[Dictionary] = []
	for family_key: String in family_groups.keys():
		var family_info: Dictionary = family_groups[family_key]
		result.append({
			"display_name": family_info["display_name"],
			"count": int(family_info["count"]),
			"max_rarity": int(family_info["max_rarity"]),
			"effects": family_info["effects"]
		})

	result.sort_custom(_sort_family_groups)
	return result


func _sort_family_groups(left: Dictionary, right: Dictionary) -> bool:
	var left_rarity: int = int(left["max_rarity"])
	var right_rarity: int = int(right["max_rarity"])
	if left_rarity != right_rarity:
		return left_rarity > right_rarity

	var left_count: int = int(left["count"])
	var right_count: int = int(right["count"])
	if left_count != right_count:
		return left_count > right_count

	return str(left["display_name"]).nocasecmp_to(str(right["display_name"])) < 0


func _build_family_summary_text(family_info: Dictionary) -> String:
	var rarity_name: String = TraitDefinition.rarity_name_from_value(
		int(family_info["max_rarity"])
	)
	var title: String = "%s %s (%s)" % [
		family_info["display_name"],
		_to_roman(int(family_info["count"])),
		rarity_name.to_lower()
	]
	var lines: Array[String] = [
		"[color=%s][b]%s[/b][/color]" % [
			ThemeTextHelper.get_rarity_color_hex(rarity_name),
			title
		]
	]

	for effect_entry: Dictionary in family_info["effects"] as Array:
		var effect_color: String = _get_effect_color_hex(bool(effect_entry["beneficial"]))
		lines.append("[color=%s]• %s[/color]" % [effect_color, effect_entry["text"]])

	return "\n".join(lines)


func _get_effect_entries(trait_iter: TraitInstance) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var summary_lines: Array[String] = trait_iter.get_effect_summary_lines()
	var summary_index: int = 0

	for effect_iter: EffectComponent in trait_iter.get_effective_components():
		if effect_iter == null or effect_iter.effect_type != EffectComponent.EffectType.STAT_MODIFIER:
			continue

		if summary_index >= summary_lines.size():
			break

		entries.append({
			"text": summary_lines[summary_index],
			"beneficial": _is_effect_beneficial(effect_iter, trait_iter.get_effect_value(effect_iter))
		})
		summary_index += 1

	return entries


func _is_effect_beneficial(effect_iter: EffectComponent, effect_value: float) -> bool:
	var higher_is_better: bool = effect_iter.target_stat != "respawn_time"
	var direction: float = 0.0

	match effect_iter.operation:
		EffectComponent.Operation.ADD:
			direction = effect_value
		EffectComponent.Operation.SUBTRACT:
			direction = -effect_value
		EffectComponent.Operation.MULTIPLY:
			direction = effect_value - 1.0
		EffectComponent.Operation.DIVIDE:
			direction = 1.0 - effect_value
		EffectComponent.Operation.OVERRIDE:
			direction = effect_value - 1.0

	return direction > 0.0 if higher_is_better else direction < 0.0


func _get_effect_color_hex(beneficial: bool) -> String:
	var color: Color = ThemeSystem.get_color("success" if beneficial else "danger")
	return color.to_html(false)


func _get_square_help_detail(square_data: SquareData) -> String:
	var lines: Array[String] = []
	for trait_iter: TraitInstance in square_data.traits:
		if trait_iter == null or trait_iter.definition == null:
			continue

		var trait_title: String = trait_iter.definition.get_stack_display_name()
		if trait_iter.stack_index > 1:
			trait_title += " #%s" % trait_iter.stack_index
		lines.append("%s (%s)" % [trait_title, trait_iter.definition.get_rarity_name().to_lower()])
		for effect_line: String in trait_iter.get_effect_summary_lines():
			lines.append("  %s" % effect_line)

	if lines.is_empty():
		return "This square has no Traits or modifiers yet."

	return "Traits and modifiers:\n%s" % "\n".join(lines)


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
