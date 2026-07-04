extends Node2D

const CELL_SIZE = 22.0
const GRID_COLS = 10
const GRID_ROWS = 20

const SHAPES = [
	[[1, 1, 1, 1]], # I
	[[1, 1], [1, 1]], # O
	[[0, 1, 0], [1, 1, 1]], # T
	[[0, 1, 1], [1, 1, 0]], # S
	[[1, 1, 0], [0, 1, 1]], # Z
	[[1, 0, 0], [1, 1, 1]], # J
	[[0, 0, 1], [1, 1, 1]]  # L
]

const PALETTE = [
	Color(0.12, 0.1, 0.18),    # 0: Empty background cell
	Color(0.0, 0.9, 0.9),      # 1: Cyan (I)
	Color(0.9, 0.9, 0.0),      # 2: Yellow (O)
	Color(0.7, 0.0, 0.9),      # 3: Purple (T)
	Color(0.0, 0.9, 0.0),      # 4: Green (S)
	Color(0.9, 0.0, 0.0),      # 5: Red (Z)
	Color(0.0, 0.4, 0.9),      # 6: Blue (J)
	Color(0.9, 0.5, 0.0),      # 7: Orange (L)
	Color(0.5, 0.5, 0.5)       # 8: Gray (Garbage)
]

const BOARD_BORDER_COLOR = Color(0.2, 0.25, 0.4)

var boards = []
var game_active = true
var tick_timer = 0.8
var current_tick_cooldown = 0.8

var touch_starts = {}
var touch_last_xs = {}

class TetrisBoard:
	var player_id: int
	var grid: Array = []
	var active_shape: Array = []
	var active_type: int = 0
	var active_pos: Vector2 = Vector2.ZERO
	var next_type: int = 0
	var game_over: bool = false
	
	func _init(p_id: int):
		player_id = p_id
		# Initialize grid
		for r in range(GRID_ROWS):
			var row = []
			for c in range(GRID_COLS):
				row.append(0)
			grid.append(row)

func _ready():
	GameManager.reset_game_state()
	
	# Configure gravity tick speed based on difficulty
	if GameManager.current_difficulty == "easy":
		tick_timer = 1.3
	elif GameManager.current_difficulty == "hard":
		tick_timer = 0.4
	else:
		tick_timer = 0.8
		
	current_tick_cooldown = tick_timer
	
	# Configure boards side-by-side
	for i in range(1, GameManager.player_count + 1):
		var board = TetrisBoard.new(i)
		boards.append(board)
		_spawn_piece(board)
	
	queue_redraw()

func _input(event):
	if not game_active:
		return
		
	if event is InputEventScreenTouch:
		var col_width = 1280.0 / boards.size()
		var player_idx = int(event.position.x / col_width)
		if player_idx < boards.size():
			var board = boards[player_idx]
			if board.game_over:
				return
				
			if event.pressed:
				touch_starts[event.index] = event.position
				touch_last_xs[event.index] = event.position.x
			else:
				if touch_starts.has(event.index):
					var start_pos = touch_starts[event.index]
					var dist = start_pos.distance_to(event.position)
					if dist < 25.0:
						_rotate_active_piece(board)
					touch_starts.erase(event.index)
					touch_last_xs.erase(event.index)
					
	elif event is InputEventScreenDrag:
		var col_width = 1280.0 / boards.size()
		var player_idx = int(event.position.x / col_width)
		if player_idx < boards.size():
			var board = boards[player_idx]
			if board.game_over:
				return
				
			# Horizontal Swipe
			var last_x = touch_last_xs.get(event.index, event.position.x)
			var diff_x = event.position.x - last_x
			if diff_x > 25.0:
				var new_pos = board.active_pos + Vector2(1, 0)
				if not _check_collision(board, new_pos, board.active_shape):
					board.active_pos = new_pos
					queue_redraw()
				touch_last_xs[event.index] = event.position.x
			elif diff_x < -25.0:
				var new_pos = board.active_pos + Vector2(-1, 0)
				if not _check_collision(board, new_pos, board.active_shape):
					board.active_pos = new_pos
					queue_redraw()
				touch_last_xs[event.index] = event.position.x
				
			# Vertical Swipe Down
			if touch_starts.has(event.index):
				var start_pos = touch_starts[event.index]
				var diff_y = event.position.y - start_pos.y
				if diff_y > 80.0:
					var new_pos = board.active_pos + Vector2(0, 1)
					if not _check_collision(board, new_pos, board.active_shape):
						board.active_pos = new_pos
						queue_redraw()
					else:
						_lock_piece(board)
						queue_redraw()
					touch_starts[event.index].y = event.position.y

