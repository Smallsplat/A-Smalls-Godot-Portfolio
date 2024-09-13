extends Node

class_name CharacterStateMachine

@export var character : CharacterBody2D

enum states {grounded, airal, landing}

@onready var current_state = states.keys()[states.grounded]

func SwitchStates(new_state : String):
	if VerifyNewState(new_state):
		current_state = new_state
		StateOnEnter(current_state)

# Saftey Verification to catch typos
func VerifyNewState(new_state : String):
	for state in states.keys():
		if state == new_state:
			if state == current_state:
				return false
			else:
				return true
	push_warning("Requested New state, " + new_state + ", is not a Valid state")
	return false

# Manage and Call Aniamtions when changing state
func StateOnEnter(state : String):
	if state == "landing":
		character.animation_controller.Landed()
		#await get_tree().create_timer(0.2).timeout
		if state == "landing":
			SwitchStates("grounded")
	if state == "airal":
		if character.movement_controller.jumping == true:
			character.animation_controller.Jump()
		else:
			character.animation_controller.Fall()
