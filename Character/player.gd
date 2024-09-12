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
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var double_jump_valid : bool = true
var direction : Vector2 = Vector2.ZERO
var on_ground : bool = true

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		double_jump_valid = true

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		movement_controller.jump()
	
	if is_on_floor(): 			# Check if we've landed
		if not on_ground: 		# Change on_ground vairable to prevent function spam
			on_ground = true
			state_machine.SwitchStates("landing")
	else:						# Check if we've fallen (off a ledge)
		if on_ground:
			on_ground = false

	direction = Input.get_vector("left", "right", "up", "down") # Get the input direction
	movement_controller.move(direction)
	move_and_slide()
