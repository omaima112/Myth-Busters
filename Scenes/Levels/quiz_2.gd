extends Control

@onready var question_label = $Panel/QuestionLabel
@onready var progress_label = $Panel/ProgressLabel
@onready var option_buttons = [
	$Panel/Option1,
	$Panel/Option2,
	$Panel/Option3,
	$Panel/Option4
]
@onready var next_button    = $Panel/NextButton
@onready var stars_container = $Panel/Stars
@onready var star1  = $Panel/Stars/Star1
@onready var star2  = $Panel/Stars/Star2
@onready var star3  = $Panel/Stars/Star3
@onready var note_label = $Panel/NoteLabel

var current_question  = 0
var score             = 0
var selected_answer   = -1
var answer_history: Array = []

# Result screen nodes
var result_overlay: Panel   = null
var anim_time:  float       = 0.0
var animating:  bool        = false
var earned_stars: int       = 0
var star_labels: Array      = []
var score_ring_label: Label = null
var grade_label:      Label = null
var result_note_label: Label = null
var back_btn:  Button       = null
var retry_btn: Button       = null
var result_title: Label     = null
var pulse_time: float       = 0.0

var questions = [
	{
		"question": "What is the typical radiation dose from ONE CT scan?",
		"options": ["0.02 mSv", "1 mSv", "1-6 mSv", "7-10 mSv"],
		"correct": 3
	},
	{
		"question": "Which releases MORE radiation into the surrounding environment?",
		"options": ["Nuclear power plant vicinity", "Coal plant vicinity", "They're exactly the same", "Neither releases radiation"],
		"correct": 1
	},
	{
		"question": "Which energy source causes the FEWEST deaths per terawatt-hour (TWh)?",
		"options": ["Coal", "Oil", "Solar", "Nuclear"],
		"correct": 3
	},
	{
		"question": "What does ALARA stand for in radiation safety?",
		"options": ["As Low As Reasonably Achievable", "Always Low And Reliable Administration", "Advanced Laser And Radiation Application", "Avoid Long-term Accumulated Radiation Absorption"],
		"correct": 0
	},
	{
		"question": "Can a nuclear power plant explode like an atomic bomb?",
		"options": ["Yes, if the reactor overheats", "Yes, under extreme conditions", "No, reactors cannot produce a nuclear explosion", "Only older reactor designs can"],
		"correct": 2
	},
	{
		"question": "What happens to modern reactors if abnormal conditions are detected?",
		"options": ["They increase power output", "They require manual shutdown by operators", "They automatically shut down", "They release steam to cool down"],
		"correct": 2
	},
	{
		"question": "How is used nuclear fuel waste stored?",
		"options": ["Released as gas into the atmosphere", "Pumped into deep ocean trenches", "As solid material in secure, monitored facilities", "Mixed with concrete and buried in landfills"],
		"correct": 2
	},
	{
		"question": "Nuclear technology in medicine is used for which of the following?",
		"options": ["Only surgery", "Diagnosis and cancer treatment", "Producing vaccines", "Blood transfusions"],
		"correct": 1
	},
	{
		"question": "Where does most of our daily radiation exposure come from?",
		"options": ["Nuclear power plants", "Cell phones", "Natural sources", "Medical X-rays"],
		"correct": 2
	},
	{
		"question": "What is a key advantage of nuclear power over solar and wind energy?",
		"options": ["It is cheaper to build", "It produces electricity continuously, day and night", "It requires no water", "It emits no waste of any kind"],
		"correct": 1
	}
]

# ─────────────────────────────────────────────
#  STYLE HELPERS
# ─────────────────────────────────────────────
func _make_stylebox(border_color: Color, bg_color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = border_color
	s.border_width_left   = 5
	s.border_width_right  = 5
	s.border_width_top    = 5
	s.border_width_bottom = 5
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	return s

func _make_panel_style(bg: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color    = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _clear_button_styles():
	for btn in option_buttons:
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_stylebox_override("pressed")
		btn.remove_theme_stylebox_override("disabled")
		btn.modulate = Color.WHITE

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))

	next_button.pressed.connect(_on_next_pressed)
	next_button.disabled = true
	load_question()

