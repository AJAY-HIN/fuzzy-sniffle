extends Node2D

const CELL_SIZE = 36.0
const GRID_SIZE = 10

const SHAPES_EASY = [
	[[1]],                                  # 1x1 Single
	[[1, 1]],                               # Horizontal 2
	[[1], [1]],                             # Vertical 2
	[[1, 1], [1, 1]]                        # 2x2 Square
]

const SHAPES_MEDIUM = [
	[[1]],                                  # 1x1 Single
	[[1, 1], [1, 1]],                       # 2x2 Square
	[[1, 1, 1], [1, 1, 1], [1, 1, 1]],     # 3x3 Square
	[[1], [1]],                             # Vertical 2
	[[1], [1], [1]],                        # Vertical 3
	[[1, 1]],                               # Horizontal 2
	[[1, 1, 1]],                            # Horizontal 3
	[[1, 0], [1, 1]],                       # L-Shape
	[[0, 1], [1, 1]]                        # J-Shape
]

const SHAPES_HARD = [
	[[1]],                                  # 1x1 Single
	[[1, 1], [1, 1]],                       # 2x2 Square
	[[1, 1, 1], [1, 1, 1], [1, 1, 1]],     # 3x3 Square
	[[1], [1]],                             # Vertical 2
	[[1], [1], [1]],                        # Vertical 3
	[[1, 1]],                               # Horizontal 2
	[[1, 1, 1]],                            # Horizontal 3
	[[1, 0], [1, 1]],                       # L-Shape
	[[0, 1], [1, 1]],                       # J-Shape
	[[1, 0, 0], [1, 0, 0], [1, 1, 1]],     # Large L-Shape (3x3)
	[[1, 1, 1], [0, 1, 0], [0, 1, 0]],     # Large T-Shape (3x3)
	[[0, 1, 0], [1, 1, 1], [0, 1, 0]],     # Plus/Cross (3x3)
	[[1, 0], [0, 1]]                        # Diagonal 2
]

var active_templates = []

const PALETTE = [
	Color(0.08, 0.07, 0.15),   # 0: Empty cell
	Color(0.3, 0.7, 1.0),      # 1: P1 Blue
	Color(1.0, 0.3, 0.3),      # 2: P2 Red
	Color(0.3, 1.0, 0.3),      # 3: P3 Green
	Color(1.0, 0.9, 0.3)       # 4: P4 Yellow
]

var grid = []
var active_players = []
var current_turn_idx = 0
var game_active = true

var player_racks = {}    # { player_id (int): Array of shapes }
var player_cursors = {}  # { player_id (int): int (0-99) }
var active_shape_idx = {} # { player_id (int): int (0-2) active index }

var input_timers = {}    # { action_name (string): float }
const KEY_REPEAT_DELAY = 0.12

func _ready():
	GameManager.reset_game_state()
	
	# Load active templates based on difficulty
	if GameManager.current_difficulty == "easy":
		active_templates = SHAPES_EASY
	elif GameManager.current_difficulty == "hard":
		active_templates = SHAPES_HARD
	else:
		active_templates = SHAPES_MEDIUM
	
	# Initialize 10x10 grid
	for r in range(GRID_SIZE):
		var row = []
		for c in range(GRID_SIZE):
			row.append(0)
		grid.append(row)
		
	# Configure active players
	for i in range(1, GameManager.player_count + 1):
		active_players.append(i)
		player_cursors[i] = 45 # Spawn cursor at center
		active_shape_idx[i] = 0
		_generate_new_rack(i)
		
	current_turn_idx = 0
	_check_and_rotate_valid_shapes()
	queue_redraw()

