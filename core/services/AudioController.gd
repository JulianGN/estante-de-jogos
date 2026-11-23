class_name AudioControllerService
extends Node

const SFX_POOL_SIZE: int = 4
const SETTING_SFX_ENABLED: String = "sfx_enabled"
const SETTING_MUSIC_ENABLED: String = "music_enabled"

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _sfx_enabled: bool = true
var _music_enabled: bool = true


func _ready() -> void:
	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		add_child(player)
		_sfx_players.append(player)

	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		_sfx_enabled = bool(save_manager.get_setting(SETTING_SFX_ENABLED, true))
		_music_enabled = bool(save_manager.get_setting(SETTING_MUSIC_ENABLED, true))


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		save_manager.set_setting(SETTING_SFX_ENABLED, enabled)


func is_sfx_enabled() -> bool:
	return _sfx_enabled


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		save_manager.set_setting(SETTING_MUSIC_ENABLED, enabled)


func is_music_enabled() -> bool:
	return _music_enabled


func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if not _sfx_enabled or stream == null or _sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = _sfx_players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.play()


func _get_save_manager() -> SaveManagerService:
	var node: Node = get_node_or_null("/root/SaveManager")
	if node is SaveManagerService:
		return node as SaveManagerService
	return null
