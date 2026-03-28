extends Node2D

# ─── Constants ───────────────────────────────────────────────────────────────
const SPEED              := 205.0
const JUMP               := -390.0   # makin minus = makin tinggi
const GRAVITY            := 920.0
const ENEMY_SPEED_GROUND := 78.0
const ENEMY_SPEED_BEE    := 72.0
const MAP_LEFT           := 12.0
const MAP_RIGHT          := 3008.0

const IDLE_TEXTURE    := preload("res://Character/Idle/Idle-Sheet.png")
const RUN_TEXTURE     := preload("res://Character/Run/Run-Sheet.png")
const JUMP_TEXTURE    := preload("res://Character/Jumlp-All/Jump-All-Sheet.png")
const ATTACK_TEXTURE  := preload("res://Character/Attack-01/Attack-01-Sheet.png")
const ATTACK_SOUND_STREAM := preload("res://assets/sounds/07_human_atk_sword_1.wav")
const DROP_BASE_TEXTURE := preload("res://assets/Tiles.png")

const PLAYER_IDLE_POS      := Vector2(0, -24)
const PLAYER_IDLE_SCALE    := Vector2(1.0, 1.0)
const PLAYER_RUN_POS       := Vector2(0, -24)
const PLAYER_RUN_SCALE     := Vector2(0.9, 0.9)
const PLAYER_ATTACK_POS    := Vector2(0, -24)
const PLAYER_ATTACK_SCALE  := Vector2(0.86, 0.86)
const PLAYER_ATTACK_OFFSET_RIGHT := Vector2(28, -10)
const PLAYER_ATTACK_OFFSET_LEFT  := Vector2(-28, -10)

const PLAYER_RUN_FRAMES    := 8
const PLAYER_JUMP_FRAMES   := 15
const PLAYER_ATTACK_FRAMES := 8
const SNAIL_FRAMES         := 8
const BEE_FRAMES           := 4
const MAX_HEALTH           := 3

# ─── Node References ─────────────────────────────────────────────────────────
@onready var player         : CharacterBody2D = $Player
@onready var player_visual  : Sprite2D        = $Player/Visual
@onready var attack_hitbox  : Area2D           = $Player/AttackHitbox
@onready var attack_shape   : CollisionShape2D = $Player/AttackHitbox/CollisionShape2D
@onready var npc            : Area2D           = $NPC
@onready var npc_dialog     : Control          = $NPC/DialogBubble
@onready var npc2           : Area2D           = $NPC2
@onready var npc2_dialog    : Control          = $NPC2/DialogBubble
@onready var gate           : Area2D           = $Gate
@onready var drops_root     : Node2D           = $Drops
@onready var popup          : Label            = $CanvasLayer/PopupLabel
@onready var score_label    : Label            = $CanvasLayer/StatusBar/ScoreCard/VBox/Value
@onready var health_label   : Label            = $CanvasLayer/StatusBar/HealthCard/VBox/Value
@onready var level_label    : Label            = $CanvasLayer/StatusBar/LevelCard/VBox/Value
@onready var popup_timer    : Timer            = $PopupTimer
@onready var animation_timer: Timer            = $AnimationTimer
@onready var attack_timer   : Timer            = $AttackTimer
@onready var game_over_overlay     : Control = $CanvasLayer/GameOverOverlay
@onready var game_over_retry_button: Button  = $CanvasLayer/GameOverOverlay/Center/VBox/Buttons/RetryButton
@onready var game_over_menu_button : Button  = $CanvasLayer/GameOverOverlay/Center/VBox/Buttons/MenuButton
@onready var jump_sound     : AudioStreamPlayer2D = get_node_or_null("JumpSound")
@onready var hit_sound      : AudioStreamPlayer2D = get_node_or_null("HitSound")
@onready var attack_sound   : AudioStreamPlayer2D = get_node_or_null("AttackSound")
@onready var correct_sound   = get_node_or_null("CorrectSound")
@onready var game_over_sound = get_node_or_null("GameOverSound")

# ─── State ───────────────────────────────────────────────────────────────────
var player_anim_tick   := 0
var current_anim_state := "idle"
var facing_right       := true
var is_attacking       := false
var health             := MAX_HEALTH
var enemy_data         : Array[Dictionary] = []
var drop_texture       : AtlasTexture
var is_game_over       := false
var is_finishing       := false
var can_talk_npc       := false
var can_talk_npc2      := false

