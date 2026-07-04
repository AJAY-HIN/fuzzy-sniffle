extends CanvasLayer

@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var lives_label = $MarginContainer/HBoxContainer/LivesLabel
@onready var message_panel = $MessagePanel
@onready var message_label = $MessagePanel/VBoxContainer/MessageLabel
@onready var restart_button = $MessagePanel/VBoxContainer/RestartButton

func _ready():
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_completed.connect(_on_level_completed)
	
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	
	message_panel.hide()
	restart_button.pressed.connect(_on_restart_button_pressed)

func _on_score_changed(new_score: int):
	score_label.text = "Coins: %d" % new_score

func _on_lives_changed(new_lives: int):
	lives_label.text = "Lives: %d" % new_lives

func _on_game_over():
	message_label.text = "GAME OVER"
	restart_button.text = "Try Again"
	message_panel.show()
	get_tree().paused = true

func _on_level_completed():
	message_label.text = "LEVEL COMPLETED!"
	restart_button.text = "Play Again"
	message_panel.show()
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	GameManager.reset_game_state()
	get_tree().reload_current_scene()
