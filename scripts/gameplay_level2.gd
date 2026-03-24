extends Node2D

const SPEED := 205.0
# Ubah angka ini untuk mengatur tinggi lompatan (makin minus = makin tinggi)
const JUMP := -390.0
const GRAVITY := 920.0
const ENEMY_SPEED_GROUND := 78.0
const ENEMY_SPEED_BEE := 72.0
const MAP_LEFT := 12.0
const MAP_RIGHT := 3008.0

const IDLE_TEXTURE := preload("res://Character/Idle/Idle-Sheet.png")
const RUN_TEXTURE := preload("res://Character/Run/Run-Sheet.png")
const JUMP_TEXTURE := preload("res://Character/Jumlp-All/Jump-All-Sheet.png")
const ATTACK_TEXTURE := preload("res://Character/Attack-01/Attack-01-Sheet.png")
const DROP_BASE_TEXTURE := preload("res://assets/Tiles.png")

@onready var player: CharacterBody2D = $Player
@onready var player_visual: Sprite2D = $Player/Visual
@onready var attack_hitbox: Area2D = $Player/AttackHitbox
@onready var attack_shape: CollisionShape2D = $Player/AttackHitbox/CollisionShape2D
@onready var npc: Area2D = $NPC
@onready var npc_dialog: Control = $NPC/DialogBubble
@onready var npc_dialog_label: Label = $NPC/DialogBubble/Panel/Label
@onready var npc2: Area2D = $NPC2
@onready var npc2_dialog: Control = $NPC2/DialogBubble
@onready var npc2_dialog_label: Label = $NPC2/DialogBubble/Panel/Label
@onready var gate: Area2D = $Gate
@onready var enemies_root: Node2D = $Enemies
@onready var drops_root: Node2D = $Drops
@onready var popup: Label = $CanvasLayer/PopupLabel
@onready var score_label: Label = $CanvasLayer/StatusBar/ScoreCard/VBox/Value
@onready var health_label: Label = $CanvasLayer/StatusBar/HealthCard/VBox/Value
@onready var level_label: Label = $CanvasLayer/StatusBar/LevelCard/VBox/Value
@onready var popup_timer: Timer = $PopupTimer
@onready var animation_timer: Timer = $AnimationTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var game_over_overlay: Control = $CanvasLayer/GameOverOverlay
@onready var game_over_retry_button: Button = $CanvasLayer/GameOverOverlay/Center/VBox/Buttons/RetryButton
@onready var game_over_menu_button: Button = $CanvasLayer/GameOverOverlay/Center/VBox/Buttons/MenuButton

const PLAYER_IDLE_POS := Vector2(0, -24)
const PLAYER_IDLE_SCALE := Vector2(1.0, 1.0)
const PLAYER_RUN_POS := Vector2(0, -24)
const PLAYER_RUN_SCALE := Vector2(0.9, 0.9)
const PLAYER_ATTACK_POS := Vector2(0, -24)
const PLAYER_ATTACK_SCALE := Vector2(0.86, 0.86)
const PLAYER_RUN_FRAMES := 8
const PLAYER_JUMP_FRAMES := 15
const PLAYER_ATTACK_FRAMES := 8
const PLAYER_ATTACK_OFFSET_RIGHT := Vector2(28, -10)
const PLAYER_ATTACK_OFFSET_LEFT := Vector2(-28, -10)
const SNAIL_FRAMES := 8
const BEE_FRAMES := 4
const MAX_HEALTH := 3

var player_anim_tick := 0
var enemy_anim_tick := 0
var current_anim_state := "idle"
var facing_right := true
var is_attacking := false
var health := MAX_HEALTH
var enemy_data: Array[Dictionary] = []
var drop_texture: AtlasTexture
var is_game_over := false
var can_talk_npc := false
var can_talk_npc2 := false
var npc_dir := 1.0
var npc2_dir := -1.0

