extends TestCase


func test_normalize_resource_path_handles_android_remap() -> void:
	assert_eq(
		GameCatalog.normalize_resource_path("res://core/catalog", "backgammon.tres"),
		"res://core/catalog/backgammon.tres",
	)
	assert_eq(
		GameCatalog.normalize_resource_path("res://core/catalog/", "backgammon.tres.remap"),
		"res://core/catalog/backgammon.tres",
	)
	assert_eq(
		GameCatalog.normalize_resource_path("res://core/catalog", "GameCatalog.gd"),
		"",
	)


func test_load_all_and_find_by_id_returns_backgammon() -> void:
	var entries: Array[GameMetadata] = GameCatalog.load_all()
	assert_true(entries.size() >= 1, "Catálogo deve conter ao menos o Gamão.")

	var backgammon: GameMetadata = GameCatalog.find_by_id("backgammon")
	assert_not_null(backgammon, "Gamão deve ser encontrado no catálogo.")
	assert_eq(backgammon.title, "Gamão")
	assert_true(backgammon.supports_ai)
	assert_true(backgammon.supports_local_multiplayer)
	assert_true(backgammon.supports_difficulty(CoreTypes.Difficulty.EASY))
	assert_true(backgammon.supports_difficulty(CoreTypes.Difficulty.MEDIUM))
	assert_true(backgammon.supports_difficulty(CoreTypes.Difficulty.HARD))
	assert_null(GameCatalog.find_by_id("jogo_inexistente"))
