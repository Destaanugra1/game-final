extends Node

const MENU_MUSIC_STREAM := preload("res://assets/music/AdhesiveWombat - Night Shade  NO COPYRIGHT 8-bit Music.mp3")
const GAMEPLAY_MUSIC_STREAM := preload("res://assets/music/time_for_adventure.mp3")

var score              := 0
var selected_character := 0
var unlocked_characters: Array[bool] = [true, false, false]
var selected_level     := 1
var max_level          := 3
var quiz_completed     := false
var achievements := {"first_quiz": false, "all_coins": false, "new_character": false}
var collected_coins    := 0
var max_health         := 3
var player_health      := 3
var return_scene       := "res://scenes/gameplay.tscn"
var return_position    := Vector2(120, 420)
var killed_enemies     : Array[String] = []
var completed_quiz_keys: Array[String] = []
var active_question_key := "math_l1"
var player_name        := "Player"
var pending_correct_sfx := false
var menu_music_player  : AudioStreamPlayer
var gameplay_music_player: AudioStreamPlayer

const CHARACTER_DATA := [
	{"name": "AKSA",  "stat": "Logika +2",   "hint": "Karakter awal"},
	{"name": "NARA",  "stat": "Kekuatan +2", "hint": "Selesaikan soal Sains SD"},
	{"name": "PIXEL", "stat": "Reflex +2",   "hint": "Selesaikan soal Sains SMP"},
]

const QUIZ_UNLOCK_MAP := {
	"sains_sd_1": 1,  "sains_sd_2": 1,  "sains_sd_3": 1,
	"sains_smp_1": 2, "sains_smp_2": 2, "sains_smp_3": 2,
}

var question_banks := {
	"math_l1": {
		"question": "8 + 4 = ?",
		"answers": ["12", "10", "14", "11"], "correct": 0,
		"explanation": "8 + 4 = 12. Penjumlahan adalah operasi dasar matematika.\nCoba hitung: 8 jari lalu tambah 4 jari = 12 jari! 🖐️"
	},
	"math_l2": {
		"question": "9 x 3 = ?",
		"answers": ["21", "27", "24", "18"], "correct": 1,
		"explanation": "9 x 3 = 27. Perkalian = penjumlahan berulang: 9+9+9 = 27.\nTrik cepat: (10×3) − 3 = 30 − 3 = 27! 💡"
	},
	"math_l3": {
		"question": "20 - 7 = ?",
		"answers": ["12", "13", "15", "14"], "correct": 1,
		"explanation": "20 - 7 = 13. Mulai dari 20, mundur 7 langkah:\n20 → 19 → 18 → 17 → 16 → 15 → 14 → 13 ✅"
	},
	"sains_sd_1": {
		"question": "Apa fungsi utama akar pada tumbuhan?",
		"answers": ["Menyerap air & mineral", "Membuat makanan", "Menghirup oksigen", "Menyimpan biji"],
		"correct": 0,
		"explanation": "Akar berfungsi menyerap air dan mineral dari tanah untuk dikirim ke seluruh tubuh tumbuhan. Akar juga menopang tumbuhan agar berdiri kokoh! 🌱"
	},
	"sains_sd_2": {
		"question": "Benda yang bisa menarik besi disebut…",
		"answers": ["Konduktor", "Isolator", "Magnet", "Generator"],
		"correct": 2,
		"explanation": "Magnet adalah benda yang memiliki gaya tarik terhadap besi atau baja.\nMagnet memiliki dua kutub: Utara (N) dan Selatan (S). Kutub berbeda saling tarik! 🧲"
	},
	"sains_sd_3": {
		"question": "Hewan yang mengalami metamorfosis sempurna adalah…",
		"answers": ["Kucing", "Katak", "Kupu-kupu", "Ikan"],
		"correct": 2,
		"explanation": "Kupu-kupu mengalami metamorfosis sempurna:\nTelur → Ulat (larva) → Kepompong (pupa) → Kupu-kupu dewasa (imago). Ada 4 tahap! 🦋"
	},
	"sains_smp_1": {
		"question": "Organel sel yang berfungsi sebagai 'dapur energi' adalah…",
		"answers": ["Nukleus", "Ribosom", "Mitokondria", "Vakuola"],
		"correct": 2,
		"explanation": "Mitokondria adalah organel tempat respirasi seluler yang menghasilkan energi (ATP).\nItulah mengapa mitokondria disebut 'pembangkit listrik sel'! ⚡"
	},
	"sains_smp_2": {
		"question": "Rumus kimia air adalah…",
		"answers": ["CO₂", "H₂O", "O₂", "NaCl"],
		"correct": 1,
		"explanation": "Air = H₂O → 2 atom Hidrogen + 1 atom Oksigen.\nCO₂=karbon dioksida, O₂=oksigen, NaCl=garam dapur. 💧"
	},
	"sains_smp_3": {
		"question": "Gaya gravitasi bumi menyebabkan benda jatuh dengan percepatan sekitar…",
		"answers": ["5 m/s²", "15 m/s²", "10 m/s²", "20 m/s²"],
		"correct": 2,
		"explanation": "Percepatan gravitasi g ≈ 9.8 m/s² (dibulatkan 10 m/s²).\nArtinya setiap detik, kecepatan benda jatuh bertambah 10 m/s. Rumus: F = m × g 🌍"
	},
	"sains_smp_4": {
		"question": "Logam yang berwujud cair pada suhu ruang adalah…",
		"answers": ["Emas", "Perak", "Raksa", "Tembaga"],
		"correct": 2,
		"explanation": "Raksa (Merkuri/Hg) adalah satu-satunya logam yang berwujud cair pada suhu standar.\nSering digunakan pada termometer raksa klasik! 🌡️"
	},
	"sains_smp_5": {
		"question": "Jika dua kutub magnet yang senama (Utara-Utara) didekatkan, yang terjadi adalah…",
		"answers": ["Tarik-menarik", "Tolak-menolak", "Netral", "Meledak"],
		"correct": 1,
		"explanation": "Kutub yang senama (U-U atau S-S) pada magnet selalu tolak-menolak.\nHanya kutub yang berbeda (U-S) yang saling tarik menarik! 🧲"
	},
}

