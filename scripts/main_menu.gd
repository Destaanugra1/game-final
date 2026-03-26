extends Control

func _ready() -> void:
	$MenuContainer/StartButton.pressed.connect(_start_game)
	$MenuContainer/LevelButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	$MenuContainer/CharacterButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
	$MenuContainer/AchievementButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/achievement.tscn"))
	
	if has_node("TopRightProfile/MarginContainer/HBoxContainer/Label"):
		$TopRightProfile/MarginContainer/HBoxContainer/Label.text = GameState.player_name
		
	if has_node("CharacterPreview"):
		$CharacterPreview.modulate = GameState.current_character_color()

func _start_game() -> void:
	if GameState.selected_level == 3:
		get_tree().change_scene_to_file("res://scenes/gameplay_level3.tscn")
	elif GameState.selected_level == 2:
		get_tree().change_scene_to_file("res://scenes/gameplay_level2.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