func _ready() -> void:
	drop_texture = AtlasTexture.new()
	drop_texture.atlas = DROP_BASE_TEXTURE
	drop_texture.region = Rect2(176, 320, 16, 16)

	$CanvasLayer/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
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
	npc_dialog.visible = false
	npc2_dialog.visible = false
	npc_dialog_label.text = "NPC 1: Tekan E untuk soal pertama!"
	npc2_dialog_label.text = "NPC 2: Tekan E untuk soal berikutnya!"
	_ensure_level2_floor()
	_ensure_level2_obstacles()
	_apply_level2_layout()

	for coin in $Coins.get_children():
		coin.body_entered.connect(_on_coin_entered.bind(coin))

	if has_node("Enemies/Snail1"): _register_enemy($Enemies/Snail1, "snail", 520.0, 1000.0, 448.0)
	if has_node("Enemies/Snail2"): _register_enemy($Enemies/Snail2, "snail", 1180.0, 1780.0, 448.0)
	if has_node("Enemies/Snail3"): _register_enemy($Enemies/Snail3, "snail", 2100.0, 2800.0, 448.0)
	if has_node("Enemies/Bee1"): _register_enemy($Enemies/Bee1, "bee", 820.0, 1410.0, 220.0)
	if has_node("Enemies/Bee2"): _register_enemy($Enemies/Bee2, "bee", 1500.0, 2240.0, 190.0)
	if has_node("Enemies/Bee3"): _register_enemy($Enemies/Bee3, "bee", 2350.0, 2940.0, 170.0)

	player_visual.modulate = GameState.current_character_color()
	player_visual.position = PLAYER_IDLE_POS
	player_visual.scale = PLAYER_IDLE_SCALE
	player_visual.flip_h = false
	$NPC/Visual.modulate = Color(1, 0.78, 0.38, 1)
	health = GameState.player_health
	_setup_level()
	if GameState.return_scene == "res://scenes/gameplay_level2.tscn":
		player.global_position = GameState.return_position
	_refresh()
	if health <= 0:
		_show_game_over()

func _setup_level() -> void:
	GameState.selected_level = 2
	GameState.quiz_completed = false if GameState.collected_coins == 0 and not GameState.quiz_completed else GameState.quiz_completed

	for coin in $Coins.get_children():
		coin.visible = true
		coin.set_deferred("monitoring", true)
		coin.set_deferred("monitorable", true)

func _ensure_level2_floor() -> void:
	if has_node("Environment/Level2Floor"):
		return
	var floor := StaticBody2D.new()
	floor.name = "Level2Floor"
	floor.position = Vector2(1700, 520)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3350, 76)
	col.shape = rect
	floor.add_child(col)
	$Environment.add_child(floor)

func _ensure_level2_obstacles() -> void:
	if has_node("Environment/ObstacleA"):
		return
	_add_obstacle("ObstacleA", Vector2(940, 484), Vector2(64, 72), Color(0.5, 0.22, 0.2, 1))
	_add_obstacle("ObstacleB", Vector2(1740, 484), Vector2(84, 84), Color(0.42, 0.2, 0.18, 1))
	_add_obstacle("ObstacleC", Vector2(2280, 484), Vector2(72, 96), Color(0.58, 0.24, 0.18, 1))
	_add_obstacle("ObstacleD", Vector2(2680, 484), Vector2(92, 110), Color(0.42, 0.16, 0.16, 1))

