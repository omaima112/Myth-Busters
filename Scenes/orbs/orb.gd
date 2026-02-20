extends Node3D

@export var info_title: String = "Custom Title"
@export_multiline var info_text: String = "Nuclear Myth Busted!\n\nRadiation from plants is less than from a banana or flight. NST powers clean energy!"
@export var info_image: Texture2D  
@export var info_voice: AudioStream  # 🎙️ drag any mp3/ogg/wav here in Inspector
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

func _process(delta):
	if collected:
		return
		
	time += delta
	
	# Bobbing (sin wave up/down)
	var bob_offset = sin((time * bob_speed) + phase_offset) * bob_height * 0.5
	position.y = start_y + bob_offset
	
	# Gentle spin
	rotate_y(delta * spin_speed)

# When orb is hidden (police chase), disable its trigger so it can't be collected
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if has_node("TriggerArea"):
			$TriggerArea.monitoring = visible
			$TriggerArea.monitorable = visible

func _on_car_entered(body):
	if collected:
		return

	# Only the PLAYER (vehicles group) can collect — enemy uses collision_layer 2
	if not body.is_in_group("vehicles"):
		return

	collected = true
	
	# Play sound independently (completely separate)
	play_sound_only()
	
	# Play voice if assigned
	if info_voice != null:
		play_voice_only()
	
	# Show popup and remove orb instantly
	GameManager.collect_orb()
	GameManager.show_orb_popup(info_title, info_text, info_image)
	queue_free()

func play_sound_only():
	"""Play sound completely independently - not linked to anything"""
	var audio_player = AudioStreamPlayer3D.new()
	
	var sound = load("res://Scenes/driken5482-retro-coin-1-236677.mp3")
	
	if sound == null:
		return
	
	audio_player.stream = sound
	audio_player.bus = &"Master"
	
	# Add to scene root (not to orb, so it survives orb deletion)
	get_tree().root.add_child(audio_player)
	audio_player.play()
	
	# Clean up when done
	audio_player.finished.connect(func(): 
		audio_player.queue_free()
	)

func play_voice_only():
	"""🎙️ Play voice clip — stops when popup is closed"""
	var voice_player = AudioStreamPlayer.new()
	voice_player.stream = info_voice
	voice_player.bus = &"Master"
	get_tree().root.add_child(voice_player)
	GameManager.active_voice_player = voice_player
	voice_player.play()
	voice_player.finished.connect(func():
		if GameManager.active_voice_player == voice_player:
			GameManager.active_voice_player = null
		voice_player.queue_free()
	)

func _on_car_exited(body):
	if body.is_in_group("vehicles") or body.collision_layer & (1 << 1):
		if not collected:
			GameManager.hide_orb_popup()
