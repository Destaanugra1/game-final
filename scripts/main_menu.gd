extends Control

func _ready() -> void:
	$MenuPanel/StartButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/gameplay.tscn"))
	$MenuPanel/LevelButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	$MenuPanel/CharacterButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_select.tscn"))
	$MenuPanel/AchievementButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/achievement.tscn"))
	$ScoreLabel.text = "Score: %d" % GameState.score
	$CharacterLabel.text = "Karakter: %s" % GameState.current_character_name()
	$PreviewPanel/CharacterPreview.color = GameState.current_character_color()
