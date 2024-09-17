extends Node

class_name MovementController

@export var character : CharacterBody2D
@export var wall_run_raycast: RayCast2D
@export var ground_raycast: RayCast2D

# Movement Variables
@export var run_speed : float = 200.0
@export var max_speed : float = 2000.0
@export var acceleration : float = 20.0
@export var brake_force : float = 5.0
@export var jump_velocity : float = -200.0
@export var overspeed_multi = 1

@export var coyote_frames: float = 10
@export var coyote_jump_distance: float = 50
@export var coyote_jump_hieght: float = -150

@export var double_jump_velocity : float = -100
@export var air_control_speed : float = 200.0
@export var air_control_force: float = 10.0

@export var minimum_wallrun_speed: float = 200
@export var wall_grab_length: float = 10.0
@export var wall_jump_distance_multi: float = 1.1
@export var wall_jump_velocity: float = -100.0
@export var wall_jump_blocker: float = 0.2
# Player managers
@export var state_machine : CharacterStateMachine
@export var animation_controller : AnimationController

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var on_ground : bool = true
var jumping : bool = false
var double_jump_valid : bool = true
var coyote_counter : float = 0
var coyote_time_active : bool = false
var overspeed_limiter : float = 0
var is_crouching : bool = true
var movement_direction_x : float = 0

func MovementPhysicsProcess(delta):
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
	
	# Manage Gravity
	if (state_machine.current_state != "wallrunning"): 
		character.velocity.y += gravity * delta # Gravity
	
	# Manage Overspeed
	if (state_machine.current_state == "grounded"):
		overspeed_limiter = ((character.velocity.x / run_speed)) * overspeed_multi
		if (character.velocity.x < 0):
			overspeed_limiter * -1
			
	# Simplify left/right	
	if (character.velocity.x > 0):
		movement_direction_x = 1
	elif (character.velocity.x == 0):
		movement_direction_x = 0
	else:
		movement_direction_x = -1

func jump(direction : Vector2): # Called From Player Controller
	if ValidJump():
		# Jumping while on the ground
		if (state_machine.current_state == "grounded"):
			jumping = true
			double_jump_valid = true
			on_ground = false
			if coyote_time_active:
				coyote_time_active = false
				character.velocity.x += (coyote_jump_distance * direction.x)
				character.velocity.y = coyote_jump_hieght
			else:
				character.velocity.y = jump_velocity
			state_machine.SwitchStates("airal")
			
		# Jumping while in the air
		elif (state_machine.current_state == "airal") && double_jump_valid:
			character.velocity.y = double_jump_velocity
			double_jump_valid = false
		
		# Jumping while wallrunning
		elif (state_machine.current_state == "wallrunning"):
			state_machine.SwitchStates("walljumping")
			character.velocity.x += (character.velocity.y * direction.x * wall_jump_distance_multi)
			character.velocity.y += wall_jump_velocity
			await get_tree().create_timer(wall_jump_blocker).timeout
			state_machine.SwitchStates("airal")

func move(direction : Vector2):
	TryWallRun(direction)
	if state_machine.current_state == "grounded":
		#Are we crouching
		if is_crouching:
			print (ground_raycast.get_collision_normal())
			var ground_normal = ground_raycast.get_collision_normal()
			if (ground_normal.x > 0 && character.velocity.x > 0) or (ground_normal.x < 0 && character.velocity.x < 0):
				character.velocity.x += (ground_normal.x + 1) * movement_direction_x
				print (character.velocity.x)
				
		#If We're not crouching, walk
		else:
			if direction.x:
				#Is the character trying to accelerate
				if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
					#If we're not at Ground Speed, accelerate to it
					if (character.velocity.x * movement_direction_x < run_speed):
						character.velocity.x += direction.x * acceleration
					#Else, slow down to Ground speed via overspeed Limiter
					elif(character.velocity.x * movement_direction_x != run_speed):
						character.velocity.x = move_toward(character.velocity.x, (run_speed * movement_direction_x), (overspeed_limiter * direction.x))
						print ("Velocity ",character.velocity.x, ". Run speed ", run_speed, " Overspeed Limiter", overspeed_limiter)
				#If we're not accelerating, break
				else:
					character.velocity.x += direction.x * brake_force
			#If we're not moving, stop via break
			else:
				character.velocity.x = move_toward(character.velocity.x, 0, brake_force)

	elif state_machine.current_state == "airal":
		if direction.x:
			#if we're trying to accelerate
			if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
				#If we're not at Air Speed, accelerate to it
				if (character.velocity.x * movement_direction_x < air_control_speed ): 
					character.velocity.x += direction.x * air_control_force
			elif (direction.x != 0):
				character.velocity.x += direction.x * brake_force
				
	elif state_machine.current_state == "wallrunning":
		if TryWallRun(direction):
			pass
		else:
			state_machine.SwitchStates("airal")

func ValidJump(): 	# Checks to see if we're allowed to jump in the current state
	var validstates = ["grounded", "airal", "landed", "wallrunning"] 	# States we can jump in
	for state in validstates:
		if state_machine.current_state == state:
			return true
	return false

func TryWallRun(direction : Vector2):
	wall_run_raycast.target_position = Vector2((wall_grab_length * direction.x), 0)
	if wall_run_raycast.is_colliding():
		if state_machine.current_state != "wallrunning" and state_machine.current_state != "walljumping":
			WallRunOnEnter()
		return true
	else:
		return false

func WallRunOnEnter():
	if (abs(character.velocity.x) < minimum_wallrun_speed):
		character.velocity.y = minimum_wallrun_speed * -1
	else:
		character.velocity.y = abs(character.velocity.x) * -1
	character.velocity.x = 0
	state_machine.SwitchStates("wallrunning")


# Set State to wallrunning
# Set Veclotiy Y + vecloity X
# Stick to wall until wall jump or wall runs out
	#If jump while wallrunning, wall jump
	#Disable inputs while walljumping
	#State to Arial
