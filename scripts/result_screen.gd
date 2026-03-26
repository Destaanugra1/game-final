extends Control

func _ready() -> void:
	$Panel/Stats/ScoreText.text = "Skor: %d" % GameState.score
	$Panel/Stats/CoinText.text = "Koin: %d" % GameState.collected_coins
	$Panel/Buttons/ContinueButton.pressed.connect(_on_continue)
	$Panel/Buttons/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _on_continue() -> void:
	if GameState.advance_level():
		if GameState.selected_level == 2:
			get_tree().change_scene_to_file("res://scenes/gameplay_level2.tscn")
		elif GameState.selected_level == 3:
			get_tree().change_scene_to_file("res://scenes/gameplay_level3.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
