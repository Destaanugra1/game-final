extends Node

var score := 0
var selected_character := 0
var unlocked_characters := [true, false, false]
var selected_level := 1
var max_level := 3
var quiz_completed := false
var achievements := {
	"first_quiz": false,
	"all_coins": false,
	"new_character": false
}
var collected_coins := 0
var max_health := 3
var player_health := 3

var questions := {
	1: {"question": "8 + 4 = ?", "answers": ["12", "10", "14", "11"], "correct": 0},
	2: {"question": "9 x 3 = ?", "answers": ["21", "27", "24", "18"], "correct": 1},
	3: {"question": "20 - 7 = ?", "answers": ["12", "13", "15", "14"], "correct": 1}
}

func reset_progress() -> void:
	score = 0
	quiz_completed = false
	collected_coins = 0
	selected_level = 1
	player_health = max_health

func start_level(level: int) -> void:
	selected_level = clamp(level, 1, max_level)
	quiz_completed = false
	collected_coins = 0
	player_health = max_health

func add_score(amount: int) -> void:
	score += amount
	if score >= 15:
		unlocked_characters[1] = true
		achievements["new_character"] = true
	if score >= 30:
		unlocked_characters[2] = true

func current_character_name() -> String:
	return ["Aksa", "Nara", "Pixel"][selected_character]

func current_character_color() -> Color:
	return [Color(0.23,0.5,0.96,1), Color(0.58,0.24,0.9,1), Color(0.1,0.78,0.78,1)][selected_character]

func current_question() -> Dictionary:
	return questions.get(selected_level, questions[1])

func damage_player(amount: int = 1) -> int:
	player_health = max(player_health - amount, 0)
	return player_health

func heal_full() -> void:
	player_health = max_health

func advance_level() -> bool:
	if selected_level < max_level:
		selected_level += 1
		quiz_completed = false
		collected_coins = 0
		player_health = max_health
		return true
	return false
