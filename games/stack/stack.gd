extends Node2D

@onready var camera = $Camera2D
@onready var turn_label = $UI/TurnLabel

const BLOCK_HEIGHT = 35.0
var slide_speed = 400.0
var starting_width = 320.0

var stack_layers = [] # Array of Dictionary {"x": float, "width": float}
var active_players = []
var current_turn_idx = 0
var game_active = true

var active_block: ColorRect
var active_block_direction = 1
var active_block_width = 320.0
var active_block_x = 0.0

var current_y = 600.0
var base_x = 640.0 # Screen center

const PLAYER_COLORS = {
	1: Color(0.3, 0.7, 1.0),  # Blue
	2: Color(1.0, 0.3, 0.3),  # Red
	3: Color(0.3, 1.0, 0.3),  # Green
	4: Color(1.0, 0.9, 0.3)   # Yellow
}

func _ready():
	# Configure parameters based on difficulty
	if GameManager.current_difficulty == "easy":
		slide_speed = 250.0
		starting_width = 320.0
	elif GameManager.current_difficulty == "hard":
		slide_speed = 600.0
		starting_width = 220.0
	else:
		slide_speed = 400.0
		starting_width = 320.0
		
	active_block_width = starting_width
	
	# Configure active players list
	for i in range(1, GameManager.player_count + 1):
		active_players.append(i)
	
	# Place initial ground layer
	var ground = ColorRect.new()
	ground.size = Vector2(starting_width, BLOCK_HEIGHT)
	ground.position = Vector2(base_x - starting_width / 2.0, current_y)
	ground.color = Color(0.3, 0.3, 0.35)
	add_child(ground)
	stack_layers.append({"x": base_x - starting_width / 2.0, "width": starting_width})
	
	# Start first turn
	current_turn_idx = 0
	_spawn_next_block()

func _spawn_next_block():
	if not game_active or active_players.size() == 0:
		return
		
	# Move Y target up
	current_y -= BLOCK_HEIGHT
	
	# Create sliding block
	active_block = ColorRect.new()
	active_block_width = clamp(active_block_width, 10.0, 320.0)
	active_block.size = Vector2(active_block_width, BLOCK_HEIGHT)
	active_block_x = 100.0
	active_block.position = Vector2(active_block_x, current_y)
	
	var active_p_id = active_players[current_turn_idx]
	active_block.color = PLAYER_COLORS[active_p_id]
	add_child(active_block)
	
	active_block_direction = 1
	_update_turn_ui()

func _process(delta):
	if not game_active or not is_instance_valid(active_block):
		return
		
	active_block_x += active_block_direction * slide_speed * delta
	
	var left_bound = 80.0
	var right_bound = 1200.0 - active_block_width
	
	if active_block_x <= left_bound:
		active_block_x = left_bound
		active_block_direction = 1
	elif active_block_x >= right_bound:
		active_block_x = right_bound
		active_block_direction = -1
		
	active_block.position.x = active_block_x

func _input(event):
	if not game_active or not is_instance_valid(active_block):
		return
		
	var active_p_id = active_players[current_turn_idx]
	var action_jump = "p%d_jump" % active_p_id
	
	if event.is_action_pressed(action_jump) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_place_block()

func _place_block():
	var active_p_id = active_players[current_turn_idx]
	var prev_layer = stack_layers.back()
	
	var prev_left = prev_layer["x"]
	var prev_right = prev_left + prev_layer["width"]
	
	var curr_left = active_block_x
	var curr_right = curr_left + active_block_width
	
	var overlap_left = max(prev_left, curr_left)
	var overlap_right = min(prev_right, curr_right)
	var overlap_width = overlap_right - overlap_left
	
	# Check for perfect snap
	var center_diff = abs((curr_left + active_block_width / 2.0) - (prev_left + prev_layer["width"] / 2.0))
	var is_perfect = center_diff < 10.0
	
	if is_perfect:
		overlap_left = prev_left
		overlap_width = prev_layer["width"]
		_play_perfect_effect(overlap_left, overlap_width)
	
	if overlap_width <= 1.0:
		# Missed completely
		_eliminate_active_player()
	else:
		# Finalize block placement
		stack_layers.append({"x": overlap_left, "width": overlap_width})
		active_block.position.x = overlap_left
		active_block.size.x = overlap_width
		
		# Create side falling chop
		_create_chopped_piece(curr_left, curr_right, overlap_left, overlap_right)
		
		# Update active width
		active_block_width = overlap_width
		
		# Award points
		var score_gain = 2 if is_perfect else 1
		GameManager.add_score(active_p_id, score_gain)
		
		# Scroll Camera Up
		_scroll_camera()
		
		# Advance turn
		_advance_turn()
		_spawn_next_block()

func _create_chopped_piece(curr_left, curr_right, overlap_left, overlap_right):
	var chop_left = 0.0
	var chop_width = 0.0
	
	if curr_left < overlap_left:
		chop_left = curr_left
		chop_width = overlap_left - curr_left
	elif curr_right > overlap_right:
		chop_left = overlap_right
		chop_width = curr_right - overlap_right
		
	if chop_width > 2.0:
		var chop = ColorRect.new()
		chop.size = Vector2(chop_width, BLOCK_HEIGHT)
		chop.position = Vector2(chop_left, current_y)
		chop.color = active_block.color * 0.7
		add_child(chop)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(chop, "position:y", current_y + 600, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(chop, "rotation", randf_range(-1.5, 1.5), 1.0)
		tween.tween_property(chop, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(chop.queue_free)

func _play_perfect_effect(x, width):
	var flash = ColorRect.new()
	flash.size = Vector2(width, BLOCK_HEIGHT)
	flash.position = Vector2(x, current_y)
	flash.color = Color.WHITE
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(flash.queue_free)
	
	var label = Label.new()
	label.text = "PERFECT!"
	label.position = Vector2(x + width/2.0 - 50, current_y - 25)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
	add_child(label)
	
	var l_tween = create_tween()
	l_tween.set_parallel(true)
	l_tween.tween_property(label, "position:y", label.position.y - 30, 0.4)
	l_tween.tween_property(label, "modulate:a", 0.0, 0.4)
	l_tween.chain().tween_callback(label.queue_free)

func _scroll_camera():
	var target_cam_y = current_y - 200.0
	if target_cam_y < camera.position.y:
		var tween = create_tween()
		tween.tween_property(camera, "position:y", target_cam_y, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _eliminate_active_player():
	var p_id = active_players[current_turn_idx]
	active_block.color = Color(0.2, 0.2, 0.2)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(active_block, "position:y", current_y + 600, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(active_block, "rotation", 0.8, 1.2)
	tween.chain().tween_callback(active_block.queue_free)
	
	active_players.remove_at(current_turn_idx)
	
	if active_players.size() == 1:
		game_active = false
		GameManager.complete_level()
	elif active_players.size() == 0:
		# If single-player, end game immediately
		game_active = false
		GameManager.complete_level()
	else:
		if current_turn_idx >= active_players.size():
			current_turn_idx = 0
		_spawn_next_block()

func _advance_turn():
	if active_players.size() > 0:
		current_turn_idx = (current_turn_idx + 1) % active_players.size()

func _update_turn_ui():
	if not game_active or active_players.size() == 0:
		return
	var active_p_id = active_players[current_turn_idx]
	turn_label.text = "PLAYER %d'S TURN" % active_p_id
	turn_label.add_theme_color_override("font_color", PLAYER_COLORS[active_p_id])