# Stars untuk animasi kedip
var star_nodes: Array[Polygon2D] = []

# ─── Ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	GameState.play_gameplay_music()
	drop_texture        = AtlasTexture.new()
	drop_texture.atlas  = DROP_BASE_TEXTURE
	drop_texture.region = Rect2(176, 320, 16, 16)
	_ensure_attack_sound()

	_connect_signals()
	_build_world()
	_setup_sky_decorations()
	_polish_ui()
	_spawn_enemies()
	_setup_level()

	player_visual.modulate = GameState.current_character_color()
	player_visual.position = PLAYER_IDLE_POS
	player_visual.scale    = PLAYER_IDLE_SCALE
	player_visual.flip_h   = false
	$NPC/Visual.modulate   = Color(1, 0.78, 0.38, 1)

	health = GameState.player_health
	if GameState.return_scene == "res://scenes/gameplay_level2.tscn":
		player.global_position = GameState.return_position
	_refresh()
	_play_pending_correct_sound()
	if health <= 0:
		_show_game_over()

# ─── Signals ─────────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	$CanvasLayer/MenuButton.pressed.connect(
		func():
			GameState.stop_gameplay_music()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	npc.body_entered.connect(_on_npc_entered)
	npc.body_exited.connect(_on_npc_exited)
	npc2.body_entered.connect(_on_npc2_entered)
	npc2.body_exited.connect(_on_npc2_exited)
	gate.body_entered.connect(_on_gate_entered)
	popup_timer.timeout.connect(func(): popup.visible = false)
	animation_timer.timeout.connect(_on_animation_tick)
	attack_timer.timeout.connect(_end_attack)
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	game_over_retry_button.pressed.connect(_on_game_over_retry)
	game_over_menu_button.pressed.connect(_on_game_over_menu)
	game_over_overlay.visible = false
	npc_dialog.visible        = false
	npc2_dialog.visible       = false
	$NPC/DialogBubble/Panel/Label.text  = "NPC 1: Tekan E untuk soal pertama!"
	$NPC2/DialogBubble/Panel/Label.text = "NPC 2: Tekan E untuk soal berikutnya!"

	for coin in $Coins.get_children():
		coin.body_entered.connect(_on_coin_entered.bind(coin))

# ─── World Building ──────────────────────────────────────────────────────────
func _build_world() -> void:
	_ensure_floor()
	_ensure_obstacles()
	_ensure_extended_area()
	_apply_layout()

func _ensure_floor() -> void:
	if has_node("Environment/Level2Floor"):
		return
	var body := StaticBody2D.new()
	body.name = "Level2Floor"
	body.position = Vector2(1700, 520)
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3350, 76)
	col.shape = rect
	body.add_child(col)
	$Environment.add_child(body)

func _ensure_obstacles() -> void:
	if has_node("Environment/ObstacleA"):
		return
	# Batu dekoratif menggunakan region proporsional dari Props-Rocks.png
	# Scale seragam 2x agar pixel art tetap tajam, posisi Y di atas ground
	_add_obstacle("ObstacleA", Vector2(900,  465), Vector2(48, 50),  Rect2(0,   0,  24, 25), Vector2(2.0, 2.0))
	_add_obstacle("ObstacleB", Vector2(1700, 460), Vector2(56, 56),  Rect2(27,  0,  28, 28), Vector2(2.0, 2.0))
	_add_obstacle("ObstacleC", Vector2(2250, 462), Vector2(44, 52),  Rect2(58,  0,  22, 26), Vector2(2.0, 2.0))
	_add_obstacle("ObstacleD", Vector2(2700, 458), Vector2(52, 60),  Rect2(83,  0,  26, 30), Vector2(2.0, 2.0))

func _add_obstacle(obstacle_name: String, pos: Vector2, size: Vector2, rock_region: Rect2, sc: Vector2 = Vector2(2.0, 2.0)) -> void:
	var body := StaticBody2D.new()
	body.name     = obstacle_name
	body.position = pos
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	# Sprite batu dari Props-Rocks.png dengan scale proporsional
	var atlas := AtlasTexture.new()
	atlas.atlas  = load("res://assets/Props-Rocks.png")
	atlas.region = rock_region
	var visual := Sprite2D.new()
	visual.texture = atlas
	visual.scale   = sc
	body.add_child(col)
	body.add_child(visual)
	$Environment.add_child(body)

