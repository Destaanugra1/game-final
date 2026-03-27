extends Control

const IDLE_TEXTURE := preload("res://Character/Idle/Idle-Sheet.png")
const CHAR_COLORS  := [
	Color(0.23, 0.50, 0.96, 1),  # Aksa  — biru
	Color(0.58, 0.24, 0.90, 1),  # Nara  — ungu
	Color(0.10, 0.78, 0.78, 1),  # Pixel — teal
]

@onready var cards_row   : HBoxContainer = $CardsRow
@onready var back_button : Button        = $BackButton

var cards: Array[Panel] = []
var anim_ticks: Array[int] = []
var anim_timers: Array[Timer] = []

func _ready() -> void:
	GameState.play_menu_music()
	_polish_back_button()
	_build_cards()
	back_button.pressed.connect(
		func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

# ─── Build Cards ─────────────────────────────────────────────────────────────
func _build_cards() -> void:
	var data: Array = GameState.CHARACTER_DATA
	for i in data.size():
		var unlocked: bool = GameState.unlocked_characters[i]
		var card := _make_card(i, unlocked)
		cards_row.add_child(card)
		cards.append(card)

	# Slot gembok ekstra (slot ke-4 selalu terkunci placeholder)
	var lock_card := _make_lock_placeholder()
	cards_row.add_child(lock_card)

	_highlight_selected()

func _make_card(idx: int, unlocked: bool) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(170, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# --- Spacer atas
	var sp_top := Control.new()
	sp_top.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(sp_top)

	if unlocked:
		# Sprite karakter
		var sprite := Sprite2D.new()
		sprite.texture  = IDLE_TEXTURE
		sprite.hframes  = 4
		sprite.frame    = 1
		sprite.scale    = Vector2(3.5, 3.5)
		sprite.modulate = CHAR_COLORS[idx]
		sprite.position = Vector2(85, 80)
		card.add_child(sprite)   # langsung ke card bukan vbox (agar bebas posisi)

		anim_ticks.append(0)
		var tmr := Timer.new()
		tmr.wait_time = 0.15
		tmr.autostart = true
		card.add_child(tmr)
		var sprite_ref := sprite
		var tick_idx   := anim_ticks.size() - 1
		tmr.timeout.connect(func():
			anim_ticks[tick_idx] += 1
			sprite_ref.frame = anim_ticks[tick_idx] % 4
		)

		# Nama
		var name_lbl := Label.new()
		name_lbl.text = GameState.CHARACTER_DATA[idx]["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		name_lbl.offset_top   = -68.0
		name_lbl.offset_bottom = -44.0
		card.add_child(name_lbl)

		# Stat
		var stat_lbl := Label.new()
		stat_lbl.text = GameState.CHARACTER_DATA[idx]["stat"]
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_lbl.add_theme_color_override("font_color", Color(1, 0.88, 0.22, 1))
		stat_lbl.add_theme_font_size_override("font_size", 14)
		stat_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		stat_lbl.offset_top    = -46.0
		stat_lbl.offset_bottom = -16.0
		card.add_child(stat_lbl)

		# Klik
		card.gui_input.connect(_on_card_input.bind(idx))
		card.mouse_entered.connect(_on_card_hover.bind(card, true))
		card.mouse_exited.connect(_on_card_hover.bind(card, false))
	else:
		# Gembok
		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 52)
		lock_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_lbl.offset_top   = -20.0
		card.add_child(lock_lbl)

		var hint_lbl := Label.new()
		hint_lbl.text = GameState.CHARACTER_DATA[idx]["hint"]
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		hint_lbl.offset_top    = -48.0
		hint_lbl.offset_bottom = -8.0
		card.add_child(hint_lbl)

	_apply_card_style(card, false, unlocked)
	return card

func _make_lock_placeholder() -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(170, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = "🔒"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(lbl)
	_apply_card_style(card, false, false)
	return card

# ─── Card Styling ─────────────────────────────────────────────────────────────
func _apply_card_style(card: Panel, selected: bool, unlocked: bool) -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color     = Color(0.10, 0.14, 0.30, 1)
		style.border_color = Color(1, 0.88, 0.22, 1)
		style.set_border_width_all(3)
	elif unlocked:
		style.bg_color     = Color(0.08, 0.12, 0.26, 1)
		style.border_color = Color(0.35, 0.45, 0.70, 0.70)
		style.set_border_width_all(2)
	else:
		style.bg_color     = Color(0.06, 0.09, 0.18, 1)
		style.border_color = Color(0.25, 0.28, 0.38, 0.50)
		style.set_border_width_all(2)
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("panel", style)

func _highlight_selected() -> void:
	var data_size := GameState.CHARACTER_DATA.size()
	for i in cards.size():
		if i >= data_size:
			break
		var is_selected : bool = (i == GameState.selected_character)
		var is_unlocked : bool = GameState.unlocked_characters[i]
		_apply_card_style(cards[i], is_selected, is_unlocked)

# ─── Input ────────────────────────────────────────────────────────────────────
func _on_card_input(event: InputEvent, char_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState.unlocked_characters[char_idx]:
			GameState.selected_character = char_idx
			_highlight_selected()

func _on_card_hover(card: Panel, hovered: bool) -> void:
	var idx := cards.find(card)
	if idx < 0 or idx >= GameState.CHARACTER_DATA.size():
		return
	var is_sel     : bool = (idx == GameState.selected_character)
	var is_unlocked: bool = GameState.unlocked_characters[idx]
	if hovered and is_unlocked and not is_sel:
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color     = Color(0.12, 0.18, 0.35, 1)
		hover_style.border_color = Color(0.55, 0.70, 1.0, 0.80)
		hover_style.set_border_width_all(2)
		hover_style.corner_radius_top_left     = 10
		hover_style.corner_radius_top_right    = 10
		hover_style.corner_radius_bottom_left  = 10
		hover_style.corner_radius_bottom_right = 10
		card.add_theme_stylebox_override("panel", hover_style)
	else:
		_apply_card_style(card, is_sel, is_unlocked)

# ─── UI Polish ────────────────────────────────────────────────────────────────
func _polish_back_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.06, 0.10, 0.22, 1)
	style.border_color = Color(1, 0.88, 0.22, 0.80)
	style.set_border_width_all(2)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	back_button.add_theme_stylebox_override("normal", style)
	back_button.add_theme_color_override("font_color", Color(1, 0.88, 0.22, 1))
	back_button.add_theme_font_size_override("font_size", 18)
