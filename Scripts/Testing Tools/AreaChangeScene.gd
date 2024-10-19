extends Area2D

@export var player : Node2D
@export var new_scene : String

func _ready():
	connect("body_entered", BodyEntered)

func BodyEntered(body: Node2D):
	if body == player:
		call_deferred("ChangeLevel")

func ChangeLevel():
	get_tree().change_scene_to_file(new_scene)
