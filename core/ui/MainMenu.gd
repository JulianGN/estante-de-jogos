class_name MainMenu
extends Control

signal launch_requested(metadata: GameMetadata, config: GameSessionConfig)

const GAME_CARD_SCENE: PackedScene = preload("res://core/ui/components/GameCard.tscn")

var _catalog_dir: String = GameCatalog.DEFAULT_CATALOG_DIR
var _save_manager: SaveManagerService
var _loaded_metadata: Array[GameMetadata] = []
var _selected_metadata: GameMetadata
var _selected_mode: CoreTypes.GameMode = CoreTypes.GameMode.VS_AI
var _selected_difficulty: CoreTypes.Difficulty = CoreTypes.Difficulty.MEDIUM
var _mode_buttons: Dictionary = {}
var _difficulty_buttons: Dictionary = {}

@onready var _sfx_toggle_button: Button = %SfxToggleButton
@onready var _games_list: VBoxContainer = %GamesList
@onready var _empty_state_label: Label = %EmptyStateLabel
@onready var _mode_modal_overlay: ColorRect = %ModeModalOverlay
@onready var _modal_title_label: Label = %ModalTitleLabel
@onready var _modal_description_label: Label = %ModalDescriptionLabel
@onready var _modal_stats_label: Label = %ModalStatsLabel
@onready var _mode_buttons_box: HBoxContainer = %ModeButtonsBox
@onready var _difficulty_section: VBoxContainer = %DifficultySection
@onready var _difficulty_buttons_box: HBoxContainer = %DifficultyButtonsBox
@onready var _cancel_modal_button: Button = %CancelModalButton
@onready var _start_match_button: Button = %StartMatchButton


func _ready() -> void:
	var sfx_err: Error = _sfx_toggle_button.pressed.connect(_on_sfx_toggle_pressed)
	var cancel_err: Error = _cancel_modal_button.pressed.connect(_close_modal)
	var start_err: Error = _start_match_button.pressed.connect(confirm_launch)
	if sfx_err != OK or cancel_err != OK or start_err != OK:
		push_warning("MainMenu: falha ao conectar botões.")

	_mode_modal_overlay.visible = false
	_refresh_sfx_button()
	reload_catalog()


func set_save_manager(manager: SaveManagerService) -> void:
	_save_manager = manager
	if is_node_ready():
		_refresh_sfx_button()
		reload_catalog()


func set_catalog_dir(dir_path: String) -> void:
	_catalog_dir = dir_path
	if is_node_ready():
		reload_catalog()


func reload_catalog() -> void:
	_loaded_metadata = GameCatalog.load_all(_catalog_dir)
	if not is_node_ready():
		return

	_clear_children(_games_list)
	_empty_state_label.visible = _loaded_metadata.is_empty()

	var manager: SaveManagerService = _resolve_save_manager()
	for metadata in _loaded_metadata:
		var card: GameCard = GAME_CARD_SCENE.instantiate() as GameCard
		var stats: Dictionary = {}
		if manager != null:
			stats = manager.get_game_stats(metadata.id)
		_games_list.add_child(card)
		card.configure(metadata, stats)
		var card_err: Error = card.play_requested.connect(open_launch_modal)
		if card_err != OK:
			push_warning("MainMenu: falha ao conectar card '%s' (%d)." % [metadata.id, card_err])


func get_loaded_metadata() -> Array[GameMetadata]:
	return _loaded_metadata.duplicate()


func open_launch_modal(metadata: GameMetadata) -> void:
	if metadata == null or not metadata.is_valid():
		return

	_selected_metadata = metadata
	var supported_modes: Array[CoreTypes.GameMode] = metadata.get_supported_modes()
	_selected_mode = supported_modes[0]
	_selected_difficulty = metadata.get_default_difficulty()

	if not is_node_ready():
		return

	_modal_title_label.text = metadata.title
	_modal_description_label.text = metadata.description
	_update_modal_stats(metadata.id)
	_rebuild_mode_buttons(supported_modes)
	_rebuild_difficulty_buttons(metadata.supported_difficulties)
	_refresh_modal_selection_ui()
	_mode_modal_overlay.visible = true


func select_mode(mode: CoreTypes.GameMode) -> void:
	if _selected_metadata == null or not _selected_metadata.supports_mode(mode):
		return
	_selected_mode = mode
	if is_node_ready():
		_refresh_modal_selection_ui()


func select_difficulty(difficulty: CoreTypes.Difficulty) -> void:
	if _selected_metadata == null or not _selected_metadata.supports_difficulty(difficulty):
		return
	_selected_difficulty = difficulty
	if is_node_ready():
		_refresh_modal_selection_ui()


