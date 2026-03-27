extends Control

const FINISH_SOUND_STREAM := preload("res://assets/sounds/mixkit-game-level-completed-2059.wav")

var finish_sound_player: AudioStreamPlayer

func _ready() -> void:
	GameState.stop_gameplay_music()
	_play_finish_sound()
	$Panel/Stats/ScoreText.text = "Skor: %d" % GameState.score
	$Panel/Stats/CoinText.text = "Koin: %d" % GameState.collected_coins
	$Panel/Buttons/ContinueButton.pressed.connect(_on_continue)
	$Panel/Buttons/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _play_finish_sound() -> void:
	finish_sound_player = AudioStreamPlayer.new()
	finish_sound_player.name = "FinishSoundPlayer"
	finish_sound_player.stream = FINISH_SOUND_STREAM
	add_child(finish_sound_player)
	finish_sound_player.play()

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