func _ensure_extended_area() -> void:
	# Perluas background agar menutupi seluruh map
	if has_node("BackgroundArt"):
		$BackgroundArt.offset_right = 3100.0

	# Ground5
	if not has_node("Environment/Ground5"):
		var g5 := StaticBody2D.new()
		g5.name     = "Ground5"
		g5.position = Vector2(2760, 520)
		var col5  := CollisionShape2D.new()
		var rect5 := RectangleShape2D.new()
		rect5.size = Vector2(460, 196)
		col5.shape = rect5
		var atlas5 := AtlasTexture.new()
		atlas5.atlas  = load("res://assets/Tiles.png")
		atlas5.region = Rect2(0, 0, 80, 80)
		var tile5 := TextureRect.new()
		tile5.texture      = atlas5
		tile5.offset_left  = -230.0
		tile5.offset_top   = -120.0
		tile5.offset_right = 230.0
		tile5.offset_bottom = 78.0
		tile5.stretch_mode = TextureRect.STRETCH_TILE
		g5.add_child(col5)
		g5.add_child(tile5)
		$Environment.add_child(g5)

	# Platform3
	if not has_node("Environment/Platform3"):
		var p3 := StaticBody2D.new()
		p3.name     = "Platform3"
		p3.position = Vector2(2500, 300)
		var col_p3  := CollisionShape2D.new()
		var rect_p3 := RectangleShape2D.new()
		rect_p3.size    = Vector2(138.5, 24)
		col_p3.position = Vector2(8.25, 37)
		col_p3.shape    = rect_p3
		var atlas_p3 := AtlasTexture.new()
		atlas_p3.atlas  = load("res://assets/Tiles.png")
		atlas_p3.region = Rect2(0, 0, 80, 80)
		var tile_p3 := TextureRect.new()
		tile_p3.texture       = atlas_p3
		tile_p3.offset_left   = -68.0
		tile_p3.offset_top    = 7.0
		tile_p3.offset_right  = 85.0
		tile_p3.offset_bottom = 98.0
		tile_p3.stretch_mode  = TextureRect.STRETCH_TILE
		p3.add_child(col_p3)
		p3.add_child(tile_p3)
		$Environment.add_child(p3)

	# Pohon dekorasi ujung kanan
	_add_decor_tree("Tree5", Vector2(2560, 355), Vector2(1.5, 1.5), Rect2(224, 0,  112, 80))
	_add_decor_tree("Tree6", Vector2(2860, 370), Vector2(1.3, 1.4), Rect2(224, 80, 112, 80))

func _add_decor_tree(tree_name: String, pos: Vector2, sc: Vector2, region: Rect2) -> void:
	if has_node("DecorBack/" + tree_name):
		return
	var tree    := Sprite2D.new()
	tree.name   = tree_name
	tree.position = pos
	tree.scale  = sc
	var atlas   := AtlasTexture.new()
	atlas.atlas  = load("res://assets/Tree-Assets.png")
	atlas.region = region
	tree.texture = atlas
	$DecorBack.add_child(tree)

