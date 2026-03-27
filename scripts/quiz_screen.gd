extends Control

# ─── Constants ───────────────────────────────────────────────────────────────
const QUIZ_TIME    := 27.0
const MAX_WRONG    := 3
const IDLE_TEXTURE := preload("res://Character/Idle/Idle-Sheet.png")

const SUBJECT_MAP := {
	"math_l1": "MATH",   "math_l2": "MATH",   "math_l3": "MATH",
	"sains_sd_1": "SAINS SD",  "sains_sd_2": "SAINS SD",  "sains_sd_3": "SAINS SD",
	"sains_smp_1": "SAINS SMP", "sains_smp_2": "SAINS SMP", "sains_smp_3": "SAINS SMP",
}

# ─── State ───────────────────────────────────────────────────────────────────
var time_left      := QUIZ_TIME
var answered       := false
var wrong_attempts := 0
var anim_tick      := 0

# ─── Node References ─────────────────────────────────────────────────────────
@onready var score_label    : Label     = $Frame/TopBar/ScoreLabel
@onready var health_label   : Label     = $Frame/TopBar/HealthLabel
@onready var subject_label  : Label     = $Frame/TopBar/SubjectBadge/SubjectLabel
@onready var question_label : Label     = $Frame/ContentRow/QuizColumn/QuestionPanel/Question
@onready var timer_text     : Label     = $Frame/TimerRow/TimerText
@onready var timer_fill     : ColorRect = $Frame/TimerRow/TimerBarBg/TimerBarFill
@onready var feedback_label : Label     = $Frame/BottomRow/Feedback
@onready var continue_button: Button    = $Frame/BottomRow/ContinueButton
@onready var timer          : Timer     = $Timer
@onready var char_sprite    : Sprite2D  = $Frame/ContentRow/CharacterPanel/CharacterSprite
@onready var char_name_label: Label     = $Frame/ContentRow/CharacterPanel/CharNameLabel
@onready var attempt_label  : Label     = $Frame/AttemptLabel
@onready var explanation_panel: Panel   = $Frame/ExplanationPanel
@onready var explanation_text : Label   = $Frame/ExplanationPanel/VBox/CharRow/ExpText
@onready var exp_char_sprite  : Sprite2D = $Frame/ExplanationPanel/VBox/CharRow/ExpChar
@onready var correct_sound = get_node_or_null("CorrectSound")

var anim_timer  : Timer
var anim_timer2 : Timer

# ─── Ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	var q := GameState.current_question()
	question_label.text = q["question"]
	_btn("A").text = "A   %s" % q["answers"][0]
	_btn("B").text = "B   %s" % q["answers"][1]
	_btn("C").text = "C   %s" % q["answers"][2]
	_btn("D").text = "D   %s" % q["answers"][3]

	_btn("A").pressed.connect(_answer.bind(0))
	_btn("B").pressed.connect(_answer.bind(1))
	_btn("C").pressed.connect(_answer.bind(2))
	_btn("D").pressed.connect(_answer.bind(3))
	continue_button.pressed.connect(_on_continue)
	timer.timeout.connect(_on_timer_tick)

	subject_label.text = SUBJECT_MAP.get(GameState.active_question_key, "QUIZ")

	# Karakter portrait atas
	char_sprite.texture  = IDLE_TEXTURE
	char_sprite.hframes  = 4; char_sprite.frame = 1
	char_sprite.modulate = GameState.current_character_color()
	char_name_label.text = GameState.current_character_name()

	# Karakter portrait panel penjelasan
	exp_char_sprite.texture  = IDLE_TEXTURE
	exp_char_sprite.hframes  = 4; exp_char_sprite.frame = 1
	exp_char_sprite.modulate = GameState.current_character_color()
	exp_char_sprite.scale    = Vector2(4.0, 4.0)

	# Animasi idle
	anim_timer = Timer.new(); anim_timer.wait_time = 0.15; anim_timer.autostart = true
	add_child(anim_timer)
	anim_timer.timeout.connect(func():
		anim_tick += 1
		char_sprite.frame     = anim_tick % 4
		exp_char_sprite.frame = anim_tick % 4)

	explanation_panel.visible = false
	attempt_label.text        = ""
	_polish_ui()
	_refresh_hud()
	_update_timer_bar()

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _btn(btn_name: String) -> Button:
	return $Frame/ContentRow/QuizColumn/Answers.get_node(btn_name)

