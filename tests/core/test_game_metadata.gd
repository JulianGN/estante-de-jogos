extends TestCase


func test_valid_metadata_passes() -> void:
	var meta: GameMetadata = _build_valid_metadata()
	assert_true(meta.is_valid(), "Metadados válidos devem passar.")
	assert_eq(meta.validate().size(), 0)
	assert_eq(meta.get_supported_modes().size(), 2)
	assert_true(meta.supports_mode(CoreTypes.GameMode.VS_AI))
	assert_true(meta.supports_mode(CoreTypes.GameMode.LOCAL_TWO_PLAYERS))
	assert_true(meta.supports_difficulty(CoreTypes.Difficulty.HARD))
	assert_eq(meta.get_default_difficulty(), CoreTypes.Difficulty.MEDIUM)


func test_invalid_id_rejected() -> void:
	var empty_id: GameMetadata = _build_valid_metadata()
	empty_id.id = ""
	assert_false(empty_id.is_valid(), "ID vazio deve falhar.")

	var uppercase_id: GameMetadata = _build_valid_metadata()
	uppercase_id.id = "BackGammon"
	assert_false(uppercase_id.is_valid(), "ID com maiúsculas deve falhar.")

	var spaced_id: GameMetadata = _build_valid_metadata()
	spaced_id.id = "meu jogo"
	assert_false(spaced_id.is_valid(), "ID com espaço deve falhar.")


func test_invalid_title_and_scene_rejected() -> void:
	var no_title: GameMetadata = _build_valid_metadata()
	no_title.title = "   "
	assert_false(no_title.is_valid(), "Título em branco deve falhar.")

	var bad_scene: GameMetadata = _build_valid_metadata()
	bad_scene.scene_path = "games/backgammon/BackgammonGame.gd"
	assert_false(bad_scene.is_valid(), "scene_path inválido deve falhar.")


func test_modes_and_difficulties_invariants() -> void:
	var no_modes: GameMetadata = _build_valid_metadata()
	no_modes.supports_ai = false
	no_modes.supports_local_multiplayer = false
	assert_false(no_modes.is_valid(), "Jogo sem nenhum modo suportado deve falhar.")

	var ai_without_diff: GameMetadata = _build_valid_metadata()
	ai_without_diff.supports_ai = true
	ai_without_diff.supported_difficulties = []
	assert_false(ai_without_diff.is_valid(), "Jogo com IA sem dificuldades deve falhar.")

	var local_only: GameMetadata = _build_valid_metadata()
	local_only.supports_ai = false
	local_only.supports_local_multiplayer = true
	local_only.supported_difficulties = []
	assert_true(local_only.is_valid(), "Jogo só 2 jogadores locais pode não ter dificuldades.")
	assert_false(local_only.supports_difficulty(CoreTypes.Difficulty.EASY))


func test_default_difficulty_fallback() -> void:
	var meta: GameMetadata = _build_valid_metadata()
	meta.supported_difficulties = [CoreTypes.Difficulty.HARD]
	assert_eq(meta.get_default_difficulty(), CoreTypes.Difficulty.HARD)


func _build_valid_metadata() -> GameMetadata:
	var meta: GameMetadata = GameMetadata.new()
	meta.id = "backgammon"
	meta.title = "Gamão"
	meta.description = "Jogo de tabuleiro clássico."
	meta.scene_path = "res://games/backgammon/ui/BackgammonGame.tscn"
	meta.supports_ai = true
	meta.supports_local_multiplayer = true
	meta.supported_difficulties = [
		CoreTypes.Difficulty.EASY,
		CoreTypes.Difficulty.MEDIUM,
		CoreTypes.Difficulty.HARD,
	]
	return meta