# ─────────────────────────────────────────────
#  PROCESS  (animations)
# ─────────────────────────────────────────────
func _process(delta: float):
	if not animating:
		return
	anim_time  += delta
	pulse_time += delta

	# Subtle pulse on back button after fade-in
	if back_btn != null and back_btn.modulate.a >= 0.95:
		var a = 0.75 + 0.25 * sin(pulse_time * 2.8)
		back_btn.modulate = Color(a, a, a, 1.0)

	# Stars pop in one by one
	for i in range(star_labels.size()):
		var delay = 0.3 + i * 0.45
		if anim_time > delay:
			var t      = clamp((anim_time - delay) / 0.30, 0.0, 1.0)
			var ease_t = 1.0 - pow(1.0 - t, 3.0)
			if i < earned_stars:
				star_labels[i].scale    = Vector2(ease_t, ease_t)
				star_labels[i].modulate = Color(1.0, 0.85, 0.0, ease_t)
			else:
				star_labels[i].scale    = Vector2(ease_t * 0.85, ease_t * 0.85)
				star_labels[i].modulate = Color(0.32, 0.22, 0.06, ease_t * 0.55)

	# Progress bar fills after stars
	if anim_time > 1.8 and result_overlay != null and result_overlay.has_meta("bar_fill"):
		var bar_fill   = result_overlay.get_meta("bar_fill")
		var bar_track  = result_overlay.get_meta("bar_track")
		var target_pct = result_overlay.get_meta("target_pct")
		var fill_t     = clamp((anim_time - 1.8) / 1.0, 0.0, 1.0)
		var ease_fill  = 1.0 - pow(1.0 - fill_t, 3.0)
		bar_fill.offset_right = bar_track.size.x * target_pct * ease_fill
		bar_fill.modulate.a   = clamp((anim_time - 1.8) / 0.4, 0.0, 1.0)
		bar_track.modulate.a  = clamp((anim_time - 1.8) / 0.4, 0.0, 1.0)
		# Animate label colour: bright gold while bar hasn't reached it, dark once covered
		if result_overlay.has_meta("bar_lbl") and result_overlay.has_meta("bar_pct"):
			var bar_lbl     = result_overlay.get_meta("bar_lbl")
			var final_pct   = result_overlay.get_meta("bar_pct") as int
			var current_fill_pct = int(target_pct * ease_fill * 100.0)
			if final_pct >= 50:
				# bar will cover label — fade from gold to dark as fill passes 50%
				var t_dark = clamp((current_fill_pct - 45.0) / 10.0, 0.0, 1.0)
				bar_lbl.add_theme_color_override("font_color",
					Color(0.08, 0.05, 0.01).lerp(Color(1.00, 0.80, 0.15), 1.0 - t_dark))
			else:
				# bar stays short — label stays bright gold always
				bar_lbl.add_theme_color_override("font_color", Color(1.00, 0.80, 0.15))

	# Grade + note fade in
	if anim_time > 2.4:
		var t = clamp((anim_time - 2.4) / 0.5, 0.0, 1.0)
		if grade_label:        grade_label.modulate.a        = t
		if result_note_label:  result_note_label.modulate.a  = t
		if score_ring_label:   score_ring_label.modulate.a   = t

	# Buttons fade in last
	if anim_time > 3.1:
		var t = clamp((anim_time - 3.1) / 0.6, 0.0, 1.0)
		if retry_btn and retry_btn.modulate.a < 0.95:
			retry_btn.modulate.a = t
		if back_btn and back_btn.modulate.a < 0.95:
			back_btn.modulate.a = t