# ─── Answer Logic ─────────────────────────────────────────────────────────────
func _answer(index: int) -> void:
	if answered:
		return
	var q: Dictionary = GameState.current_question()
	if index == q["correct"]:
		var solved_key := GameState.active_question_key
		GameState.pending_correct_sfx = not _play_correct_sound()
		# BENAR
		answered = true
		timer.stop()
		GameState.add_score(10)
		GameState.mark_question_completed(solved_key)
		GameState.achievements["first_quiz"] = true
		GameState.unlock_character_by_quiz(GameState.active_question_key)
		_highlight_correct(q)
		feedback_label.text     = "✅ BENAR! +10"
		feedback_label.modulate = Color(0.25, 1, 0.52, 1)
		feedback_label.visible  = true
		attempt_label.text      = ""
		continue_button.text    = "LANJUT ➜"
		continue_button.visible = true
		_disable_answers()
		_refresh_hud()
	else:
		# SALAH
		wrong_attempts += 1
		GameState.add_score(-2)
		_refresh_hud()

		if wrong_attempts >= MAX_WRONG:
			# Salah 3x — tampilkan penjelasan, lanjut = mulai ulang
			answered = true
			timer.stop()
			_highlight_correct(q)
			_disable_answers()
			feedback_label.text     = "❌ Salah %d/%d — Yuk belajar lagi!" % [wrong_attempts, MAX_WRONG]
			feedback_label.modulate = Color(1, 0.34, 0.34, 1)
			feedback_label.visible  = true
			attempt_label.text      = ""
			_show_explanation(q)
			continue_button.text    = "🔄 Mulai Ulang"
			continue_button.visible = true
		else:
			# Salah tapi belum 3x — coba lagi
			attempt_label.text     = "❌ Salah! Percobaan ke-%d/%d" % [wrong_attempts, MAX_WRONG]
			attempt_label.modulate = Color(1, 0.55, 0.22, 1)
			# Jangan disable — biarkan coba lagi

func _play_correct_sound() -> bool:
	if not correct_sound:
		return false
	if correct_sound.has_method("stop"):
		correct_sound.call("stop")
	if correct_sound.has_method("play"):
		correct_sound.call("play")
		return true
	return false

func _show_explanation(q: Dictionary) -> void:
	var explanation_str: String = q.get("explanation", "Pelajari kembali materi ini ya! 📚")
	explanation_text.text      = explanation_str
	explanation_panel.visible  = true
	$Frame/ContentRow/CharacterPanel.visible = false
	exp_char_sprite.visible    = false

func _on_continue() -> void:
	if wrong_attempts >= MAX_WRONG:
		# Mulai ulang — kembali ke return_scene (level akan reset)
		GameState.start_level(GameState.selected_level)
		get_tree().change_scene_to_file(GameState.return_scene)
	else:
		get_tree().change_scene_to_file(GameState.return_scene)

func _on_timer_tick() -> void:
	if answered:
		return
	time_left = max(time_left - timer.wait_time, 0.0)
	_update_timer_bar()
	if time_left <= 0.0:
		_on_time_up()

func _on_time_up() -> void:
	wrong_attempts += 1
	var hp_left: int = GameState.damage_player(1)
	_refresh_hud()
	if wrong_attempts >= MAX_WRONG:
		answered = true
		timer.stop()
		var q := GameState.current_question()
		_highlight_correct(q)
		_disable_answers()
		_show_explanation(q)
		feedback_label.text     = "⏱ Waktu habis! Nyawa -1. Belajar lagi yuk!"
		feedback_label.modulate = Color(1, 0.45, 0.45, 1)
		feedback_label.visible  = true
		continue_button.text    = "🔄 Mulai Ulang"
		continue_button.visible = true
		if hp_left <= 0:
			continue_button.text = "🔄 Mulai Ulang (GAME OVER)"
	else:
		# Reset timer, coba lagi
		time_left = QUIZ_TIME
		_update_timer_bar()
		attempt_label.text     = "⏱ Waktu habis! Percobaan ke-%d/%d" % [wrong_attempts, MAX_WRONG]
		attempt_label.modulate = Color(1, 0.55, 0.22, 1)

