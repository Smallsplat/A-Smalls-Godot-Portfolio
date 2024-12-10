extends Node

class_name LevelGenerator

@export var level_list : Resource
@export var inital_spawn_amount : int = 5

var rng = RandomNumberGenerator.new()
var spawned_level_list : Dictionary = {}
var active_level_list : Array = []
var latest_spawn_location : Vector2 = self.position
var player_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for level in inital_spawn_amount:
		spawn_new_segment(level)
	
func spawn_new_segment(index : int):
	var new = true
	var level_type = 0
	
	#Do we need to spawn this segment
	if active_level_list.has(index):
		print ("Segment Spawner: Already Spawned Segment at index ", index,", Ingoring")
		return false
	else:
		#Do we already know what type it is
		if spawned_level_list.has(index):	 # Get the Old level type we stored
			new = false
			level_type = spawned_level_list[index][1]
			print ("Segment Spawner: Recovering Segment ", level_type, " At index ", index)
		else:								# Get a new level type
			new = true
			level_type = rng.randi_range(0, (level_list.SetLevelList.size() -1))
			index = spawned_level_list.size()
			print ("Segment Spawner: Spawning New Segement ", level_type, " At index ", index)

	#Get the level, load the level, add it to the tree, and set its position
	var new_level = level_list.GetLevel(level_type)
	var new_level_instance = new_level.instantiate()
	get_tree().get_root().add_child.call_deferred(new_level_instance)
	if new:
		new_level_instance.position = latest_spawn_location
	else:
		new_level_instance.position = spawned_level_list[index][0]

	#Find the next spawn position
	for child in new_level_instance.get_children():
		if child is EndOfLevel and new:
			latest_spawn_location = child.global_position
		if child is LevelEndArea:
			child.UpdateIndex(index)
			child.UpdateLevelGenerator(self)
	#Update the Level array tracker
	spawned_level_list[index] = [new_level_instance.position, level_type, new_level_instance]
	active_level_list.append(index)
	print (active_level_list)

func despawn_segment(index : int):
	var target
	if active_level_list.has(index):
		target = spawned_level_list[index][2]
	
	if target:
		target.queue_free()
		active_level_list.erase(index)
		print ("Segment Spawner: Depawning Old Segement at index ", index)
	else:
		print ("No targets to despawn at index ", index, " found!!!")

func PlayerSegmentMoved(index : int):
	# > SPAWN FORWARD
	#Check if the level infront is already spawned
	spawn_new_segment(index+2)

	# > DELETE BEHIND
	if index-3 >= 0:
		despawn_segment(index - 3)
	despawn_segment(index + 3)
	#Delete Level segment -3 from Index
	#Delete level Segment +3 from index
		
	# > ENSURE BACKWARDS
	# Ensure LevelSegment -2 is spawned
	if index-2 >= 0:
		spawn_new_segment(index-2)
	
	pass