# ─────────────────────────────────────────────
#  QUIZ LOGIC
# ─────────────────────────────────────────────
func load_question():
	if current_question >= questions.size():
		show_results()
		return

	var q = questions[current_question]
	question_label.text = q["question"]
	_clear_button_styles()
	for i in range(option_buttons.size()):
		option_buttons[i].text     = q["options"][i]
		option_buttons[i].disabled = false
		option_buttons[i].visible  = true

	progress_label.text   = "Question " + str(current_question + 1) + " / " + str(questions.size())
	selected_answer       = -1
	next_button.disabled  = true
	next_button.text      = "Next >"

func _on_option_pressed(index: int):
	selected_answer = index
	var correct_index = questions[current_question]["correct"]

	for i in range(option_buttons.size()):
		option_buttons[i].disabled = true
		if i == correct_index:
			var s = _make_stylebox(Color(0.0, 0.9, 0.2), Color(0.0, 0.35, 0.08))
			option_buttons[i].add_theme_stylebox_override("normal",   s)
			option_buttons[i].add_theme_stylebox_override("disabled", s)
			option_buttons[i].modulate = Color.WHITE
		elif i == index:
			var s = _make_stylebox(Color(0.95, 0.1, 0.1), Color(0.4, 0.04, 0.04))
			option_buttons[i].add_theme_stylebox_override("normal",   s)
			option_buttons[i].add_theme_stylebox_override("disabled", s)
			option_buttons[i].modulate = Color.WHITE
		else:
			option_buttons[i].modulate = Color(0.6, 0.6, 0.6, 1.0)

	next_button.disabled = false

func _on_next_pressed():
	if selected_answer == -1:
		return
	var correct_index = questions[current_question]["correct"]
	var was_correct   = (selected_answer == correct_index)
	if was_correct:
		score += 1

	answer_history.append({
		"correct": was_correct,
		"chosen":  selected_answer,
		"right":   correct_index,
		"q_index": current_question
	})

	current_question += 1
	if current_question < questions.size():
		load_question()
	else:
		show_results()

