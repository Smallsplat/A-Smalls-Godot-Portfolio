extends Node

class_name PlayerSpawner

const player = preload("res://Scripts/Character/player.tscn")
var current_player

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		instantiate_player()
	else:
		current_player = players[0]
		current_player.player_camera.position = self.position
		
	current_player.position = self.position
	current_player.player_spawner = self
	

func instantiate_player():
	var instanced_player = player.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_player)
	current_player = instanced_player
