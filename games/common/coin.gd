extends Area2D

@onready var sprite = $Sprite2D

var collected = false
var start_y: float

func _ready():
	start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	if not collected:
		# Float up and down
		position.y = start_y + sin(Time.get_ticks_msec() * 0.004) * 5.0
		# Spin effect (scaling x)
		sprite.scale.x = sin(Time.get_ticks_msec() * 0.005)

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		collected = true
		var player_id = body.get("player_id") if "player_id" in body else 1
		GameManager.add_score(player_id, 1)
		
		# Play smooth collect animation using Tweens
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Float up further
		tween.tween_property(self, "position:y", position.y - 50.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Fade out
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		# Shrink
		tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3)
		
		# Free the node after animation finishes
		tween.chain().tween_callback(queue_free)
