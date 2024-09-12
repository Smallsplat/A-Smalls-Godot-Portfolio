extends Node

class_name AnimationController

@export var character : CharacterBody2D
@export var player_sprite : Sprite2D
@export var animation_tree : AnimationTree
@onready var playback = animation_tree["parameters/playback"]

func _physics_process(delta):
	DirectionSpriteFlip()

func DirectionSpriteFlip():
	animation_tree.set("parameters/Move/blend_position", character.direction.x) #Update walking Animations
	#Flip sprite based on direction
	if character.direction.x > 0:
		player_sprite.flip_h = false
	elif character.direction.x < 0:
		player_sprite.flip_h = true
		
func Landed():
	if (playback.get_current_node() == "Jump"):
		playback.travel("Landing")
		
func Jump():
	if (playback.get_current_node() == "Move"):
		playback.travel("Jump")

func _on_animation_tree_animation_finished(anim_name):
	if (anim_name == "Landing"):
		character.state_machine.SwitchStates("grounded")
