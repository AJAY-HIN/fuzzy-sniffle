extends Node

signal score_changed(new_score)
signal lives_changed(new_lives)
signal game_over()
signal level_completed()

var score: int = 0
var lives: int = 3
var max_lives: int = 3

func _ready():
	reset_game_state()

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func take_damage() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
	else:
		# Reload level or respawn player
		get_tree().reload_current_scene()

func reset_game_state() -> void:
	score = 0
	lives = max_lives
	score_changed.emit(score)
	lives_changed.emit(lives)

func complete_level() -> void:
	level_completed.emit()
