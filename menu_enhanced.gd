extends Control

# ── Stored selections (applied when game starts) ──────────────────────────────
var selected_quality:    String = "MEDIUM"   # LOW / MEDIUM / HIGH
var selected_difficulty: String = "EASY"     # EASY / MEDIUM / HARD

# ── Timer durations per difficulty ────────────────────────────────────────────
const DIFFICULTY_TIMES = {
	"EASY":   420,   # 7 minutes (default)
	"MEDIUM": 300,   # 5 minutes
	"HARD":   180    # 3 minutes
}

# ── UI references ──────────────────────────────────────────────────────────────
var options_overlay: ColorRect = null

# Quality button refs (so we can highlight active one)
var q_btns: Dictionary = {}   # "LOW" / "MEDIUM" / "HIGH" → Button
# Difficulty button refs
var d_btns: Dictionary = {}   # "EASY" / "MEDIUM" / "HARD" → Button


func _ready():
	var start_btn   = get_node_or_null("MainContainer/LeftPanel/StartButton")
	var quit_btn    = get_node_or_null("MainContainer/LeftPanel/QuitButton")
	var left_panel  = get_node_or_null("MainContainer/LeftPanel")

	if start_btn:
		if not start_btn.pressed.is_connected(_on_start_button_pressed):
			start_btn.pressed.connect(_on_start_button_pressed)

	if quit_btn:
		if not quit_btn.pressed.is_connected(_on_quit_button_pressed):
			quit_btn.pressed.connect(_on_quit_button_pressed)

	# Add OPTIONS button right after QUIT in the left panel
	if left_panel:
		var options_btn = _make_menu_btn("OPTIONS")
		options_btn.pressed.connect(_open_options)
		left_panel.add_child(options_btn)
		# Move it right after QuitButton (index 4)
		left_panel.move_child(options_btn, 3)

	_build_options_overlay()


# ─── Main menu button factory (matches existing style) ────────────────────────
func _make_menu_btn(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 70)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color",       Color(1.0, 0.95, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9))

	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.12, 0.12, 0.15, 0.85)
	sn.border_color = Color(0.8, 0.6, 0.2, 1.0)
	sn.border_width_left = 2; sn.border_width_top = 2
	sn.border_width_right = 2; sn.border_width_bottom = 2
	sn.corner_radius_top_left = 8; sn.corner_radius_top_right = 8
	sn.corner_radius_bottom_left = 8; sn.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", sn)

	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.2, 0.18, 0.15, 0.95)
	sh.border_color = Color(1.0, 0.8, 0.3, 1.0)
	sh.border_width_left = 3; sh.border_width_top = 3
	sh.border_width_right = 3; sh.border_width_bottom = 3
	sh.corner_radius_top_left = 8; sh.corner_radius_top_right = 8
	sh.corner_radius_bottom_left = 8; sh.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", sh)
	return btn


