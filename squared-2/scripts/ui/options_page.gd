extends Control
class_name OptionsPage

signal save_imported()
signal hard_reset_completed()

const HARD_RESET_CONFIRM_SECONDS := 5.0

@onready var options_margin: MarginContainer = $OptionsMargin
@onready var options_v_box: VBoxContainer = $OptionsMargin/OptionsScroll/OptionsVBox

@onready var autosave_enabled_check_box: CheckBox = %AutosaveEnabledCheckBox
@onready var autosave_interval_spin_box: SpinBox = %AutosaveIntervalSpinBox
@onready var cheat_square_value_check_box: CheckBox = %CheatSquareValueCheckBox
@onready var theme_option_button: OptionButton = %ThemeOptionButton
@onready var options_title_label: Label = %OptionsTitle
@onready var theme_label: Label = %ThemeLabel
@onready var autosave_title_label: Label = %AutosaveTitle
@onready var autosave_interval_label: Label = %AutosaveIntervalLabel
@onready var testing_title_label: Label = %TestingTitle
@onready var save_data_title_label: Label = %SaveDataTitle
@onready var hard_reset_title_label: Label = %HardResetTitle

@onready var save_button: Button = %SaveButton
@onready var export_save_button: Button = %ExportSaveButton
@onready var export_save_text: TextEdit = %ExportSaveText
@onready var import_save_text: TextEdit = %ImportSaveText
@onready var import_save_button: Button = %ImportSaveButton
@onready var hard_reset_button: Button = %HardResetButton
@onready var options_status_label: Label = %OptionsStatusLabel

var hard_reset_confirm_remaining: float = 0.0
var is_syncing_controls: bool = false

func _ready() -> void:
	autosave_enabled_check_box.toggled.connect(_on_autosave_enabled_toggled)
	autosave_interval_spin_box.value_changed.connect(_on_autosave_interval_changed)
	cheat_square_value_check_box.toggled.connect(_on_cheat_square_value_toggled)
	theme_option_button.item_selected.connect(_on_theme_selected)
	ThemeSystem.theme_changed.connect(_on_theme_changed)

	save_button.pressed.connect(_on_save_button_pressed)
	export_save_button.pressed.connect(_on_export_save_button_pressed)
	import_save_button.pressed.connect(_on_import_save_button_pressed)
	hard_reset_button.pressed.connect(_on_hard_reset_button_pressed)

	SaveSystem.save_saved.connect(_on_save_saved)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	SaveSystem.save_failed.connect(_on_save_failed)
	
	SaveSystem.save_settings_changed.connect(_on_save_settings_changed)

	_sync_from_save_system()
	_populate_theme_options()
	_apply_theme()


func _process(delta: float) -> void:
	if hard_reset_confirm_remaining <= 0.0:
		return

	hard_reset_confirm_remaining -= delta

	if hard_reset_confirm_remaining <= 0.0:
		hard_reset_confirm_remaining = 0.0
		hard_reset_button.text = "HARD RESET"


func refresh() -> void:
	_sync_from_save_system()


func _sync_from_save_system() -> void:
	is_syncing_controls = true

	autosave_enabled_check_box.button_pressed = SaveSystem.autosave_enabled
	autosave_interval_spin_box.value = SaveSystem.get_autosave_interval_seconds()
	autosave_interval_spin_box.editable = SaveSystem.autosave_enabled
	cheat_square_value_check_box.button_pressed = GameState.cheat_square_value_enabled
	_select_theme_option(SaveSystem.theme_id)

	is_syncing_controls = false


func _populate_theme_options() -> void:
	theme_option_button.clear()
	for theme_id: String in ThemeSystem.get_available_theme_ids():
		theme_option_button.add_item(ThemeSystem.get_theme_display_name(theme_id))
		theme_option_button.set_item_metadata(theme_option_button.item_count - 1, theme_id)
	_select_theme_option(ThemeSystem.get_theme_id())


func _select_theme_option(theme_id: String) -> void:
	for index: int in theme_option_button.item_count:
		if str(theme_option_button.get_item_metadata(index)) == theme_id:
			theme_option_button.select(index)
			return


func _on_autosave_enabled_toggled(enabled: bool) -> void:
	if is_syncing_controls:
		return

	SaveSystem.set_autosave_enabled(enabled)
	autosave_interval_spin_box.editable = enabled

	if enabled:
		options_status_label.text = "Autosave enabled."
	else:
		options_status_label.text = "Autosave disabled."


func _on_autosave_interval_changed(value: float) -> void:
	if is_syncing_controls:
		return

	SaveSystem.set_autosave_interval_seconds(value)
	options_status_label.text = "Autosave interval set to %s seconds." % int(value)