func _input(event):
	if not game_active or active_players.size() == 0:
		return
		
	if event is InputEventScreenTouch and event.pressed:
		var active_p_id = active_players[current_turn_idx]
		
		# Check if grid is clicked
		var board_w = GRID_SIZE * CELL_SIZE
		var base_x_pos = 640.0 - board_w / 2.0
		var base_y_pos = 140.0
		
		if event.position.x >= base_x_pos and event.position.x < base_x_pos + board_w and event.position.y >= base_y_pos and event.position.y < base_y_pos + board_w:
			var c = int((event.position.x - base_x_pos) / CELL_SIZE)
			var r = int((event.position.y - base_y_pos) / CELL_SIZE)
			if c >= 0 and c < GRID_SIZE and r >= 0 and r < GRID_SIZE:
				player_cursors[active_p_id] = r * 10 + c
				_try_place_shape()
				queue_redraw()
				return
				
		# Check if shape rack is clicked
		var col_width = 1280.0 / GameManager.player_count
		var idx = active_p_id - 1
		var base_rack_x = (idx + 0.5) * col_width - 80.0
		var base_rack_y = 570.0
		
		if event.position.y >= base_rack_y + 18.0 and event.position.y < base_rack_y + 63.0:
			var rel_x = event.position.x - base_rack_x
			var s = int(rel_x / 55.0)
			var rack = player_racks.get(active_p_id, [])
			if s >= 0 and s < rack.size():
				active_shape_idx[active_p_id] = s
				queue_redraw()

func _generate_new_rack(player_id: int):
	var rack = []
	for s in range(3):
		rack.append(active_templates[randi() % active_templates.size()])
	player_racks[player_id] = rack
	active_shape_idx[player_id] = 0

func _process(delta):
	if not game_active or active_players.size() == 0:
		return
		
	# Update input timers
	for key in input_timers.keys():
		if input_timers[key] > 0.0:
			input_timers[key] -= delta
			
	var active_p_id = active_players[current_turn_idx]
	var action_left = "p%d_left" % active_p_id
	var action_right = "p%d_right" % active_p_id
	var action_jump = "p%d_jump" % active_p_id
	
	# Process input navigation with key repeat
	var update_needed = false
	if Input.is_action_pressed(action_left):
		if not input_timers.has(action_left) or input_timers[action_left] <= 0.0:
			player_cursors[active_p_id] = (player_cursors[active_p_id] - 1 + 100) % 100
			input_timers[action_left] = KEY_REPEAT_DELAY
			update_needed = true
	elif Input.is_action_pressed(action_right):
		if not input_timers.has(action_right) or input_timers[action_right] <= 0.0:
			player_cursors[active_p_id] = (player_cursors[active_p_id] + 1) % 100
			input_timers[action_right] = KEY_REPEAT_DELAY
			update_needed = true
			
	if Input.is_action_just_pressed(action_jump):
		_try_place_shape()
		update_needed = true
		
	if update_needed:
		queue_redraw()

func _try_place_shape():
	var active_p_id = active_players[current_turn_idx]
	var rack = player_racks[active_p_id]
	var s_idx = active_shape_idx[active_p_id]
	
	if s_idx >= rack.size():
		return
		
	var shape = rack[s_idx]
	var cursor = player_cursors[active_p_id]
	var row = int(cursor / 10)
	var col = int(cursor % 10)
	
	if _fits_at(row, col, shape):
		# Place shape on grid
		for r in range(shape.size()):
			for c in range(shape[r].size()):
				if shape[r][c] != 0:
					grid[row + r][col + c] = active_p_id
					
		# Remove shape from rack
		rack.remove_at(s_idx)
		GameManager.add_score(active_p_id, 2) # Points for placement
		
		# Check line clears
		_check_line_clears(active_p_id)
		
		# If rack is empty, generate 3 new ones
		if rack.size() == 0:
			_generate_new_rack(active_p_id)
		else:
			# Clamp active index
			active_shape_idx[active_p_id] = 0
			
		# Advance turn
		_advance_turn()
	else:
		# If it doesn't fit, but there are other shapes in the rack, cycle to the next shape
		if rack.size() > 1:
			active_shape_idx[active_p_id] = (s_idx + 1) % rack.size()

