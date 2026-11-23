class_name GameModule
extends Control

signal exit_requested
signal game_finished(result: GameResult)

var session_config: GameSessionConfig


func setup_session(config: GameSessionConfig) -> void:
	session_config = config


func handle_back_request() -> bool:
	return false
