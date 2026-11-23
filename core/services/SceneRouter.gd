class_name SceneRouter
extends Node

signal menu_shown
signal game_launched(metadata: GameMetadata, config: GameSessionConfig)
signal game_closed(game_id: String)

var scene_container: Control
var main_menu_scene_path: String = "res://core/ui/MainMenu.tscn"
var save_manager: SaveManagerService

var _current_scene: Node
var _active_metadata: GameMetadata
var _active_config: GameSessionConfig


func show_main_menu() -> Error:
	if scene_container == null:
		return ERR_UNCONFIGURED

	var packed_menu: Resource = ResourceLoader.load(main_menu_scene_path)
	if not packed_menu is PackedScene:
		push_error("SceneRouter: não foi possível carregar '%s'." % main_menu_scene_path)
		return ERR_CANT_OPEN

	_clear_current_scene()

	var menu_instance: Node = (packed_menu as PackedScene).instantiate()
	var resolved_save: SaveManagerService = _resolve_save_manager()
	if resolved_save != null and menu_instance.has_method("set_save_manager"):
		menu_instance.call("set_save_manager", resolved_save)

	if menu_instance.has_signal("launch_requested"):
		var conn_err: Error = menu_instance.connect("launch_requested", _on_menu_launch_requested)
		if conn_err != OK:
			push_warning("SceneRouter: falha ao conectar 'launch_requested' (%d)." % conn_err)

	scene_container.add_child(menu_instance)
	_current_scene = menu_instance
	menu_shown.emit()
	return OK


func launch_game(metadata: GameMetadata, config: GameSessionConfig) -> Error:
	if scene_container == null:
		return ERR_UNCONFIGURED
	if metadata == null or config == null:
		return ERR_INVALID_PARAMETER
	if not metadata.is_valid() or not config.is_valid_for(metadata):
		return ERR_INVALID_PARAMETER

	var packed_game: Resource = ResourceLoader.load(metadata.scene_path)
	if not packed_game is PackedScene:
		push_error("SceneRouter: cena do jogo inválida '%s'." % metadata.scene_path)
		return ERR_CANT_OPEN

	_clear_current_scene()

	var game_instance: Node = (packed_game as PackedScene).instantiate()
	_active_metadata = metadata
	_active_config = config
	_current_scene = game_instance
	scene_container.add_child(game_instance)

	if game_instance.has_method("setup_session"):
		game_instance.call("setup_session", config)

	if game_instance.has_signal("exit_requested"):
		var exit_err: Error = game_instance.connect(
			"exit_requested", _on_active_game_exit_requested
		)
		if exit_err != OK:
			push_warning("SceneRouter: falha ao conectar 'exit_requested' (%d)." % exit_err)

	if game_instance.has_signal("game_finished"):
		var fin_err: Error = game_instance.connect("game_finished", _on_active_game_finished)
		if fin_err != OK:
			push_warning("SceneRouter: falha ao conectar 'game_finished' (%d)." % fin_err)

	game_launched.emit(metadata, config)
	return OK


func handle_back_request() -> bool:
	if _current_scene != null and _current_scene.has_method("handle_back_request"):
		var handled: Variant = _current_scene.call("handle_back_request")
		if handled is bool and bool(handled):
			return true

	if _active_metadata != null:
		return show_main_menu() == OK

	return false


func get_current_scene() -> Node:
	return _current_scene


func get_active_game_id() -> String:
	if _active_metadata == null:
		return ""
	return _active_metadata.id


func _clear_current_scene() -> void:
	var closed_id: String = get_active_game_id()
	if _current_scene != null:
		if _current_scene.has_signal("launch_requested"):
			if _current_scene.is_connected("launch_requested", _on_menu_launch_requested):
				_current_scene.disconnect("launch_requested", _on_menu_launch_requested)
		if _current_scene.has_signal("exit_requested"):
			if _current_scene.is_connected("exit_requested", _on_active_game_exit_requested):
				_current_scene.disconnect("exit_requested", _on_active_game_exit_requested)
		if _current_scene.has_signal("game_finished"):
			if _current_scene.is_connected("game_finished", _on_active_game_finished):
				_current_scene.disconnect("game_finished", _on_active_game_finished)

		if _current_scene.get_parent() == scene_container and scene_container != null:
			scene_container.remove_child(_current_scene)
		_current_scene.queue_free()
		_current_scene = null

	_active_metadata = null
	_active_config = null
	if not closed_id.is_empty():
		game_closed.emit(closed_id)


func _resolve_save_manager() -> SaveManagerService:
	if save_manager != null:
		return save_manager
	var node: Node = get_node_or_null("/root/SaveManager")
	if node is SaveManagerService:
		return node as SaveManagerService
	return null


func _on_menu_launch_requested(metadata: GameMetadata, config: GameSessionConfig) -> void:
	var err: Error = launch_game(metadata, config)
	if err != OK:
		push_error("SceneRouter: erro ao iniciar jogo '%s' (%d)." % [metadata.id, err])


func _on_active_game_exit_requested() -> void:
	var err: Error = show_main_menu()
	if err != OK:
		push_error("SceneRouter: falha ao retornar ao MainMenu (%d)." % err)


func _on_active_game_finished(result: GameResult) -> void:
	var manager: SaveManagerService = _resolve_save_manager()
	if manager != null:
		var saved: bool = manager.record_game_result(result)
		if not saved and result != null and result.outcome != CoreTypes.MatchOutcome.ABORTED:
			push_warning("SceneRouter: resultado não registrado para '%s'." % result.game_id)
