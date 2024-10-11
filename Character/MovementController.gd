extends Node

class_name MovementController

@export_group("Initialisers")
@export var character : CharacterBody2D
@export var ground_raycast: RayCast2D
@export var edge_detector: RayCast2D
@export var roof_raycast_right: RayCast2D
@export var roof_raycast_left: RayCast2D
@export var wall_raycast_head: RayCast2D
@export var wall_raycast_chest: RayCast2D
@export var wall_raycast_legs: RayCast2D
@export var state_machine : CharacterStateMachine
@export var animation_controller : AnimationController
@export var player_hitbox: CollisionShape2D

@export_group("Ground Movement")
@export var run_speed : float = 200.0
@export var max_speed : float = 2000.0
@export var acceleration : float = 20.0
@export var brake_force : float = 5.0
@export var jump_velocity : float = -200.0
@export var overspeed_cap : Vector2 = Vector2(400,200)
@export var overspeed_multi : Vector2 = Vector2(1,2)

@export_group("Sliding")
@export var min_slide_speed : float = 100.0
@export var slide_acceleration : float = 2
@export var slide_breaking : float = 1

@export_group("Coyote Jumping")
@export var coyote_frames: float = 10
@export var coyote_jump_edge_finder_bonus: float = 10
@export var coyote_jump_distance: float = 50
@export var coyote_jump_hieght: float = -150
@export var coyote_crouch_mod: float = 2

@export_group("Air Control")
@export var double_jump_velocity : float = -100
@export var air_control_speed : float = 200.0
@export var air_control_force: float = 10.0

@export_group("Wall Running and Jumping")
@export var minimum_wallrun_speed: float = 200
@export var wall_grab_length: float = 15.0
@export var wall_jump_distance: float = 250
@export var wall_jump_blocker: float = 0.3
@export var wall_jump_frame_buffer: float = 6

@export_group("Power Landing")
@export var min_powerlanding_fall_speed : float = 250
@export var min_powerlanding_launch_speed : float = 250
@export var powerlanding_divisor : float = 1.5
@export var powerlanding_y_ratio : float = 0.6
@export var powerlanding_blocker : float = 0.2

# Player managers

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var on_ground : bool = true
var jumping : bool = false
var sliding : bool = false
var double_jump_valid : bool = true
var coyote_counter : float = 0

var slide_velocity :Vector2 = Vector2(0,0)
#Wall Running
var wall_buffer_counter : float = 0
var wall_direction : float = 0
var wall_run_init_velocity : float = 0

var coyote_time_active : bool = false
var overspeed_limiter : Vector2 = Vector2(0,0)
#Character velcoity normalised
var movement_direction_x : float = 0
#Speedboost when landing on a slope
var character_velocty_last_frame : Vector2 = Vector2(0,0)
# Ground Normals for SLiding
var ground_normal : Vector2 = Vector2(0,0)
var ground_forward_normal : Vector2 = Vector2(0,0)
# Roof Launch Memeory
var roof_launch_blocker : bool = false
var roof_launch_velocity : float = 0
# Power Landing Memeory
var power_land_velo_blocker : bool = false
var power_land_timeout_blocker : bool = false
var power_land_veocity : Vector2 = Vector2(0,0)
var power_land_active : bool = false

