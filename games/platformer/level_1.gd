extends Node2D

@onready var camera = $Camera2D

var players = []

func _ready():
	var player_scene = preload("res://games/platformer/player.tscn")
	var spawn_start_x = 100.0
	var spawn_y = 490.0
	
	for i in range(1, GameManager.player_count + 1):
		var player_inst = player_scene.instantiate()
		player_inst.player_id = i
		player_inst.position = Vector2(spawn_start_x + (i - 1) * 60.0, spawn_y)
		add_child(player_inst)
		players.append(player_inst)
		
	# Immediate positioning of camera at start
	if players.size() > 0:
		camera.position = _get_average_player_position()

func _process(delta):
	if players.size() == 0:
		return
		
	var target_pos = _get_average_player_position()
	# Smoothly interpolate camera position
	camera.position = camera.position.lerp(target_pos, 5.0 * delta)

func _get_average_player_position() -> Vector2:
	var sum = Vector2.ZERO
	var count = 0
	for player in players:
		if is_instance_valid(player):
			sum += player.position
			count += 1
			
	if count == 0:
		return Vector2(640, 360)
		
	var avg = sum / count
	# Prevent the camera from scrolling past the left edge of the level
	avg.x = max(640.0, avg.x)
	# Clamp Y value to keep it floating comfortably around platforms
	avg.y = clamp(avg.y, 250.0, 450.0)
	return avg
