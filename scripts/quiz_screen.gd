extends Control

const QUIZ_TIME := 27.0

var time_left := QUIZ_TIME
var answered := false

@onready var score_label: Label = $Frame/Header/ScoreLabel
@onready var health_label: Label = $Frame/Header/HealthLabel
@onready var question_label: Label = $Frame/QuestionPanel/Question
@onready var timer_text: Label = $Frame/TimerText
@onready var timer_fill: ColorRect = $Frame/TimerBarBg/TimerBarFill
@onready var feedback_label: Label = $Frame/Feedback
@onready var continue_button: Button = $Frame/ContinueButton
@onready var timer: Timer = $Timer

func _ready() -> void:
	var q = GameState.current_question()
	question_label.text = q["question"]
	$Frame/Answers/A.text = "A  %s" % q["answers"][0]
	$Frame/Answers/B.text = "B  %s" % q["answers"][1]
	$Frame/Answers/C.text = "C  %s" % q["answers"][2]
	$Frame/Answers/D.text = "D  %s" % q["answers"][3]

	$Frame/Answers/A.pressed.connect(_answer.bind(0))
	$Frame/Answers/B.pressed.connect(_answer.bind(1))
	$Frame/Answers/C.pressed.connect(_answer.bind(2))
	$Frame/Answers/D.pressed.connect(_answer.bind(3))
	continue_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/gameplay.tscn"))
	timer.timeout.connect(_on_timer_tick)

	_refresh_hud()
	_update_timer_bar()

func _on_timer_tick() -> void:
	if answered:
		return
	time_left = max(time_left - timer.wait_time, 0.0)
	_update_timer_bar()
	if time_left <= 0.0:
		_on_time_up()

func _answer(index: int) -> void:
	if answered:
		return
	answered = true
	timer.stop()
	var q = GameState.current_question()
	if index == q["correct"]:
		GameState.add_score(10)
		GameState.quiz_completed = true
		GameState.achievements["first_quiz"] = true
		feedback_label.visible = true
		feedback_label.text = "BENAR! +10"
		feedback_label.modulate = Color(0.3, 1, 0.52, 1)
	else:
		GameState.add_score(-2)
		feedback_label.visible = true
		feedback_label.text = "Salah! -2"
		feedback_label.modulate = Color(1, 0.34, 0.34, 1)
	continue_button.visible = true
	_disable_answers()
	_refresh_hud()

func _on_time_up() -> void:
	answered = true
	timer.stop()
	var hp_left := GameState.damage_player(1)
	feedback_label.visible = true
	feedback_label.text = "Waktu habis! Nyawa -1"
	feedback_label.modulate = Color(1, 0.45, 0.45, 1)
	continue_button.visible = true
	_disable_answers()
	_refresh_hud()
	if hp_left <= 0:
		continue_button.text = "LANJUT (GAME OVER)"

func _disable_answers() -> void:
	$Frame/Answers/A.disabled = true
	$Frame/Answers/B.disabled = true
	$Frame/Answers/C.disabled = true
	$Frame/Answers/D.disabled = true

func _refresh_hud() -> void:
	score_label.text = "SCORE: %d" % GameState.score
	health_label.text = "NYAWA: %d" % GameState.player_health

func _update_timer_bar() -> void:
	var ratio := clamp(time_left / QUIZ_TIME, 0.0, 1.0)
	timer_text.text = "%ds" % int(ceil(time_left))
	timer_fill.custom_minimum_size.x = 676.0 * ratio
	timer_fill.size.x = 676.0 * ratio
	if ratio > 0.5:
		timer_fill.color = Color(0.1, 0.85, 0.78, 1)
	elif ratio > 0.25:
		timer_fill.color = Color(1, 0.75, 0.2, 1)
	else:
		timer_fill.color = Color(1, 0.3, 0.3, 1)
