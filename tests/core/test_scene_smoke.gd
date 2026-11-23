extends TestCase

const TEST_SAVE_PATH: String = "user://test_scene_smoke_save.json"
const APP_ROOT_SCENE: PackedScene = preload("res://core/ui/AppRoot.tscn")


func test_hub_and_backgammon_navigation_smoke() -> void:
	_cleanup_test_file()
	var save_manager: SaveManagerService = SaveManagerService.new()
	save_manager.save_file_path = TEST_SAVE_PATH
	save_manager.load_data()

	var app_root: AppRoot = APP_ROOT_SCENE.instantiate() as AppRoot
	assert_not_null(app_root)
	scene_tree.root.add_child(app_root)
	await scene_tree.process_frame

	var router: SceneRouter = app_root.get_scene_router()
	router.save_manager = save_manager
	assert_eq(router.show_main_menu(), OK)
	await scene_tree.process_frame

	var menu: MainMenu = router.get_current_scene() as MainMenu
	assert_not_null(menu, "AppRoot deve iniciar exibindo o MainMenu.")
	var catalog_items: Array[GameMetadata] = menu.get_loaded_metadata()
	assert_true(catalog_items.size() >= 1)

	var backgammon_meta: GameMetadata = GameCatalog.find_by_id("backgammon")
	assert_not_null(backgammon_meta)

	menu.open_launch_modal(backgammon_meta)
	assert_true(menu.is_modal_open())
	assert_true(router.handle_back_request(), "Back deve fechar modal antes de sair.")
	assert_false(menu.is_modal_open())

	menu.open_launch_modal(backgammon_meta)
	menu.select_mode(CoreTypes.GameMode.VS_AI)
	menu.select_difficulty(CoreTypes.Difficulty.HARD)
	menu.confirm_launch()
	await scene_tree.process_frame

	assert_eq(router.get_active_game_id(), "backgammon")
	var game_node: Node = router.get_current_scene()
	assert_not_null(game_node)
	assert_true(game_node.has_method("simulate_match_result"))

	game_node.call("simulate_match_result", CoreTypes.MatchOutcome.WIN, 2, "Gammon")
	await scene_tree.process_frame

	var stats: Dictionary = save_manager.get_game_stats("backgammon")
	assert_eq(int(stats["matches_played"]), 1)
	assert_eq(int(stats["wins"]), 1)

	assert_true(router.handle_back_request(), "Back no overlay de resultado retorna ao menu.")
	await scene_tree.process_frame
	assert_eq(router.get_active_game_id(), "")
	assert_true(router.get_current_scene() is MainMenu)

	var menu_again: MainMenu = router.get_current_scene() as MainMenu
	menu_again.open_launch_modal(backgammon_meta)
	menu_again.select_mode(CoreTypes.GameMode.LOCAL_TWO_PLAYERS)
	menu_again.confirm_launch()
	await scene_tree.process_frame
	assert_eq(router.get_active_game_id(), "backgammon")

	assert_true(router.handle_back_request(), "Primeiro Back no jogo abre confirmação.")
	assert_eq(router.get_active_game_id(), "backgammon")

	scene_tree.root.remove_child(app_root)
	app_root.free()
	save_manager.free()
	await scene_tree.process_frame
	_cleanup_test_file()


func _cleanup_test_file() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		var err: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
		assert_eq(err, OK)