func _add_obstacle(name: String, pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.position = pos
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array(
		-size.x * 0.5, -size.y * 0.5,
		size.x * 0.5, -size.y * 0.5,
		size.x * 0.5, size.y * 0.5,
		-size.x * 0.5, size.y * 0.5
	)
	body.add_child(col)
	body.add_child(visual)
	$Environment.add_child(body)

func _apply_level2_layout() -> void:
	if has_node("Player/Camera2D"):
		$Player/Camera2D.limit_right = 3040

	if has_node("Environment/Ground1"): $Environment/Ground1.position = Vector2(220, 520)
	if has_node("Environment/Ground2"): $Environment/Ground2.position = Vector2(820, 520)
	if has_node("Environment/Ground3"): $Environment/Ground3.position = Vector2(1460, 520)
	if has_node("Environment/Ground4"): $Environment/Ground4.position = Vector2(2100, 520)
	if has_node("Environment/Ground5"): $Environment/Ground5.position = Vector2(2760, 520)

	if has_node("Environment/Platform1"): $Environment/Platform1.position = Vector2(520, 360)
	if has_node("Environment/Platform2"): $Environment/Platform2.position = Vector2(1180, 310)
	if has_node("Environment/Platform3"): $Environment/Platform3.position = Vector2(2500, 300)

	$NPC.position = Vector2(1240, 424)
	$NPC2.position = Vector2(2420, 424)
	$Gate.position = Vector2(2960, 410)

	if has_node("Coins/Coin1"): $Coins/Coin1.position = Vector2(300, 390)
	if has_node("Coins/Coin2"): $Coins/Coin2.position = Vector2(560, 325)
	if has_node("Coins/Coin3"): $Coins/Coin3.position = Vector2(980, 390)
	if has_node("Coins/Coin4"): $Coins/Coin4.position = Vector2(1340, 270)
	if has_node("Coins/Coin5"): $Coins/Coin5.position = Vector2(2240, 390)
	if has_node("Coins/Coin6"): $Coins/Coin6.position = Vector2(2620, 280)

	if has_node("Enemies/Snail1"): $Enemies/Snail1.position = Vector2(700, 384)
	if has_node("Enemies/Snail2"): $Enemies/Snail2.position = Vector2(1580, 384)
	if has_node("Enemies/Snail3"): $Enemies/Snail3.position = Vector2(2460, 384)
	if has_node("Enemies/Bee1"): $Enemies/Bee1.position = Vector2(1080, 220)
	if has_node("Enemies/Bee2"): $Enemies/Bee2.position = Vector2(1840, 190)
	if has_node("Enemies/Bee3"): $Enemies/Bee3.position = Vector2(2660, 170)

func _register_enemy(enemy: Area2D, enemy_type: String, left: float, right: float, base_y: float) -> void:
	enemy.body_entered.connect(_on_enemy_entered.bind(enemy))
	enemy_data.append({
		"node": enemy,
		"type": enemy_type,
		"left": left,
		"right": right,
		"base_y": base_y,
		"dir": -1.0 if enemy_type == "snail" else 1.0,
		"phase": randf() * TAU,
	})
	var visual: Sprite2D = enemy.get_node("Visual")
	visual.flip_h = enemy_type == "bee"

func _physics_process(delta: float) -> void:
	if is_game_over:
		return
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta

	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W)) and player.is_on_floor():
		player.velocity.y = JUMP

	if Input.is_key_pressed(KEY_J) and not is_attacking:
		_start_attack()

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		direction = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	player.velocity.x = direction * SPEED
	player.move_and_slide()
	player.global_position.x = clamp(player.global_position.x, MAP_LEFT, MAP_RIGHT)
	if can_talk_npc and Input.is_key_pressed(KEY_E):
		can_talk_npc = false
		npc_dialog.visible = false
		GameState.return_scene = "res://scenes/gameplay_level2.tscn"
		GameState.return_position = player.global_position
		get_tree().change_scene_to_file("res://scenes/quiz_screen.tscn")
		return
	if can_talk_npc2 and Input.is_key_pressed(KEY_E):
		can_talk_npc2 = false
		npc2_dialog.visible = false
		GameState.return_scene = "res://scenes/gameplay_level2.tscn"
		GameState.return_position = player.global_position
		get_tree().change_scene_to_file("res://scenes/quiz_screen.tscn")
		return
	if player.global_position.y > 620:
		_damage_player()

	_update_npcs(delta)
	_update_enemies(delta)
	_update_player_visual(direction)
	_update_drops(delta)

func _update_npcs(delta: float) -> void:
	$NPC.position.x += 52.0 * npc_dir * delta
	if $NPC.position.x < 1120.0:
		npc_dir = 1.0
		$NPC/Visual.flip_h = false
	elif $NPC.position.x > 1420.0:
		npc_dir = -1.0
		$NPC/Visual.flip_h = true

	$NPC2.position.x += 68.0 * npc2_dir * delta
	if $NPC2.position.x < 2200.0:
		npc2_dir = 1.0
		$NPC2/Visual.flip_h = false
	elif $NPC2.position.x > 2620.0:
		npc2_dir = -1.0
		$NPC2/Visual.flip_h = true

