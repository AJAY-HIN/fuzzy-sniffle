extends Control

@onready var p1_preview = $Previews/P1
@onready var p2_preview = $Previews/P2
@onready var p3_preview = $Previews/P3
@onready var p4_preview = $Previews/P4

func _ready():
	$VBoxContainer/GridContainer/Btn1.pressed.connect(func(): _on_player_count_selected(1))
	$VBoxContainer/GridContainer/Btn2.pressed.connect(func(): _on_player_count_selected(2))
	$VBoxContainer/GridContainer/Btn3.pressed.connect(func(): _on_player_count_selected(3))
	$VBoxContainer/GridContainer/Btn4.pressed.connect(func(): _on_player_count_selected(4))
	
	$VBoxContainer/GridContainer/Btn1.mouse_entered.connect(func(): _update_previews(1))
	$VBoxContainer/GridContainer/Btn2.mouse_entered.connect(func(): _update_previews(2))
	$VBoxContainer/GridContainer/Btn3.mouse_entered.connect(func(): _update_previews(3))
	$VBoxContainer/GridContainer/Btn4.mouse_entered.connect(func(): _update_previews(4))
	
	_update_previews(2) # Default to 2 players visually

func _update_previews(count: int):
	p1_preview.visible = count >= 1
	p2_preview.visible = count >= 2
	p3_preview.visible = count >= 3
	p4_preview.visible = count >= 4

func _on_player_count_selected(count: int):
	GameManager.set_player_count(count)
	get_tree().change_scene_to_file("res://menus/game_select/game_select.tscn")
