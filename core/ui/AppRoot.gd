class_name AppRoot
extends Control

@onready var _scene_container: Control = %SceneContainer
@onready var _scene_router: SceneRouter = %SceneRouter


func _ready() -> void:
	_scene_router.scene_container = _scene_container
	var err: Error = _scene_router.show_main_menu()
	if err != OK:
		push_error("AppRoot: falha ao exibir MainMenu (%d)." % err)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_back_or_quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		_handle_back_or_quit()


func get_scene_router() -> SceneRouter:
	return _scene_router


func _handle_back_or_quit() -> void:
	if _scene_router != null and _scene_router.handle_back_request():
		return
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.quit()