func _rotate_active_piece(board: TetrisBoard):
	var rotated = _rotate_matrix(board.active_shape)
	var kicked_pos = board.active_pos
	var kick_success = false
	for offset in [0, -1, 1, -2, 2]:
		var test_pos = board.active_pos + Vector2(offset, 0)
		if not _check_collision(board, test_pos, rotated):
			kicked_pos = test_pos
			kick_success = true
			break
	if kick_success:
		board.active_shape = rotated
		board.active_pos = kicked_pos
		queue_redraw()

func _spawn_piece(board: TetrisBoard):
	if board.next_type == 0:
		board.next_type = randi() % SHAPES.size() + 1
		
	board.active_type = board.next_type
	board.active_shape = SHAPES[board.active_type - 1]
	board.next_type = randi() % SHAPES.size() + 1
	
	# Position at top center
	var shape_width = board.active_shape[0].size()
	board.active_pos = Vector2(floor((GRID_COLS - shape_width) / 2.0), 0)
	
	# Check instant collision -> Game Over
	if _check_collision(board, board.active_pos, board.active_shape):
		board.game_over = true
		_check_global_game_over()

func _process(delta):
	if not game_active:
		return
		
	# Game tick timer
	current_tick_cooldown -= delta
	if current_tick_cooldown <= 0.0:
		print("DEBUG: Tetris process tick. Boards size = ", boards.size())
		current_tick_cooldown = tick_timer
		_game_tick()
	
	# Process input events
	var update_visuals = false
	for board in boards:
		if board.game_over:
			continue
			
		var p_id = board.player_id
		var action_left = "p%d_left" % p_id
		var action_right = "p%d_right" % p_id
		var action_jump = "p%d_jump" % p_id # Jump acts as Rotate
		
		if Input.is_action_just_pressed(action_left):
			var new_pos = board.active_pos + Vector2(-1, 0)
			if not _check_collision(board, new_pos, board.active_shape):
				board.active_pos = new_pos
				update_visuals = true
		elif Input.is_action_just_pressed(action_right):
			var new_pos = board.active_pos + Vector2(1, 0)
			if not _check_collision(board, new_pos, board.active_shape):
				board.active_pos = new_pos
				update_visuals = true
		elif Input.is_action_just_pressed(action_jump):
			var rotated = _rotate_matrix(board.active_shape)
			# Wall kick check (simple horizontal offset kick)
			var kicked_pos = board.active_pos
			var kick_success = false
			for offset in [0, -1, 1, -2, 2]:
				var test_pos = board.active_pos + Vector2(offset, 0)
				if not _check_collision(board, test_pos, rotated):
					kicked_pos = test_pos
					kick_success = true
					break
			if kick_success:
				board.active_shape = rotated
				board.active_pos = kicked_pos
				update_visuals = true
				
	if update_visuals:
		queue_redraw()

func _game_tick():
	var redraw_needed = false
	for board in boards:
		if board.game_over:
			continue
			
		var new_pos = board.active_pos + Vector2(0, 1)
		if not _check_collision(board, new_pos, board.active_shape):
			board.active_pos = new_pos
			redraw_needed = true
		else:
			_lock_piece(board)
			redraw_needed = true
			
	if redraw_needed:
		queue_redraw()

func _lock_piece(board: TetrisBoard):
	var shape = board.active_shape
	var pos = board.active_pos
	
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] != 0:
				var grid_y = int(pos.y) + r
				var grid_x = int(pos.x) + c
				if grid_y >= 0 and grid_y < GRID_ROWS and grid_x >= 0 and grid_x < GRID_COLS:
					board.grid[grid_y][grid_x] = board.active_type
					
	# Clear lines and score
	var lines_cleared = _clear_lines(board)
	if lines_cleared > 0:
		var score_points = [0, 10, 30, 60, 100]
		var awarded = score_points[clamp(lines_cleared, 1, 4)]
		GameManager.add_score(board.player_id, awarded)
		
		# Send garbage lines if 2+ lines cleared
		if lines_cleared >= 2:
			_send_garbage(board.player_id, lines_cleared - 1)
			
	# Spawn next
	_spawn_piece(board)

func _clear_lines(board: TetrisBoard) -> int:
	var cleared = 0
	var r = GRID_ROWS - 1
	while r >= 0:
		var is_full = true
		for c in range(GRID_COLS):
			if board.grid[r][c] == 0:
				is_full = false
				break
		if is_full:
			cleared += 1
			board.grid.remove_at(r)
			# Add empty row at top
			var empty_row = []
			for c in range(GRID_COLS):
				empty_row.append(0)
			board.grid.insert(0, empty_row)
		else:
			r -= 1
	return cleared

func _send_garbage(sender_id: int, lines_count: int):
	for board in boards:
		if board.player_id == sender_id or board.game_over:
			continue
			
		for l in range(lines_count):
			# Shift grid up
			board.grid.remove_at(0)
			# Insert garbage row at bottom with one hole
			var garbage_row = []
			var hole_col = randi() % GRID_COLS
			for c in range(GRID_COLS):
				garbage_row.append(8 if c != hole_col else 0)
			board.grid.append(garbage_row)
			
		# Check if garbage caused collision immediately on active piece
		if _check_collision(board, board.active_pos, board.active_shape):
			board.game_over = true
			_check_global_game_over()