func _ready() -> void:
	_ensure_menu_music_player()
	_ensure_gameplay_music_player()

func _ensure_menu_music_player() -> void:
	if is_instance_valid(menu_music_player):
		return
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.name = "MenuMusicPlayer"
	menu_music_player.stream = MENU_MUSIC_STREAM
	add_child(menu_music_player)

func _ensure_gameplay_music_player() -> void:
	if is_instance_valid(gameplay_music_player):
		return
	gameplay_music_player = AudioStreamPlayer.new()
	gameplay_music_player.name = "Music1"
	gameplay_music_player.stream = GAMEPLAY_MUSIC_STREAM
	if gameplay_music_player.stream is AudioStreamMP3:
		(gameplay_music_player.stream as AudioStreamMP3).loop = true
	add_child(gameplay_music_player)

func play_menu_music() -> void:
	_ensure_menu_music_player()
	stop_gameplay_music()
	if menu_music_player.stream != MENU_MUSIC_STREAM:
		menu_music_player.stream = MENU_MUSIC_STREAM
	if not menu_music_player.playing:
		menu_music_player.play()

func stop_menu_music() -> void:
	if is_instance_valid(menu_music_player) and menu_music_player.playing:
		menu_music_player.stop()

func play_gameplay_music() -> void:
	_ensure_gameplay_music_player()
	stop_menu_music()
	if gameplay_music_player.stream != GAMEPLAY_MUSIC_STREAM:
		gameplay_music_player.stream = GAMEPLAY_MUSIC_STREAM
	if gameplay_music_player.stream is AudioStreamMP3:
		(gameplay_music_player.stream as AudioStreamMP3).loop = true
	if not gameplay_music_player.playing:
		gameplay_music_player.play()

func stop_gameplay_music() -> void:
	if is_instance_valid(gameplay_music_player) and gameplay_music_player.playing:
		gameplay_music_player.stop()

func reset_progress() -> void:
	score = 0;  quiz_completed = false;  collected_coins = 0
	completed_quiz_keys.clear()
	pending_correct_sfx = false
	selected_level = 1;  player_health = max_health;  killed_enemies.clear()

func start_level(level: int) -> void:
	selected_level = clamp(level, 1, max_level)
	quiz_completed = false;  collected_coins = 0
	completed_quiz_keys.clear()
	pending_correct_sfx = false
	player_health  = max_health;  killed_enemies.clear()

func add_score(amount: int) -> void:
	score += amount

func current_character_name() -> String:
	return ["Aksa", "Nara", "Pixel"][selected_character]

func current_character_color() -> Color:
	return [Color(0.23,0.5,0.96,1), Color(0.58,0.24,0.9,1), Color(0.1,0.78,0.78,1)][selected_character]

func current_question() -> Dictionary:
	return question_banks.get(active_question_key, question_banks["math_l1"])

func set_question_key(key: String) -> void:
	if key in question_banks:
		active_question_key = key

func required_quiz_count(level: int = selected_level) -> int:
	match clamp(level, 1, max_level):
		1:
			return 1
		2, 3:
			return 2
		_:
			return 1

func mark_question_completed(question_key: String) -> void:
	if question_key.is_empty():
		return
	if question_key not in completed_quiz_keys:
		completed_quiz_keys.append(question_key)
	quiz_completed = completed_quiz_keys.size() >= required_quiz_count()

func unlock_character_by_quiz(question_key: String) -> void:
	if question_key in QUIZ_UNLOCK_MAP:
		var idx: int = QUIZ_UNLOCK_MAP[question_key]
		if idx < unlocked_characters.size() and not unlocked_characters[idx]:
			unlocked_characters[idx] = true
			achievements["new_character"] = true

func damage_player(amount: int = 1) -> int:
	player_health = max(player_health - amount, 0)
	return player_health

func heal_full() -> void:
	player_health = max_health

func advance_level() -> bool:
	if selected_level < max_level:
		selected_level += 1
		quiz_completed = false;  collected_coins = 0;  player_health = max_health
		completed_quiz_keys.clear()
		return true
	return false