func MovementPhysicsProcess(delta):
	
	# Manage Gravity
	if not CurrentState(["wallrunning", "walljumping"]): 
		character.velocity.y += gravity * delta # Gravity
	elif CurrentState(["wallrunning", "walljumping"]):
		character.velocity.y -= overspeed_limiter.y
	
	# Manage Overspeed
	overspeed_limiter.x = ((character.velocity.x / overspeed_cap.x)) * overspeed_multi.x
	overspeed_limiter.y = ((character.velocity.y / minimum_wallrun_speed) * overspeed_multi.y)
		
	# Simplify left/right	
	if (character.velocity.x > 0):
		movement_direction_x = 1
	elif (character.velocity.x < 0):
		movement_direction_x = -1
	
	# Coyote Jump Extender
	CalculateGroundForwardNormal()
	if (ground_raycast.get_collision_normal().x != 0):
		# This calculation is scuffed. We could do better, but this works for now.
		edge_detector.target_position.y = 26 + (24 * ((ground_raycast.get_collision_normal().y + 1)*2))
	else: 
		edge_detector.target_position.y = 24
	edge_detector.target_position.x = coyote_jump_edge_finder_bonus * movement_direction_x
	if not edge_detector.is_colliding() && CurrentState(["grounded","crouching", "landing"]):
		coyote_time_active = true
	else:
		coyote_time_active = false
		
	#Increase floor snapping for if we're on a slope to not bounce off it
	if on_ground:
		ground_raycast.target_position.y = 32
	else:
		ground_raycast.target_position.y = 45
	var floor_snap_var = 300 if ((CurrentState(["crouching"]) or (CurrentState(["landing"]) && GetFutureState() == "crouching")) && (ground_raycast.get_collision_normal().x != 0) && ground_raycast.is_colliding())else 10
	character.floor_snap_length = floor_snap_var
	if ((CurrentState(["crouching"]) or (CurrentState(["landing"]) && GetFutureState() == "crouching")) && ground_raycast.is_colliding()) && not jumping:
		character.apply_floor_snap()
		# Put the player Y velocity to the ground velocity because Floor snap doesnt actually snap palyer velocity to the floor because godot hates children and babys
		character.velocity.y = character.velocity.y * ground_forward_normal.y
	
	
	# Roof Blocker Velocity Calculation
	if RoofColliding() && not roof_launch_blocker:
		roof_launch_blocker = true
		roof_launch_velocity = (character_velocty_last_frame.y + (jump_velocity * -1))
	else:
		roof_launch_blocker = false
		
	if character.is_on_floor() && CurrentState(["airal"]):
		state_machine.SwitchStates("landing")

	# Power Landing Vecloity Calculation
	#If we're arial, Our character velocity is greater than the minimum, and over 60% of our velocity is vertical
	if CurrentState(["airal"]) && character.velocity.y > min_powerlanding_fall_speed && (character.velocity.y > (character.velocity.y + abs(character.velocity.x)) * powerlanding_y_ratio):
		if ground_raycast.is_colliding() && not power_land_velo_blocker && ground_forward_normal.y == 0:
			power_land_velo_blocker = true
			power_land_veocity = character_velocty_last_frame
	elif not ground_raycast.is_colliding() && power_land_velo_blocker:
		power_land_velo_blocker = false
		
	if not character.is_on_floor():#ground_raycast.is_colliding():
		slide_velocity = character.velocity
		
	#Manage touching the Floor
	if character.is_on_floor():
		coyote_counter = 0
		if not on_ground: 		# Change on_ground vairable to prevent function spam
			on_ground = true
			jumping = false
			state_machine.SwitchStates("landing")
			character.apply_floor_snap()
	else:						# Check if we've fallen (off a ledge)
		# Manage coyote time if we've fallen
		if on_ground && state_machine.current_state != "wallrunning":
			coyote_time_active = true
			coyote_counter += 1
			if coyote_counter >= coyote_frames:
				coyote_time_active = false
				on_ground = false
				state_machine.SwitchStates("airal")
				coyote_counter = 0

	character_velocty_last_frame = character.velocity

func Jump(direction : Vector2): # Called From Player Controller
	#States we're allowed to jump is
	if CurrentState(["grounded", "airal", "landing", "wallrunning", "crouching", "walljumping"]):
		# Jumping while on the ground
		if CurrentState(["grounded", "crouching", "landing"]):
			jumping = true
			double_jump_valid = true
			on_ground = false
			#Are we in Coyote Time
			if coyote_time_active:
				coyote_time_active = false
				var coyote_boost = coyote_crouch_mod if (CurrentState(["crouching"]) or GetFutureState() == "crouching") else 1.0 #Coyote Time Crouch Boosting
				character.velocity.x += (coyote_jump_distance * direction.x) * coyote_boost
				character.velocity.y = coyote_jump_hieght * (1 + abs(ground_forward_normal.y)/4)
				state_machine.SwitchStates("airal")
			#Make sure we're not Power landing
			elif not power_land_active:
				character.velocity.y = jump_velocity * (1 + abs(ground_forward_normal.y)/4)
				state_machine.SwitchStates("airal")
			
		# Jumping while in the air
		elif CurrentState(["airal", "walljumping"]):
			# Roof Slam
			if RoofColliding():
				character.velocity.y = roof_launch_velocity + abs(character.velocity.x / 4)
				character.velocity.x = character.velocity.x / 4
				state_machine.SwitchStates("roofslam")
				await get_tree().create_timer(0.2).timeout
				state_machine.SwitchStates(GetFutureState())
			# Double Jump
			elif double_jump_valid:
				if character.velocity.y >double_jump_velocity:
					character.velocity.y = double_jump_velocity
				else:
					character.velocity.y += double_jump_velocity
				double_jump_valid = false
		
		# Jumping while wallrunning
		elif CurrentState(["wallrunning"]):
			jumping = true
			state_machine.SwitchStates("walljumping")
			character.velocity.x += ((wall_direction *-1) * wall_jump_distance)
			await get_tree().create_timer(wall_jump_blocker).timeout
			jumping = false
			state_machine.SwitchStates("airal")

