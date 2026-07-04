extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -500.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D

var was_on_floor = true
var facing_dir = 1.0

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
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Jump stretch
		sprite.scale = Vector2(facing_dir * 0.7, 1.3)
		was_on_floor = false

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing_dir = sign(direction)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		
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
	GameManager.take_damage()
