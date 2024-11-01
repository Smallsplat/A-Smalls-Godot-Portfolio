extends Area2D

@export var new_scene_path : String

@onready var new_scene = load(new_scene_path).instantiate()

var CurrentLevel
var player : Node2D
var awake : bool = false

func _ready():
	var ActiveLevels
	connect("body_entered", BodyEntered)
	ActiveLevels = get_tree().get_nodes_in_group("LevelScene")
	CurrentLevel = ActiveLevels[0]
	
	

func BodyEntered(body: Node2D):#
	if not awake:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() == 0:
			print_debug("Area Level Changer has failed to find a player")
		else:
			player = players[0]
		awake = true

	if body == player:
		call_deferred("ChangeLevel")

func ChangeLevel():
	#get_tree().change_scene_to_file(new_scene_path)
	get_tree().root.add_child(new_scene)
	get_tree().root.move_child(new_scene, 0)
	get_tree().root.remove_child(CurrentLevel)
