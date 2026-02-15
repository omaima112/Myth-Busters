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
var collected: bool = false

func _ready():
	start_y = global_position.y
	phase_offset = randf() * TAU
	$TriggerArea.body_entered.connect(_on_car_entered)
	print("🎯 Orb ready: ", info_title)

func _process(delta):
	if collected:
		return
		
	time += delta
	
	# Bobbing (sin wave up/down)
	var bob_offset = sin((time * bob_speed) + phase_offset) * bob_height * 0.5
	position.y = start_y + bob_offset
	
	# Gentle spin
	rotate_y(delta * spin_speed)
		
func _on_car_entered(body):
	if collected:
		return
		
	# Check if player/vehicle hit it
	if body.is_in_group("vehicles") or body.collision_layer & (1 << 1):
		collected = true
		print("✨ COLLECTED: ", info_title)
		
		# ✅ SEPARATED: Play sound independently (completely separate)
		play_sound_only()
		
		# ✅ SEPARATED: Show popup and remove orb instantly (no sound link)
		GameManager.collect_orb()
		GameManager.show_orb_popup(info_title, info_text, info_image)
		queue_free()
		
		print("✅ Popup shown, orb removed instantly")
		print("🔊 Sound playing independently")

func play_sound_only():
	"""Play sound completely independently - not linked to anything"""
	# Create a completely separate audio player (not a child)
	var audio_player = AudioStreamPlayer3D.new()
	
	# Load the correct path
	var sound = load("res://Scenes/driken5482-retro-coin-1-236677.mp3")
	
	if sound == null:
		print("❌ Sound file not found at: res://Scenes/driken5482-retro-coin-1-236677.mp3")
		return
	
	print("✅ Sound loaded from correct path")
	audio_player.stream = sound
	audio_player.bus = &"Master"
	
	# Add to scene root (not to orb, so it survives orb deletion)
	get_tree().root.add_child(audio_player)
	
	print("🔊 Playing sound...")
	audio_player.play()
	
	# Clean up when done (completely independent)
	audio_player.finished.connect(func(): 
		print("🔊 Sound finished, cleaning up audio player")
		audio_player.queue_free()
	)

func _on_car_exited(body):
	if body.is_in_group("vehicles") or body.collision_layer & (1 << 1):
		if not collected:
			GameManager.hide_orb_popup()
