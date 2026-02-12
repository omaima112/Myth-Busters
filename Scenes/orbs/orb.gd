extends Node3D

@export var info_title: String = "Custom Title"
@export_multiline var info_text: String = "Nuclear Myth Busted!\n\nRadiation from plants is less than from a banana or flight. NST powers clean energy!"
@export var info_image: Texture2D  
@export var bob_height: float = 1.0
@export var bob_speed: float = 2.0
@export var spin_speed: float = 1.5

var start_y: float
var time: float = 0.0
var phase_offset: float = 0.0

func _ready():
	start_y = global_position.y
	phase_offset = randf() * TAU
	$TriggerArea.body_entered.connect(_on_car_entered)  # Connect in code (or editor)
	#$TriggerArea.body_exited.connect(_on_car_exited)  # Connect in code (or editor)
	print("Orb ready at: ", global_position)

func _process(delta):
	time += delta
	
	# Bobbing (sin wave up/down)
	var bob_offset = sin((time * bob_speed) + phase_offset) * bob_height * 0.5
	position.y = start_y + bob_offset
	
	# Gentle spin
	rotate_y(delta * spin_speed)
		
func _on_car_entered(body):
	if body.is_in_group("vehicles") or body.collision_layer & (1 << 1):  # Layer 2 = Vehicle
		GameManager.show_orb_popup(info_title, info_text, info_image)  # Show popup
		GameManager.collect_orb()  # Track collection
		queue_free()

func _on_car_exited(body):
	if body.is_in_group("vehicles") or body.collision_layer & (1 << 1):
		GameManager.hide_orb_popup()  # Hide popup
		
		
