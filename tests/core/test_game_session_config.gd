extends TestCase


func test_valid_configurations() -> void:
	var meta: GameMetadata = _create_metadata()
	var vs_ai: GameSessionConfig = (
		GameSessionConfig
		. create(
			"backgammon",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.Difficulty.HARD,
		)
	)
	assert_true(vs_ai.is_valid_for(meta))

	var two_players: GameSessionConfig = (
		GameSessionConfig
		. create(
			"backgammon",
			CoreTypes.GameMode.LOCAL_TWO_PLAYERS,
		)
	)
	assert_true(two_players.is_valid_for(meta))


func test_rejects_mismatches_and_unsupported_options() -> void:
	var meta: GameMetadata = _create_metadata()
	meta.supports_local_multiplayer = false
	meta.supported_difficulties = [CoreTypes.Difficulty.EASY]

	var wrong_id: GameSessionConfig = (
		GameSessionConfig
		. create(
			"chess",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.Difficulty.EASY,
		)
	)
	assert_false(wrong_id.is_valid_for(meta))

	var unsupported_mode: GameSessionConfig = (
		GameSessionConfig
		. create(
			"backgammon",
			CoreTypes.GameMode.LOCAL_TWO_PLAYERS,
		)
	)
	assert_false(unsupported_mode.is_valid_for(meta))

	var unsupported_diff: GameSessionConfig = (
		GameSessionConfig
		. create(
			"backgammon",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.Difficulty.HARD,
		)
	)
	assert_false(unsupported_diff.is_valid_for(meta))
	assert_false(unsupported_diff.is_valid_for(null))


func _create_metadata() -> GameMetadata:
	var meta: GameMetadata = GameMetadata.new()
	meta.id = "backgammon"
	meta.title = "Gamão"
	meta.scene_path = "res://games/backgammon/ui/BackgammonGame.tscn"
	meta.supports_ai = true
	meta.supports_local_multiplayer = true
	meta.supported_difficulties = [
		CoreTypes.Difficulty.EASY,
		CoreTypes.Difficulty.MEDIUM,
		CoreTypes.Difficulty.HARD,
	]
	return meta
