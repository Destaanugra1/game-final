extends Control

func _ready() -> void:
	GameState.play_menu_music()
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	
	$Cards/Level1.pressed.connect(func():
		GameState.start_level(1)
		GameState.stop_menu_music()
		get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
	)
	
	if GameState.max_level >= 2:
		_unlock_card($Cards/Level2, "LV 2", "Gua Sains", "SAINS")
		$Cards/Level2.pressed.connect(func():
			GameState.start_level(2)
			GameState.stop_menu_music()
			get_tree().change_scene_to_file("res://scenes/gameplay_level2.tscn")
		)
		
	if GameState.max_level >= 3:
		_unlock_card($Cards/Level3, "LV 3", "Labirin Logika", "LOGIKA")
		$Cards/Level3.pressed.connect(func():
			GameState.start_level(3)
			GameState.stop_menu_music()
			get_tree().change_scene_to_file("res://scenes/gameplay_level3.tscn")
		)

func _unlock_card(card: Button, lv_text: String, sub_text: String, badge_text: String) -> void:
	var bg = card.get_node("Bg")
	bg.get_node("Border").border_color = Color(0, 0.9, 0.8, 1) # Cyan border
	
	var icon = bg.get_node("Icon")
	icon.text = "▒" # Pixel shape icon
	icon.add_theme_color_override("font_color", Color(0, 0.9, 0.8, 1))
	
	var lv = bg.get_node("LvText")
	lv.text = lv_text
	lv.add_theme_color_override("font_color", Color.WHITE)
	
	var st_label = Label.new()
	st_label.name = "SubText"
	st_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_label.text = sub_text
	st_label.add_theme_font_size_override("font_size", 10)
	st_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1))
	st_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	st_label.offset_top = 30
	bg.add_child(st_label)
	
	var badge = ColorRect.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.color = Color(0, 0.9, 0.8, 1)
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	badge.offset_top = -40
	badge.offset_bottom = -20
	badge.offset_left = -30
	badge.offset_right = 30
	bg.add_child(badge)
	
	var badge_l = Label.new()
	badge_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_l.text = badge_text
	badge_l.add_theme_font_size_override("font_size", 10)
	badge_l.add_theme_color_override("font_color", Color(0.04, 0.09, 0.16, 1))
	badge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(badge_l)