func _update_enemies(delta: float) -> void:
	var still_alive: Array[Dictionary] = []
	for enemy_entry in enemy_data:
		if not is_instance_valid(enemy_entry["node"]):
			continue
		still_alive.append(enemy_entry)
		var enemy: Area2D = enemy_entry["node"]
		var enemy_type: String = enemy_entry["type"]
		var visual: Sprite2D = enemy.get_node("Visual")
		if enemy_type == "snail":
			enemy.position.x += ENEMY_SPEED_GROUND * float(enemy_entry["dir"]) * delta
			if enemy.position.x <= float(enemy_entry["left"]):
				enemy_entry["dir"] = 1.0
				visual.flip_h = true
			elif enemy.position.x >= float(enemy_entry["right"]):
				enemy_entry["dir"] = -1.0
				visual.flip_h = false
		else:
			enemy.position.x += ENEMY_SPEED_BEE * float(enemy_entry["dir"]) * delta
			enemy.position.y = float(enemy_entry["base_y"]) + sin(Time.get_ticks_msec() / 250.0 + float(enemy_entry["phase"])) * 18.0
			if enemy.position.x <= float(enemy_entry["left"]):
				enemy_entry["dir"] = 1.0
				visual.flip_h = true
			elif enemy.position.x >= float(enemy_entry["right"]):
				enemy_entry["dir"] = -1.0
				visual.flip_h = false
	enemy_data = still_alive

func _update_drops(delta: float) -> void:
	for drop in drops_root.get_children():
		if not is_instance_valid(drop):
			continue
		drop.position.y += 12.0 * delta

func _start_attack() -> void:
	is_attacking = true
	current_anim_state = "attack"
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	attack_shape.disabled = false
	attack_hitbox.position = PLAYER_ATTACK_OFFSET_RIGHT if facing_right else PLAYER_ATTACK_OFFSET_LEFT
	player_visual.texture = ATTACK_TEXTURE
	player_visual.hframes = PLAYER_ATTACK_FRAMES
	player_visual.frame = 0
	player_visual.position = PLAYER_ATTACK_POS
	player_visual.scale = PLAYER_ATTACK_SCALE
	_show_popup("Serang!")
	attack_timer.start()

func _end_attack() -> void:
	is_attacking = false
	current_anim_state = "idle"
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true
	player_visual.texture = IDLE_TEXTURE
	player_visual.hframes = 4
	player_visual.frame = 0
	player_visual.position = PLAYER_IDLE_POS
	player_visual.scale = PLAYER_IDLE_SCALE

func _spawn_drop(pos: Vector2) -> void:
	var drop := Area2D.new()
	drop.position = pos + Vector2(0, -18)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	var sprite := Sprite2D.new()
	sprite.texture = drop_texture
	sprite.scale = Vector2(2, 2)
	drop.add_child(shape)
	drop.add_child(sprite)
	drops_root.add_child(drop)
	drop.body_entered.connect(_on_drop_collected.bind(drop))

func _on_drop_collected(body: Node2D, drop: Area2D) -> void:
	if body != player:
		return
	GameState.add_score(7)
	_show_popup("Drop +7")
	if is_instance_valid(drop):
		drop.queue_free()
	_refresh()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return
	if not is_instance_valid(area):
		return
	GameState.add_score(10)
	_show_popup("Musuh kalah! +10")
	call_deferred("_spawn_drop", area.global_position)
	area.queue_free()
	_refresh()

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player or not coin.visible:
		return
	coin.visible = false
	coin.set_deferred("monitoring", false)
	coin.set_deferred("monitorable", false)
	GameState.collected_coins += 1
	GameState.add_score(5)
	if GameState.collected_coins >= 6:
		GameState.achievements["all_coins"] = true
	_show_popup("+5 Coin")
	_refresh()

func _on_npc_entered(body: Node2D) -> void:
	if body != player:
		return
	can_talk_npc = true
	npc_dialog.visible = true

