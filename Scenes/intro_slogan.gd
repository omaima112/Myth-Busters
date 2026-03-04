extends Control

# ── State ──────────────────────────────────────────────────────────────────────
var _tween: Tween    = null
var _audio_done: bool = false
var _anim_done:  bool = false
var _going:      bool = false

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var icon_label:   Label             = $CenterContainer/VBox/IconLabel
@onready var line1:        Label             = $CenterContainer/VBox/Line1
@onready var line2:        Label             = $CenterContainer/VBox/Line2
@onready var sub_label:    RichTextLabel     = $CenterContainer/VBox/SubLabel
@onready var continue_btn: Button            = $CenterContainer/VBox/ContinueBtn
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var vbox:         VBoxContainer     = $CenterContainer/VBox

func _ready() -> void:
	_apply_responsive_fonts()
	icon_label.modulate.a   = 0.0
	line1.modulate.a        = 0.0
	line2.modulate.a        = 0.0
	sub_label.modulate.a    = 0.0
	continue_btn.modulate.a = 0.0
	continue_btn.visible    = false
	audio_player.play()
	audio_player.finished.connect(_on_audio_finished)
	_animate_intro()


func _process(_delta: float) -> void:
	# Click anywhere to skip to menu — nothing can block this
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_go_to_menu()


func _apply_responsive_fonts() -> void:
	var screen_w = DisplayServer.window_get_size().x
	var scale: float
	if screen_w <= 540:
		scale = 0.55
	elif screen_w <= 800:
		scale = 0.72
	elif screen_w <= 1280:
		scale = 0.88
	else:
		scale = 1.0
	icon_label.add_theme_font_size_override("font_size",       int(72 * scale))
	line1.add_theme_font_size_override("font_size",            int(30 * scale))
	line2.add_theme_font_size_override("font_size",            int(30 * scale))
	sub_label.add_theme_font_size_override("normal_font_size", int(22 * scale))
	continue_btn.add_theme_font_size_override("font_size",     int(26 * scale))
	if screen_w <= 540:
		vbox.custom_minimum_size = Vector2(screen_w * 0.88, 0)
	elif screen_w <= 800:
		vbox.custom_minimum_size = Vector2(screen_w * 0.82, 0)
	else:
		vbox.custom_minimum_size = Vector2(760, 0)
	if screen_w <= 800:
		continue_btn.custom_minimum_size = Vector2(260, 80)


func _animate_intro() -> void:
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(icon_label, "modulate:a", 1.0, 1.2)
	_tween.tween_interval(0.4)
	_tween.tween_property(line1,      "modulate:a", 1.0, 1.0)
	_tween.tween_interval(0.6)
	_tween.tween_property(line2,      "modulate:a", 1.0, 1.0)
	_tween.tween_interval(0.8)
	_tween.tween_property(sub_label,  "modulate:a", 1.0, 1.0)
	_tween.finished.connect(_on_anim_finished)


func _on_anim_finished() -> void:
	_anim_done = true
	_check_show_continue()


func _on_audio_finished() -> void:
	_audio_done = true
	_check_show_continue()


func _check_show_continue() -> void:
	if _audio_done and _anim_done:
		continue_btn.visible = true
		var t = create_tween()
		t.tween_property(continue_btn, "modulate:a", 1.0, 0.6)


func _on_continue_pressed() -> void:
	_go_to_menu()


func _go_to_menu() -> void:
	if _going:
		return
	_going = true
	if _tween:
		_tween.kill()
	audio_player.stop()
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.finished.connect(func():
		get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	)