func _fits_at(row: int, col: int, shape: Array) -> bool:
	var sh_h = shape.size()
	var sh_w = shape[0].size()
	
	# Bounds check
	if row + sh_h > GRID_SIZE or col + sh_w > GRID_SIZE:
		return false
		
	# Collision check
	for r in range(sh_h):
		for c in range(sh_w):
			if shape[r][c] != 0:
				if grid[row + r][col + c] != 0:
					return false
	return true

func _has_any_valid_moves(player_id: int) -> bool:
	var rack = player_racks[player_id]
	for shape in rack:
		# Test all 100 cell positions
		for i in range(100):
			var r = int(i / 10)
			var c = int(i % 10)
			if _fits_at(r, c, shape):
				return true
	return false

func _check_line_clears(player_id: int):
	var rows_to_clear = []
	var cols_to_clear = []
	
	# Check rows
	for r in range(GRID_SIZE):
		var full = true
		for c in range(GRID_SIZE):
			if grid[r][c] == 0:
				full = false
				break
		if full:
			rows_to_clear.append(r)
			
	# Check columns
	for c in range(GRID_SIZE):
		var full = true
		for r in range(GRID_SIZE):
			if grid[r][c] == 0:
				full = false
				break
		if full:
			cols_to_clear.append(c)
			
	# Clear cells
	for r in rows_to_clear:
		for c in range(GRID_SIZE):
			grid[r][c] = 0
	for c in cols_to_clear:
		for r in range(GRID_SIZE):
			grid[r][c] = 0
			
	var cleared_lines = rows_to_clear.size() + cols_to_clear.size()
	if cleared_lines > 0:
		GameManager.add_score(player_id, cleared_lines * 10)

func _advance_turn():
	if active_players.size() == 0:
		return
	current_turn_idx = (current_turn_idx + 1) % active_players.size()
	_check_and_rotate_valid_shapes()

func _check_and_rotate_valid_shapes():
	# Loop checking if next player can move. If not, eliminate them!
	var iterations = 0
	var max_iterations = active_players.size()
	
	while iterations < max_iterations:
		var test_p_id = active_players[current_turn_idx]
		if _has_any_valid_moves(test_p_id):
			# This player has valid moves, keep their turn active!
			# Ensure the active shape idx points to a shape that fits somewhere
			var rack = player_racks[test_p_id]
			var start_idx = active_shape_idx[test_p_id]
			for offset in range(rack.size()):
				var test_idx = (start_idx + offset) % rack.size()
				if _shape_has_moves(rack[test_idx]):
					active_shape_idx[test_p_id] = test_idx
					break
			return
		else:
			# Eliminated! No moves available
			_eliminate_player(test_p_id)
			iterations += 1
			
	# If loop exits without returning, all players are eliminated
	game_active = false
	_find_winner_and_end()

func _shape_has_moves(shape: Array) -> bool:
	for i in range(100):
		var r = int(i / 10)
		var c = int(i % 10)
		if _fits_at(r, c, shape):
			return true
	return false

func _eliminate_player(player_id: int):
	# Grey out their remaining shapes
	player_racks[player_id] = []
	
	# Find player index in active list
	var idx = active_players.find(player_id)
	if idx != -1:
		active_players.remove_at(idx)
		
	if active_players.size() == 0:
		game_active = false
		_find_winner_and_end()
	else:
		if current_turn_idx >= active_players.size():
			current_turn_idx = 0

