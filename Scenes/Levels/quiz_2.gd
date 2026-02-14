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
		"question": "What is the capital of France?",
		"options": ["London", "Berlin", "Paris", "Madrid"],
		"correct": 2
	},
	{
		"question": "What is 2 + 2?",
		"options": ["3", "4", "5", "6"],
		"correct": 1
	},
	{
		"question": "Which planet is closest to the Sun?",
		"options": ["Venus", "Mercury", "Earth", "Mars"],
		"correct": 1
	},
	{
		"question": "What is the largest ocean?",
		"options": ["Atlantic", "Indian", "Arctic", "Pacific"],
		"correct": 3
	},
	{
		"question": "Who wrote Romeo and Juliet?",
		"options": ["Marlowe", "Shakespeare", "Jonson", "Bacon"],
		"correct": 1
	},
	{
		"question": "What is the chemical symbol for Gold?",
		"options": ["Go", "Gd", "Au", "Ag"],
		"correct": 2
	},
	{
		"question": "In which year did the Titanic sink?",
		"options": ["1911", "1912", "1913", "1914"],
		"correct": 1
	},
	{
		"question": "What is the smallest prime number?",
		"options": ["0", "1", "2", "3"],
		"correct": 2
	},
	{
		"question": "Which country is home to the kangaroo?",
		"options": ["New Zealand", "Australia", "South Africa", "Brazil"],
		"correct": 1
	},
	{
		"question": "What is the speed of light?",
		"options": ["300,000 km/s", "150,000 km/s", "450,000 km/s", "600,000 km/s"],
		"correct": 0
	}
]

func _ready():
	print("🟢 quiz_2.gd _ready() called!")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
	next_button.text = "Back to Level"
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
