extends Node

class_name CharacterStateMachine

@export var character : CharacterBody2D


enum states {grounded, airal, crouching, landing, wallrunning, walljumping, powerstance, roofslam}

@onready var current_state = states.keys()[states.grounded]

func SwitchStates(new_state : String):
	if VerifyNewState(new_state):
		StateOnExit(current_state)
		print (new_state)
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
		if CalculateState() == "crouching":
			character.movement_controller.ToggleCrouchHitbox(true)
		else:
			character.movement_controller.ToggleCrouchHitbox(false)
	if state == "airal":
		if character.movement_controller.jumping == true:
			character.animation_controller.Jump()
		else:
			character.animation_controller.Fall()
	if state == "wallrunning":
		character.animation_controller.WallRun()
	if state == "walljumping":
		character.animation_controller.Jump()
	if state == "roofslam":
		character.animation_controller.Jump()
	if state == "grounded":
		character.animation_controller.Move()
		character.movement_controller.ToggleCrouchHitbox(false)
	if state == "crouching":
		character.animation_controller.Slide()
		character.movement_controller.ToggleCrouchHitbox(true)

func StateOnExit(state : String):
	if state == "crouching":
		character.movement_controller.ToggleCrouchHitbox(false)

func CalculateState():
	if character.is_on_floor():
		if Input.is_action_pressed("crouch"):
			return "crouching"
		else:
			return "grounded"
	else:
		return "airal"
