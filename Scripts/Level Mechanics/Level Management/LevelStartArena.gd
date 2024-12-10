extends Node

class_name LevelEndArea

var index : int = 0 
var levelgenerator : LevelGenerator

func UpdateIndex(new_index : int):
	index = new_index

func UpdateLevelGenerator(new_levelgenerator : LevelGenerator):
	levelgenerator = new_levelgenerator

func _on_body_entered(body):
	if body is CharacterBody2D:
		if levelgenerator:
			levelgenerator.PlayerSegmentMoved(index)
		pass # Replace with function body.
