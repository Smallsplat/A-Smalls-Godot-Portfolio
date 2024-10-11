extends Node

class_name UIController

@export var character : CharacterBody2D

var player_camera
var speedometer

# Called when the node enters the scene tree for the first time.
func OnSpawned():
	speedometer = player_camera.find_child("Speedometer")
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	UpdateSpeedometer(snapped(character.velocity.length(), 1))

func UpdateSpeedometer(speed):
	speedometer.text = str("Speed : ", speed)
