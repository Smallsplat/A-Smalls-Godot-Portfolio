extends Node

class_name MovementController

@export var character : CharacterBody2D
@export var wall_run_raycast: RayCast2D
@export var ground_raycast: RayCast2D
@export var edge_detector: RayCast2D
@export var debug_raycast: RayCast2D

# Movement Variables
@export var run_speed : float = 200.0
@export var max_speed : float = 2000.0
@export var acceleration : float = 20.0
@export var brake_force : float = 5.0
@export var jump_velocity : float = -200.0
@export var overspeed_multi = 1

@export var coyote_frames: float = 10
@export var coyote_jump_edge_finder_bonus: float = 10
@export var coyote_jump_distance: float = 50
@export var coyote_jump_hieght: float = -150

@export var double_jump_velocity : float = -100
@export var air_control_speed : float = 200.0
@export var air_control_force: float = 10.0

@export var minimum_wallrun_speed: float = 200
@export var wallrun_friction: float = 250
@export var wall_grab_length: float = 15.0
@export var wall_jump_distance: float = 250
@export var wall_jump_velocity: float = -100.0
@export var wall_jump_blocker: float = 0.2
@export var wall_jump_frame_buffer: float = 6
# Player managers
@export var state_machine : CharacterStateMachine
@export var animation_controller : AnimationController

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var on_ground : bool = true
var jumping : bool = false
var double_jump_valid : bool = true
var coyote_counter : float = 0
var wall_buffer_counter : float = 0
var wall_direction : float = 0
var coyote_time_active : bool = false
var overspeed_limiter : Vector2 = Vector2(0,0)
#Character velcoity normalised
var movement_direction_x : float = 0
#Speedboost when landing on a slope
var character_velocty_last_frame : Vector2 = Vector2(0,0)
# Ground Normals for SLiding
var ground_normal : Vector2 = Vector2(0,0)
var ground_forward_normal : Vector2 = Vector2(0,0)

func MovementPhysicsProcess(delta):
	debug_raycast.target_position = Vector2((character.velocity.normalized().x * abs(character.velocity.x)), (character.velocity.normalized().y* abs(character.velocity.y)))
	#Manage touching the Floor
	if character.is_on_floor():
		if not on_ground: 		# Change on_ground vairable to prevent function spam
			on_ground = true
			jumping = false
			state_machine.SwitchStates("landing")
			character.velocity.x += (character_velocty_last_frame.y/2) * (ground_forward_normal.y * movement_direction_x)# Speed boost on landing on slopes
	else:						# Check if we've fallen (off a ledge)
		if on_ground && state_machine.current_state != "wallrunning":
			coyote_time_active = true
			coyote_counter += 1
			if coyote_counter >= coyote_frames:
				coyote_time_active = false
				on_ground = false
				state_machine.SwitchStates("airal")
				coyote_counter = 0
	
	# Manage Gravity
	if not CurrentState(["wallrunning", "walljumping"]): 
		character.velocity.y += gravity * delta # Gravity
	elif CurrentState(["wallrunning", "walljumping"]):
		character.velocity.y -= overspeed_limiter.y
	
	# Manage Overspeed
	overspeed_limiter.x = ((character.velocity.x / run_speed)) * overspeed_multi
	overspeed_limiter.y = ((character.velocity.y / minimum_wallrun_speed) * overspeed_multi)
		
	# Simplify left/right	
	if (character.velocity.x > 0):
		movement_direction_x = 1
	#elif (character.velocity.x == 0):
		#movement_direction_x = 0
	else:
		movement_direction_x = -1
	
	# Get ground forward Normals
	ground_normal = ground_raycast.get_collision_normal()
	if movement_direction_x < 0:
		ground_forward_normal = Vector2(ground_normal.y, -ground_normal.x)
	elif movement_direction_x > 0:
		ground_forward_normal = Vector2(-ground_normal.y, ground_normal.x)
		
	# Coyote Jump Extender
	if (ground_raycast.get_collision_normal().x != 0):
		# This calculation is scuffed. We could do better, but this works for now.
		edge_detector.target_position.y = 25 + (18 * ((ground_raycast.get_collision_normal().y + 1)*2))
	else: 
		edge_detector.target_position.y = 18
	edge_detector.target_position.x = coyote_jump_edge_finder_bonus * movement_direction_x
	if not edge_detector.is_colliding() && CurrentState(["grounded","crouching"]):
		coyote_time_active = true
	else:
		coyote_time_active = false

	#Increase floor snapping for if we're on a slope to not bounce off it
	var floor_snap_var = 20 if ((CurrentState(["crouching"]) or GetFutureState() == "crouching") && ground_raycast.is_colliding() && (ground_raycast.get_collision_normal().x != 0))else 5
	character.floor_snap_length = floor_snap_var

	character_velocty_last_frame = character.velocity