func _apply_layout() -> void:
	if has_node("Player/Camera2D"):
		$Player/Camera2D.limit_right = 3040

	# Ground
	for gd in [["Ground1", Vector2(220, 520)], ["Ground2", Vector2(820, 520)],
			   ["Ground3", Vector2(1460, 520)], ["Ground4", Vector2(2100, 520)],
			   ["Ground5", Vector2(2760, 520)]]:
		if has_node("Environment/" + gd[0]):
			$Environment.get_node(gd[0]).position = gd[1]

	# Platform
	if has_node("Environment/Platform1"): $Environment/Platform1.position = Vector2(520,  360)
	if has_node("Environment/Platform2"): $Environment/Platform2.position = Vector2(1180, 310)
	if has_node("Environment/Platform3"): $Environment/Platform3.position = Vector2(2500, 300)

	# NPC & Gate — NPC1 tengah Ground3, NPC2 di dalam Ground5 (hindari gap)
	$NPC.position  = Vector2(1350, 424)
	$NPC2.position = Vector2(2650, 424)
	$Gate.position = Vector2(2960, 410)

	# Koin
	for cd in [["Coin1", Vector2(300, 390)], ["Coin2", Vector2(560, 325)],
			   ["Coin3", Vector2(980, 390)], ["Coin4", Vector2(1340, 270)],
			   ["Coin5", Vector2(2240, 390)], ["Coin6", Vector2(2620, 280)]]:
		if has_node("Coins/" + cd[0]):
			$Coins.get_node(cd[0]).position = cd[1]

	# Musuh — posisi awal di tengah ground masing-masing
	if has_node("Enemies/Snail1"): $Enemies/Snail1.position = Vector2(770,  448)
	if has_node("Enemies/Snail2"): $Enemies/Snail2.position = Vector2(1540, 448)
	if has_node("Enemies/Snail3"): $Enemies/Snail3.position = Vector2(2180, 448)
	if has_node("Enemies/Bee1"):   $Enemies/Bee1.position   = Vector2(1080, 220)
	if has_node("Enemies/Bee2"):   $Enemies/Bee2.position   = Vector2(1840, 190)
	if has_node("Enemies/Bee3"):   $Enemies/Bee3.position   = Vector2(2660, 170)

func _spawn_enemies() -> void:
	# Patrol range keong dibatasi agar tetap di atas ground platform
	# Ground2: ~533-1004, Ground3: ~1305-1776, Ground4: ~1940-2430
	var enemy_configs := [
		["Snail1", "snail", 560.0,   980.0, 448.0],  # di Ground2
		["Snail2", "snail", 1330.0, 1750.0, 448.0],  # di Ground3
		["Snail3", "snail", 1960.0, 2400.0, 448.0],  # di Ground4
		["Bee1",   "bee",   820.0,  1410.0, 220.0],
		["Bee2",   "bee",   1500.0, 2240.0, 190.0],
		["Bee3",   "bee",   2350.0, 2940.0, 170.0],
	]
	for cfg in enemy_configs:
		var node_path := "Enemies/" + str(cfg[0])
		if not has_node(node_path):
			continue
		var enemy_node: Area2D = get_node(node_path)
		# Sembunyikan dan skip jika sudah pernah dibunuh
		if str(cfg[0]) in GameState.killed_enemies:
			enemy_node.hide()
			enemy_node.set_deferred("monitoring",  false)
			enemy_node.set_deferred("monitorable", false)
			continue
		_register_enemy(enemy_node, str(cfg[1]), float(cfg[2]), float(cfg[3]), float(cfg[4]))

func _setup_level() -> void:
	GameState.selected_level = 2
	GameState.quiz_completed = false if GameState.collected_coins == 0 and not GameState.quiz_completed else GameState.quiz_completed
	for coin in $Coins.get_children():
		coin.visible = true
		coin.set_deferred("monitoring",  true)
		coin.set_deferred("monitorable", true)

# ─── Sky Decorations ─────────────────────────────────────────────────────────
func _setup_sky_decorations() -> void:
	# Bulan (crescent effect: lingkaran penuh - shadow disk)
	var moon_root := Node2D.new()
	moon_root.name    = "MoonRoot"
	moon_root.z_index = -4
	moon_root.position = Vector2(2700, 90)
	add_child(moon_root)

	var moon := _make_circle_polygon(32, Color(0.98, 0.94, 0.76, 1.0))
	moon_root.add_child(moon)

	var moon_shadow := _make_circle_polygon(28, Color(0.05, 0.09, 0.20, 1.0))
	moon_shadow.position = Vector2(10, -6)
	moon_root.add_child(moon_shadow)

	# Ambience cahaya bulan (bintang besar di sekitar bulan)
	var glow := Polygon2D.new()
	glow.color = Color(0.98, 0.94, 0.76, 0.08)
	glow.polygon = _make_circle_points(60)
	moon_root.add_child(glow)

	# Bintang-bintang acak
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # seed tetap agar bintang konsisten
	var star_root := Node2D.new()
	star_root.name    = "StarRoot"
	star_root.z_index = -4
	add_child(star_root)

	for i in 80:
		var px := rng.randf_range(0.0, 3100.0)
		var py := rng.randf_range(10.0, 260.0)
		var r  := rng.randf_range(1.2, 3.0)
		var br := rng.randf_range(0.55, 1.0)

		var star := Polygon2D.new()
		star.position = Vector2(px, py)
		star.color    = Color(br, br, br * 0.92, 1.0)
		star.polygon  = _make_circle_points(r, 6)
		star_root.add_child(star)
		star_nodes.append(star)