func _on_cheat_square_value_toggled(enabled: bool) -> void:
	if is_syncing_controls:
		return

	GameState.cheat_square_value_enabled = enabled
	if enabled:
		options_status_label.text = "Cheat enabled: Squares are worth x100."
	else:
		options_status_label.text = "Cheat disabled: normal Square values restored."


func _on_theme_selected(index: int) -> void:
	if is_syncing_controls:
		return

	var selected_theme_id: String = str(theme_option_button.get_item_metadata(index))
	if not ThemeSystem.load_theme_by_id(selected_theme_id):
		return

	SaveSystem.set_theme_id(selected_theme_id)
	options_status_label.text = "Theme set to %s." % ThemeSystem.get_theme_display_name(selected_theme_id)
	# OptionButton closes its PopupMenu after item selection. Reopen it after
	# the theme refresh so the player can compare themes until clicking away.
	call_deferred("_reopen_theme_popup")


func _reopen_theme_popup() -> void:
	if not is_inside_tree() or not theme_option_button.visible:
		return
	theme_option_button.show_popup()


func _on_theme_changed() -> void:
	_apply_theme()


func _apply_theme() -> void:
	ThemeLayoutHelper.apply_dense_margin(options_margin, "inner_margin")
	ThemeLayoutHelper.apply_dense_box_separation(options_v_box, "section_gap")

	ThemeButtonHelper.apply_button_theme(save_button)
	ThemeButtonHelper.apply_button_theme(export_save_button)
	ThemeButtonHelper.apply_button_theme(import_save_button)
	ThemeButtonHelper.apply_button_theme(hard_reset_button)
	ThemeButtonHelper.apply_button_theme(theme_option_button)
	_apply_control_text(autosave_enabled_check_box)
	_apply_control_text(autosave_interval_spin_box)
	_apply_control_text(cheat_square_value_check_box)
	_apply_control_text(autosave_interval_spin_box.get_line_edit())
	_apply_text_edit_theme(export_save_text)
	_apply_text_edit_theme(import_save_text)
	ThemeTextHelper.apply_page_title(options_title_label)
	ThemeTextHelper.apply_body_label(theme_label)
	ThemeTextHelper.apply_body_label(autosave_title_label)
	ThemeTextHelper.apply_body_label(autosave_interval_label)
	ThemeTextHelper.apply_body_label(testing_title_label)
	ThemeTextHelper.apply_body_label(save_data_title_label)
	ThemeTextHelper.apply_body_label(hard_reset_title_label)
	ThemeTextHelper.apply_body_label(options_status_label)


func _apply_control_text(control: Control) -> void:
	if control == null:
		return

	control.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
	control.add_theme_font_size_override("font_size", ThemeSystem.get_font_size("body"))


func _apply_text_edit_theme(text_edit: TextEdit) -> void:
	if text_edit == null:
		return

	text_edit.add_theme_stylebox_override("normal", ThemeSystem.make_card_style())
	text_edit.add_theme_color_override("font_color", ThemeSystem.get_color("text_primary"))
	text_edit.add_theme_color_override("font_placeholder_color", ThemeSystem.get_color("text_muted"))
	text_edit.add_theme_font_size_override("font_size", ThemeSystem.get_font_size("body"))


func _on_save_button_pressed() -> void:
	var saved: bool = SaveSystem.save_game()

	if saved:
		options_status_label.text = "Game saved."


func _on_export_save_button_pressed() -> void:
	export_save_text.text = SaveSystem.export_save_string()
	options_status_label.text = "Save exported."


func _on_import_save_button_pressed() -> void:
	var imported: bool = SaveSystem.import_save_string(import_save_text.text)

	if imported:
		options_status_label.text = "Save imported."
		save_imported.emit()
	else:
		options_status_label.text = "Import failed."


func _on_hard_reset_button_pressed() -> void:
	if hard_reset_confirm_remaining <= 0.0:
		hard_reset_confirm_remaining = HARD_RESET_CONFIRM_SECONDS
		hard_reset_button.text = "Click again to confirm"
		options_status_label.text = "Hard reset will erase progression. Click again to confirm."
		return

	hard_reset_confirm_remaining = 0.0
	hard_reset_button.text = "HARD RESET"

	SaveSystem.hard_reset()
	options_status_label.text = "Hard reset complete."
	hard_reset_completed.emit()


func _on_save_saved() -> void:
	options_status_label.text = "Game saved."


func _on_save_loaded() -> void:
	_sync_from_save_system()

func _on_save_settings_changed() -> void:
	_sync_from_save_system()

func _on_save_failed(message: String) -> void:
	options_status_label.text = message
