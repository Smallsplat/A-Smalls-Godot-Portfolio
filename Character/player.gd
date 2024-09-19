extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100

@onready var state_machine : CharacterStateMachine = $CharacterStateMachine
@onready var movement_controller : MovementController = $MovementController
@onready var animation_controller : AnimationController = $AnimationController
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var playback = animation_tree["parameters/playback"]

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