func Jump(direction : Vector2): # Called From Player Controller
	#States we're allowed to jump is
	if CurrentState(["grounded", "airal", "landing", "wallrunning", "crouching"]):
		# Jumping while on the ground
		if CurrentState(["grounded", "crouching", "landing"]):
			jumping = true
			double_jump_valid = true
			on_ground = false
			#Are we in Coyote Time
			if coyote_time_active:
				coyote_time_active = false
				var coyote_boost = 2.5 if CurrentState(["crouching"]) else 1.0 #Coyote Time Crouch Boosting
				character.velocity.x += (coyote_jump_distance * direction.x) * coyote_boost
				character.velocity.y = coyote_jump_hieght
			else:
				character.velocity.y = jump_velocity
			state_machine.SwitchStates("airal")
			
		# Jumping while in the air
		elif CurrentState(["airal"]) && double_jump_valid:
			character.velocity.y = double_jump_velocity
			double_jump_valid = false
		
		# Jumping while wallrunning
		elif CurrentState(["wallrunning"]):
			state_machine.SwitchStates("walljumping")
			character.velocity.x += ((wall_direction *-1) * wall_jump_distance)
			#character.velocity.y += wall_jump_velocity
			await get_tree().create_timer(wall_jump_blocker).timeout
			state_machine.SwitchStates("airal")

func Move(direction : Vector2):
	TryWallRun()
	if CurrentState(["crouching"]) or (CurrentState(["landing"]) && GetFutureState() == "crouching"):
		ground_normal = ground_raycast.get_collision_normal()
		if movement_direction_x < 0:
			ground_forward_normal = Vector2(ground_normal.y, -ground_normal.x)
		elif movement_direction_x > 0:
				ground_forward_normal = Vector2(-ground_normal.y, ground_normal.x)
		if (ground_normal.x > 0 && character.velocity.x > 0) or (ground_normal.x < 0 && character.velocity.x < 0):
			character.velocity += ground_forward_normal*2
		else:
			character.velocity.x -= ground_forward_normal.x*2

	if CurrentState(["grounded"]) or (CurrentState(["landing"]) && (GetFutureState() == "grounded")):
		if direction.x:
			#Is the character trying to accelerated
			if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
				#If we're not at Ground Speed, accelerate to it
				if (character.velocity.x * movement_direction_x < run_speed):
					character.velocity.x += direction.x * acceleration
				#Else, slow down to Ground speed via overspeed Limiter
				elif(character.velocity.x * movement_direction_x != run_speed):
					character.velocity.x = move_toward(character.velocity.x, (run_speed * movement_direction_x), (overspeed_limiter.x * direction.x))
			#If we're not accelerating, break
			else:
				character.velocity.x += direction.x * brake_force
		#If we're not moving, stop via break
		else:
			character.velocity.x = move_toward(character.velocity.x, 0, brake_force)

	if CurrentState(["airal"]):
		if direction.x:
			#if we're trying to accelerate
			if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
				#If we're not at Air Speed, accelerate to it
				if (character.velocity.x * movement_direction_x < air_control_speed ): 
					character.velocity.x += direction.x * air_control_force
			elif (direction.x != 0):
				character.velocity.x += direction.x * brake_force
				
	if CurrentState(["wallrunning"]):
		if TryWallRun():
			wall_buffer_counter = 0
			if (abs(character_velocty_last_frame.x) < minimum_wallrun_speed) and (character.velocity.y * -1 <= minimum_wallrun_speed):
				character.velocity.y = minimum_wallrun_speed * -1
		else:
			wall_buffer_counter += 1
			if wall_buffer_counter >= wall_jump_frame_buffer:
				state_machine.SwitchStates("airal")

func EnterCrouch():
	if CurrentState(["grounded"]):
		state_machine.SwitchStates("crouching")

func ExitCrouch():
	if CurrentState(["crouching"]):
		character.state_machine.SwitchStates(character.state_machine.CalculateState())

func TryWallRun():
	wall_run_raycast.target_position = Vector2(((wall_grab_length + (character.velocity.x * get_physics_process_delta_time())) * character.direction.x), 0)
	if wall_run_raycast.is_colliding():
		if not CurrentState(["wallrunning", "walljumping"]):
			WallRunOnEnter()
		return true
	else:
		return false

func WallRunOnEnter():
	wall_direction = character.direction.x
	if(character.velocity.y * -1 <= minimum_wallrun_speed):
		character.velocity.y = abs(character_velocty_last_frame.x) * -1
	character.position.x = (wall_run_raycast.get_collision_point().x + (10 * movement_direction_x))
	character.velocity.x = 0
	state_machine.SwitchStates("wallrunning")

func CurrentState(requested_state : Array):
	for state in requested_state:
		if state_machine.states.find_key(state) != null:
			push_error("Requested Current State, " + state + ", is not a Valid state")
		if state_machine.current_state == state:
			return true
	return false

func GetFutureState():
	return character.state_machine.CalculateState()
