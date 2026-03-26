extends Control

@onready var line_edit = $VBoxContainer/NameInput
@onready var submit_btn = $VBoxContainer/SubmitButton

func _ready() -> void:
	line_edit.grab_focus()
	submit_btn.pressed.connect(_on_submit)
	line_edit.text_submitted.connect(_on_text_submit)

func _on_submit() -> void:
	_save_and_continue(line_edit.text)

func _on_text_submit(new_text: String) -> void:
	_save_and_continue(new_text)

func _save_and_continue(given_name: String) -> void:
	var clean_name = given_name.strip_edges()
	if clean_name == "":
		clean_name = "Player"
	
	GameState.player_name = clean_name
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
