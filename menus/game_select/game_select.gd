extends Control

@onready var btn_easy = $VBoxContainer/DifficultyContainer/BtnEasy
@onready var btn_medium = $VBoxContainer/DifficultyContainer/BtnMedium
@onready var btn_hard = $VBoxContainer/DifficultyContainer/BtnHard
@onready var high_score_label = $VBoxContainer/HighScoreLabel

var hovered_game_id: String = ""

const GAME_NAMES = {
	"platformer": "Platformer Collect",
	"stack": "Stack Tower",
	"tetris": "Falling Blocks",
	"grid_puzzle": "Grid Board Puzzle"
}

func _ready():
	# Connect difficulty buttons
	btn_easy.pressed.connect(func(): _set_difficulty("easy"))
	btn_medium.pressed.connect(func(): _set_difficulty("medium"))
	btn_hard.pressed.connect(func(): _set_difficulty("hard"))
	
	# Connect game launch buttons
	$VBoxContainer/GridContainer/BtnPlatformer.pressed.connect(func(): _launch_game("res://games/platformer/main.tscn", "platformer"))
	$VBoxContainer/GridContainer/BtnStack.pressed.connect(func(): _launch_game("res://games/stack/stack.tscn", "stack"))
	$VBoxContainer/GridContainer/BtnTetris.pressed.connect(func(): _launch_game("res://games/tetris/tetris.tscn", "tetris"))
	$VBoxContainer/GridContainer/BtnGridPuzzle.pressed.connect(func(): _launch_game("res://games/grid_puzzle/grid_puzzle.tscn", "grid_puzzle"))
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	
	# Connect hover events for dynamic high score updates
	$VBoxContainer/GridContainer/BtnPlatformer.mouse_entered.connect(func(): _on_game_hovered("platformer"))
	$VBoxContainer/GridContainer/BtnStack.mouse_entered.connect(func(): _on_game_hovered("stack"))
	$VBoxContainer/GridContainer/BtnTetris.mouse_entered.connect(func(): _on_game_hovered("tetris"))
	$VBoxContainer/GridContainer/BtnGridPuzzle.mouse_entered.connect(func(): _on_game_hovered("grid_puzzle"))
	
	# Reset hover label when leaving buttons
	for btn in [$VBoxContainer/GridContainer/BtnPlatformer, $VBoxContainer/GridContainer/BtnStack, $VBoxContainer/GridContainer/BtnTetris, $VBoxContainer/GridContainer/BtnGridPuzzle]:
		btn.mouse_exited.connect(_on_game_unhovered)
		
	# Initial visual update of difficulty buttons
	_update_difficulty_visuals()

func _set_difficulty(diff: String):
	GameManager.current_difficulty = diff
	_update_difficulty_visuals()
	if hovered_game_id != "":
		_update_high_score_display(hovered_game_id)

func _update_difficulty_visuals():
	var diff = GameManager.current_difficulty
	var active_color = Color(1.0, 0.9, 0.3)
	var inactive_color = Color(0.5, 0.5, 0.6)
	
	btn_easy.add_theme_color_override("font_color", active_color if diff == "easy" else inactive_color)
	btn_medium.add_theme_color_override("font_color", active_color if diff == "medium" else inactive_color)
	btn_hard.add_theme_color_override("font_color", active_color if diff == "hard" else inactive_color)

func _on_game_hovered(game_id: String):
	hovered_game_id = game_id
	_update_high_score_display(game_id)

func _on_game_unhovered():
	hovered_game_id = ""
	high_score_label.text = "Select a game to see High Score"

func _update_high_score_display(game_id: String):
	var diff = GameManager.current_difficulty
	var score = GameManager.high_scores.get(game_id, {}).get(diff, 0)
	var g_name = GAME_NAMES.get(game_id, "Game")
	
	high_score_label.text = "%s High Score: %d (%s)" % [g_name, score, diff.capitalize()]

func _launch_game(scene_path: String, game_id: String):
	GameManager.active_game_id = game_id
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://menus/player_select/player_select.tscn")
