class_name SaveManagerService
extends Node

signal stats_updated(game_id: String)
signal settings_updated

const SCHEMA_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://estante_save.json"

var save_file_path: String = DEFAULT_SAVE_PATH

var _data: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	load_data()


func load_data() -> void:
	_data = _create_default_data()
	_loaded = true
	if not FileAccess.file_exists(save_file_path):
		return

	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		push_warning(
			"SaveManager: falha ao abrir '%s' (%d)." % [save_file_path, FileAccess.get_open_error()]
		)
		return

	var raw_text: String = file.get_as_text()
	file.close()
	if raw_text.strip_edges().is_empty():
		return

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(raw_text)
	if parse_err != OK or not json.data is Dictionary:
		push_warning("SaveManager: arquivo '%s' corrompido; usando estado padrão." % save_file_path)
		return

	_data = _normalize_loaded_data(json.data as Dictionary)


func save_data() -> Error:
	_ensure_loaded()
	var file: FileAccess = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	var json_text: String = JSON.stringify(_data, "\t")
	var stored: bool = file.store_string(json_text)
	file.close()
	if not stored:
		return ERR_FILE_CANT_WRITE
	return OK


func reset_all() -> void:
	_data = _create_default_data()
	_loaded = true
	var err: Error = save_data()
	if err != OK:
		push_warning("SaveManager: falha ao salvar reset (%d)." % err)
	settings_updated.emit()


func get_settings() -> Dictionary:
	_ensure_loaded()
	var settings: Dictionary = _data.get("settings", {}) as Dictionary
	return settings.duplicate(true)


func get_setting(key: String, default_value: Variant = null) -> Variant:
	_ensure_loaded()
	var settings: Dictionary = _data.get("settings", {}) as Dictionary
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_ensure_loaded()
	var settings: Dictionary = _data.get("settings", {}) as Dictionary
	settings[key] = value
	_data["settings"] = settings
	var err: Error = save_data()
	if err != OK:
		push_warning("SaveManager: falha ao salvar configuração '%s' (%d)." % [key, err])
	settings_updated.emit()


func record_game_result(result: GameResult) -> bool:
	if result == null or not result.is_valid():
		return false
	if result.outcome == CoreTypes.MatchOutcome.ABORTED:
		return false

	_ensure_loaded()
	var game_entry: Dictionary = _ensure_game_entry(result.game_id)
	var stats: Dictionary = game_entry["stats"] as Dictionary
	_apply_outcome_to_stats(stats, result.outcome)

	if result.mode == CoreTypes.GameMode.VS_AI:
		var diff_key: String = CoreTypes.difficulty_to_key(result.difficulty)
		var by_difficulty: Dictionary = stats.get("by_difficulty", {}) as Dictionary
		var diff_stats: Dictionary = (
			by_difficulty.get(diff_key, _create_empty_diff_stats()) as Dictionary
		)
		diff_stats["matches_played"] = int(diff_stats.get("matches_played", 0)) + 1
		match result.outcome:
			CoreTypes.MatchOutcome.WIN:
				diff_stats["wins"] = int(diff_stats.get("wins", 0)) + 1
			CoreTypes.MatchOutcome.LOSS:
				diff_stats["losses"] = int(diff_stats.get("losses", 0)) + 1
			CoreTypes.MatchOutcome.DRAW:
				diff_stats["draws"] = int(diff_stats.get("draws", 0)) + 1
		by_difficulty[diff_key] = diff_stats
		stats["by_difficulty"] = by_difficulty

	if (
		result.outcome == CoreTypes.MatchOutcome.WIN
		and not result.score_label.strip_edges().is_empty()
	):
		var special_wins: Dictionary = stats.get("special_wins", {}) as Dictionary
		var label_key: String = result.score_label.strip_edges()
		special_wins[label_key] = int(special_wins.get(label_key, 0)) + 1
		stats["special_wins"] = special_wins

	game_entry["stats"] = stats
	var games: Dictionary = _data["games"] as Dictionary
	games[result.game_id] = game_entry
	_data["games"] = games

	var err: Error = save_data()
	if err != OK:
		push_warning(
			"SaveManager: falha ao persistir resultado de '%s' (%d)." % [result.game_id, err]
		)
	stats_updated.emit(result.game_id)
	return true


func get_game_stats(game_id: String) -> Dictionary:
	_ensure_loaded()
	var games: Dictionary = _data.get("games", {}) as Dictionary
	if not games.has(game_id):
		return _create_empty_stats()
	var game_entry: Dictionary = games[game_id] as Dictionary
	var raw_stats: Dictionary = game_entry.get("stats", {}) as Dictionary
	return _normalize_stats_dict(raw_stats)


func get_game_custom_data(game_id: String) -> Dictionary:
	_ensure_loaded()
	var games: Dictionary = _data.get("games", {}) as Dictionary
	if not games.has(game_id):
		return {}
	var game_entry: Dictionary = games[game_id] as Dictionary
	var custom_data: Variant = game_entry.get("custom_data", {})
	if custom_data is Dictionary:
		return (custom_data as Dictionary).duplicate(true)
	return {}


