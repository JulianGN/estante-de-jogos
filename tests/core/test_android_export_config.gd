extends TestCase

const PRESETS_PATH: String = "res://export_presets.cfg"
const PROJECT_PATH: String = "res://project.godot"


func test_android_export_preset_has_minimal_permissions_and_no_secrets() -> void:
	assert_true(FileAccess.file_exists(PROJECT_PATH), "Arquivo project.godot deve existir.")
	var proj_file: FileAccess = FileAccess.open(PROJECT_PATH, FileAccess.READ)
	assert_not_null(proj_file)
	var proj_content: String = proj_file.get_as_text()
	proj_file.close()
	assert_contains(
		proj_content,
		"window/handheld/orientation=1",
		"Orientação Portrait em project.godot deve usar valor inteiro 1.",
	)

	assert_true(
		FileAccess.file_exists(PRESETS_PATH),
		"Arquivo export_presets.cfg deve existir.",
	)
	var file: FileAccess = FileAccess.open(PRESETS_PATH, FileAccess.READ)
	assert_not_null(file)
	var content: String = file.get_as_text()
	file.close()

	assert_contains(content, 'package/unique_name="com.juliangn.estantedejogos"')
	assert_contains(content, 'package/name="Estante de Jogos"')
	assert_contains(content, "screen/orientation=1")
	assert_contains(content, "permissions/custom_permissions=PackedStringArray()")

	assert_contains(content, 'keystore/debug=""')
	assert_contains(content, 'keystore/debug_user=""')
	assert_contains(content, 'keystore/debug_password=""')
	assert_contains(content, 'keystore/release=""')
	assert_contains(content, 'keystore/release_user=""')
	assert_contains(content, 'keystore/release_password=""')

	assert_false(content.contains("C:\\"), "Não deve conter caminhos locais C:\\.")
	assert_false(content.contains("C:/"), "Não deve conter caminhos locais C:/.")
	assert_false(content.contains("D:\\"), "Não deve conter caminhos locais D:\\.")
	assert_false(content.contains("D:/"), "Não deve conter caminhos locais D:/.")

	var lines: PackedStringArray = content.split("\n")
	for raw_line in lines:
		var line: String = raw_line.strip_edges()
		if line.begins_with("permissions/"):
			assert_false(
				line.ends_with("=true"),
				"Permissão desnecessária ativada em export_presets.cfg: %s" % line,
			)