func _make_circle_polygon(radius: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.color   = color
	p.polygon = _make_circle_points(radius)
	return p

func _make_circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var angle := TAU * i / segments
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

# Kedipan bintang via _process
func _process(_delta: float) -> void:
	if is_game_over or star_nodes.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	for i in star_nodes.size():
		var alpha := 0.6 + 0.4 * sin(t * 1.2 + i * 0.73)
		var star  := star_nodes[i]
		star.color = Color(star.color.r, star.color.g, star.color.b, alpha)

# ─── UI Polish ───────────────────────────────────────────────────────────────
func _polish_ui() -> void:
	# Kartu status: warna panel gelap bertema malam
	for card_path in ["ScoreCard", "HealthCard", "LevelCard"]:
		var card: Panel = $CanvasLayer/StatusBar.get_node(card_path)
		var style := StyleBoxFlat.new()
		style.bg_color          = Color(0.05, 0.08, 0.18, 0.88)
		style.border_color      = Color(0.38, 0.55, 0.90, 0.80)
		style.set_border_width_all(2)
		style.corner_radius_top_left     = 8
		style.corner_radius_top_right    = 8
		style.corner_radius_bottom_left  = 8
		style.corner_radius_bottom_right = 8
		style.set_content_margin_all(6)
		card.add_theme_stylebox_override("panel", style)
		# Label judul
		var title: Label = card.get_node("VBox/Title")
		title.add_theme_color_override("font_color", Color(0.60, 0.78, 1.00, 1))
		title.add_theme_font_size_override("font_size", 13)
		# Label nilai
		var value: Label = card.get_node("VBox/Value")
		value.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
		value.add_theme_font_size_override("font_size", 26)

	# Popup label bergaya
	var pop_style := StyleBoxFlat.new()
	pop_style.bg_color     = Color(0.05, 0.08, 0.18, 0.80)
	pop_style.border_color = Color(0.38, 0.55, 0.90, 0.60)
	pop_style.set_border_width_all(1)
	pop_style.corner_radius_top_left     = 6
	pop_style.corner_radius_top_right    = 6
	pop_style.corner_radius_bottom_left  = 6
	pop_style.corner_radius_bottom_right = 6
	pop_style.set_content_margin_all(4)
	popup.add_theme_stylebox_override("normal", pop_style)
	popup.add_theme_color_override("font_color", Color(1, 1, 0.6, 1))
	popup.add_theme_font_size_override("font_size", 22)
	popup.add_theme_constant_override("outline_size", 3)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

	# Tombol menu
	var menu_btn: Button = $CanvasLayer/MenuButton
	var mb_style := StyleBoxFlat.new()
	mb_style.bg_color     = Color(0.05, 0.08, 0.18, 0.88)
	mb_style.border_color = Color(0.38, 0.55, 0.90, 0.80)
	mb_style.set_border_width_all(2)
	mb_style.corner_radius_top_left     = 6
	mb_style.corner_radius_top_right    = 6
	mb_style.corner_radius_bottom_left  = 6
	mb_style.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", mb_style)
	menu_btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1, 1))

# ─── Enemy Registration ───────────────────────────────────────────────────────
func _register_enemy(enemy: Area2D, enemy_type: String, left: float, right: float, base_y: float) -> void:
	enemy.body_entered.connect(_on_enemy_entered.bind(enemy))
	enemy_data.append({
		"node":      enemy,
		"type":      enemy_type,
		"left":      left,
		"right":     right,
		"base_y":    base_y,
		"dir":       -1.0 if enemy_type == "snail" else 1.0,
		"phase":     randf() * TAU,
		"vel_y":     0.0,
		"anim_tick": 0,
	})
	var visual: Sprite2D = enemy.get_node("Visual")
	visual.flip_h = enemy_type == "bee"
	visual.hframes = SNAIL_FRAMES if enemy_type == "snail" else BEE_FRAMES
	visual.frame   = 0

