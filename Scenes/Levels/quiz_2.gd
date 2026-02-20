extends Control

@onready var question_label = $Panel/QuestionLabel
@onready var progress_label = $Panel/ProgressLabel
@onready var option_buttons = [
	$Panel/Option1,
	$Panel/Option2,
	$Panel/Option3,
	$Panel/Option4
]
@onready var next_button = $Panel/NextButton
@onready var stars_container = $Panel/Stars
@onready var star1 = $Panel/Stars/Star1
@onready var star2 = $Panel/Stars/Star2
@onready var star3 = $Panel/Stars/Star3
@onready var note_label = $Panel/NoteLabel

var current_question = 0
var score = 0
var selected_answer = -1

# Result screen nodes (built in code)
var result_overlay: Panel = null
var anim_time: float = 0.0
var animating: bool = false
var earned_stars: int = 0
var star_labels: Array = []
var score_ring_label: Label = null
var grade_label: Label = null
var result_note_label: Label = null
var back_btn: Button = null
var result_title: Label = null
var pulse_time: float = 0.0

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

func _make_panel_style(bg: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = 3
	s.border_width_right  = 3
	s.border_width_top    = 3
	s.border_width_bottom = 3
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
#  PROCESS — drives result screen animations
# ─────────────────────────────────────────────
func _process(delta: float):
	if not animating:
		return
	anim_time += delta
	pulse_time += delta

	# Pulse the back button glow
	if back_btn != null:
		var a = 0.75 + 0.25 * sin(pulse_time * 3.0)
		back_btn.modulate = Color(1.0, a, 0.0, 1.0)

	# Animate stars popping in one by one
	for i in range(star_labels.size()):
		var delay = 0.4 + i * 0.55
		if anim_time > delay:
			var t = clamp((anim_time - delay) / 0.35, 0.0, 1.0)
			var ease_t = 1.0 - pow(1.0 - t, 3.0)   # ease-out cubic
			if i < earned_stars:
				var sc = lerp(0.0, 1.0, ease_t)
				star_labels[i].scale = Vector2(sc, sc)
				star_labels[i].modulate = Color(1.0, 0.85, 0.0, ease_t)
			else:
				var sc = lerp(0.0, 0.85, ease_t)
				star_labels[i].scale = Vector2(sc, sc)
				star_labels[i].modulate = Color(0.35, 0.35, 0.35, ease_t * 0.7)

	# Fade-in score bar label and animate bar fill after stars
	if anim_time > 2.2:
		var t = clamp((anim_time - 2.2) / 0.5, 0.0, 1.0)
		if result_overlay != null and result_overlay.has_meta("bar_fill"):
			var bar_fill = result_overlay.get_meta("bar_fill")
			var bar_track = result_overlay.get_meta("bar_track")
			var target_pct = result_overlay.get_meta("target_pct")
			var fill_t = clamp((anim_time - 2.2) / 0.9, 0.0, 1.0)
			var ease_fill = 1.0 - pow(1.0 - fill_t, 3.0)
			var track_w = bar_track.size.x
			bar_fill.offset_right = track_w * target_pct * ease_fill
			bar_fill.modulate.a = clamp((anim_time - 2.2) / 0.5, 0.0, 1.0)
			bar_track.modulate.a = clamp((anim_time - 2.2) / 0.5, 0.0, 1.0)
		if grade_label:
			grade_label.modulate.a = t

	# Fade-in note label last
	if anim_time > 3.0:
		var t = clamp((anim_time - 3.0) / 0.6, 0.0, 1.0)
		if result_note_label:
			result_note_label.modulate.a = t
		if back_btn:
			back_btn.modulate.a = clamp((anim_time - 3.2) / 0.5, 0.0, 1.0)

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
		option_buttons[i].text = q["options"][i]
		option_buttons[i].disabled = false
		option_buttons[i].visible = true

	progress_label.text = "Question " + str(current_question + 1) + " / " + str(questions.size())
	selected_answer = -1
	next_button.disabled = true
	next_button.text = "Next >"

func _on_option_pressed(index: int):
	selected_answer = index

	var correct_index = questions[current_question]["correct"]

	for i in range(option_buttons.size()):
		option_buttons[i].disabled = true

		if i == correct_index:
			var s = _make_stylebox(Color(0.0, 0.9, 0.2), Color(0.0, 0.35, 0.08))
			option_buttons[i].add_theme_stylebox_override("normal", s)
			option_buttons[i].add_theme_stylebox_override("disabled", s)
			option_buttons[i].modulate = Color.WHITE
		elif i == index:
			var s = _make_stylebox(Color(0.95, 0.1, 0.1), Color(0.4, 0.04, 0.04))
			option_buttons[i].add_theme_stylebox_override("normal", s)
			option_buttons[i].add_theme_stylebox_override("disabled", s)
			option_buttons[i].modulate = Color.WHITE
		else:
			option_buttons[i].modulate = Color(0.6, 0.6, 0.6, 1.0)

	next_button.disabled = false

func _on_next_pressed():
	if selected_answer == -1:
		return

	var correct_index = questions[current_question]["correct"]
	if selected_answer == correct_index:
		score += 1

	current_question += 1
	if current_question < questions.size():
		load_question()
	else:
		show_results()

# ─────────────────────────────────────────────
#  BEAUTIFUL RESULT SCREEN
# ─────────────────────────────────────────────
func show_results():
	var percentage = (score * 100) / questions.size()

	# Calculate stars
	if score > 8:
		earned_stars = 3
	elif score > 6:
		earned_stars = 2
	elif score > 4:
		earned_stars = 1
	else:
		earned_stars = 0

	# Grade label
	var grade_text = ""
	var grade_color = Color.WHITE
	if earned_stars == 3:
		grade_text = "🏆  EXPERT!"
		grade_color = Color(1.0, 0.85, 0.0)
	elif earned_stars == 2:
		grade_text = "🎯  GREAT JOB!"
		grade_color = Color(0.9, 0.75, 0.2)
	elif earned_stars == 1:
		grade_text = "📚  KEEP LEARNING"
		grade_color = Color(0.7, 0.7, 0.7)
	else:
		grade_text = "💡  TRY AGAIN!"
		grade_color = Color(0.55, 0.55, 0.55)

	# Note text
	var note_text = ""
	if earned_stars <= 1:
		note_text = "Your learning journey isn't complete yet.\nReview the facts and try again!"
	else:
		note_text = "You are now well informed and free\nof misconceptions about Nuclear Power!"

	# Hide all quiz UI
	for btn in option_buttons:
		btn.visible = false
	question_label.visible = false
	progress_label.visible = false
	next_button.visible = false
	stars_container.visible = false
	note_label.visible = false

	# Build result overlay
	result_overlay = Panel.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.10, 0.10, 0.10, 0.96)
	result_overlay.add_theme_stylebox_override("panel", overlay_style)
	add_child(result_overlay)

	var card = Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left   = -280
	card.offset_top    = -265
	card.offset_right  =  270
	card.offset_bottom =  265
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	card_style.border_color = Color(1.0, 0.82, 0.0, 0.9)
	card_style.border_width_left   = 3
	card_style.border_width_right  = 3
	card_style.border_width_top    = 3
	card_style.border_width_bottom = 3
	card_style.corner_radius_top_left     = 24
	card_style.corner_radius_top_right    = 24
	card_style.corner_radius_bottom_left  = 24
	card_style.corner_radius_bottom_right = 24
	card_style.shadow_color = Color(1.0, 0.8, 0.0, 0.35)
	card_style.shadow_size  = 20
	card.add_theme_stylebox_override("panel", card_style)
	result_overlay.add_child(card)

	# TITLE
	result_title = Label.new()
	result_title.text = "QUIZ COMPLETE"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 46)
	result_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	result_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	result_title.offset_top    = 32
	result_title.offset_bottom = 82
	card.add_child(result_title)

	# DIVIDER
	var divider = Panel.new()
	divider.set_anchors_preset(Control.PRESET_TOP_WIDE)
	divider.offset_left   = 30
	divider.offset_right  = -30
	divider.offset_top    = 100
	divider.offset_bottom = 103
	var div_style = StyleBoxFlat.new()
	div_style.bg_color = Color(1.0, 0.82, 0.0, 0.6)
	divider.add_theme_stylebox_override("panel", div_style)
	card.add_child(divider)

	# PROGRESS BAR
	var bar_track = Panel.new()
	bar_track.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar_track.offset_left   = -230
	bar_track.offset_right  =  230
	bar_track.offset_top    = 131
	bar_track.offset_bottom = 171
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.22, 0.22, 0.22, 1.0)
	track_style.corner_radius_top_left     = 20
	track_style.corner_radius_top_right    = 20
	track_style.corner_radius_bottom_left  = 20
	track_style.corner_radius_bottom_right = 20
	bar_track.add_theme_stylebox_override("panel", track_style)
	card.add_child(bar_track)

	var bar_fill = Panel.new()
	bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_fill.offset_left   = 0
	bar_fill.offset_right  = 0
	bar_fill.offset_top    = 0
	bar_fill.offset_bottom = 0
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.82, 0.0, 1.0)
	fill_style.corner_radius_top_left     = 20
	fill_style.corner_radius_top_right    = 20
	fill_style.corner_radius_bottom_left  = 20
	fill_style.corner_radius_bottom_right = 20
	bar_fill.add_theme_stylebox_override("panel", fill_style)
	bar_track.add_child(bar_fill)

	var pct_label = Label.new()
	var pct = int((float(score) / float(questions.size())) * 100.0)
	pct_label.text = str(pct) + "%"
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	pct_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	pct_label.add_theme_font_size_override("font_size", 20)
	pct_label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.0))
	bar_track.add_child(pct_label)

	# Store refs for _process animation
	result_overlay.set_meta("bar_fill", bar_fill)
	result_overlay.set_meta("bar_track", bar_track)
	result_overlay.set_meta("target_pct", float(score) / float(questions.size()))
	score_ring_label = Label.new()
	score_ring_label.visible = false
	card.add_child(score_ring_label)

	# GRADE BADGE
	grade_label = Label.new()
	grade_label.text = grade_text
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_label.add_theme_font_size_override("font_size", 32)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	grade_label.offset_left   = -230
	grade_label.offset_right  =  230
	grade_label.offset_top    = 199
	grade_label.offset_bottom = 243
	grade_label.modulate.a = 0.0
	card.add_child(grade_label)

	# STARS ROW
	var stars_row = HBoxContainer.new()
	stars_row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	stars_row.offset_left   = -150
	stars_row.offset_right  =  150
	stars_row.offset_top    = 271
	stars_row.offset_bottom = 341
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 14)
	card.add_child(stars_row)

	star_labels.clear()
	for i in range(3):
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 64)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.scale = Vector2.ZERO
		star.pivot_offset = Vector2(32, 32)
		star.modulate.a = 0.0
		stars_row.add_child(star)
		star_labels.append(star)

	# NOTE TEXT
	result_note_label = Label.new()
	result_note_label.text = note_text
	result_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_note_label.add_theme_font_size_override("font_size", 19)
	result_note_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	result_note_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	result_note_label.offset_left   = -230
	result_note_label.offset_right  =  230
	result_note_label.offset_top    = 369
	result_note_label.offset_bottom = 431
	result_note_label.modulate.a = 0.0
	card.add_child(result_note_label)

	# BACK BUTTON
	back_btn = Button.new()
	back_btn.text = "☰ BACK TO MENU"
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back_btn.offset_left   = 60
	back_btn.offset_right  = -60
	back_btn.offset_top    = -86
	back_btn.offset_bottom = -32
	back_btn.modulate.a = 0.0
	var btn_normal = _make_panel_style(Color(0.22, 0.19, 0.02, 1.0), Color(1.0, 0.82, 0.0), 22)
	back_btn.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover = _make_panel_style(Color(0.35, 0.30, 0.02, 1.0), Color(1.0, 0.95, 0.3), 22)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	back_btn.pressed.connect(_go_back_to_level)
	card.add_child(back_btn)

	# Start animation
	anim_time  = 0.0
	pulse_time = 0.0
	animating  = true

func display_stars(count: int):
	var dim  = Color(0.3, 0.3, 0.3, 1.0)
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	stars_container.visible = true
	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim

func _go_back_to_level():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
