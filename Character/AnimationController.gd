extends Node

class_name AnimationController

@export var character : CharacterBody2D
@export var player_sprite : Sprite2D
@export var animation_tree : AnimationTree
@onready var playback = animation_tree["parameters/playback"]

var power_land : float = 0
var animation_speed_adjustment : bool = true

# Jump ! 0 - Normal ! 1 - Wall ! 2 - roof !

func _ready():
	animation_tree.active = true

func VerifyAnimationSpeedAdjustment(state):
	var animation_speed_states : Array = ["grounded", "landing", "wallrunning", "crouching"]
	for allowed_state in animation_speed_states:
		if state == allowed_state:
			return true
	return false

func AnimationPhysicsProcess():
	DirectionSpriteFlip()
	animation_tree.set("parameters/Move/blend_position", character.direction.x) #Update walking Animations

	animation_speed_adjustment = VerifyAnimationSpeedAdjustment(character.state_machine.current_state)
	if animation_speed_adjustment:
		animation_tree.set("parameters/TimeScale/scale",(character.velocity.length()/character.movement_controller.run_speed))
	else:
		animation_tree.set("parameters/TimeScale/scale", 1)

#Play Turn around animation if player is trying to turn around
	#Ground
	if (playback.get_current_node() == "Move"):
		if (sign(character.direction.x) != sign(character.velocity.x)) and ((character.direction.x != 0) or (character.velocity.x > (character.movement_controller.run_speed / 2))):
			playback.travel("Move Turnaround")
	if (playback.get_current_node() == "Move Turnaround"):
		if (sign(character.direction.x) == sign(character.velocity.x)):
			playback.travel("Move")
			
	#Airal
	if (playback.get_current_node() == "Falling"):
		if ((sign(character.direction.x) != sign(character.velocity.x))) and (character.direction.x != 0):
			playback.travel("Airal Turnaround")
	if (playback.get_current_node() == "Airal Turnaround"):
		if (sign(character.direction.x) == sign(character.velocity.x)):
			playback.travel("Falling")

func DirectionSpriteFlip():
	#Flip sprite based on direction
	if (character.movement_controller.wall_direction != 0) and (character.state_machine.current_state == "walljumping" or character.state_machine.current_state == "wallrunning"):
		player_sprite.scale.x = character.movement_controller.wall_direction
	else:
		if character.velocity.x > 0:
			player_sprite.scale.x = 1
		elif character.velocity.x < 0:
			player_sprite.scale.x = -1
		
func Landed():
	if character.movement_controller.power_land_active == true:
		power_land = 1
	else:
		power_land = 0
	
	animation_tree.set("parameters/Landing/blend_position", power_land)
	
	if (playback.get_current_node() == "Falling") or (playback.get_current_node() == "Airal Turnaround"):
		playback.travel("Landing")
	elif (playback.get_current_node() == "Jump"):
		playback.travel("Landing")
	elif (playback.get_current_node() == "Slide Entry") && (power_land == 1):
		playback.travel("Landing")
		
func Jump():
	var jump_type = 0
	if character.state_machine.current_state == "walljumping":
		jump_type = 1
	if character.state_machine.current_state == "roofslam":
		jump_type = 2
	else:
		jump_type = 0
	animation_tree.set("parameters/Jump/blend_position", jump_type)
	playback.travel("Jump")

func Fall():
	playback.travel("Falling")
		
func WallRun():
	playback.travel("WallClimb")

func _on_animation_tree_animation_finished(anim_name):
	if (anim_name == "Landing"):
		if power_land == 0:
			if character.velocity.x == 0:
				playback.travel("Landing Exit")
			else:
				character.state_machine.SwitchStates(character.state_machine.CalculateState())

	if (anim_name == "Landing Exit"):
		character.state_machine.SwitchStates(character.state_machine.CalculateState())

func Move():
	if (playback.get_current_node() == "Slide"):
		playback.travel("Slide Exit")
	else:
		playback.travel("Move")
	
func Slide():
	if character.velocity.x == 0:
		playback.travel("Slide Pre Entry")
	else:
		playback.travel("Slide Entry")
