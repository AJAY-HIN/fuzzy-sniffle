extends CharacterBody2D

var active_touches = {}

var current_speed = 250.0
const JUMP_VELOCITY = -500.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

@export var player_id: int = 1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D

var was_on_floor = true
var facing_dir = 1.0
var spawn_position: Vector2

var action_left: String
var action_right: String
var action_jump: String

const PLAYER_COLORS = {
	1: Color(0.3, 0.7, 1.0),  # Blue
	2: Color(1.0, 0.3, 0.3),  # Red
	3: Color(0.3, 1.0, 0.3),  # Green
	4: Color(1.0, 0.9, 0.3)   # Yellow
}

func _ready():
	spawn_position = global_position
	
	# Adjust speed based on difficulty
	if GameManager.current_difficulty == "easy":
		current_speed = 200.0
	elif GameManager.current_difficulty == "hard":
		current_speed = 320.0
	else:
		current_speed = 250.0
		
	# Configure player-specific actions and appearance
	action_left = "p%d_left" % player_id
	action_right = "p%d_right" % player_id
	action_jump = "p%d_jump" % player_id
	
	if sprite:
		sprite.modulate = PLAYER_COLORS.get(player_id, Color.WHITE)

func _input(event):
	if player_id == 1:
		if event is InputEventScreenTouch:
			if event.pressed:
				active_touches[event.index] = event.position
			else:
				active_touches.erase(event.index)
		elif event is InputEventScreenDrag:
			active_touches[event.index] = event.position

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
		# Stretch when moving vertically in the air
		var target_y_scale = 1.1 if velocity.y < 0 else 0.9
		var target_x_scale = 0.9 if velocity.y < 0 else 1.1
		sprite.scale.x = lerp(sprite.scale.x, facing_dir * target_x_scale, 8 * delta)
		sprite.scale.y = lerp(sprite.scale.y, target_y_scale, 8 * delta)
	else:
		if not was_on_floor:
			# Just landed! Apply landing squash
			sprite.scale = Vector2(facing_dir * 1.3, 0.7)
			was_on_floor = true
	
	# Handle Jump.
	var touch_jump_active = false
	var touch_direction = 0.0
	
	if player_id == 1:
		for touch_pos in active_touches.values():
			if touch_pos.y < 360.0:
				touch_jump_active = true
			else:
				if touch_pos.x < 640.0:
					touch_direction -= 1.0
				else:
					touch_direction += 1.0
					
	var jump_triggered = Input.is_action_just_pressed(action_jump) or (touch_jump_active and is_on_floor())
	if jump_triggered and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Jump stretch
		sprite.scale = Vector2(facing_dir * 0.7, 1.3)
		was_on_floor = false

	# Get the input direction and handle the movement/deceleration.
	var direction = touch_direction if touch_direction != 0.0 else Input.get_axis(action_left, action_right)
	if direction != 0:
		facing_dir = sign(direction)
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCELERATION * delta)
		
		# Face direction and tilt slightly when running
		var target_rotation = direction * 0.15
		sprite.rotation = rotate_toward(sprite.rotation, target_rotation, 5 * delta)
		
		# Bobbing while walking
		if is_on_floor():
			var bob = sin(Time.get_ticks_msec() * 0.015) * 0.06
			sprite.scale.y = 1.0 + bob
			sprite.scale.x = facing_dir * (1.0 - bob)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		sprite.rotation = rotate_toward(sprite.rotation, 0, 5 * delta)
		
		# Idle breathing animation
		if is_on_floor():
			var breath = sin(Time.get_ticks_msec() * 0.003) * 0.03
			sprite.scale.x = lerp(sprite.scale.x, facing_dir * (1.0 + breath), 5 * delta)
			sprite.scale.y = lerp(sprite.scale.y, 1.0 - breath, 5 * delta)

	# Gradually return scale to normal (1.0, 1.0)
	if is_on_floor():
		sprite.scale.x = move_toward(sprite.scale.x, facing_dir * 1.0, 5 * delta)
		sprite.scale.y = move_toward(sprite.scale.y, 1.0, 5 * delta)
	else:
		sprite.scale.x = move_toward(sprite.scale.x, facing_dir * 1.0, 2 * delta)
		sprite.scale.y = move_toward(sprite.scale.y, 1.0, 2 * delta)

	move_and_slide()
	
	# Check if player fell out of the world
	if position.y > 1000:
		die()

func die():
	# Deduct score for falling/dying
	GameManager.add_score(player_id, -1)
	
	# Teleport back to starting spawn position
	global_position = spawn_position
	velocity = Vector2.ZERO
	sprite.rotation = 0
	
	# Apply landing squash effect
	sprite.scale = Vector2(facing_dir * 1.3, 0.7)
