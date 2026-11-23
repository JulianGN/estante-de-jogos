class_name GameMetadata
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var category: String = "Clássicos"
@export var icon: Texture2D
@export var accent_color: Color = Color(0.85, 0.55, 0.2, 1.0)
@export_file("*.tscn") var scene_path: String = ""
@export var supports_ai: bool = true
@export var supports_local_multiplayer: bool = false
@export var supported_difficulties: Array[CoreTypes.Difficulty] = [
	CoreTypes.Difficulty.EASY,
	CoreTypes.Difficulty.MEDIUM,
	CoreTypes.Difficulty.HARD,
]
@export var enabled: bool = true
@export var sort_order: int = 100


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var clean_id: String = id.strip_edges()
	if clean_id.is_empty():
		errors.append("O campo 'id' não pode ser vazio.")
	else:
		var id_regex: RegEx = RegEx.new()
		var compile_err: Error = id_regex.compile("^[a-z0-9_-]+$")
		if compile_err != OK or id_regex.search(clean_id) == null:
			errors.append("O campo 'id' deve conter apenas [a-z0-9_-].")

	if title.strip_edges().is_empty():
		errors.append("O campo 'title' não pode ser vazio.")

	var clean_scene: String = scene_path.strip_edges()
	if not clean_scene.begins_with("res://") or not clean_scene.ends_with(".tscn"):
		errors.append("O campo 'scene_path' deve apontar para uma cena .tscn em res://.")

	if not supports_ai and not supports_local_multiplayer:
		errors.append("O jogo deve suportar ao menos um modo (IA ou 2 Jogadores).")

	if supports_ai and supported_difficulties.is_empty():
		errors.append("Jogos com suporte à IA devem listar ao menos uma dificuldade.")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func get_supported_modes() -> Array[CoreTypes.GameMode]:
	var modes: Array[CoreTypes.GameMode] = []
	if supports_ai:
		modes.append(CoreTypes.GameMode.VS_AI)
	if supports_local_multiplayer:
		modes.append(CoreTypes.GameMode.LOCAL_TWO_PLAYERS)
	return modes


func supports_mode(mode: CoreTypes.GameMode) -> bool:
	match mode:
		CoreTypes.GameMode.VS_AI:
			return supports_ai
		CoreTypes.GameMode.LOCAL_TWO_PLAYERS:
			return supports_local_multiplayer
	return false


func supports_difficulty(difficulty: CoreTypes.Difficulty) -> bool:
	if not supports_ai:
		return false
	return supported_difficulties.has(difficulty)


func get_default_difficulty() -> CoreTypes.Difficulty:
	if supported_difficulties.has(CoreTypes.Difficulty.MEDIUM):
		return CoreTypes.Difficulty.MEDIUM
	if not supported_difficulties.is_empty():
		return supported_difficulties[0]
	return CoreTypes.Difficulty.MEDIUM
