extends Control

func _ready() -> void:
	var q = GameState.current_question()
	$Panel/Question.text = q["question"]
	$Panel/A.text = q["answers"][0]
	$Panel/B.text = q["answers"][1]
	$Panel/C.text = q["answers"][2]
	$Panel/D.text = q["answers"][3]
	$Panel/A.pressed.connect(_answer.bind(0))
	$Panel/B.pressed.connect(_answer.bind(1))
	$Panel/C.pressed.connect(_answer.bind(2))
	$Panel/D.pressed.connect(_answer.bind(3))
	$Panel/ContinueButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/gameplay.tscn"))

func _answer(index: int) -> void:
	var q = GameState.current_question()
	if index == q["correct"]:
		GameState.add_score(10)
		GameState.quiz_completed = true
		GameState.achievements["first_quiz"] = true
		$Panel/Feedback.visible = true
		$Panel/Feedback.text = "BENAR! +10"
		$Panel/Feedback.modulate = Color(0.1, 0.7, 0.2, 1)
		$Panel/ContinueButton.visible = true
		_disable()
	else:
		GameState.add_score(-2)
		$Panel/Feedback.visible = true
		$Panel/Feedback.text = "Salah, ulangi lagi! -2"
		$Panel/Feedback.modulate = Color(0.9, 0.2, 0.2, 1)

func _disable() -> void:
	$Panel/A.disabled = true
	$Panel/B.disabled = true
	$Panel/C.disabled = true
	$Panel/D.disabled = true