func _highlight_correct(q: Dictionary) -> void:
	var labels: Array[String] = ["A", "B", "C", "D"]
	var correct_btn: String   = labels[int(q["correct"])]
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color     = Color(0.10, 0.50, 0.22, 1)
	ok_style.border_color = Color(0.25, 0.85, 0.45, 0.9)
	ok_style.set_border_width_all(2)
	ok_style.corner_radius_top_left     = 8; ok_style.corner_radius_top_right    = 8
	ok_style.corner_radius_bottom_left  = 8; ok_style.corner_radius_bottom_right = 8
	_btn(correct_btn).add_theme_stylebox_override("disabled", ok_style)

func _disable_answers() -> void:
	for n in ["A", "B", "C", "D"]:
		_btn(n).disabled = true

# ─── HUD ─────────────────────────────────────────────────────────────────────
func _refresh_hud() -> void:
	score_label.text  = "SCORE: %d" % GameState.score
	health_label.text = "❤️ ".repeat(max(GameState.player_health, 0)).strip_edges()

func _update_timer_bar() -> void:
	var ratio := clampf(time_left / QUIZ_TIME, 0.0, 1.0)
	var bar_bg : ColorRect = $Frame/TimerRow/TimerBarBg
	timer_text.text               = "%ds" % int(ceil(time_left))
	timer_fill.custom_minimum_size.x = bar_bg.size.x * ratio
	timer_fill.size.x               = bar_bg.size.x * ratio
	if ratio > 0.5:   timer_fill.color = Color(0.1, 0.85, 0.78, 1)
	elif ratio > 0.25: timer_fill.color = Color(1, 0.75, 0.2, 1)
	else:              timer_fill.color = Color(1, 0.3, 0.3, 1)

# ─── UI Polish ────────────────────────────────────────────────────────────────
func _polish_ui() -> void:
	# Character panel
	var char_style := _flat_style(Color(0.06, 0.12, 0.25, 0.95), Color(0.30, 0.50, 0.85, 0.80), 10)
	$Frame/ContentRow/CharacterPanel.add_theme_stylebox_override("panel", char_style)

	# Subject badge
	var badge_style := _flat_style(Color(0.05, 0.35, 0.35, 1), Color(0.1, 0.85, 0.78, 0.9), 8)
	$Frame/TopBar/SubjectBadge.add_theme_stylebox_override("panel", badge_style)

	# Question panel
	var q_style := StyleBoxFlat.new()
	q_style.bg_color = Color(0.96, 0.97, 1.0, 1)
	q_style.border_color = Color(0.80, 0.85, 1.0, 1); q_style.set_border_width_all(2)
	q_style.corner_radius_top_left = 10; q_style.corner_radius_top_right = 10
	q_style.corner_radius_bottom_left = 10; q_style.corner_radius_bottom_right = 10
	q_style.set_content_margin_all(12)
	$Frame/ContentRow/QuizColumn/QuestionPanel.add_theme_stylebox_override("panel", q_style)
	question_label.add_theme_color_override("font_color", Color(0.08, 0.10, 0.22, 1))

	# Answer buttons
	var btn_normal := _flat_style(Color(0.07, 0.12, 0.28, 1), Color(0.28, 0.45, 0.80, 0.70), 8)
	var btn_hover  := _flat_style(Color(0.12, 0.22, 0.48, 1), Color(0.45, 0.70, 1.0, 0.90), 8)
	for n in ["A", "B", "C", "D"]:
		var btn := _btn(n)
		btn.add_theme_stylebox_override("normal",  btn_normal)
		btn.add_theme_stylebox_override("hover",   btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_hover)
		btn.add_theme_color_override("font_color", Color(0.90, 0.94, 1, 1))

	# Explanation panel
	var exp_style := _flat_style(Color(0.05, 0.10, 0.24, 0.97), Color(0.55, 0.70, 1.0, 0.60), 10)
	explanation_panel.add_theme_stylebox_override("panel", exp_style)
	explanation_text.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1))
	explanation_text.add_theme_font_size_override("font_size", 17)

	# Continue / restart button
	var cont_style := _flat_style(Color(0.10, 0.55, 0.35, 1), Color(0.20, 0.85, 0.55, 0.80), 8)
	continue_button.add_theme_stylebox_override("normal", cont_style)
	continue_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	# Attempt label
	attempt_label.add_theme_font_size_override("font_size", 18)

func _flat_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border; s.set_border_width_all(2)
	s.corner_radius_top_left    = radius; s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	return s
