extends Node

class_name MovementController

@export var character : CharacterBody2D

# Movement Variables
@export var run_speed : float = 200.0
@export var max_speed : float = 2000.0
@export var acceleration : float = 20.0
@export var brake_force : float = 5.0
@export var jump_velocity : float = -200.0
@export var coyote_frames: float = 6
@export var double_jump_velocity : float = -100
@export var air_control_speed : float = 200.0
@export var air_control_force: float = 10.0

# Player managers
@export var state_machine : CharacterStateMachine
@export var animation_controller : AnimationController

var on_ground : bool = true
var jumping : bool = false
var double_jump_valid : bool = true
var coyote_counter = 0
var coyote_time_active = false

func _physics_process(_delta):
	
	#Manage touching the Floor
	if character.is_on_floor():
		if not on_ground: 		# Change on_ground vairable to prevent function spam
			on_ground = true
			jumping = false
			state_machine.SwitchStates("landing")
	else:						# Check if we've fallen (off a ledge)
		if on_ground:
			coyote_time_active = true
			coyote_counter += 1
			if coyote_counter >= coyote_frames:
				coyote_time_active = false
				on_ground = false
				state_machine.SwitchStates("airal")
				coyote_counter = 0

func jump():
	if ValidJump():
		if (state_machine.current_state == "grounded"): 
			jumping = true
			double_jump_valid = true
			on_ground = false
			character.velocity.y = jump_velocity
			state_machine.SwitchStates("airal")
		elif (state_machine.current_state == "airal") && double_jump_valid:
			character.velocity.y = double_jump_velocity
			double_jump_valid = false
		
func move(direction):
	if state_machine.current_state == "grounded":
		if direction.x:
			if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
				if (character.velocity.x * direction.x < run_speed):
					character.velocity.x += direction.x * acceleration
				else:
					character.velocity.x = direction.x * run_speed
			else:
				character.velocity.x += direction.x * brake_force
		else:
				character.velocity.x = move_toward(character.velocity.x, 0, brake_force)

	elif state_machine.current_state == "airal":
		if direction.x:
			if (character.velocity.x * direction.x < air_control_speed):
				character.velocity.x += direction.x * air_control_force
			else:
				character.velocity.x = direction.x * air_control_speed		

func ValidJump():
	var validstates = ["grounded", "airal", "landed"]
	for state in validstates:
		if state_machine.current_state == state:
			return true
	return false
