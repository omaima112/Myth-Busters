extends Node3D

var time = 0.0
var base_height = 2.5
var bob_amount = 0.3
var bob_speed = 2.0
var rotation_speed = 1.0  # Rotation speed

func _ready():
	base_height = position.y
	

func _process(delta):
	time += delta
	
	# Bob up and down
	var bob = sin(time * bob_speed) * bob_amount
	position.y = base_height + bob
	
	# Rotate around Y axis (spin)
	rotation.y += delta * rotation_speed