func confirm_launch() -> void:
	if _selected_metadata == null:
		return

	var config: GameSessionConfig = (
		GameSessionConfig
		. create(
			_selected_metadata.id,
			_selected_mode,
			_selected_difficulty,
		)
	)
	if not config.is_valid_for(_selected_metadata):
		push_warning("MainMenu: configuração de sessão inválida para '%s'." % _selected_metadata.id)
		return

	var metadata: GameMetadata = _selected_metadata
	_close_modal()
	launch_requested.emit(metadata, config)


func is_modal_open() -> bool:
	return _selected_metadata != null


func handle_back_request() -> bool:
	if _selected_metadata != null:
		_close_modal()
		return true
	return false


func _close_modal() -> void:
	_selected_metadata = null
	if is_node_ready():
		_mode_modal_overlay.visible = false


func _update_modal_stats(game_id: String) -> void:
	var manager: SaveManagerService = _resolve_save_manager()
	if manager == null:
		_modal_stats_label.text = "Estatísticas locais indisponíveis"
		return
	var stats: Dictionary = manager.get_game_stats(game_id)
	var played: int = int(stats.get("matches_played", 0))
	var wins: int = int(stats.get("wins", 0))
	var streak: int = int(stats.get("best_streak", 0))
	_modal_stats_label.text = (
		"Histórico: %d partidas • %d vitórias • Recorde de sequência: %d" % [played, wins, streak]
	)


func _rebuild_mode_buttons(modes: Array[CoreTypes.GameMode]) -> void:
	_clear_children(_mode_buttons_box)
	_mode_buttons.clear()
	for mode in modes:
		var btn: Button = Button.new()
		btn.text = CoreTypes.game_mode_label(mode)
		btn.custom_minimum_size = Vector2(0, 88)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mode_err: Error = btn.pressed.connect(select_mode.bind(mode))
		if mode_err != OK:
			push_warning("MainMenu: falha ao conectar botão de modo (%d)." % mode_err)
		_mode_buttons_box.add_child(btn)
		_mode_buttons[mode] = btn


func _rebuild_difficulty_buttons(difficulties: Array[CoreTypes.Difficulty]) -> void:
	_clear_children(_difficulty_buttons_box)
	_difficulty_buttons.clear()
	for difficulty in difficulties:
		var btn: Button = Button.new()
		btn.text = CoreTypes.difficulty_label(difficulty)
		btn.custom_minimum_size = Vector2(0, 88)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var diff_err: Error = btn.pressed.connect(select_difficulty.bind(difficulty))
		if diff_err != OK:
			push_warning("MainMenu: falha ao conectar botão de dificuldade (%d)." % diff_err)
		_difficulty_buttons_box.add_child(btn)
		_difficulty_buttons[difficulty] = btn


func _refresh_modal_selection_ui() -> void:
	_difficulty_section.visible = (_selected_mode == CoreTypes.GameMode.VS_AI)

	for mode_key: Variant in _mode_buttons.keys():
		var btn: Button = _mode_buttons[mode_key] as Button
		var active: bool = int(mode_key) == _selected_mode
		btn.modulate = Color(1.0, 0.86, 0.56, 1.0) if active else Color(0.76, 0.68, 0.60, 1.0)

	for diff_key: Variant in _difficulty_buttons.keys():
		var btn: Button = _difficulty_buttons[diff_key] as Button
		var active: bool = int(diff_key) == _selected_difficulty
		btn.modulate = Color(1.0, 0.86, 0.56, 1.0) if active else Color(0.76, 0.68, 0.60, 1.0)


func _refresh_sfx_button() -> void:
	var audio: AudioControllerService = _resolve_audio_controller()
	if audio != null:
		_sfx_toggle_button.text = "Som: ON" if audio.is_sfx_enabled() else "Som: OFF"
		return
	var manager: SaveManagerService = _resolve_save_manager()
	if manager != null:
		var enabled: bool = bool(manager.get_setting("sfx_enabled", true))
		_sfx_toggle_button.text = "Som: ON" if enabled else "Som: OFF"
	else:
		_sfx_toggle_button.text = "Som: ON"


func _on_sfx_toggle_pressed() -> void:
	var audio: AudioControllerService = _resolve_audio_controller()
	if audio != null:
		audio.set_sfx_enabled(not audio.is_sfx_enabled())
		_refresh_sfx_button()
		return
	var manager: SaveManagerService = _resolve_save_manager()
	if manager != null:
		var enabled: bool = bool(manager.get_setting("sfx_enabled", true))
		manager.set_setting("sfx_enabled", not enabled)
	_refresh_sfx_button()


func _resolve_save_manager() -> SaveManagerService:
	if _save_manager != null:
		return _save_manager
	var node: Node = get_node_or_null("/root/SaveManager")
	if node is SaveManagerService:
		return node as SaveManagerService
	return null


func _resolve_audio_controller() -> AudioControllerService:
	var node: Node = get_node_or_null("/root/AudioController")
	if node is AudioControllerService:
		return node as AudioControllerService
	return null


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
