extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100

@onready var state_machine : CharacterStateMachine = $CharacterStateMachine
@onready var movement_controller : MovementController = $MovementController
@onready var animation_controller : AnimationController = $AnimationController
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var playback = animation_tree["parameters/playback"]
@onready var camera_position : RemoteTransform2D = $RemoteCameraTransform2D
# Get the gravity from the project settings to be synced with RigidBody nodes.
var direction : Vector2 = Vector2.ZERO
	
func _physics_process(delta):
	animation_controller.AnimationPhysicsProcess()
	movement_controller.MovementPhysicsProcess(delta)
	
	direction = Input.get_vector("left", "right", "up", "down") # Get the input direction
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		movement_controller.Jump(direction)
	
	if Input.is_action_pressed("crouch"):
		movement_controller.EnterCrouch()
	else:
		movement_controller.ExitCrouch()
		
	movement_controller.Move(direction)
	move_and_slide()

func tick():
	move_camera()

func move_camera():
	var look_forward : Vector2 = Vector2((velocity.normalized().x * abs(velocity.x)), (velocity.normalized().y* abs(velocity.y)))
	look_forward = look_forward.clamp((get_viewport_rect().size * -0.25), get_viewport_rect().size * 0.25) 
	var camera_speed: Vector2 = Vector2(abs(camera_position.position.x - look_forward.x),abs(camera_position.position.y - look_forward.y))
	camera_speed = Vector2(camera_speed.x / 100, camera_speed.y / 100)
	print (camera_speed)
	camera_position.position.x = move_toward(camera_position.position.x, look_forward.x, camera_speed.x)
	camera_position.position.y = move_toward(camera_position.position.y, look_forward.y, camera_speed.y)
