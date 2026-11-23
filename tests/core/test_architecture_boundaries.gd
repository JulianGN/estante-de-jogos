extends TestCase


func test_core_never_depends_on_games_or_shared() -> void:
	var core_files: PackedStringArray = PackedStringArray()
	_collect_gd_files("res://core", core_files)
	assert_true(core_files.size() > 0)

	for file_path in core_files:
		var source: String = _read_text(file_path)
		assert_false(
			source.contains("res://games/"),
			"Violação arquitetural em %s: referência a res://games/." % file_path,
		)
		assert_false(
			source.contains("res://shared/"),
			"Violação arquitetural em %s: referência a res://shared/." % file_path,
		)


func test_shared_never_depends_on_games() -> void:
	assert_not_null(
		DirAccess.open("res://shared"),
		"Diretório res://shared deve existir.",
	)
	var shared_files: PackedStringArray = PackedStringArray()
	_collect_gd_files("res://shared", shared_files)
	for file_path in shared_files:
		var source: String = _read_text(file_path)
		assert_false(
			source.contains("res://games/"),
			"Violação arquitetural em %s: referência a res://games/." % file_path,
		)


func test_games_are_isolated_from_each_other() -> void:
	var dir: DirAccess = DirAccess.open("res://games")
	assert_not_null(dir)
	var game_dirs: PackedStringArray = PackedStringArray()
	var err: Error = dir.list_dir_begin()
	assert_eq(err, OK)
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != ".." and dir.current_is_dir():
			game_dirs.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()

	for game_id in game_dirs:
		var files: PackedStringArray = PackedStringArray()
		_collect_gd_files("res://games/%s" % game_id, files)
		for file_path in files:
			var source: String = _read_text(file_path)
			for other_id in game_dirs:
				if other_id != game_id:
					assert_false(
						source.contains("res://games/%s/" % other_id),
						"Jogo '%s' não deve importar '%s' (%s)." % [game_id, other_id, file_path],
					)


func test_backgammon_logic_stays_pure() -> void:
	assert_not_null(
		DirAccess.open("res://games/backgammon/logic"),
		"Diretório res://games/backgammon/logic deve existir.",
	)
	var logic_files: PackedStringArray = PackedStringArray()
	_collect_gd_files("res://games/backgammon/logic", logic_files)
	for file_path in logic_files:
		var source: String = _read_text(file_path)
		assert_false(
			source.contains("extends Node") or source.contains("extends Control"),
			"Lógica pura em %s não deve herdar Node/Control." % file_path,
		)
		assert_false(
			source.contains("res://core/ui/"),
			"Lógica pura em %s não deve referenciar core/ui." % file_path,
		)


func _collect_gd_files(dir_path: String, out_files: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	var err: Error = dir.list_dir_begin()
	if err != OK:
		return
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var full_path: String = "%s/%s" % [dir_path.rstrip("/"), entry]
			if dir.current_is_dir():
				_collect_gd_files(full_path, out_files)
			elif entry.ends_with(".gd"):
				out_files.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _read_text(file_path: String) -> String:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content
