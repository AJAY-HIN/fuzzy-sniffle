extends Control

@onready var prompt_label = $VBoxContainer/PromptLabel

func _ready():
	# Make the prompt blink smoothly
	var tween = create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.2, 0.6)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)

func _input(event):
	# Advance on keyboard jump/space, accept or mouse click
	if event.is_action_pressed("p1_jump") or event.is_action_pressed("p2_jump") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_tree().change_scene_to_file("res://menus/player_select/player_select.tscn")