func set_game_custom_data(game_id: String, data: Dictionary) -> Error:
	var clean_id: String = game_id.strip_edges()
	if clean_id.is_empty():
		return ERR_INVALID_PARAMETER
	_ensure_loaded()
	var game_entry: Dictionary = _ensure_game_entry(clean_id)
	game_entry["custom_data"] = data.duplicate(true)
	var games: Dictionary = _data["games"] as Dictionary
	games[clean_id] = game_entry
	_data["games"] = games
	return save_data()


func _ensure_loaded() -> void:
	if not _loaded:
		load_data()


func _create_default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"settings":
		{
			"sfx_enabled": true,
			"music_enabled": true,
		},
		"games": {},
	}


func _create_empty_stats() -> Dictionary:
	return {
		"matches_played": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"current_streak": 0,
		"best_streak": 0,
		"by_difficulty": {},
		"special_wins": {},
	}


func _create_empty_diff_stats() -> Dictionary:
	return {
		"matches_played": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0,
	}


func _ensure_game_entry(game_id: String) -> Dictionary:
	var games: Dictionary = _data.get("games", {}) as Dictionary
	if not games.has(game_id) or not games[game_id] is Dictionary:
		return {
			"stats": _create_empty_stats(),
			"custom_data": {},
		}
	var entry: Dictionary = games[game_id] as Dictionary
	var raw_stats: Variant = entry.get("stats", {})
	var stats: Dictionary = (
		_normalize_stats_dict(raw_stats as Dictionary)
		if raw_stats is Dictionary
		else _create_empty_stats()
	)
	var raw_custom: Variant = entry.get("custom_data", {})
	var custom_data: Dictionary = (
		(raw_custom as Dictionary).duplicate(true) if raw_custom is Dictionary else {}
	)
	return {
		"stats": stats,
		"custom_data": custom_data,
	}


func _normalize_loaded_data(raw: Dictionary) -> Dictionary:
	var normalized: Dictionary = _create_default_data()
	var raw_settings: Variant = raw.get("settings", {})
	if raw_settings is Dictionary:
		var merged_settings: Dictionary = normalized["settings"] as Dictionary
		var loaded_settings: Dictionary = raw_settings as Dictionary
		for key: Variant in loaded_settings.keys():
			merged_settings[key] = loaded_settings[key]
		normalized["settings"] = merged_settings

	var raw_games: Variant = raw.get("games", {})
	if raw_games is Dictionary:
		var loaded_games: Dictionary = raw_games as Dictionary
		var out_games: Dictionary = {}
		for game_key: Variant in loaded_games.keys():
			var game_id: String = str(game_key)
			var raw_entry: Variant = loaded_games[game_key]
			if raw_entry is Dictionary:
				var entry_dict: Dictionary = raw_entry as Dictionary
				var raw_stats: Variant = entry_dict.get("stats", {})
				var raw_custom: Variant = entry_dict.get("custom_data", {})
				out_games[game_id] = {
					"stats":
					(
						_normalize_stats_dict(raw_stats as Dictionary)
						if raw_stats is Dictionary
						else _create_empty_stats()
					),
					"custom_data":
					(raw_custom as Dictionary).duplicate(true) if raw_custom is Dictionary else {},
				}
		normalized["games"] = out_games

	return normalized


func _normalize_stats_dict(raw: Dictionary) -> Dictionary:
	var stats: Dictionary = _create_empty_stats()
	stats["matches_played"] = int(raw.get("matches_played", 0))
	stats["wins"] = int(raw.get("wins", 0))
	stats["losses"] = int(raw.get("losses", 0))
	stats["draws"] = int(raw.get("draws", 0))
	stats["current_streak"] = int(raw.get("current_streak", 0))
	stats["best_streak"] = int(raw.get("best_streak", 0))

	var raw_by_diff: Variant = raw.get("by_difficulty", {})
	if raw_by_diff is Dictionary:
		stats["by_difficulty"] = (raw_by_diff as Dictionary).duplicate(true)

	var raw_special: Variant = raw.get("special_wins", {})
	if raw_special is Dictionary:
		stats["special_wins"] = (raw_special as Dictionary).duplicate(true)

	return stats


func _apply_outcome_to_stats(stats: Dictionary, outcome: CoreTypes.MatchOutcome) -> void:
	stats["matches_played"] = int(stats.get("matches_played", 0)) + 1
	match outcome:
		CoreTypes.MatchOutcome.WIN:
			stats["wins"] = int(stats.get("wins", 0)) + 1
			var next_streak: int = int(stats.get("current_streak", 0)) + 1
			stats["current_streak"] = next_streak
			stats["best_streak"] = maxi(int(stats.get("best_streak", 0)), next_streak)
		CoreTypes.MatchOutcome.LOSS:
			stats["losses"] = int(stats.get("losses", 0)) + 1
			stats["current_streak"] = 0
		CoreTypes.MatchOutcome.DRAW:
			stats["draws"] = int(stats.get("draws", 0)) + 1
			stats["current_streak"] = 0
