class_name GameCard
extends PanelContainer

signal play_requested(metadata: GameMetadata)

var _metadata: GameMetadata
var _stats: Dictionary = {}

@onready var _accent_stripe: ColorRect = %AccentStripe
@onready var _icon_rect: TextureRect = %IconRect
@onready var _title_label: Label = %TitleLabel
@onready var _category_label: Label = %CategoryLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _modes_label: Label = %ModesLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	var err: Error = _play_button.pressed.connect(_on_play_button_pressed)
	if err != OK:
		push_warning("GameCard: falha ao conectar PlayButton (%d)." % err)
	_refresh_ui()


func configure(metadata: GameMetadata, stats: Dictionary = {}) -> void:
	_metadata = metadata
	_stats = stats.duplicate(true)
	if is_node_ready():
		_refresh_ui()


func get_metadata() -> GameMetadata:
	return _metadata


func _refresh_ui() -> void:
	if _metadata == null:
		return

	_accent_stripe.color = _metadata.accent_color
	_icon_rect.texture = _metadata.icon
	_icon_rect.visible = _metadata.icon != null
	_title_label.text = _metadata.title
	_category_label.text = _metadata.category.to_upper()
	_description_label.text = _metadata.description

	var mode_labels: PackedStringArray = PackedStringArray()
	for mode in _metadata.get_supported_modes():
		mode_labels.append(CoreTypes.game_mode_label(mode))
	_modes_label.text = "Modos: %s" % " • ".join(mode_labels)

	var matches_played: int = int(_stats.get("matches_played", 0))
	var wins: int = int(_stats.get("wins", 0))
	var best_streak: int = int(_stats.get("best_streak", 0))
	if matches_played <= 0:
		_stats_label.text = "Nenhuma partida registrada ainda"
	else:
		_stats_label.text = (
			"Partidas: %d • Vitórias: %d • Melhor sequência: %d"
			% [matches_played, wins, best_streak]
		)


func _on_play_button_pressed() -> void:
	if _metadata != null:
		play_requested.emit(_metadata)
