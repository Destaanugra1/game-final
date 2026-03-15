extends Node2D

const SPEED := 205.0
const JUMP := -390.0
const GRAVITY := 920.0
const ENEMY_SPEED := 90.0

@onready var player: CharacterBody2D = $Player
@onready var npc: Area2D = $NPC
@onready var gate: Area2D = $Gate
@onready var enemy: Area2D = $Enemy
@onready var popup: Label = $CanvasLayer/PopupLabel
@onready var popup_timer: Timer = $PopupTimer

var enemy_direction := 1.0
var enemy_min_x := 520.0
var enemy_max_x := 760.0

func _ready() -> void:
	$CanvasLayer/MenuButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	npc.body_entered.connect(_on_npc_entered)
	gate.body_entered.connect(_on_gate_entered)
	enemy.body_entered.connect(_on_enemy_entered)
	popup_timer.timeout.connect(func(): popup.visible = false)
	for coin in $Coins.get_children():
		coin.body_entered.connect(_on_coin_entered.bind(coin))
	$Player/Visual.color = GameState.current_character_color()
	_setup_level()
	_refresh()

func _physics_process(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W)) and player.is_on_floor():
		player.velocity.y = JUMP
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		direction = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	player.velocity.x = direction * SPEED
	player.move_and_slide()
	player.global_position.x = clamp(player.global_position.x, 12.0, 948.0)
	if player.global_position.y > 620:
		_reset_player()

	enemy.position.x += ENEMY_SPEED * enemy_direction * delta
	if enemy.position.x <= enemy_min_x or enemy.position.x >= enemy_max_x:
		enemy_direction *= -1.0

func _setup_level() -> void:
	GameState.quiz_completed = false if GameState.collected_coins == 0 and not GameState.quiz_completed else GameState.quiz_completed
	match GameState.selected_level:
		1:
			$Platform.position = Vector2(470, 355)
			$NPC.position = Vector2(760, 420)
			$Enemy.position = Vector2(560, 420)
			enemy_min_x = 520.0
			enemy_max_x = 760.0
			$Coins/Coin1.position = Vector2(260, 420)
			$Coins/Coin2.position = Vector2(470, 315)
			$Coins/Coin3.position = Vector2(640, 420)
		2:
			$Platform.position = Vector2(360, 320)
			$NPC.position = Vector2(790, 420)
			$Enemy.position = Vector2(480, 420)
			enemy_min_x = 430.0
			enemy_max_x = 760.0
			$Coins/Coin1.position = Vector2(220, 420)
			$Coins/Coin2.position = Vector2(360, 280)
			$Coins/Coin3.position = Vector2(600, 420)
		3:
			$Platform.position = Vector2(560, 300)
			$NPC.position = Vector2(820, 420)
			$Enemy.position = Vector2(420, 420)
			enemy_min_x = 380.0
			enemy_max_x = 760.0
			$Coins/Coin1.position = Vector2(240, 420)
			$Coins/Coin2.position = Vector2(560, 260)
			$Coins/Coin3.position = Vector2(690, 420)
	for coin in $Coins.get_children():
		coin.visible = true
		coin.set_deferred("monitoring", true)
		coin.set_deferred("monitorable", true)

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player or not coin.visible:
		return
	coin.visible = false
	coin.set_deferred("monitoring", false)
	coin.set_deferred("monitorable", false)
	GameState.collected_coins += 1
	GameState.add_score(5)
	if GameState.collected_coins >= 3:
		GameState.achievements["all_coins"] = true
	_show_popup("+5 Coin")
	_refresh()

func _on_npc_entered(body: Node2D) -> void:
	if body == player:
		get_tree().change_scene_to_file("res://scenes/quiz_screen.tscn")

func _on_gate_entered(body: Node2D) -> void:
	if body != player:
		return
	if not GameState.quiz_completed:
		_show_popup("Selesaikan soal dulu!")
		return
	get_tree().change_scene_to_file("res://scenes/result_screen.tscn")

func _on_enemy_entered(body: Node2D) -> void:
	if body != player:
		return
	GameState.add_score(-3)
	_show_popup("Kena musuh! -3")
	_reset_player()
	_refresh()

func _reset_player() -> void:
	player.global_position = Vector2(120, 420)
	player.velocity = Vector2.ZERO

func _show_popup(text: String) -> void:
	popup.text = text
	popup.visible = true
	popup_timer.start()

func _refresh() -> void:
	$CanvasLayer/ScoreLabel.text = "Score: %d" % GameState.score
	$CanvasLayer/LevelLabel.text = "Level %d" % GameState.selected_level