func Move(direction : Vector2): # INPUT FUNCTION - Inputs Character Inputs from Main Controller!
	# Try wallrun before we move
	if not CurrentState(["wallrunning"]):
		TryWallRun()
	
	#If we're landing, pressing the crouch button, and have a valid Power landing
	if (CurrentState(["landing"]) && GetFutureState() == "crouching") and power_land_velo_blocker and not power_land_active:
		PowerLandStart()
		
	#If we're sliding (Or about to be sliding while landing)
	elif (CurrentState(["crouching"]) or (CurrentState(["landing"]) && GetFutureState() == "crouching")) and not power_land_velo_blocker:
		if sliding:
			Slide()
		else: 
			SlideOnEnter()
	else:
		sliding = false
	
	#If we're Pressing a direction, We're Power-landed, and the ANiamtion timer is over, Launch the player.
	if direction.x and power_land_active and CurrentState(["landing"]) and (not power_land_timeout_blocker):
		PowerLandLaunch()
	
	
	
	#If we're grounded (Or about to be grounded while landing)
	if CurrentState(["grounded"]) or (CurrentState(["landing"]) && (GetFutureState() == "grounded")):
		Run(direction)
	
	#If we're airal
	if CurrentState(["airal"]):
		AirControl(direction)
				
	#If we're walllrunning
	if CurrentState(["wallrunning"]):
		WallRun()

	#Drop through 1 way floors
	if CurrentState(["grounded", "crouching", "landing"]):
		if IsOneWayCollidor(ground_raycast) && direction.y > 0:
			character.position.y += 1

func Run(direction : Vector2):
	if direction.x:
		#Is the character trying to accelerated
		if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
			#If we're not at Ground Speed, accelerate to it
			if (character.velocity.x * movement_direction_x < run_speed):
				character.velocity.x += direction.x * acceleration
			#Else, slow down to Ground speed via overspeed Limiter
			elif(character.velocity.x * movement_direction_x > overspeed_cap.x):
				character.velocity.x = move_toward(character.velocity.x, (run_speed * movement_direction_x), (overspeed_limiter.x * direction.x))
		#If we're not accelerating, break
		else:
			character.velocity.x += direction.x * brake_force
	#If we're not moving, stop via break
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, brake_force)
	
func SlideOnEnter():
	# Nerf slide boosts on uphills
	if sign(ground_normal.x) != sign(slide_velocity.x):
		slide_velocity.x *= 1 - abs(ground_normal.x / 4)
		
	if CurrentState(["landing"]):
		if not (sign(ground_normal.x) == sign(slide_velocity.x)):
			if abs(slide_velocity.y) < jump_velocity:
				slide_velocity.y = 0
			else:
				slide_velocity.y += jump_velocity
		character.velocity = ground_forward_normal * slide_velocity.length()
	else:
		character.velocity = ground_forward_normal * character_velocty_last_frame.length()
	slide_velocity = Vector2(0,0)
	sliding = true
	character.apply_floor_snap()
	
func Slide():
	# Work out if we should speed up Player direction based on ground slope
	if ((ground_normal.x > 0 && character.velocity.x > 0) or (ground_normal.x < 0 && character.velocity.x < 0)):
		character.velocity += ground_forward_normal*slide_acceleration
	# Work out if we should be slowing the player
	#	Is slideing uphill
	elif not ((ground_normal.x >= 0 && character.velocity.x > 0) or (ground_normal.x <= 0 && character.velocity.x < 0)):
		character.velocity.x -= ground_forward_normal.x*slide_breaking
	#	is trying to turn around
	elif not ((character.direction.x >= 0 && character.velocity.x > 0) or (character.direction.x <= 0 && character.velocity.x < 0)):
		character.velocity.x -= ground_forward_normal.x*slide_acceleration
	#	is is flat
	elif (ground_normal.x == 0) and (abs(character.velocity.x) > min_slide_speed):
		character.velocity.x -= ground_forward_normal.x*slide_breaking
	# If we're not slowing down and we're below minimum speed, reach it.
	elif (abs(character.velocity.x) < min_slide_speed) and (not power_land_active):
		character.velocity += ground_forward_normal*slide_acceleration
	character.apply_floor_snap()

