class_name CoreTypes
extends RefCounted

enum GameMode { VS_AI, LOCAL_TWO_PLAYERS }
enum Difficulty { EASY, MEDIUM, HARD }
enum MatchOutcome { WIN, LOSS, DRAW, ABORTED }


static func game_mode_to_key(mode: GameMode) -> String:
	match mode:
		GameMode.VS_AI:
			return "vs_ai"
		GameMode.LOCAL_TWO_PLAYERS:
			return "local_two_players"
	return "vs_ai"


static func game_mode_from_key(key: String) -> GameMode:
	match key.strip_edges().to_lower():
		"local_two_players":
			return GameMode.LOCAL_TWO_PLAYERS
		_:
			return GameMode.VS_AI


static func game_mode_label(mode: GameMode) -> String:
	match mode:
		GameMode.VS_AI:
			return "Contra IA"
		GameMode.LOCAL_TWO_PLAYERS:
			return "2 Jogadores (Local)"
	return "Desconhecido"


static func difficulty_to_key(difficulty: Difficulty) -> String:
	match difficulty:
		Difficulty.EASY:
			return "easy"
		Difficulty.MEDIUM:
			return "medium"
		Difficulty.HARD:
			return "hard"
	return "medium"


static func difficulty_from_key(key: String) -> Difficulty:
	match key.strip_edges().to_lower():
		"easy":
			return Difficulty.EASY
		"hard":
			return Difficulty.HARD
		_:
			return Difficulty.MEDIUM


static func difficulty_label(difficulty: Difficulty) -> String:
	match difficulty:
		Difficulty.EASY:
			return "Fácil"
		Difficulty.MEDIUM:
			return "Médio"
		Difficulty.HARD:
			return "Difícil"
	return "Médio"


static func outcome_to_key(outcome: MatchOutcome) -> String:
	match outcome:
		MatchOutcome.WIN:
			return "win"
		MatchOutcome.LOSS:
			return "loss"
		MatchOutcome.DRAW:
			return "draw"
		MatchOutcome.ABORTED:
			return "aborted"
	return "aborted"


static func outcome_label(outcome: MatchOutcome) -> String:
	match outcome:
		MatchOutcome.WIN:
			return "Vitória"
		MatchOutcome.LOSS:
			return "Derrota"
		MatchOutcome.DRAW:
			return "Empate"
		MatchOutcome.ABORTED:
			return "Partida Encerrada"
	return "Partida Encerrada"
