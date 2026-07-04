extends CanvasLayer

@onready var p1_label = $MarginContainer/HBoxContainer/P1Label
@onready var p2_label = $MarginContainer/HBoxContainer/P2Label
@onready var p3_label = $MarginContainer/HBoxContainer/P3Label
@onready var p4_label = $MarginContainer/HBoxContainer/P4Label

@onready var message_panel = $MessagePanel
@onready var message_label = $MessagePanel/VBoxContainer/MessageLabel
@onready var restart_button = $MessagePanel/VBoxContainer/RestartButton

const PLAYER_COLORS = {
	1: Color(0.3, 0.7, 1.0),  # Blue
	2: Color(1.0, 0.3, 0.3),  # Red
	3: Color(0.3, 1.0, 0.3),  # Green
	4: Color(1.0, 0.9, 0.3)   # Yellow
}

func _ready():
	GameManager.player_scores_updated.connect(_on_scores_updated)
	GameManager.level_completed.connect(_on_level_completed)
	
	_setup_score_labels()
	message_panel.hide()
	restart_button.pressed.connect(_on_restart_button_pressed)

func _setup_score_labels():
	var labels = [p1_label, p2_label, p3_label, p4_label]
	for idx in range(labels.size()):
		var p_num = idx + 1
		var label = labels[idx]
		if p_num <= GameManager.player_count:
			label.show()
			label.text = "P%d: 0" % p_num
			label.add_theme_color_override("font_color", PLAYER_COLORS[p_num])
		else:
			label.hide()

func _on_scores_updated():
	var labels = [p1_label, p2_label, p3_label, p4_label]
	for idx in range(GameManager.player_count):
		var p_num = idx + 1
		var label = labels[idx]
		label.text = "P%d: %d" % [p_num, GameManager.player_scores[p_num]]

func _on_level_completed(winner_id: int):
	if winner_id == 0:
		message_label.text = "TIE GAME!"
		message_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		message_label.text = "PLAYER %d WINS!" % winner_id
		message_label.add_theme_color_override("font_color", PLAYER_COLORS.get(winner_id, Color.WHITE))
		
	restart_button.text = "Play Again"
	message_panel.show()
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	GameManager.reset_game_state()
	# Go back to player selection screen
	get_tree().change_scene_to_file("res://menus/player_select/player_select.tscn")
