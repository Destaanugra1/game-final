extends Control

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Level1.pressed.connect(func():
		GameState.selected_level = 1
		get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
	)
	$Level2.disabled = true
	$Level3.disabled = true
