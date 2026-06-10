extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"
const MIN_AUTOSAVE_INTERVAL_SECONDS := 5.0
const DEFAULT_AUTOSAVE_INTERVAL_SECONDS := 60.0

signal save_loaded()
signal save_saved()
signal save_failed(message: String)
signal save_settings_changed()


var autosave_enabled: bool = true
var autosave_interval_seconds: float = DEFAULT_AUTOSAVE_INTERVAL_SECONDS
var autosave_elapsed_seconds: float = 0.0
var is_applying_save_data: bool = false


func _process(delta: float) -> void:
	if not autosave_enabled:
		return

	if autosave_interval_seconds <= 0.0:
		return

	if is_applying_save_data:
		return

	autosave_elapsed_seconds += delta

	if autosave_elapsed_seconds >= autosave_interval_seconds:
		autosave_elapsed_seconds = 0.0
		save_game()

func save_game() -> bool:
	var save_data: Dictionary = _build_save_data()
	var json_text: String = JSON.stringify(save_data)

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		var error_message: String = "Could not open save file for writing."
		push_error(error_message)
		save_failed.emit(error_message)
		return false

	file.store_string(json_text)
	file.close()

	save_saved.emit()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		var error_message: String = "Could not open save file for reading."
		push_error(error_message)
		save_failed.emit(error_message)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)

	if not parsed is Dictionary:
		var error_message: String = "Save file is not valid JSON."
		push_error(error_message)
		save_failed.emit(error_message)
		return false

	_apply_save_data(parsed as Dictionary)

	save_loaded.emit()
	return true

func hard_reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	var preserved_autosave_enabled: bool = autosave_enabled
	var preserved_autosave_interval_seconds: float = autosave_interval_seconds

	GameState.reset_to_new_game()
	PassiveSystem.reset_to_new_game()
	AchievementSystem.reset_to_new_game()

	autosave_enabled = preserved_autosave_enabled
	autosave_interval_seconds = preserved_autosave_interval_seconds
	autosave_elapsed_seconds = 0.0

	save_game()

func export_save_string() -> String:
	var save_data: Dictionary = _build_save_data()
	var json_text: String = JSON.stringify(save_data)
	var bytes: PackedByteArray = json_text.to_utf8_buffer()
	var compressed: PackedByteArray = bytes.compress(FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(compressed)

func import_save_string(import_text: String) -> bool:
	var clean_text: String = import_text.strip_edges()

	if clean_text == "":
		var empty_error: String = "Import string is empty."
		save_failed.emit(empty_error)
		return false

	var compressed: PackedByteArray = Marshalls.base64_to_raw(clean_text)

	if compressed.is_empty():
		var base64_error: String = "Import string is not valid Base64."
		save_failed.emit(base64_error)
		return false

	var decompressed: PackedByteArray = compressed.decompress_dynamic(
		-1,
		FileAccess.COMPRESSION_GZIP
	)

	if decompressed.is_empty():
		var decompress_error: String = "Could not decompress import string."
		save_failed.emit(decompress_error)
		return false

	var json_text: String = decompressed.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json_text)

	if not parsed is Dictionary:
		var json_error: String = "Imported save is not valid JSON."
		save_failed.emit(json_error)
		return false

	_apply_save_data(parsed as Dictionary)
	save_game()

	save_loaded.emit()
	return true

func _build_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"settings": {
			"autosave_enabled": autosave_enabled,
			"autosave_interval_seconds": autosave_interval_seconds
		},
		"game_state": GameState.to_save_dict(),
		"passive_system": PassiveSystem.to_save_dict(),
		"achievement_system": AchievementSystem.to_save_dict()
	}

func _apply_save_data(save_data: Dictionary) -> void:
	is_applying_save_data = true

	var version: int = int(save_data.get("version", 0))

	if version > SAVE_VERSION:
		push_warning("Save version is newer than current game version.")

	var settings_variant: Variant = save_data.get("settings", {})

	if settings_variant is Dictionary:
		_apply_settings_save_data(settings_variant as Dictionary)
	else:
		_apply_settings_save_data({})

	var game_state_data: Dictionary = save_data.get("game_state", {})
	var passive_system_data: Dictionary = save_data.get("passive_system", {})
	var achievement_system_data: Dictionary = save_data.get("achievement_system", {})

	GameState.from_save_dict(game_state_data)
	PassiveSystem.from_save_dict(passive_system_data)
	AchievementSystem.from_save_dict(achievement_system_data)

	EventBus.squares_changed.emit(GameState.squares)
	EventBus.vertices_changed.emit(GameState.vertices)
	EventBus.prestige_changed.emit(GameState.prestige_count)
	EventBus.grid_changed.emit()
	EventBus.story_message.emit("Save loaded.")
	PassiveSystem.passive_state_changed.emit()

	print(
		"Loaded autosave settings: enabled=%s interval=%s" % [
			autosave_enabled,
			autosave_interval_seconds
		]
	)

	is_applying_save_data = false

func _apply_settings_save_data(settings_data: Dictionary) -> void:
	autosave_enabled = bool(settings_data.get("autosave_enabled", autosave_enabled))

	autosave_interval_seconds = float(settings_data.get(
		"autosave_interval_seconds",
		autosave_interval_seconds
	))

	autosave_interval_seconds = max(
		MIN_AUTOSAVE_INTERVAL_SECONDS,
		autosave_interval_seconds
	)

	autosave_elapsed_seconds = 0.0
	save_settings_changed.emit()
	

func set_autosave_enabled(value: bool) -> void:
	autosave_enabled = value
	autosave_elapsed_seconds = 0.0
	save_settings_changed.emit()
	save_game()


func set_autosave_interval_seconds(value: float) -> void:
	autosave_interval_seconds = max(MIN_AUTOSAVE_INTERVAL_SECONDS, value)
	autosave_elapsed_seconds = 0.0
	save_settings_changed.emit()
	save_game()

func get_autosave_interval_seconds() -> float:
	return autosave_interval_seconds