func _check_collision(board: TetrisBoard, pos: Vector2, shape: Array) -> bool:
	for r in range(shape.size()):
		for c in range(shape[r].size()):
			if shape[r][c] != 0:
				var test_x = int(pos.x) + c
				var test_y = int(pos.y) + r
				
				# Grid bounds check
				if test_x < 0 or test_x >= GRID_COLS or test_y >= GRID_ROWS:
					return true
				# Collision with existing locked pieces
				if test_y >= 0 and board.grid[test_y][test_x] != 0:
					return true
	return false

func _rotate_matrix(matrix: Array) -> Array:
	var n = matrix.size()
	var m = matrix[0].size()
	var rotated = []
	for i in range(m):
		var row = []
		for j in range(n - 1, -1, -1):
			row.append(matrix[j][i])
		rotated.append(row)
	return rotated

func _check_global_game_over():
	var all_over = true
	for board in boards:
		if not board.game_over:
			all_over = false
			break
			
	if all_over:
		game_active = false
		GameManager.complete_level()

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.058, 0.05, 0.15), true)
	
	var col_width = 1280.0 / boards.size()
	var board_pixel_w = GRID_COLS * CELL_SIZE
	var board_pixel_h = GRID_ROWS * CELL_SIZE
	
	for idx in range(boards.size()):
		var board = boards[idx]
		var base_x_pos = (idx + 0.5) * col_width - board_pixel_w / 2.0
		var base_y_pos = 130.0
		
		# Draw outer border box
		var border_rect = Rect2(base_x_pos - 4, base_y_pos - 4, board_pixel_w + 8, board_pixel_h + 8)
		draw_rect(border_rect, BOARD_BORDER_COLOR, false, 4.0)
		
		# Draw grid lines & cells
		for r in range(GRID_ROWS):
			for c in range(GRID_COLS):
				var cell_x = base_x_pos + c * CELL_SIZE
				var cell_y = base_y_pos + r * CELL_SIZE
				var cell_rect = Rect2(cell_x, cell_y, CELL_SIZE, CELL_SIZE)
				
				var cell_val = board.grid[r][c]
				draw_rect(cell_rect, PALETTE[cell_val], true)
				# Cell border outline
				draw_rect(cell_rect, Color(0.08, 0.07, 0.12), false, 1.0)
				
		# Draw active falling piece
		if not board.game_over:
			var shape = board.active_shape
			var pos = board.active_pos
			for r in range(shape.size()):
				for c in range(shape[r].size()):
					if shape[r][c] != 0:
						var cell_x = base_x_pos + (pos.x + c) * CELL_SIZE
						var cell_y = base_y_pos + (pos.y + r) * CELL_SIZE
						if cell_y >= base_y_pos:
							var cell_rect = Rect2(cell_x, cell_y, CELL_SIZE, CELL_SIZE)
							draw_rect(cell_rect, PALETTE[board.active_type], true)
							draw_rect(cell_rect, Color.WHITE * 0.4, false, 1.0)
							
		# Draw Next Piece box
		var next_box_x = base_x_pos + board_pixel_w + 10.0
		var next_box_y = base_y_pos + 10.0
		var next_rect = Rect2(next_box_x, next_box_y, 4.0 * CELL_SIZE, 3.0 * CELL_SIZE)
		draw_rect(next_rect, BOARD_BORDER_COLOR * 0.5, true)
		draw_rect(next_rect, BOARD_BORDER_COLOR, false, 2.0)
		
		# Render next piece inside box
		if not board.game_over:
			var next_shape = SHAPES[board.next_type - 1]
			var ns_h = next_shape.size()
			var ns_w = next_shape[0].size()
			var draw_offset_x = next_box_x + (4.0 * CELL_SIZE - ns_w * CELL_SIZE) / 2.0
			var draw_offset_y = next_box_y + (3.0 * CELL_SIZE - ns_h * CELL_SIZE) / 2.0
			
			for r in range(ns_h):
				for c in range(ns_w):
					if next_shape[r][c] != 0:
						var cell_rect = Rect2(draw_offset_x + c * CELL_SIZE, draw_offset_y + r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
						draw_rect(cell_rect, PALETTE[board.next_type], true)
						draw_rect(cell_rect, Color(0.08, 0.07, 0.12), false, 1.0)
						
		# Game over gray overlay
		if board.game_over:
			var overlay = Rect2(base_x_pos, base_y_pos, board_pixel_w, board_pixel_h)
			draw_rect(overlay, Color(0.1, 0.1, 0.1, 0.75), true)
