extends CharacterBody2D

const SPEED = 60.0
var direction = -1.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D
@onready var floor_detector = $FloorDetector
@onready var hit_box = $HitBox

var is_dead = false

func _ready():
	# Position the floor detector raycast based on start direction
	floor_detector.position.x = -20.0
	hit_box.body_entered.connect(_on_hit_box_body_entered)

func _physics_process(delta):
	if is_dead:
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor():
		var turn_around = false
		if is_on_wall():
			turn_around = true
		elif not floor_detector.is_colliding():
			turn_around = true
			
		if turn_around:
			direction *= -1.0
			floor_detector.position.x = 20.0 * direction
			sprite.scale.x = abs(sprite.scale.x) * direction
			
	velocity.x = direction * SPEED
	move_and_slide()

func _on_hit_box_body_entered(body):
	if is_dead:
		return
		
	if body.is_in_group("player"):
		# Check if the player is landing on top of the enemy (stomping)
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 15.0:
			# Stomped! Bounce the player up
			body.velocity.y = -400.0
			stomp_die()
		else:
			# Hit from the side - kill the player
			body.die()

func stomp_die():
	is_dead = true
	velocity = Vector2.ZERO
	
	# Disable physics collisions immediately
	$CollisionShape2D.set_deferred("disabled", true)
	hit_box.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# Play squash and fade out effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 0.1), 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	
	tween.chain().tween_callback(queue_free)