func _on_npc_exited(body: Node2D) -> void:
	if body != player:
		return
	can_talk_npc = false
	npc_dialog.visible = false

func _on_npc2_entered(body: Node2D) -> void:
	if body != player:
		return
	can_talk_npc2 = true
	npc2_dialog.visible = true

func _on_npc2_exited(body: Node2D) -> void:
	if body != player:
		return
	can_talk_npc2 = false
	npc2_dialog.visible = false

func _on_gate_entered(body: Node2D) -> void:
	if body != player:
		return
	if not GameState.quiz_completed:
		_show_popup("Selesaikan soal dulu!")
		return
	get_tree().change_scene_to_file("res://scenes/result_screen.tscn")

func _on_enemy_entered(body: Node2D, enemy: Area2D) -> void:
	if body != player:
		return
	_damage_player()

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

func _show_game_over() -> void:
	is_game_over = true
	player.velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true
	is_attacking = false
	popup.visible = false
	npc_dialog.visible = false
	npc2_dialog.visible = false
	animation_timer.stop()
	attack_timer.stop()
	game_over_overlay.visible = true

func _on_game_over_retry() -> void:
	GameState.start_level(GameState.selected_level)
	get_tree().reload_current_scene()

func _on_game_over_menu() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _reset_player() -> void:
	player.global_position = Vector2(120, 420)
	player.velocity = Vector2.ZERO

func _show_popup(text: String) -> void:
	popup.text = text
	popup.visible = true
	popup_timer.start()

func _refresh() -> void:
	score_label.text = "%d" % GameState.score
	level_label.text = "%d" % GameState.selected_level
	health_label.text = "❤️".repeat(max(health, 0))

func _update_player_visual(direction: float) -> void:
	if direction < 0:
		facing_right = false
		player_visual.flip_h = true
	elif direction > 0:
		facing_right = true
		player_visual.flip_h = false

	attack_hitbox.position = PLAYER_ATTACK_OFFSET_RIGHT if facing_right else PLAYER_ATTACK_OFFSET_LEFT

	if is_attacking:
		return

	var target_state := "idle"
	if not player.is_on_floor():
		target_state = "jump"
	elif abs(player.velocity.x) > 5.0:
		target_state = "run"

	if current_anim_state != target_state:
		current_anim_state = target_state
		if target_state == "jump":
			player_visual.texture = JUMP_TEXTURE
			player_visual.hframes = PLAYER_JUMP_FRAMES
			player_visual.frame = 0
			player_visual.position = PLAYER_IDLE_POS
			player_visual.scale = PLAYER_IDLE_SCALE
		elif target_state == "run":
			player_visual.texture = RUN_TEXTURE
			player_visual.hframes = PLAYER_RUN_FRAMES
			player_visual.frame = 0
			player_visual.position = PLAYER_RUN_POS
			player_visual.scale = PLAYER_RUN_SCALE
		else:
			player_visual.texture = IDLE_TEXTURE
			player_visual.hframes = 4
			player_visual.frame = 0
			player_visual.position = PLAYER_IDLE_POS
			player_visual.scale = PLAYER_IDLE_SCALE

func _on_animation_tick() -> void:
	player_anim_tick += 1
	enemy_anim_tick += 1

	if current_anim_state == "attack":
		player_visual.frame = player_anim_tick % PLAYER_ATTACK_FRAMES
	elif current_anim_state == "jump":
		player_visual.frame = player_anim_tick % PLAYER_JUMP_FRAMES
	elif current_anim_state == "run":
		player_visual.frame = player_anim_tick % PLAYER_RUN_FRAMES
	else:
		player_visual.frame = player_anim_tick % 4

	for enemy_entry in enemy_data:
		var raw_enemy = enemy_entry["node"]
		if not is_instance_valid(raw_enemy) or raw_enemy.is_queued_for_deletion():
			continue
		var enemy: Area2D = raw_enemy
		var visual: Sprite2D = enemy.get_node("Visual")
		if enemy_entry["type"] == "snail":
			visual.frame = enemy_anim_tick % SNAIL_FRAMES
		else:
			visual.frame = enemy_anim_tick % BEE_FRAMES
