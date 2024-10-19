extends CharacterBody2D

@onready var player_sprite : Sprite2D = $PlayerSprite
@onready var player_collider : CollisionShape2D = $PlayerCollidor
@onready var state_machine : CharacterStateMachine = $CharacterStateMachine
@onready var movement_controller : MovementController = $MovementController
@onready var animation_controller : AnimationController = $AnimationController
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var ui_controller : UIController = $UIController
@onready var floor_raycast : RayCast2D = $FloorRayCast
@onready var playback = animation_tree["parameters/playback"]
const camera = preload("res://Scripts/Character/player_camera.tscn")
const weapon = preload("res://Scripts/Character/Weapon/CharacterWeapon.tscn")
var player_camera
var player_weapon
var weapon_controller : WeaponController
var previous_velocity : Vector2 = Vector2(0, 0)

@export var camera_movement_speed : float = 15000
@export var camera_minimum_speed : float = 0.1
@export var camera_bounds : Vector2 = Vector2(0.35, 0.40)

var direction : Vector2 = Vector2.ZERO
var camera_position : RemoteTransform2D

var inverted : bool = false

func _ready():
	#Spawn Camera
	var cameras = get_tree().get_nodes_in_group("Camera")
	if cameras.size() == 0:
		instantiate_camera()
	else:
		player_camera = cameras[0]
	player_camera.position = self.position
	ui_controller.player_camera = player_camera
	ui_controller.OnSpawned()
	
	#Spawn Weapon
	var instanced_weapon = weapon.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_weapon)
	player_weapon = instanced_weapon
	weapon_controller = player_weapon.find_child("WeaponController")
	weapon_controller.character = self
	weapon_controller.OnSpawned()
	
	state_machine.SwitchStates(state_machine.CalculateState())

func instantiate_camera():
	var instanced_camera = camera.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_camera)
	player_camera = instanced_camera
	
	
func _physics_process(delta):
	animation_controller.AnimationPhysicsProcess()

	direction = Input.get_vector("left", "right", "up", "down") # Get the input direction
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		movement_controller.Jump(direction)
	# Handle Crouch
	if Input.is_action_just_pressed("crouch"):
		movement_controller.EnterCrouch()
		
	if Input.is_action_just_released("crouch"):
		movement_controller.ExitCrouch()
	if not Input.is_action_pressed("crouch") && state_machine.current_state == "crouching":
		movement_controller.ExitCrouch()
	
	if Input.is_action_just_pressed("fire"):
		weapon_controller.FireWeapon()
	get_global_mouse_position()
	# Move the player base don controlelr input direction
	movement_controller.Move(direction)
	
	# Request Movement_Controller Physics
	movement_controller.MovementPhysicsProcess(delta)
	
	if is_on_floor():
		var ground_normal = movement_controller.ground_raycast.get_collision_normal()
		var ground_forward_normal = Vector2(-ground_normal.y, ground_normal.x)
		self.rotation = move_toward(self.rotation, ground_forward_normal.angle(), 0.15)
		movement_controller.ground_raycast.rotation = move_toward(movement_controller.ground_raycast.rotation, -ground_forward_normal.angle(), 0.15)
	else:
		self.rotation = move_toward(self.rotation, 0, 0.15)
		movement_controller.ground_raycast.rotation = move_toward(movement_controller.ground_raycast.rotation, 0, 0.15)
	
	if movement_controller.movement_direction_x == 1:
		floor_raycast.position.x = 3
	else:
		floor_raycast.position.x = -3
	move_and_slide()

func _process(_delta):
	move_camera()

func IsOnFloor():
	if not (movement_controller.IsOneWayCollidor(floor_raycast) and velocity.y < 0) and floor_raycast.is_colliding():
		return true
	else:
		return false
	
func move_camera():
	if player_camera:

		var player_velocity = get_real_velocity()
		
		if abs(player_velocity.y) - abs(previous_velocity.y) > 0.01:
			if player_velocity.y > 0:
				player_velocity.y = previous_velocity.y + 0.01
			else:
				player_velocity.y = previous_velocity.y - 0.01
			
		# Add Player Velocity Offset
		var look_forward : Vector2 = Vector2((player_velocity.normalized().x * abs(player_velocity.x)), (player_velocity.normalized().y* abs(velocity.y) / 4))
		# Clamp Player Velocity to keep character on screen
		look_forward.x = clamp(look_forward.x,((get_viewport_rect().size.x * -camera_bounds.x)), get_viewport_rect().size.x * camera_bounds.y)
		look_forward.y = clamp(look_forward.y,((get_viewport_rect().size.y * -camera_bounds.y)), get_viewport_rect().size.y * camera_bounds.y)
		# Add Player Position
		look_forward = look_forward + self.position
		# Add Offset
		look_forward.y -= movement_controller.player_hitbox.shape.height
		
		#Adjust camera speed based on distance from characeter - further = faster
		var camera_speed: Vector2 = Vector2(abs(player_camera.position.x - look_forward.x),abs(player_camera.position.y + look_forward.y))
		#Adjust camera speed based on player velocity, - faster = faster
		camera_speed = Vector2((camera_speed.x / (camera_movement_speed / abs(player_velocity.x))), (camera_speed.y / (camera_movement_speed / abs(player_velocity.y))))

		# Adjust Camera speed if too slow
		if camera_speed.x < camera_minimum_speed:
			camera_speed.x = camera_minimum_speed
		if camera_speed.y < camera_minimum_speed:
			camera_speed.y = camera_minimum_speed
		
		#Finally move the damn camera
		player_camera.position.x = move_toward(player_camera.position.x, look_forward.x, camera_speed.x)
		player_camera.position.y = move_toward(player_camera.position.y, look_forward.y, camera_speed.y)
		
		previous_velocity = get_real_velocity()
	#else:
		#player_camera.position = self.position
