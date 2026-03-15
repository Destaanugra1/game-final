extends Control

func _ready() -> void:
	$Panel/ScoreText.text = "Score: %d" % GameState.score
	$Panel/ContinueButton.pressed.connect(_on_continue)
	$Panel/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _on_continue() -> void:
	if GameState.advance_level():
		get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/achievement.tscn")
