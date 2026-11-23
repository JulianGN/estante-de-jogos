extends TestCase

const TEST_SAVE_PATH: String = "user://test_estante_save.json"


func test_save_manager_records_and_persists_isolated_stats() -> void:
	_cleanup_test_file()
	var manager: SaveManagerService = SaveManagerService.new()
	manager.save_file_path = TEST_SAVE_PATH
	manager.load_data()

	var initial: Dictionary = manager.get_game_stats("backgammon")
	assert_eq(int(initial["matches_played"]), 0)
	assert_eq(int(initial["wins"]), 0)

	assert_true(
		(
			manager
			. record_game_result(
				(
					GameResult
					. create(
						"backgammon",
						CoreTypes.GameMode.VS_AI,
						CoreTypes.MatchOutcome.WIN,
						CoreTypes.Difficulty.HARD,
						"Você",
						2,
						"Gammon",
					)
				)
			)
		)
	)
	assert_true(
		(
			manager
			. record_game_result(
				(
					GameResult
					. create(
						"backgammon",
						CoreTypes.GameMode.VS_AI,
						CoreTypes.MatchOutcome.WIN,
						CoreTypes.Difficulty.MEDIUM,
						"Você",
						1,
						"Simples",
					)
				)
			)
		)
	)
	assert_true(
		(
			manager
			. record_game_result(
				(
					GameResult
					. create(
						"backgammon",
						CoreTypes.GameMode.LOCAL_TWO_PLAYERS,
						CoreTypes.MatchOutcome.LOSS,
					)
				)
			)
		)
	)
	assert_true(
		(
			manager
			. record_game_result(
				(
					GameResult
					. create(
						"backgammon",
						CoreTypes.GameMode.LOCAL_TWO_PLAYERS,
						CoreTypes.MatchOutcome.DRAW,
					)
				)
			)
		)
	)
	assert_false(
		(
			manager
			. record_game_result(
				(
					GameResult
					. create(
						"backgammon",
						CoreTypes.GameMode.VS_AI,
						CoreTypes.MatchOutcome.ABORTED,
					)
				)
			)
		),
		"Partidas abortadas não devem ser contabilizadas.",
	)

	assert_eq(manager.set_game_custom_data("backgammon", {"board_theme": "walnut"}), OK)
	manager.set_setting("sfx_enabled", false)

	var reloaded: SaveManagerService = SaveManagerService.new()
	reloaded.save_file_path = TEST_SAVE_PATH
	reloaded.load_data()

	var stats: Dictionary = reloaded.get_game_stats("backgammon")
	assert_eq(int(stats["matches_played"]), 4)
	assert_eq(int(stats["wins"]), 2)
	assert_eq(int(stats["losses"]), 1)
	assert_eq(int(stats["draws"]), 1)
	assert_eq(int(stats["current_streak"]), 0)
	assert_eq(int(stats["best_streak"]), 2)

	var by_diff: Dictionary = stats["by_difficulty"] as Dictionary
	assert_eq(int((by_diff["hard"] as Dictionary)["wins"]), 1)
	assert_eq(int((by_diff["medium"] as Dictionary)["wins"]), 1)

	var special_wins: Dictionary = stats["special_wins"] as Dictionary
	assert_eq(int(special_wins["Gammon"]), 1)
	assert_eq(int(special_wins["Simples"]), 1)

	var bg_custom: Dictionary = reloaded.get_game_custom_data("backgammon")
	assert_eq(bg_custom.get("board_theme", ""), "walnut")
	assert_eq(reloaded.get_game_custom_data("chess").size(), 0)
	assert_false(bool(reloaded.get_setting("sfx_enabled", true)))

	manager.free()
	reloaded.free()
	_cleanup_test_file()


func _cleanup_test_file() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		var err: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
		assert_eq(err, OK, "Limpeza do arquivo temporário de save deve funcionar.")