func _find_winner_and_end():
	GameManager.complete_level()

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.058, 0.05, 0.15), true)
	
	# Centered 10x10 Grid Drawing
	var board_w = GRID_SIZE * CELL_SIZE
	var base_x_pos = 640.0 - board_w / 2.0
	var base_y_pos = 140.0
	
	# Outer border box
	var border = Rect2(base_x_pos - 4, base_y_pos - 4, board_w + 8, board_w + 8)
	draw_rect(border, Color(0.2, 0.25, 0.4), false, 4.0)
	
	# Draw cells
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var cell_rect = Rect2(base_x_pos + c * CELL_SIZE, base_y_pos + r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var cell_val = grid[r][c]
			draw_rect(cell_rect, PALETTE[cell_val], true)
			draw_rect(cell_rect, Color(0.08, 0.07, 0.12), false, 1.0)
			
	if not game_active or active_players.size() == 0:
		return
		
	# Draw active player ghost preview and cursor
	var active_p_id = active_players[current_turn_idx]
	var cursor = player_cursors[active_p_id]
	var cursor_r = int(cursor / 10)
	var cursor_c = int(cursor % 10)
	
	var rack = player_racks[active_p_id]
	var s_idx = active_shape_idx[active_p_id]
	
	if s_idx < rack.size():
		var shape = rack[s_idx]
		var fits = _fits_at(cursor_r, cursor_c, shape)
		var ghost_color = PALETTE[active_p_id]
		ghost_color.a = 0.5 if fits else 0.15 # transparent faint ghost if blocked
		
		# Render ghost outline on grid
		for r in range(shape.size()):
			for c in range(shape[r].size()):
				if shape[r][c] != 0:
					var test_r = cursor_r + r
					var test_c = cursor_c + c
					if test_r < GRID_SIZE and test_c < GRID_SIZE:
						var ghost_rect = Rect2(base_x_pos + test_c * CELL_SIZE, base_y_pos + test_r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
						draw_rect(ghost_rect, ghost_color, true)
						draw_rect(ghost_rect, Color.WHITE * (0.8 if fits else 0.2), false, 1.5)
						
		# Render cursor outline around top-left ghost cell
		var cursor_rect = Rect2(base_x_pos + cursor_c * CELL_SIZE, base_y_pos + cursor_r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(cursor_rect, Color.WHITE, false, 2.0)
		
	# Render Turn header text
	var font = SystemFont.new()
	var font_size = 28
	var header_text = "PLAYER %d'S TURN" % active_p_id
	draw_string(font, Vector2(640.0 - 100, 100.0), header_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, PALETTE[active_p_id])
	
	# Render dynamic racks for active players side-by-side at the bottom
	var col_width = 1280.0 / GameManager.player_count
	for idx in range(GameManager.player_count):
		var p_num = idx + 1
		var base_rack_x = (idx + 0.5) * col_width - 80.0
		var base_rack_y = 570.0
		
		# Draw active turn box
		var active_glow = p_num == active_p_id and game_active
		if active_glow:
			var border_glow = Rect2(base_rack_x - 10, base_rack_y - 10, 180, 110)
			draw_rect(border_glow, PALETTE[p_num] * 0.4, true)
			draw_rect(border_glow, PALETTE[p_num], false, 2.0)
			
		# Label
		draw_string(font, Vector2(base_rack_x + 80.0, base_rack_y - 15.0), "P%d" % p_num, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, PALETTE[p_num])
		
		var p_rack = player_racks.get(p_num, [])
		var p_active_s_idx = active_shape_idx.get(p_num, 0)
		
		# Render the 3 shapes in rack
		for s in range(p_rack.size()):
			var shape = p_rack[s]
			var draw_x = base_rack_x + s * 55.0
			var draw_y = base_rack_y + 20.0
			var is_current = s == p_active_s_idx and p_num == active_p_id
			
			# Draw background preview bounding box
			var box = Rect2(draw_x - 2, draw_y - 2, 45, 45)
			draw_rect(box, Color(0.1, 0.1, 0.15) if is_current else Color(0.06, 0.05, 0.1), true)
			draw_rect(box, PALETTE[p_num] if is_current else Color(0.2, 0.2, 0.25), false, 1.0)
			
			# Render shape matrix
			var scale_factor = 10.0
			var sh_h = shape.size()
			var sh_w = shape[0].size()
			var offset_x = draw_x + (40.0 - sh_w * scale_factor) / 2.0
			var offset_y = draw_y + (40.0 - sh_h * scale_factor) / 2.0
			
			for r in range(sh_h):
				for c in range(sh_w):
					if shape[r][c] != 0:
						var preview_cell = Rect2(offset_x + c * scale_factor, offset_y + r * scale_factor, scale_factor, scale_factor)
						draw_rect(preview_cell, PALETTE[p_num] if is_current else PALETTE[p_num] * 0.4, true)
