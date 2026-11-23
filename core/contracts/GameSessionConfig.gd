class_name GameSessionConfig
extends RefCounted

var game_id: String = ""
var mode: CoreTypes.GameMode = CoreTypes.GameMode.VS_AI
var difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM
var options: Dictionary = {}


static func create(
	p_game_id: String,
	p_mode: CoreTypes.GameMode,
	p_difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM,
	p_options: Dictionary = {}
) -> GameSessionConfig:
	var config: GameSessionConfig = GameSessionConfig.new()
	config.game_id = p_game_id.strip_edges()
	config.mode = p_mode
	config.difficulty = p_difficulty
	config.options = p_options.duplicate(true)
	return config


func validate_against(metadata: GameMetadata) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if metadata == null:
		errors.append("Metadados do jogo ausentes.")
		return errors

	if not metadata.is_valid():
		errors.append("Metadados do jogo inválidos.")

	if game_id.strip_edges() != metadata.id.strip_edges():
		errors.append("Configuração incompatível: 'game_id' diverge dos metadados.")

	if not metadata.supports_mode(mode):
		errors.append("Modo de jogo não suportado por '%s'." % metadata.id)

	if mode == CoreTypes.GameMode.VS_AI and not metadata.supports_difficulty(difficulty):
		errors.append("Dificuldade selecionada não suportada por '%s'." % metadata.id)

	return errors


func is_valid_for(metadata: GameMetadata) -> bool:
	return validate_against(metadata).is_empty()