# ─── Physics ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	# Gravitasi player
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta

	# Lompat
	if (Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("ui_up")
			or Input.is_key_pressed(KEY_W)) and player.is_on_floor():
		player.velocity.y = JUMP
		_play_jump_sound()

	# Serangan
	if Input.is_key_pressed(KEY_J) and not is_attacking:
		_start_attack()

	# Gerak horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		direction = float(int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)))
	player.velocity.x = direction * SPEED
	player.move_and_slide()
	player.global_position.x = clamp(player.global_position.x, MAP_LEFT, MAP_RIGHT)

	# Interaksi NPC — masing-masing NPC bisa membuka quiz-nya saat ditekan E
	if can_talk_npc and Input.is_key_pressed(KEY_E):
		_start_quiz("sains_sd_1")
		return
	if can_talk_npc2 and Input.is_key_pressed(KEY_E):
		_start_quiz("sains_smp_1")
		return

	# Jatuh ke jurang
	if player.global_position.y > 620:
		_play_hit_sound()
		_damage_player()

	_update_enemies(delta)
	_update_player_visual(direction)
	_update_drops(delta)

func _start_quiz(question_key: String) -> void:
	can_talk_npc        = false
	can_talk_npc2       = false
	npc_dialog.visible  = false
	npc2_dialog.visible = false
	GameState.set_question_key(question_key)
	GameState.return_scene    = "res://scenes/gameplay_level2.tscn"
	GameState.return_position = player.global_position
	get_tree().change_scene_to_file("res://scenes/quiz_screen.tscn")

# ─── Enemy Update ─────────────────────────────────────────────────────────────
func _update_enemies(delta: float) -> void:
	var still_alive: Array[Dictionary] = []
	for entry in enemy_data:
		if not is_instance_valid(entry["node"]):
			continue
		still_alive.append(entry)
		var enemy      : Area2D   = entry["node"]
		var enemy_type : String   = entry["type"]
		var visual     : Sprite2D = enemy.get_node("Visual")

		if enemy_type == "snail":
			enemy.position.x += ENEMY_SPEED_GROUND * float(entry["dir"]) * delta
			# Simulasi gravitasi agar snail tidak melayang
			var vy: float = float(entry["vel_y"]) + GRAVITY * delta
			enemy.position.y = minf(enemy.position.y + vy * delta, float(entry["base_y"]))
			entry["vel_y"] = 0.0 if enemy.position.y >= float(entry["base_y"]) else vy
			# Balik arah
			if   enemy.position.x <= float(entry["left"]):
				entry["dir"] = 1.0;  visual.flip_h = true
			elif enemy.position.x >= float(entry["right"]):
				entry["dir"] = -1.0; visual.flip_h = false
		else: # bee
			enemy.position.x += ENEMY_SPEED_BEE * float(entry["dir"]) * delta
			enemy.position.y  = float(entry["base_y"]) + sin(Time.get_ticks_msec() / 250.0 + float(entry["phase"])) * 18.0
			if   enemy.position.x <= float(entry["left"]):
				entry["dir"] = 1.0;  visual.flip_h = true
			elif enemy.position.x >= float(entry["right"]):
				entry["dir"] = -1.0; visual.flip_h = false

		# Animasi per-enemy dengan tick sendiri
		entry["anim_tick"] = int(entry["anim_tick"]) + 1
		visual.frame = int(entry["anim_tick"]) % (SNAIL_FRAMES if enemy_type == "snail" else BEE_FRAMES)

	enemy_data = still_alive

# ─── Drops ───────────────────────────────────────────────────────────────────
func _update_drops(delta: float) -> void:
	for drop in drops_root.get_children():
		if is_instance_valid(drop):
			drop.position.y += 12.0 * delta

func _play_jump_sound() -> void:
	if not jump_sound:
		return
	# Keep source near player so 2D attenuation does not reduce volume while traversing the map.
	jump_sound.global_position = player.global_position
	if jump_sound.playing:
		jump_sound.stop()
	jump_sound.play()

