class_name GameCatalog
extends RefCounted

const DEFAULT_CATALOG_DIR: String = "res://core/catalog"


static func normalize_resource_path(dir_path: String, file_name: String) -> String:
	var clean_dir: String = dir_path.rstrip("/")
	if file_name.ends_with(".tres.remap"):
		var base_name: String = file_name.trim_suffix(".remap")
		return "%s/%s" % [clean_dir, base_name]
	if file_name.ends_with(".tres"):
		return "%s/%s" % [clean_dir, file_name]
	return ""


static func load_all(
	catalog_dir: String = DEFAULT_CATALOG_DIR,
	include_disabled: bool = false,
) -> Array[GameMetadata]:
	var items: Array[GameMetadata] = []
	var dir: DirAccess = DirAccess.open(catalog_dir)
	if dir == null:
		push_warning("GameCatalog: não foi possível abrir '%s'." % catalog_dir)
		return items

	var seen_paths: Dictionary = {}
	var seen_ids: Dictionary = {}

	var list_err: Error = dir.list_dir_begin()
	if list_err != OK:
		push_warning("GameCatalog: falha ao listar '%s' (%d)." % [catalog_dir, list_err])
		return items

	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir():
			var resource_path: String = normalize_resource_path(catalog_dir, file_name)
			if not resource_path.is_empty() and not seen_paths.has(resource_path):
				seen_paths[resource_path] = true
				var metadata: GameMetadata = _load_valid_metadata(resource_path)
				if metadata != null:
					if seen_ids.has(metadata.id):
						push_warning(
							"GameCatalog: id duplicado '%s' em '%s'." % [metadata.id, resource_path]
						)
					else:
						seen_ids[metadata.id] = true
						if include_disabled or metadata.enabled:
							items.append(metadata)
		file_name = dir.get_next()
	dir.list_dir_end()

	items.sort_custom(_compare_metadata)
	return items


static func find_by_id(
	game_id: String,
	catalog_dir: String = DEFAULT_CATALOG_DIR,
	include_disabled: bool = false,
) -> GameMetadata:
	var clean_id: String = game_id.strip_edges()
	if clean_id.is_empty():
		return null
	var catalog: Array[GameMetadata] = load_all(catalog_dir, include_disabled)
	for entry in catalog:
		if entry.id == clean_id:
			return entry
	return null


static func _load_valid_metadata(resource_path: String) -> GameMetadata:
	var loaded: Resource = ResourceLoader.load(resource_path)
	if not loaded is GameMetadata:
		return null
	var metadata: GameMetadata = loaded as GameMetadata
	var errors: PackedStringArray = metadata.validate()
	if not errors.is_empty():
		push_warning(
			"GameCatalog: metadados inválidos em '%s': %s" % [resource_path, "; ".join(errors)]
		)
		return null
	return metadata


static func _compare_metadata(a: GameMetadata, b: GameMetadata) -> bool:
	if a.sort_order != b.sort_order:
		return a.sort_order < b.sort_order
	return a.title.naturalnocasecmp_to(b.title) < 0