# ─── Build the options overlay (hidden at start) ──────────────────────────────
func _build_options_overlay():
	# Dark full-screen backdrop
	options_overlay = ColorRect.new()
	options_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_overlay.color = Color(0.0, 0.0, 0.0, 0.80)
	options_overlay.visible = false
	options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(options_overlay)

	# Centered card
	var card = Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -340
	card.offset_top    = -300
	card.offset_right  =  340
	card.offset_bottom =  300

	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.09, 0.12, 0.98)
	cs.border_color = Color(0.8, 0.6, 0.2, 0.9)
	cs.border_width_left = 2; cs.border_width_top = 2
	cs.border_width_right = 2; cs.border_width_bottom = 2
	cs.corner_radius_top_left = 16; cs.corner_radius_top_right = 16
	cs.corner_radius_bottom_left = 16; cs.corner_radius_bottom_right = 16
	cs.shadow_color = Color(0, 0, 0, 0.6)
	cs.shadow_size = 24
	card.add_theme_stylebox_override("panel", cs)
	options_overlay.add_child(card)

	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 40; vbox.offset_top = 30
	vbox.offset_right = -40; vbox.offset_bottom = -30
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	card.add_child(vbox)

	# ── Title ─────────────────────────────────────────────────────────────────
	var title = Label.new()
	title.text = "⚙  OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	# ── Divider ───────────────────────────────────────────────────────────────
	var div1 = _make_divider()
	vbox.add_child(div1)

	# ── GRAPHICS QUALITY section ──────────────────────────────────────────────
	var gfx_lbl = Label.new()
	gfx_lbl.text = "GRAPHICS QUALITY"
	gfx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gfx_lbl.add_theme_font_size_override("font_size", 18)
	gfx_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(gfx_lbl)

	var gfx_row = HBoxContainer.new()
	gfx_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gfx_row.add_theme_constant_override("separation", 12)
	vbox.add_child(gfx_row)

	q_btns["LOW"]    = _make_option_btn("🔴  LOW",    Color(0.50, 0.07, 0.05), Color(1.0, 0.3, 0.2))
	q_btns["MEDIUM"] = _make_option_btn("🟡  MEDIUM", Color(0.38, 0.28, 0.03), Color(1.0, 0.78, 0.15))
	q_btns["HIGH"]   = _make_option_btn("🟢  HIGH",   Color(0.05, 0.28, 0.08), Color(0.2, 0.9, 0.4))

	q_btns["LOW"].pressed.connect(func():    _select_quality("LOW"))
	q_btns["MEDIUM"].pressed.connect(func(): _select_quality("MEDIUM"))
	q_btns["HIGH"].pressed.connect(func():   _select_quality("HIGH"))

	gfx_row.add_child(q_btns["LOW"])
	gfx_row.add_child(q_btns["MEDIUM"])
	gfx_row.add_child(q_btns["HIGH"])

	# ── Divider ───────────────────────────────────────────────────────────────
	vbox.add_child(_make_divider())

	# ── DIFFICULTY section ────────────────────────────────────────────────────
	var dif_lbl = Label.new()
	dif_lbl.text = "DIFFICULTY"
	dif_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dif_lbl.add_theme_font_size_override("font_size", 18)
	dif_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(dif_lbl)

	# Difficulty description label (updates on selection)
	var diff_desc = Label.new()
	diff_desc.name = "DiffDesc"
	diff_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_desc.add_theme_font_size_override("font_size", 14)
	diff_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	diff_desc.text = "⏱  7:00 minutes  —  Plenty of time to explore"
	vbox.add_child(diff_desc)

	var dif_row = HBoxContainer.new()
	dif_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dif_row.add_theme_constant_override("separation", 12)
	vbox.add_child(dif_row)

	d_btns["EASY"]   = _make_option_btn("😊  EASY",   Color(0.05, 0.28, 0.08), Color(0.2, 0.9, 0.4))
	d_btns["MEDIUM"] = _make_option_btn("😐  MEDIUM", Color(0.38, 0.28, 0.03), Color(1.0, 0.78, 0.15))
	d_btns["HARD"]   = _make_option_btn("💀  HARD",   Color(0.50, 0.07, 0.05), Color(1.0, 0.3, 0.2))

	d_btns["EASY"].pressed.connect(func():   _select_difficulty("EASY",   diff_desc))
	d_btns["MEDIUM"].pressed.connect(func(): _select_difficulty("MEDIUM", diff_desc))
	d_btns["HARD"].pressed.connect(func():   _select_difficulty("HARD",   diff_desc))

	dif_row.add_child(d_btns["EASY"])
	dif_row.add_child(d_btns["MEDIUM"])
	dif_row.add_child(d_btns["HARD"])

	# ── Close button ──────────────────────────────────────────────────────────
	vbox.add_child(_make_divider())

	var close_btn = Button.new()
	close_btn.text = "✔  SAVE & CLOSE"
	close_btn.custom_minimum_size = Vector2(220, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))

	var cbn = StyleBoxFlat.new()
	cbn.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	cbn.border_color = Color(0.8, 0.6, 0.2, 0.9)
	cbn.border_width_left = 2; cbn.border_width_top = 2
	cbn.border_width_right = 2; cbn.border_width_bottom = 2
	cbn.corner_radius_top_left = 8; cbn.corner_radius_top_right = 8
	cbn.corner_radius_bottom_left = 8; cbn.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", cbn)

	var cbh = cbn.duplicate()
	cbh.bg_color = Color(0.22, 0.20, 0.10, 0.97)
	cbh.border_color = Color(1.0, 0.85, 0.3, 1.0)
	close_btn.add_theme_stylebox_override("hover", cbh)
	close_btn.pressed.connect(func(): options_overlay.visible = false)
	vbox.add_child(close_btn)

	# Apply default highlights
	_refresh_quality_highlights()
	_refresh_difficulty_highlights()


# ─── Helpers ──────────────────────────────────────────────────────────────────
func _make_divider() -> HSeparator:
	var sep = HSeparator.new()
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0.8, 0.6, 0.2, 0.35)
	ss.content_margin_top = 1
	ss.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", ss)
	return sep