# ─────────────────────────────────────────────
#  RESULT SCREEN  — fixed-anchor centred card
# ─────────────────────────────────────────────
func show_results():
	var total       = questions.size()
	var pct         = int((float(score) / float(total)) * 100.0)
	var target_frac = float(score) / float(total)

	if   score > 8: earned_stars = 3
	elif score > 6: earned_stars = 2
	elif score > 4: earned_stars = 1
	else:           earned_stars = 0

	# ── Palette matching the game's dark/orange/gold theme ──
	var C_BG      = Color(0.10, 0.08, 0.04, 1.0)
	var C_CARD    = Color(0.16, 0.12, 0.05, 1.0)
	var C_SURFACE = Color(0.22, 0.16, 0.06, 1.0)
	var C_BORDER  = Color(0.60, 0.40, 0.05, 1.0)
	var C_ORANGE  = Color(0.95, 0.48, 0.05, 1.0)
	var C_GOLD    = Color(1.00, 0.80, 0.15, 1.0)
	var C_TEXT    = Color(0.97, 0.93, 0.82, 1.0)
	var C_SUB     = Color(0.65, 0.54, 0.34, 1.0)
	var C_DIM     = Color(0.45, 0.32, 0.08, 1.0)

	var grade_text  := ""
	var grade_color : Color = C_ORANGE
	var grade_emoji := ""
	match earned_stars:
		3:
			grade_text  = "EXPERT!"
			grade_emoji = "🏆"
			grade_color = Color(1.00, 0.82, 0.10, 1.0)
		2:
			grade_text  = "GREAT JOB!"
			grade_emoji = "🎯"
			grade_color = Color(0.95, 0.55, 0.08, 1.0)
		1:
			grade_text  = "KEEP LEARNING"
			grade_emoji = "📚"
			grade_color = Color(0.85, 0.35, 0.06, 1.0)
		_:
			grade_text  = "TRY AGAIN!"
			grade_emoji = "💡"
			grade_color = Color(0.80, 0.20, 0.08, 1.0)

	var note_text := ""
	match earned_stars:
		3: note_text = "Outstanding! You truly understand nuclear power and radiation safety."
		2: note_text = "Well done! A little more study and you'll reach expert level."
		1: note_text = "Good start! Review the material and give it another try."
		_: note_text = "Don't give up — study the key facts and try again!"

	for btn in option_buttons: btn.visible = false
	question_label.visible  = false
	progress_label.visible  = false
	next_button.visible     = false
	stars_container.visible = false
	note_label.visible      = false

	# ─── Full-screen dark overlay ───────────────────────────
	result_overlay = Panel.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ov_s = StyleBoxFlat.new()
	ov_s.bg_color = C_BG
	result_overlay.add_theme_stylebox_override("panel", ov_s)
	add_child(result_overlay)

	# Top + bottom orange bars (match game UI)
	for tb in [true, false]:
		var bar = Panel.new()
		bar.anchor_left  = 0.0; bar.anchor_right  = 1.0
		bar.anchor_top   = 0.0 if tb else 1.0
		bar.anchor_bottom = 0.0 if tb else 1.0
		bar.offset_top    = 0;  bar.offset_bottom = 5 if tb else 0
		bar.offset_top    = -5 if not tb else 0
		bar.offset_bottom = 0  if not tb else 5
		bar.offset_left   = 0; bar.offset_right   = 0
		var bs = StyleBoxFlat.new(); bs.bg_color = C_ORANGE
		bar.add_theme_stylebox_override("panel", bs)
		result_overlay.add_child(bar)

	# Corner brackets (game style)
	# Corner brackets — [anchor_x, anchor_y, h_left, h_right, h_top, h_bot, v_left, v_right, v_top, v_bot]
	var P  = 10   # padding from edge
	var LN = 4    # line thickness
	var SZ = 52   # bracket arm length
	var brk_data = [
		# top-left
		[0.0, 0.0,  P,       P+SZ,    P,       P+LN,    P,       P+LN,    P,       P+SZ  ],
		# top-right
		[1.0, 0.0,  -(P+SZ), -P,      P,       P+LN,    -(P+LN), -P,      P,       P+SZ  ],
		# bottom-left
		[0.0, 1.0,  P,       P+SZ,    -(P+LN), -P,      P,       P+LN,    -(P+SZ), -P    ],
		# bottom-right
		[1.0, 1.0,  -(P+SZ), -P,      -(P+LN), -P,      -(P+LN), -P,      -(P+SZ), -P    ],
	]
	for b in brk_data:
		var bH = Panel.new()
		bH.anchor_left   = b[0]; bH.anchor_right  = b[0]
		bH.anchor_top    = b[1]; bH.anchor_bottom = b[1]
		bH.offset_left   = b[2]; bH.offset_right  = b[3]
		bH.offset_top    = b[4]; bH.offset_bottom = b[5]
		var hs = StyleBoxFlat.new(); hs.bg_color = C_BORDER
		bH.add_theme_stylebox_override("panel", hs)
		result_overlay.add_child(bH)
		var bV = Panel.new()
		bV.anchor_left   = b[0]; bV.anchor_right  = b[0]
		bV.anchor_top    = b[1]; bV.anchor_bottom = b[1]
		bV.offset_left   = b[6]; bV.offset_right  = b[7]
		bV.offset_top    = b[8]; bV.offset_bottom = b[9]
		var vs = StyleBoxFlat.new(); vs.bg_color = C_BORDER
		bV.add_theme_stylebox_override("panel", vs)
		result_overlay.add_child(bV)

	# ─── Centred column 680 px ──────────────────────────────
	var COL_W = 680
	var col   = Panel.new()
	col.anchor_left   = 0.5;  col.anchor_right  = 0.5
	col.anchor_top    = 0.0;  col.anchor_bottom = 1.0
	col.offset_left   = -(COL_W / 2)
	col.offset_right  =  (COL_W / 2)
	col.offset_top    = 0;    col.offset_bottom = 0
	var col_s = StyleBoxFlat.new()
	col_s.bg_color = Color(0, 0, 0, 0)
	col.add_theme_stylebox_override("panel", col_s)
	result_overlay.add_child(col)

	var Y = 0

	# ─── TITLE ──────────────────────────────────────────────
	Y = 44

	result_title = _rl("QUIZ COMPLETE", 50, C_GOLD)
	result_title.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	result_title.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	result_title.set_anchor_and_offset(SIDE_TOP,    0, Y)
	result_title.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + 62)
	col.add_child(result_title)
	Y += 66

	# Orange underline — centred using symmetric padding from both sides
	var ul = Panel.new()
	ul.set_anchor_and_offset(SIDE_LEFT,   0, 210)
	ul.set_anchor_and_offset(SIDE_RIGHT,  1, -210)
	ul.set_anchor_and_offset(SIDE_TOP,    0, Y)
	ul.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + 3)
	var ul_s = StyleBoxFlat.new()
	ul_s.bg_color = C_ORANGE
	ul_s.corner_radius_top_left     = 2
	ul_s.corner_radius_top_right    = 2
	ul_s.corner_radius_bottom_left  = 2
	ul_s.corner_radius_bottom_right = 2
	ul.add_theme_stylebox_override("panel", ul_s)
	col.add_child(ul)
	Y += 22

	# ─── SCORE + GRADE CARDS ────────────────────────────────
	var CARD_H = 118
	var HALF_W = (COL_W - 16) / 2

	# Score card
	var sc = _panel(C_CARD, C_BORDER, 14)
	sc.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	sc.set_anchor_and_offset(SIDE_RIGHT,  0, HALF_W)
	sc.set_anchor_and_offset(SIDE_TOP,    0, Y)
	sc.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + CARD_H)
	col.add_child(sc)

	var sc_top = _rl("YOUR SCORE", 12, C_SUB)
	sc_top.set_anchor_and_offset(SIDE_LEFT, 0, 0); sc_top.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	sc_top.set_anchor_and_offset(SIDE_TOP, 0, 12); sc_top.set_anchor_and_offset(SIDE_BOTTOM, 0, 30)
	sc.add_child(sc_top)

	score_ring_label = _rl(str(score) + " / " + str(total), 50, C_GOLD)
	score_ring_label.set_anchor_and_offset(SIDE_LEFT, 0, 0); score_ring_label.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	score_ring_label.set_anchor_and_offset(SIDE_TOP, 0, 30); score_ring_label.set_anchor_and_offset(SIDE_BOTTOM, 0, 88)
	score_ring_label.modulate.a = 0.0
	sc.add_child(score_ring_label)

	var sc_bot = _rl(str(pct) + "% correct", 13, C_SUB)
	sc_bot.set_anchor_and_offset(SIDE_LEFT, 0, 0); sc_bot.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	sc_bot.set_anchor_and_offset(SIDE_TOP, 0, 88); sc_bot.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	sc.add_child(sc_bot)

	# Grade card
	var g_bg = Color(grade_color.r * 0.20, grade_color.g * 0.12, grade_color.b * 0.03, 1.0)
	var gc = _panel(g_bg, grade_color, 14)
	gc.set_anchor_and_offset(SIDE_LEFT,   0, HALF_W + 16)
	gc.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	gc.set_anchor_and_offset(SIDE_TOP,    0, Y)
	gc.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + CARD_H)
	col.add_child(gc)

	var gc_em = _rl(grade_emoji, 30, Color.WHITE)
	gc_em.set_anchor_and_offset(SIDE_LEFT, 0, 0); gc_em.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	gc_em.set_anchor_and_offset(SIDE_TOP, 0, 10); gc_em.set_anchor_and_offset(SIDE_BOTTOM, 0, 48)
	gc.add_child(gc_em)

	grade_label = _rl(grade_text, 24, grade_color)
	grade_label.set_anchor_and_offset(SIDE_LEFT, 0, 0); grade_label.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	grade_label.set_anchor_and_offset(SIDE_TOP, 0, 48); grade_label.set_anchor_and_offset(SIDE_BOTTOM, 0, 86)
	grade_label.modulate.a = 0.0
	gc.add_child(grade_label)

	var gc_sub = _rl(str(earned_stars) + " / 3 stars", 13, C_SUB)
	gc_sub.set_anchor_and_offset(SIDE_LEFT, 0, 0); gc_sub.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	gc_sub.set_anchor_and_offset(SIDE_TOP, 0, 86); gc_sub.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	gc.add_child(gc_sub)

	Y += CARD_H + 20

	# ─── PROGRESS BAR ───────────────────────────────────────
	var BAR_H = 30
	var bar_track = _panel(C_SURFACE, C_DIM, BAR_H / 2)
	bar_track.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	bar_track.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	bar_track.set_anchor_and_offset(SIDE_TOP,    0, Y)
	bar_track.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + BAR_H)
	bar_track.modulate.a = 0.0
	col.add_child(bar_track)

	var bar_fill = Panel.new()
	bar_fill.anchor_left   = 0.0; bar_fill.anchor_right  = 0.0
	bar_fill.anchor_top    = 0.0; bar_fill.anchor_bottom = 1.0
	bar_fill.offset_left   = 4;   bar_fill.offset_right  = 0
	bar_fill.offset_top    = 4;   bar_fill.offset_bottom = -4
	var bf_s = StyleBoxFlat.new()
	bf_s.bg_color                   = C_ORANGE
	bf_s.corner_radius_top_left     = BAR_H / 2
	bf_s.corner_radius_top_right    = BAR_H / 2
	bf_s.corner_radius_bottom_left  = BAR_H / 2
	bf_s.corner_radius_bottom_right = BAR_H / 2
	bar_fill.add_theme_stylebox_override("panel", bf_s)
	bar_fill.modulate.a = 0.0
	bar_track.add_child(bar_fill)

	# Label color: dark when bar covers it (>=50%), bright gold when uncovered (<50%)
	var bar_lbl_color = Color(0.08, 0.05, 0.01) if pct >= 50 else Color(1.00, 0.80, 0.15)
	var bar_lbl = _rl(str(pct) + "%", 14, bar_lbl_color)
	bar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_track.add_child(bar_lbl)
	result_overlay.set_meta("bar_lbl",     bar_lbl)
	result_overlay.set_meta("bar_pct",     pct)

	result_overlay.set_meta("bar_fill",   bar_fill)
	result_overlay.set_meta("bar_track",  bar_track)
	result_overlay.set_meta("target_pct", target_frac)

	Y += BAR_H + 24

	# ─── STARS ──────────────────────────────────────────────
	var STAR_SZ  = 70
	var STAR_GAP = 20
	var star_sx  = (COL_W - (3 * STAR_SZ + 2 * STAR_GAP)) / 2

	star_labels.clear()
	for i in range(3):
		var star = Label.new()
		star.text                 = "★"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 56)
		var sx = star_sx + i * (STAR_SZ + STAR_GAP)
		star.set_anchor_and_offset(SIDE_LEFT,   0, sx)
		star.set_anchor_and_offset(SIDE_RIGHT,  0, sx + STAR_SZ)
		star.set_anchor_and_offset(SIDE_TOP,    0, Y)
		star.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + STAR_SZ)
		star.scale        = Vector2.ZERO
		star.pivot_offset = Vector2(STAR_SZ / 2.0, STAR_SZ / 2.0)
		star.modulate.a   = 0.0
		col.add_child(star)
		star_labels.append(star)

	Y += STAR_SZ + 22

	# ─── NOTE PANEL ─────────────────────────────────────────
	var NOTE_H = 70
	var note_panel = _panel(C_SURFACE, C_DIM, 10)
	note_panel.set_anchor_and_offset(SIDE_LEFT,   0, 0)
	note_panel.set_anchor_and_offset(SIDE_RIGHT,  1, 0)
	note_panel.set_anchor_and_offset(SIDE_TOP,    0, Y)
	note_panel.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + NOTE_H)
	col.add_child(note_panel)

	result_note_label = Label.new()
	result_note_label.text                 = note_text
	result_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_note_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	result_note_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	result_note_label.add_theme_font_size_override("font_size", 17)
	result_note_label.add_theme_color_override("font_color", C_TEXT)
	result_note_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_note_label.offset_left  = 24
	result_note_label.offset_right = -24
	result_note_label.modulate.a   = 0.0
	note_panel.add_child(result_note_label)

	Y += NOTE_H + 28

	# ─── BUTTONS ────────────────────────────────────────────
	var BTN_H   = 52
	var BTN_W   = 260
	var BTN_GAP = 16
	var bx      = (COL_W - BTN_W * 2 - BTN_GAP) / 2

	# Try Again — dark outlined
	retry_btn = Button.new()
	retry_btn.text = "↺   TRY AGAIN"
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.set_anchor_and_offset(SIDE_LEFT,   0, bx)
	retry_btn.set_anchor_and_offset(SIDE_RIGHT,  0, bx + BTN_W)
	retry_btn.set_anchor_and_offset(SIDE_TOP,    0, Y)
	retry_btn.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + BTN_H)
	retry_btn.modulate.a = 0.0
	retry_btn.add_theme_stylebox_override("normal", _btn_s(C_SURFACE, C_BORDER, 14))
	retry_btn.add_theme_stylebox_override("hover",  _btn_s(Color(0.30, 0.20, 0.06, 1.0), C_ORANGE, 14))
	retry_btn.add_theme_color_override("font_color", C_GOLD)
	retry_btn.pressed.connect(_retry_quiz)
	col.add_child(retry_btn)

	# Back to Menu — filled orange
	var bx2 = bx + BTN_W + BTN_GAP
	back_btn = Button.new()
	back_btn.text = "☰   BACK TO MENU"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.set_anchor_and_offset(SIDE_LEFT,   0, bx2)
	back_btn.set_anchor_and_offset(SIDE_RIGHT,  0, bx2 + BTN_W)
	back_btn.set_anchor_and_offset(SIDE_TOP,    0, Y)
	back_btn.set_anchor_and_offset(SIDE_BOTTOM, 0, Y + BTN_H)
	back_btn.modulate.a = 0.0
	back_btn.add_theme_stylebox_override("normal", _btn_s(C_ORANGE,                    Color(0,0,0,0), 14))
	back_btn.add_theme_stylebox_override("hover",  _btn_s(Color(1.0, 0.62, 0.10, 1.0), Color(0,0,0,0), 14))
	back_btn.add_theme_color_override("font_color", Color(0.07, 0.04, 0.01))
	back_btn.pressed.connect(_go_back_to_level)
	col.add_child(back_btn)

	anim_time  = 0.0
	pulse_time = 0.0
	animating  = true

# ── micro helpers ─────────────────────────────────────────

func _rl(txt: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text                 = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _panel(bg: Color, border: Color, radius: int) -> Panel:
	var p = Panel.new()
	var s = StyleBoxFlat.new()
	s.bg_color                   = bg
	s.border_color               = border
	s.border_width_left          = 2
	s.border_width_right         = 2
	s.border_width_top           = 2
	s.border_width_bottom        = 2
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	p.add_theme_stylebox_override("panel", s)
	return p

func _btn_s(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color                   = bg
	s.border_color               = border
	s.border_width_left          = 2
	s.border_width_right         = 2
	s.border_width_top           = 2
	s.border_width_bottom        = 2
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _retry_quiz():
	get_tree().reload_current_scene()

func _go_back_to_level():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