func AirControl(direction : Vector2):
	if direction.x:
		#if we're trying to accelerate
		if (direction.x > 0 && character.velocity.x > 0) or (direction.x < 0 && character.velocity.x < 0):
			#If we're not at Air Speed, accelerate to it
			if (character.velocity.x * movement_direction_x < air_control_speed ): 
				character.velocity.x += direction.x * air_control_force
		elif (direction.x != 0):
			character.velocity.x += direction.x * brake_force

func WallRun():
	#Try and see if we should continue wall-running
	if TryWallRun():
		wall_buffer_counter = 0
		# Force Minimum wall Run Speed if wallrunning
		if (abs(character_velocty_last_frame.x) < minimum_wallrun_speed) and (character.velocity.y * -1 <= minimum_wallrun_speed):
			character.velocity.y = minimum_wallrun_speed * -1
	#If we're not wallrunning, buffer for wall=jumps
	else:
		wall_buffer_counter += 1
		#Raycast the top of the wall
		var space_state = character.get_world_2d().direct_space_state
		var ground_query = PhysicsRayQueryParameters2D.create(character.global_position + Vector2((wall_direction * (player_hitbox.shape.radius + 3)),0), character.global_position + Vector2((wall_direction * (player_hitbox.shape.radius + 3)), 50))
		var ground_result = space_state.intersect_ray(ground_query)
		#var wall_query = PhysicsRayQueryParameters2D.create(character.global_position + Vector2(0,default_rect_size/2),character.global_position + Vector2((wall_direction * (player_hitbox.shape.radius + 10)),default_rect_size/2), int(pow(2,2-1)))
		#var wall_result = space_state.intersect_ray(wall_query)
		
		#if we're crouched and theres no wall and theres floor to mantle, mantle
		# THIS IS COMMENTED OUT TO MADE A DECITION ABOUT LATER. ISSUE IS THAT RELEACING CROUCH IS UNINTUITIVE
		if not true:#Input.is_action_pressed("crouch") && ground_result && not wall_result:
			#Teleport to the top of the floor to ensure location
			character.position =  ground_result.position - Vector2(0,default_rect_size/2)
			#Stop character vertical movement to roll over the top
			character.velocity.x = (character.velocity.y / 1.5) * (character.direction.x * -1)
			character.velocity.y = 0
			on_ground = true
			state_machine.SwitchStates("crouching")
		elif wall_buffer_counter >= wall_jump_frame_buffer:
			#else, fling into the air
			state_machine.SwitchStates("airal")

func TryWallRun():
	var collision_raycast
	var target_X = ((wall_grab_length + abs((character.velocity.x * get_physics_process_delta_time()))) * character.direction.x)
	wall_raycast_head.target_position.x = target_X
	wall_raycast_chest.target_position.x = target_X
	wall_raycast_legs.target_position.x = target_X
	if wall_raycast_head.is_colliding() or wall_raycast_chest.is_colliding() or wall_raycast_legs.is_colliding():
		if wall_raycast_head.is_colliding() && not CurrentState(["crouching"]) && abs(wall_raycast_head.get_collision_normal().x) == 1:
			collision_raycast = wall_raycast_head
		elif wall_raycast_chest.is_colliding() && not CurrentState(["crouching"]) && abs(wall_raycast_chest.get_collision_normal().x) == 1:
			collision_raycast = wall_raycast_chest
		elif wall_raycast_legs.is_colliding() && abs(wall_raycast_legs.get_collision_normal().x) == 1:
			collision_raycast = wall_raycast_legs
		else:
			return false
		if not CurrentState(["wallrunning", "walljumping"]):
			if not (IsOneWayCollidor(collision_raycast)):
				WallRunOnEnter(collision_raycast)
		return true
	return false

