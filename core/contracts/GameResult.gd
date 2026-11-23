class_name GameResult
extends RefCounted

var game_id: String = ""
var mode: CoreTypes.GameMode = CoreTypes.GameMode.VS_AI
var difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM
var outcome: CoreTypes.MatchOutcome = CoreTypes.MatchOutcome.ABORTED
var winner_label: String = ""
var score_multiplier: int = 1
var score_label: String = ""
var duration_seconds: int = 0
var details: Dictionary = {}


static func create(
	p_game_id: String,
	p_mode: CoreTypes.GameMode,
	p_outcome: CoreTypes.MatchOutcome,
	p_difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM,
	p_winner_label: String = "",
	p_score_multiplier: int = 1,
	p_score_label: String = "",
	p_duration_seconds: int = 0,
	p_details: Dictionary = {}
) -> GameResult:
	var result: GameResult = GameResult.new()
	result.game_id = p_game_id.strip_edges()
	result.mode = p_mode
	result.outcome = p_outcome
	result.difficulty = p_difficulty
	result.winner_label = p_winner_label.strip_edges()
	result.score_multiplier = p_score_multiplier
	result.score_label = p_score_label.strip_edges()
	result.duration_seconds = p_duration_seconds
	result.details = p_details.duplicate(true)
	return result


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if game_id.strip_edges().is_empty():
		errors.append("O campo 'game_id' do resultado não pode ser vazio.")
	if score_multiplier < 1:
		errors.append("O campo 'score_multiplier' deve ser maior ou igual a 1.")
	if duration_seconds < 0:
		errors.append("O campo 'duration_seconds' não pode ser negativo.")
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dict() -> Dictionary:
	return {
		"game_id": game_id,
		"mode": CoreTypes.game_mode_to_key(mode),
		"difficulty": CoreTypes.difficulty_to_key(difficulty),
		"outcome": CoreTypes.outcome_to_key(outcome),
		"winner_label": winner_label,
		"score_multiplier": score_multiplier,
		"score_label": score_label,
		"duration_seconds": duration_seconds,
		"details": details.duplicate(true),
	}
