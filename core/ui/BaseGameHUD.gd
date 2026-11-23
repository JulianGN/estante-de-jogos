class_name BaseGameHUD
extends Control

signal exit_confirmed
signal replay_requested

var _title: String = ""
var _subtitle: String = ""

@onready var _exit_button: Button = %ExitButton
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _extra_slot: HBoxContainer = %ExtraSlot
@onready var _exit_confirm_overlay: ColorRect = %ExitConfirmOverlay
@onready var _continue_button: Button = %ContinueButton
@onready var _confirm_exit_button: Button = %ConfirmExitButton
@onready var _result_overlay: ColorRect = %ResultOverlay
@onready var _result_title_label: Label = %ResultTitleLabel
@onready var _result_details_label: Label = %ResultDetailsLabel
@onready var _replay_button: Button = %ReplayButton
@onready var _result_exit_button: Button = %ResultExitButton


func _ready() -> void:
	var e1: Error = _exit_button.pressed.connect(request_exit_confirmation)
	var e2: Error = _continue_button.pressed.connect(hide_overlays)
	var e3: Error = _confirm_exit_button.pressed.connect(_on_confirm_exit_pressed)
	var e4: Error = _replay_button.pressed.connect(_on_replay_pressed)
	var e5: Error = _result_exit_button.pressed.connect(_on_confirm_exit_pressed)
	if e1 != OK or e2 != OK or e3 != OK or e4 != OK or e5 != OK:
		push_warning("BaseGameHUD: falha ao conectar sinais dos botões.")

	_exit_confirm_overlay.visible = false
	_result_overlay.visible = false
	_refresh_header()


func configure_header(title: String, subtitle: String) -> void:
	_title = title
	_subtitle = subtitle
	if is_node_ready():
		_refresh_header()


func get_extra_slot() -> HBoxContainer:
	return _extra_slot


func request_exit_confirmation() -> void:
	if is_node_ready():
		_result_overlay.visible = false
		_exit_confirm_overlay.visible = true


func show_result_dialog(result: GameResult) -> void:
	if result == null or not is_node_ready():
		return

	_exit_confirm_overlay.visible = false
	_result_title_label.text = "%s!" % CoreTypes.outcome_label(result.outcome)

	var detail_lines: PackedStringArray = PackedStringArray()
	if not result.winner_label.is_empty():
		detail_lines.append("Vencedor: %s" % result.winner_label)
	if not result.score_label.is_empty():
		detail_lines.append("Pontuação: %s (%dx)" % [result.score_label, result.score_multiplier])
	if result.duration_seconds > 0:
		detail_lines.append("Duração: %ds" % result.duration_seconds)
	if detail_lines.is_empty():
		detail_lines.append("Partida concluída e registrada.")

	_result_details_label.text = "\n".join(detail_lines)
	_result_overlay.visible = true


func hide_overlays() -> void:
	if is_node_ready():
		_exit_confirm_overlay.visible = false
		_result_overlay.visible = false


func is_overlay_open() -> bool:
	if not is_node_ready():
		return false
	return _exit_confirm_overlay.visible or _result_overlay.visible


func handle_back_request() -> bool:
	if not is_node_ready():
		return false
	if _exit_confirm_overlay.visible:
		_exit_confirm_overlay.visible = false
		return true
	if _result_overlay.visible:
		_result_overlay.visible = false
		exit_confirmed.emit()
		return true
	_exit_confirm_overlay.visible = true
	return true


func _refresh_header() -> void:
	_title_label.text = _title
	_subtitle_label.text = _subtitle


func _on_confirm_exit_pressed() -> void:
	hide_overlays()
	exit_confirmed.emit()


func _on_replay_pressed() -> void:
	hide_overlays()
	replay_requested.emit()
