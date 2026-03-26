extends Control

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	
	_set_achievement($VBox/Item1, GameState.achievements["first_quiz"])
	_set_achievement($VBox/Item2, GameState.achievements["all_coins"])
	_set_achievement($VBox/Item3, GameState.achievements["new_character"])

func _set_achievement(item: Control, unlocked: bool) -> void:
	var btn = item.get_node("Bg/StatusBtn")
	if unlocked:
		btn.text = "✓ DAPAT"
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.modulate = Color(0, 0.8, 0.4, 1) # Green
	else:
		btn.text = "✖ KUNCI"
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		btn.modulate = Color(0.2, 0.2, 0.25, 1) # Dark grey
