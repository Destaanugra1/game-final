extends Control

@onready var fill: ColorRect = $BarFill
@onready var label: Label = $LoadingLabel
@onready var timer: Timer = $Timer

var progress := 0

func _ready() -> void:
	GameState.reset_progress()
	timer.timeout.connect(_tick)

func _tick() -> void:
	progress += 2
	if progress > 100:
		progress = 100
	
	# BarFill starts at offset_left = -148.
	# The full width is 296, which means offset_right goes up to 148.
	fill.offset_right = -148 + (296.0 * float(progress) / 100.0)
	label.text = "%d%%" % progress
	
	# Make the snail bounce slightly
	if $Snail:
		var time_sec = float(Time.get_ticks_msec()) / 1000.0
		$Snail.position.y = (size.y / 2) - 140.0 + sin(time_sec * 5.0) * 10.0
	
	if progress >= 100:
		timer.stop()
		get_tree().change_scene_to_file("res://scenes/name_input.tscn")
