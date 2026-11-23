extends SceneTree

const TESTS_ROOT: String = "res://tests"


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var test_files: PackedStringArray = PackedStringArray()
	_collect_test_files(TESTS_ROOT, test_files)
	test_files.sort()

	if test_files.is_empty():
		printerr("Nenhum arquivo de teste encontrado em '%s'." % TESTS_ROOT)
		quit(1)
		return

	var total_tests: int = 0
	var total_passed: int = 0
	var total_failed: int = 0
	var total_assertions: int = 0

	for file_path in test_files:
		var script_res: Resource = ResourceLoader.load(file_path)
		if not script_res is GDScript:
			printerr("FALHA ao carregar script de teste: %s" % file_path)
			total_failed += 1
			continue

		var gd_script: GDScript = script_res as GDScript
		var method_names: PackedStringArray = _extract_test_methods(gd_script)
		for method_name in method_names:
			total_tests += 1
			var instance: Variant = gd_script.new()
			if not instance is TestCase:
				printerr("FALHA %s::%s — classe deve herdar TestCase." % [file_path, method_name])
				total_failed += 1
				continue

			var test_case: TestCase = instance as TestCase
			test_case.scene_tree = self
			test_case.reset_counters()
			await test_case.call(method_name)
			await process_frame

			total_assertions += test_case.get_assertions_count()
			var failures: PackedStringArray = test_case.get_failures()
			if test_case.get_assertions_count() == 0 and failures.is_empty():
				failures.append("Nenhuma asserção executada (possível erro em tempo de execução).")
			if failures.is_empty():
				total_passed += 1
				print("[PASS] %s::%s" % [file_path, method_name])
			else:
				total_failed += 1
				printerr("[FAIL] %s::%s" % [file_path, method_name])
				for failure in failures:
					printerr("  -> %s" % failure)

	print(
		(
			"\nResumo dos testes: %d executados | %d passaram | %d falharam | %d asserções"
			% [total_tests, total_passed, total_failed, total_assertions]
		)
	)
	quit(0 if total_failed == 0 else 1)


func _collect_test_files(dir_path: String, out_files: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return

	var err: Error = dir.list_dir_begin()
	if err != OK:
		return

	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var full_path: String = "%s/%s" % [dir_path.rstrip("/"), entry]
			if dir.current_is_dir():
				_collect_test_files(full_path, out_files)
			elif entry.begins_with("test_") and entry.ends_with(".gd") and entry != "test_case.gd":
				out_files.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _extract_test_methods(gd_script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for method_info in gd_script.get_script_method_list():
		var method_dict: Dictionary = method_info as Dictionary
		var name_str: String = str(method_dict.get("name", ""))
		if name_str.begins_with("test_"):
			names.append(name_str)
	names.sort()
	return names
