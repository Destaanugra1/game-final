extends Control

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Item1.modulate = Color(0.75, 1.0, 0.75, 1) if GameState.achievements["first_quiz"] else Color(1,1,1,1)
	$Item2.modulate = Color(0.75, 1.0, 0.75, 1) if GameState.achievements["all_coins"] else Color(1,1,1,1)
	$Item3.modulate = Color(0.75, 1.0, 0.75, 1) if GameState.achievements["new_character"] else Color(1,1,1,1)
