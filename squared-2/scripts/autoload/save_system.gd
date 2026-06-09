extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"

signal save_loaded()
signal save_saved()
signal save_failed(message: String)

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

	GameState.reset_to_new_game()
	PassiveSystem.reset_to_new_game()

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
		"game_state": GameState.to_save_dict(),
		"passive_system": PassiveSystem.to_save_dict()
	}

func _apply_save_data(save_data: Dictionary) -> void:
	var version: int = int(save_data.get("version", 0))

	if version > SAVE_VERSION:
		push_warning("Save version is newer than current game version.")

	var game_state_data: Dictionary = save_data.get("game_state", {})
	var passive_system_data: Dictionary = save_data.get("passive_system", {})

	GameState.from_save_dict(game_state_data)
	PassiveSystem.from_save_dict(passive_system_data)

	EventBus.squares_changed.emit(GameState.squares)
	EventBus.vertices_changed.emit(GameState.vertices)
	EventBus.prestige_changed.emit(GameState.prestige_count)
	EventBus.grid_changed.emit()
	EventBus.story_message.emit("Save loaded.")
	PassiveSystem.passive_state_changed.emit()
