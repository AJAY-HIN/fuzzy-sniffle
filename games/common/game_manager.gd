extends Node

signal player_scores_updated()
signal game_over(winner_id)
signal level_completed(winner_id)

var player_count: int = 1
var player_scores: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}

var active_game_id: String = "platformer"
var current_difficulty: String = "medium"

var high_scores: Dictionary = {
	"platformer": { "easy": 0, "medium": 0, "hard": 0 },
	"stack": { "easy": 0, "medium": 0, "hard": 0 },
	"tetris": { "easy": 0, "medium": 0, "hard": 0 },
	"grid_puzzle": { "easy": 0, "medium": 0, "hard": 0 }
}

const SAVE_PATH = "user://highscores.json"

func _ready():
	load_high_scores()
	reset_game_state()

func set_player_count(count: int) -> void:
	player_count = clamp(count, 1, 4)
	reset_scores()

func add_score(player_id: int, amount: int) -> void:
	if player_scores.has(player_id):
		player_scores[player_id] = max(0, player_scores[player_id] + amount)
		player_scores_updated.emit()

func reset_scores() -> void:
	player_scores = {1: 0, 2: 0, 3: 0, 4: 0}
	player_scores_updated.emit()

func get_winner() -> int:
	var max_score = -1
	var winner_id = 1
	var tie = false
	
	# Find high score
	for id in range(1, player_count + 1):
		if player_scores[id] > max_score:
			max_score = player_scores[id]
			winner_id = id
			tie = false
		elif player_scores[id] == max_score and max_score > 0:
			tie = true
			
	if tie:
		return 0 # 0 denotes a tie
	return winner_id

func complete_level() -> void:
	var winner = get_winner()
	
	# Check and save high score
	var highest_session_score = 0
	for id in range(1, player_count + 1):
		highest_session_score = max(highest_session_score, player_scores[id])
		
	if highest_session_score > high_scores.get(active_game_id, {}).get(current_difficulty, 0):
		high_scores[active_game_id][current_difficulty] = highest_session_score
		save_high_scores()
		
	level_completed.emit(winner)

func reset_game_state() -> void:
	reset_scores()

# Load high scores from local user storage
func load_high_scores():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_err = json.parse(content)
	if parse_err == OK:
		var parsed_data = json.get_data()
		if typeof(parsed_data) == TYPE_DICTIONARY:
			# Merge loaded values safely
			for g_key in parsed_data.keys():
				if high_scores.has(g_key):
					for d_key in parsed_data[g_key].keys():
						if high_scores[g_key].has(d_key):
							high_scores[g_key][d_key] = int(parsed_data[g_key][d_key])

# Save high scores to local user storage
func save_high_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data_str = JSON.stringify(high_scores)
	file.store_string(data_str)
	file.close()