func WallRunOnEnter(raycast : RayCast2D):
	#Initalise Wall Climb by launching the player up and killing horisontal velocity
	jumping = false
	wall_direction = character.direction.x
	if(character.velocity.y * -1 <= minimum_wallrun_speed):
		character.velocity.y = abs(character_velocty_last_frame.x) * -1
	
	#Set character variables
		#Unrotate if rotated
	character.rotation = 0
		#Stop X velocity
	character.velocity.x = 0
		# Get wall Corodinates and set palyer upon them
	var collidor = raycast.get_collider()
	#If theres no collidors return false
	if not collidor == null:
		var raycast_collsion_point = raycast.get_collision_point() + (Vector2(4,0) * character.direction.x)
		var tilemap = raycast.get_collider()
		#Get the cell
		var cell = collidor.local_to_map(raycast_collsion_point)
		#Get the cells world cornidates
		var tile_center_pos = tilemap.map_to_local(cell)
		#Add half cell Size + half Character Size * Opposite of character direction
		character.position.x = (tile_center_pos.x + ((16 + 8) * -character.direction.x))
	
	state_machine.SwitchStates("wallrunning")

func EnterCrouch():
	if CurrentState(["grounded"]):
		state_machine.SwitchStates("crouching")

func ExitCrouch():
	if CurrentState(["crouching"]):
		character.state_machine.SwitchStates(character.state_machine.CalculateState())

func PowerLandStart():
	character.velocity = Vector2(0,0)
	power_land_active = true
	character.animation_controller.Landed()
	power_land_timeout_blocker = true
	await get_tree().create_timer(powerlanding_blocker).timeout
	power_land_timeout_blocker = false

func PowerLandLaunch():
	var launch_speed = ((power_land_veocity.y) / powerlanding_divisor) * character.direction.x
	if abs(launch_speed) < abs(min_powerlanding_launch_speed):
		character.velocity.x = min_powerlanding_launch_speed * character.direction.x
	else:
		character.velocity.x = ((power_land_veocity.y) / powerlanding_divisor) * character.direction.x
	state_machine.SwitchStates(GetFutureState())
	power_land_active = false
	power_land_velo_blocker = false

func IsOneWayCollidor(raycast : RayCast2D):
	var collidor = raycast.get_collider()
	#If theres no collidors return false
	if collidor == null:
		return false
	#else get the collisoon point
	var raycast_collsion_point = raycast.get_collision_point() + (Vector2(4,0) * character.direction.x)
	#Get the cell
	var cell = collidor.local_to_map(raycast_collsion_point)
	#Get the cell Data
	var data = collidor.get_cell_tile_data(0,cell)
	if data != null:
		if data.is_collision_polygon_one_way(0,0):
			return true
		else:
			return false
	return false



func CurrentState(requested_state : Array):
	for state in requested_state:
		if not state_machine.states.find_key(state) == null:
			push_error("Requested Current State, " + state + ", is not a Valid state")
		if state_machine.current_state == state:
			return true
	return false

func GetFutureState():
	return character.state_machine.CalculateState()

@onready var default_rect_size : float = player_hitbox.shape.height

func ToggleCrouchHitbox(is_crouching : bool):
	if is_crouching:
		player_hitbox.shape.height = (default_rect_size*0.4)
		player_hitbox.position.y = 13 #ground_raycast.get_collision_point().y - character.position.y - ((default_rect_size*0.4)/ 2)#13
		roof_raycast_right.position.y = 7
		roof_raycast_right.target_position.y = -21
		roof_raycast_left.position.y = 7
		roof_raycast_left.target_position.y = -21
		character.apply_floor_snap()
	else:
		player_hitbox.shape.height = default_rect_size
		player_hitbox.position.y = 0
		roof_raycast_right.position.y = -21
		roof_raycast_right.target_position.y = -10
		roof_raycast_left.position.y = -21
		roof_raycast_left.target_position.y = -10
		character.apply_floor_snap()

func CalculateGroundForwardNormal():
	ground_normal = ground_raycast.get_collision_normal()
	if movement_direction_x < 0:
		ground_forward_normal = Vector2(ground_normal.y, -ground_normal.x)
	elif movement_direction_x > 0:
		ground_forward_normal = Vector2(-ground_normal.y, ground_normal.x)

func RoofColliding():
	if roof_raycast_right.is_colliding() or roof_raycast_left.is_colliding():
		return true
	return false
