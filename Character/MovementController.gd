extends Node

class_name MovementController

@export var character : CharacterBody2D

# Movement Variables
@export var speed : float = 200.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100

# Player managers
@export var state_machine : CharacterStateMachine
@export var animation_controller : AnimationController

func jump():
	if (state_machine.current_state == "grounded"):
		character.velocity.y = jump_velocity
		state_machine.SwitchStates("airal")
		animation_controller.Jump()
	elif (state_machine.current_state == "grounded"):
		character.velocity.y = double_jump_velocity
		
func move(direction):
	if direction.x:
		character.velocity.x = direction.x * speed
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, speed)
