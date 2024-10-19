extends Node

class_name WeaponController

var movement_controller : MovementController
var character : CharacterBody2D
var inverted : bool = false
# Called when the node enters the scene tree for the first time.
func OnSpawned():
	movement_controller = character.movement_controller

func FireWeapon():
	var LaunchDirection = (character.position - character.get_global_mouse_position()).normalized()
	if inverted:
		print (LaunchDirection)
		movement_controller.LaunchPlayer(LaunchDirection, 200)
	else:
		movement_controller.LaunchPlayer(-LaunchDirection, 200)
