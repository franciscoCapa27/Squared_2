extends PanelContainer
class_name OptionsPage

signal save_imported()
signal hard_reset_completed()

const HARD_RESET_CONFIRM_SECONDS := 5.0

@onready var autosave_enabled_check_box: CheckBox = %AutosaveEnabledCheckBox
@onready var autosave_interval_spin_box: SpinBox = %AutosaveIntervalSpinBox
@onready var cheat_square_value_check_box: CheckBox = %CheatSquareValueCheckBox

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

	save_button.pressed.connect(_on_save_button_pressed)
	export_save_button.pressed.connect(_on_export_save_button_pressed)
	import_save_button.pressed.connect(_on_import_save_button_pressed)
	hard_reset_button.pressed.connect(_on_hard_reset_button_pressed)

	SaveSystem.save_saved.connect(_on_save_saved)
	SaveSystem.save_loaded.connect(_on_save_loaded)
	SaveSystem.save_failed.connect(_on_save_failed)
	
	SaveSystem.save_settings_changed.connect(_on_save_settings_changed)

	_sync_from_save_system()


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

	is_syncing_controls = false


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