func _ensure_attack_sound() -> void:
	if not attack_sound:
		attack_sound = AudioStreamPlayer2D.new()
		attack_sound.name = "AttackSound"
		add_child(attack_sound)
	if attack_sound.stream == null:
		attack_sound.stream = ATTACK_SOUND_STREAM

func _play_attack_sound() -> void:
	if not attack_sound:
		return
	attack_sound.global_position = player.global_position
	if attack_sound.playing:
		attack_sound.stop()
	attack_sound.play()

func _play_hit_sound() -> void:
	if not hit_sound:
		return
	hit_sound.global_position = player.global_position
	if hit_sound.playing:
		hit_sound.stop()
	hit_sound.play()

func _play_pending_correct_sound() -> void:
	if not GameState.pending_correct_sfx:
		return
	GameState.pending_correct_sfx = false
	if not correct_sound:
		return
	if correct_sound is AudioStreamPlayer2D:
		correct_sound.global_position = player.global_position
	if correct_sound.has_method("stop"):
		correct_sound.call("stop")
	if correct_sound.has_method("play"):
		correct_sound.call("play")

func _play_game_over_sound() -> void:
	if not game_over_sound:
		return
	if game_over_sound.has_method("stop"):
		game_over_sound.call("stop")
	if game_over_sound.has_method("play"):
		game_over_sound.call("play")

func _spawn_drop(pos: Vector2) -> void:
	var drop   := Area2D.new()
	drop.position = pos + Vector2(0, -18)
	var shape  := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	var sprite := Sprite2D.new()
	sprite.texture = drop_texture
	sprite.scale   = Vector2(2, 2)
	drop.add_child(shape)
	drop.add_child(sprite)
	drops_root.add_child(drop)
	drop.body_entered.connect(_on_drop_collected.bind(drop))

# ─── Attack ───────────────────────────────────────────────────────────────────
func _start_attack() -> void:
	is_attacking             = true
	current_anim_state       = "attack"
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	attack_shape.disabled    = false
	attack_hitbox.position   = PLAYER_ATTACK_OFFSET_RIGHT if facing_right else PLAYER_ATTACK_OFFSET_LEFT
	player_visual.texture    = ATTACK_TEXTURE
	player_visual.hframes    = PLAYER_ATTACK_FRAMES
	player_visual.frame      = 0
	player_visual.position   = PLAYER_ATTACK_POS
	player_visual.scale      = PLAYER_ATTACK_SCALE
	_play_attack_sound()
	_show_popup("Serang!")
	attack_timer.start()

func _end_attack() -> void:
	is_attacking              = false
	current_anim_state        = "idle"
	attack_hitbox.monitoring  = false
	attack_hitbox.monitorable = false
	attack_shape.disabled     = true
	player_visual.texture     = IDLE_TEXTURE
	player_visual.hframes     = 4
	player_visual.frame       = 0
	player_visual.position    = PLAYER_IDLE_POS
	player_visual.scale       = PLAYER_IDLE_SCALE

# ─── Collision Callbacks ──────────────────────────────────────────────────────
func _on_drop_collected(body: Node2D, drop: Area2D) -> void:
	if body != player:
		return
	GameState.add_score(7)
	_show_popup("Drop +7")
	if is_instance_valid(drop):
		drop.queue_free()
	_refresh()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies") or not is_instance_valid(area):
		return
	# Catat nama enemy agar tidak respawn setelah kembali dari quiz
	if area.name not in GameState.killed_enemies:
		GameState.killed_enemies.append(area.name)
	GameState.add_score(10)
	_show_popup("Musuh kalah! +10")
	call_deferred("_spawn_drop", area.global_position)
	area.queue_free()
	_refresh()

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player or not coin.visible:
		return
	coin.visible = false
	coin.set_deferred("monitoring",  false)
	coin.set_deferred("monitorable", false)
	GameState.collected_coins += 1
	GameState.add_score(5)
	if GameState.collected_coins >= 6:
		GameState.achievements["all_coins"] = true
	_show_popup("+5 Coin")
	_refresh()

func _on_npc_entered(body: Node2D) -> void:
	if body != player: return
	can_talk_npc       = true
	npc_dialog.visible = true

func _on_npc_exited(body: Node2D) -> void:
	if body != player: return
	can_talk_npc       = false
	npc_dialog.visible = false