func _make_option_btn(label: String, bg: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(148, 52)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color",       Color(1.0, 0.95, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(bg.r, bg.g, bg.b, 0.75)
	sn.border_color = Color(border.r, border.g, border.b, 0.6)
	sn.border_width_left = 2; sn.border_width_top = 2
	sn.border_width_right = 2; sn.border_width_bottom = 2
	sn.corner_radius_top_left = 8; sn.corner_radius_top_right = 8
	sn.corner_radius_bottom_left = 8; sn.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", sn)
	btn.set_meta("bg", bg)
	btn.set_meta("border", border)

	var sh = sn.duplicate()
	sh.bg_color = Color(min(bg.r + 0.2, 1.0), min(bg.g + 0.15, 1.0), min(bg.b + 0.1, 1.0), 1.0)
	sh.border_color = Color(border.r, border.g, border.b, 1.0)
	sh.border_width_left = 3; sh.border_width_top = 3
	sh.border_width_right = 3; sh.border_width_bottom = 3
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sh)
	return btn


func _set_btn_active(btn: Button, active: bool):
	var bg:     Color = btn.get_meta("bg")
	var border: Color = btn.get_meta("border")
	var sn = StyleBoxFlat.new()
	if active:
		# Bright + full border when selected
		sn.bg_color = Color(min(bg.r + 0.15, 1.0), min(bg.g + 0.12, 1.0), min(bg.b + 0.08, 1.0), 1.0)
		sn.border_color = Color(border.r, border.g, border.b, 1.0)
		sn.border_width_left = 3; sn.border_width_top = 3
		sn.border_width_right = 3; sn.border_width_bottom = 3
	else:
		# Dim when not selected
		sn.bg_color = Color(bg.r, bg.g, bg.b, 0.40)
		sn.border_color = Color(border.r, border.g, border.b, 0.3)
		sn.border_width_left = 2; sn.border_width_top = 2
		sn.border_width_right = 2; sn.border_width_bottom = 2
	sn.corner_radius_top_left = 8; sn.corner_radius_top_right = 8
	sn.corner_radius_bottom_left = 8; sn.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", sn)
	btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(1.0, 1.0, 1.0, 0.6)


func _refresh_quality_highlights():
	for key in q_btns:
		_set_btn_active(q_btns[key], key == selected_quality)

func _refresh_difficulty_highlights():
	for key in d_btns:
		_set_btn_active(d_btns[key], key == selected_difficulty)


# ─── Selection handlers ───────────────────────────────────────────────────────
func _select_quality(q: String):
	selected_quality = q
	_refresh_quality_highlights()


func _select_difficulty(d: String, desc_label: Label):
	selected_difficulty = d
	_refresh_difficulty_highlights()
	match d:
		"EASY":   desc_label.text = "⏱  7:00 minutes  —  Plenty of time to explore"
		"MEDIUM": desc_label.text = "⏱  5:00 minutes  —  Stay focused"
		"HARD":   desc_label.text = "⏱  3:00 minutes  —  No time to waste!"


# ─── Options button handler ───────────────────────────────────────────────────
func _open_options():
	options_overlay.visible = true


# ─── Start button → apply settings → load tutorial ───────────────────────────
func _on_start_button_pressed():
	# Apply graphics quality
	var vp = get_viewport()
	match selected_quality:
		"LOW":
			vp.scaling_3d_scale = 0.75
			vp.msaa_3d          = Viewport.MSAA_DISABLED
			vp.screen_space_aa  = Viewport.SCREEN_SPACE_AA_DISABLED
			RenderingServer.directional_shadow_atlas_set_size(200, false)
		"MEDIUM":
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d          = Viewport.MSAA_2X
			vp.screen_space_aa  = Viewport.SCREEN_SPACE_AA_FXAA
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		"HIGH":
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d          = Viewport.MSAA_4X
			vp.screen_space_aa  = Viewport.SCREEN_SPACE_AA_FXAA
			RenderingServer.directional_shadow_atlas_set_size(4096, true)

	# Apply difficulty — store chosen timer duration in GameManager
	var duration = DIFFICULTY_TIMES[selected_difficulty]
	if GameManager:
		GameManager.time_limit    = duration
		GameManager.time_remaining_f = float(duration)
		GameManager.time_remaining   = duration

	# Load the game (tutorial first)
	var tutorial_path = "res://Scenes/Tutorial/tutorial.tscn"
	if FileAccess.file_exists(tutorial_path):
		get_tree().change_scene_to_file(tutorial_path)
	else:
		get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
