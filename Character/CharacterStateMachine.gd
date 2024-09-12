extends Node

class_name CharacterStateMachine

@export var character : CharacterBody2D

enum states {grounded, airal, landing}

@onready var current_state = states.keys()[states.grounded]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func SwitchStates(new_state):
	if VerifyNewState(new_state):
		if (new_state != current_state):
			current_state = new_state
			StateOnEnter(current_state)
	else:
		push_warning("Requested New state, " + new_state + ", is not a Valid state")

func VerifyNewState(new_state):
	for state in states.keys():
		if state == new_state:
			return true
	return false

func StateOnEnter(state):
	if state == "landing":
		character.animation_controller.Landed()
