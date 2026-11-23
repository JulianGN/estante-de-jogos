extends TestCase


func test_valid_result_and_serialization() -> void:
	var result: GameResult = (
		GameResult
		. create(
			"backgammon",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.MatchOutcome.WIN,
			CoreTypes.Difficulty.HARD,
			"Você",
			2,
			"Gammon",
			45,
			{"pips_opponent": 28},
		)
	)
	assert_true(result.is_valid())
	var dict: Dictionary = result.to_dict()
	assert_eq(dict["game_id"], "backgammon")
	assert_eq(dict["mode"], "vs_ai")
	assert_eq(dict["difficulty"], "hard")
	assert_eq(dict["outcome"], "win")
	assert_eq(dict["score_multiplier"], 2)
	assert_eq(dict["score_label"], "Gammon")
	assert_eq((dict["details"] as Dictionary)["pips_opponent"], 28)


func test_invalid_result_fields_rejected() -> void:
	var empty_id: GameResult = (
		GameResult
		. create(
			"",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.MatchOutcome.WIN,
		)
	)
	assert_false(empty_id.is_valid())

	var bad_mult: GameResult = (
		GameResult
		. create(
			"backgammon",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.MatchOutcome.WIN,
			CoreTypes.Difficulty.MEDIUM,
			"Você",
			0,
		)
	)
	assert_false(bad_mult.is_valid())

	var bad_duration: GameResult = (
		GameResult
		. create(
			"backgammon",
			CoreTypes.GameMode.VS_AI,
			CoreTypes.MatchOutcome.LOSS,
			CoreTypes.Difficulty.MEDIUM,
			"IA",
			1,
			"",
			-5,
		)
	)
	assert_false(bad_duration.is_valid())
