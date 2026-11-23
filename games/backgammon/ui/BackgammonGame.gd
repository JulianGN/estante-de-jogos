extends GameModule

var _match_started_msec: int = 0
var _simulated_round: int = 1

@onready var _hud: BaseGameHUD = %BaseGameHUD
@onready var _session_badge_label: Label = %SessionBadgeLabel
@onready var _status_label: Label = %StatusLabel
@onready var _win_simple_button: Button = %WinSimpleButton
@onready var _win_gammon_button: Button = %WinGammonButton
@onready var _loss_button: Button = %LossButton


func _ready() -> void:
	_match_started_msec = Time.get_ticks_msec()
	var e1: Error = _hud.exit_confirmed.connect(_on_hud_exit_confirmed)
	var e2: Error = _hud.replay_requested.connect(_on_hud_replay_requested)
	var e3: Error = _win_simple_button.pressed.connect(
		simulate_match_result.bind(CoreTypes.MatchOutcome.WIN, 1, "Simples")
	)
	var e4: Error = _win_gammon_button.pressed.connect(
		simulate_match_result.bind(CoreTypes.MatchOutcome.WIN, 2, "Gammon")
	)
	var e5: Error = _loss_button.pressed.connect(
		simulate_match_result.bind(CoreTypes.MatchOutcome.LOSS, 1, "")
	)
	if e1 != OK or e2 != OK or e3 != OK or e4 != OK or e5 != OK:
		push_warning("BackgammonGame: falha ao conectar sinais da interface.")

	_refresh_session_ui()


func setup_session(config: GameSessionConfig) -> void:
	super.setup_session(config)
	_match_started_msec = Time.get_ticks_msec()
	_simulated_round = 1
	if is_node_ready():
		_refresh_session_ui()


func handle_back_request() -> bool:
	if _hud != null:
		return _hud.handle_back_request()
	return false


func simulate_match_result(
	outcome: CoreTypes.MatchOutcome,
	score_multiplier: int = 1,
	score_label: String = "",
) -> GameResult:
	var mode: CoreTypes.GameMode = CoreTypes.GameMode.VS_AI
	var difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM
	if session_config != null:
		mode = session_config.mode
		difficulty = session_config.difficulty

	var winner_label: String = _resolve_winner_label(mode, outcome)
	var elapsed_seconds: int = maxi(
		1,
		int(floor(float(Time.get_ticks_msec() - _match_started_msec) / 1000.0)),
	)
	var result: GameResult = (
		GameResult
		. create(
			"backgammon",
			mode,
			outcome,
			difficulty,
			winner_label,
			score_multiplier,
			score_label,
			elapsed_seconds,
			{"stub_round": _simulated_round},
		)
	)

	game_finished.emit(result)
	if is_node_ready():
		_hud.show_result_dialog(result)
	return result


func _refresh_session_ui() -> void:
	var mode: CoreTypes.GameMode = CoreTypes.GameMode.VS_AI
	var difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM
	if session_config != null:
		mode = session_config.mode
		difficulty = session_config.difficulty

	var subtitle: String = CoreTypes.game_mode_label(mode)
	if mode == CoreTypes.GameMode.VS_AI:
		subtitle = "%s • %s" % [subtitle, CoreTypes.difficulty_label(difficulty)]

	_hud.configure_header("Gamão", subtitle)
	_session_badge_label.text = ("Sessão ativa (#%d): %s" % [_simulated_round, subtitle])
	_status_label.text = (
		"Módulo do Gamão isolado e conectado ao Hub.\n"
		+ "O motor de regras puro será implementado na Etapa 3 e o tabuleiro "
		+ "Tap-to-Move na Etapa 5.\n\n"
		+ "Use os botões abaixo para validar o ciclo completo de resultado e estatísticas:"
	)


func _resolve_winner_label(
	mode: CoreTypes.GameMode,
	outcome: CoreTypes.MatchOutcome,
) -> String:
	if mode == CoreTypes.GameMode.LOCAL_TWO_PLAYERS:
		return "Jogador 1" if outcome == CoreTypes.MatchOutcome.WIN else "Jogador 2"
	return "Você" if outcome == CoreTypes.MatchOutcome.WIN else "IA"


func _on_hud_exit_confirmed() -> void:
	exit_requested.emit()


func _on_hud_replay_requested() -> void:
	_simulated_round += 1
	_match_started_msec = Time.get_ticks_msec()
	_refresh_session_ui()
