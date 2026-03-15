extends Control

@onready var cards := [$Card1, $Card2, $Card3]

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	for i in cards.size():
		cards[i].pressed.connect(_select.bind(i))
	_refresh()

func _select(index: int) -> void:
	if not GameState.unlocked_characters[index]:
		$SelectedLabel.text = "Karakter masih terkunci"
		return
	GameState.selected_character = index
	_refresh()

func _refresh() -> void:
	var names = ["AKSA", "NARA", "PIXEL"]
	for i in cards.size():
		cards[i].text = names[i] + "\n" + ("UNLOCK" if GameState.unlocked_characters[i] else "LOCKED")
		cards[i].disabled = not GameState.unlocked_characters[i]
	$SelectedLabel.text = "Terpilih: %s" % GameState.current_character_name()
