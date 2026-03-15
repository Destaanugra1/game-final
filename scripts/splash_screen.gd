extends Control

@onready var fill: ColorRect = $Panel/BarFill
@onready var label: Label = $Panel/LoadingLabel
@onready var timer: Timer = $Timer

var progress := 0

func _ready() -> void:
	GameState.reset_progress()
	timer.timeout.connect(_tick)

func _tick() -> void:
	progress += 5
	fill.offset_right = 150 + (320.0 * float(progress) / 100.0)
	label.text = "Loading... %d%%" % progress
	$Panel/Mascot.rotation += 0.04
	if progress >= 100:
		timer.stop()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