func _on_npc2_entered(body: Node2D) -> void:
	if body != player: return
	can_talk_npc2       = true
	npc2_dialog.visible = true

func _on_npc2_exited(body: Node2D) -> void:
	if body != player: return
	can_talk_npc2       = false
	npc2_dialog.visible = false

func _on_gate_entered(body: Node2D) -> void:
	if body != player: return
	if is_finishing: return
	if not GameState.quiz_completed:
		_show_popup("Selesaikan soal dulu!")
		return
	is_finishing = true
	GameState.stop_gameplay_music()
	get_tree().change_scene_to_file("res://scenes/result_screen.tscn")

func _on_enemy_entered(body: Node2D, _enemy: Area2D) -> void:
	if body != player: return
	_play_hit_sound()
	_damage_player()

# ─── Player ───────────────────────────────────────────────────────────────────
func _damage_player() -> void:
	if is_game_over:
		return
	health = GameState.damage_player(1)
	GameState.add_score(-3)
	if health <= 0:
		health = 0
		_refresh()
		_show_game_over()
		return
	_show_popup("Kena musuh! -3")
	_reset_player()
	_refresh()

func _reset_player() -> void:
	player.global_position = Vector2(120, 420)
	player.velocity        = Vector2.ZERO

func _show_game_over() -> void:
	is_game_over = true
	_play_game_over_sound()
	player.velocity = Vector2.ZERO
	# set_deferred wajib untuk monitoring saat dalam signal fisika
	attack_hitbox.set_deferred("monitoring",  false)
	attack_hitbox.set_deferred("monitorable", false)
	attack_shape.set_deferred("disabled", true)
	is_attacking        = false
	popup.visible       = false
	npc_dialog.visible  = false
	npc2_dialog.visible = false
	animation_timer.stop()
	attack_timer.stop()
	game_over_overlay.visible = true

func _on_game_over_retry() -> void:
	GameState.start_level(GameState.selected_level)
	get_tree().reload_current_scene()

func _on_game_over_menu() -> void:
	GameState.stop_gameplay_music()
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ─── Visual Updates ───────────────────────────────────────────────────────────
func _show_popup(text: String) -> void:
	popup.text    = text
	popup.visible = true
	popup_timer.start()

func _refresh() -> void:
	score_label.text  = "%d" % GameState.score
	level_label.text  = "%d" % GameState.selected_level
	health_label.text = "❤️".repeat(max(health, 0))

func _update_player_visual(direction: float) -> void:
	if direction < 0:
		facing_right       = false
		player_visual.flip_h = true
	elif direction > 0:
		facing_right       = true
		player_visual.flip_h = false

	attack_hitbox.position = PLAYER_ATTACK_OFFSET_RIGHT if facing_right else PLAYER_ATTACK_OFFSET_LEFT

	if is_attacking:
		return

	var target := "idle"
	if not player.is_on_floor():
		target = "jump"
	elif abs(player.velocity.x) > 5.0:
		target = "run"

	if current_anim_state == target:
		return
	current_anim_state = target
	match target:
		"jump":
			player_visual.texture  = JUMP_TEXTURE
			player_visual.hframes  = PLAYER_JUMP_FRAMES
			player_visual.position = PLAYER_IDLE_POS
			player_visual.scale    = PLAYER_IDLE_SCALE
		"run":
			player_visual.texture  = RUN_TEXTURE
			player_visual.hframes  = PLAYER_RUN_FRAMES
			player_visual.position = PLAYER_RUN_POS
			player_visual.scale    = PLAYER_RUN_SCALE
		_:
			player_visual.texture  = IDLE_TEXTURE
			player_visual.hframes  = 4
			player_visual.position = PLAYER_IDLE_POS
			player_visual.scale    = PLAYER_IDLE_SCALE
	player_visual.frame = 0

func _on_animation_tick() -> void:
	player_anim_tick += 1
	match current_anim_state:
		"attack": player_visual.frame = player_anim_tick % PLAYER_ATTACK_FRAMES
		"jump":   player_visual.frame = player_anim_tick % PLAYER_JUMP_FRAMES
		"run":    player_visual.frame = player_anim_tick % PLAYER_RUN_FRAMES
		_:        player_visual.frame = player_anim_tick % 4
