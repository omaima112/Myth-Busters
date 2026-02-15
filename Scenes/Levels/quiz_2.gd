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

var questions = [
	{
		"question": "What percentage of global electricity comes from nuclear power?",
		"options": ["5%", "10%", "25%", " 50%"],
		"correct": 1
	},
	{
		"question": "What is the typical radiation dose from ONE CT scan?",
		"options": ["0.02 mSv", "1 mSv", "1-6 mSv", "7-10 mSv"],
		"correct": 3
	},
	{
		"question": "How much CO₂ does nuclear energy avoid annually?",
		"options": ["1 billion tons", "2 billion tons", "3 billion tons", "4 billion tons"],
		"correct": 1
	},
	{
		"question": "How many deaths does coal-caused air pollution cause annually worldwide?",
		"options": ["10,000+", "500,000+", "800,000+", "1,000,000"],
		"correct": 2
	},
	{
		"question": "Where does most of our daily radiation exposure come from?",
		"options": ["Nuclear power plants", "Cell phones", "Natural sources", "Medical X-rays"],
		"correct": 2
	},
	{
		"question": "What does ALARA stand for in radiation safety?",
		"options": ["As Low As Reasonably Achievable", "Always Low And Reliable Administration", "Advanced Laser And Radiation Application", "Avoid Long-term Accumulated Radiation Absorption"],
		"correct": 0
	},
	{
		"question": "Which releases MORE radiation into the environment?",
		"options": ["Nuclear power plant vicinity", "Coal plant vicinity", "They're exactly the same", "Neither releases radiation"],
		"correct": 1
	},
	{
		"question": "WHow much space does 60 years of US nuclear waste occupy?",
		"options": ["10 football fields", "One football field", "Entire state of Nevada", "One swimming pool"],
		"correct": 1
	},
	{
		"question": "Which energy source causes the FEWEST deaths per terawatt-hour (TWh)?",
		"options": ["Coal", "Oil", "Sola", "Nuclear"],
		"correct": 3
	},
	{
		"question": "How many countries are currently members of the Nuclear Non-Proliferation Treaty (NPT)?",
		"options": ["176", "180", "190", "195"],
		"correct": 1
	}
]

func _ready():
	print("🟢 quiz_2.gd _ready() called!")
	
	# ✅ CRITICAL FIX: Ensure game is unpaused
	get_tree().paused = false
	
	# ✅ CRITICAL FIX: Set mouse mode AFTER unpausing
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# ✅ CRITICAL FIX: Connect signals AFTER setting mouse mode
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	
	next_button.pressed.connect(_on_next_pressed)
	next_button.disabled = true
	
	print("✅ Quiz initialized with ", questions.size(), " questions")
	load_question()

func load_question():
	"""Load and display the current question"""
	if current_question >= questions.size():
		show_results()
		return

	var q = questions[current_question]
	question_label.text = q["question"]

	for i in range(option_buttons.size()):
		option_buttons[i].text = q["options"][i]
		option_buttons[i].disabled = false
		option_buttons[i].modulate = Color.WHITE
		option_buttons[i].visible = true

	progress_label.text = "Question " + str(current_question + 1) + " / " + str(questions.size())
	selected_answer = -1
	next_button.disabled = true
	next_button.text = "Next >"
	print("📝 Question ", current_question + 1, ": ", q["question"])

func _on_option_pressed(index: int):
	"""Called when an option button is clicked"""
	print("✅ Option ", index, " clicked!")  # ✅ DEBUG
	selected_answer = index
	for i in range(option_buttons.size()):
		option_buttons[i].modulate = Color.YELLOW if i == index else Color.WHITE
		option_buttons[i].disabled = true
	next_button.disabled = false

func _on_next_pressed():
	"""Called when Next button is pressed"""
	if selected_answer == -1:
		return

	var correct_index = questions[current_question]["correct"]
	if selected_answer == correct_index:
		print("✅ Correct!")
		score += 1
	else:
		print("❌ Wrong! Correct was: ", questions[current_question]["options"][correct_index])

	current_question += 1
	if current_question < questions.size():
		load_question()
	else:
		show_results()

func show_results():
	"""Show final score with stars and optional note"""
	var percentage = (score * 100) / questions.size()
	print("🏆 Quiz finished! Score: ", score, " / ", questions.size(), " (", percentage, "%)")

	# Hide question UI
	for button in option_buttons:
		button.visible = false

	# Show score in question label
	question_label.text = "Quiz Complete!\nYour Score: " + str(score) + " / " + str(questions.size())
	progress_label.text = str(percentage) + "%"

	# --- Star rating ---
	var earned_stars = 0
	if score > 8:
		earned_stars = 3
	elif score > 6:
		earned_stars = 2
	elif score > 4:
		earned_stars = 1
	else:
		earned_stars = 0

	display_stars(earned_stars)

	# --- Note for low performance ---
	
	if earned_stars <= 1:
		note_label.visible = true
		note_label.text = "YOUR LEARNING PROCESS IS NOT COMPLETED WELL. PLEASE TRY AGAIN!"
		
	elif score > 6:
		note_label.visible = true
		note_label.text = "CONGRATULATIONS! YOU ARE NOW WELL INFORMED AND CLEARED OF MISCONCEPTIONS ABOUT NUCLEAR POWER PLANTS"
	else:
		note_label.visible = false

	# Rewire next button to go back to level
	next_button.text = "Back to Menu"
	next_button.disabled = false
	next_button.pressed.disconnect(_on_next_pressed)
	next_button.pressed.connect(_go_back_to_level)

func display_stars(count: int):
	"""Light up earned stars gold, dim the rest"""
	var dim  = Color(0.3, 0.3, 0.3, 1.0)
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	stars_container.visible = true
	star1.modulate = gold if count >= 1 else dim
	star2.modulate = gold if count >= 2 else dim
	star3.modulate = gold if count >= 3 else dim
	print("⭐ Stars earned: ", count)

func _go_back_to_level():
	"""Return to level 2"""
	print("📍 Returning to level 2...")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
