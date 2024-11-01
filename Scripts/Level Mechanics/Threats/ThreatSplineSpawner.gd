extends Node2D

@onready var path : Path2D = $"."
@export var threat_path : String
@export var threat_distance : float = 100
@export var random_offset : Vector2 = Vector2(-1,1)  

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	#Base Index points
	var a_point_index = 0
	var b_point_index = 1
	#For each of the base nodes, generate nodes based on Threat Distance
	for points in (path.curve.get_point_count() -1):
		a_point_index = GeneratePoints(a_point_index, b_point_index) + 1
		b_point_index = a_point_index + 1
	#Spawn threats after generation
	SpawnThreats()
	
func GeneratePoints(a_point_index, b_point_index):
	var new_end_point = b_point_index
	
	#Generate Random Offset
	var random_offset_x = rng.randf_range(random_offset.x, random_offset.y)
	var random_offset_y = rng.randf_range(random_offset.x, random_offset.y)
	var local_random_offset = Vector2(random_offset_x,random_offset_y)
	
	#Calculate Distance bween Points
	var point_diffrence = (path.curve.get_point_position(a_point_index) - path.curve.get_point_position(b_point_index))
	var length = point_diffrence.length()
	
	#If we're double Threat distance length away, put it threat distance away
	if (length >= threat_distance * 2):
		var new_pos = (path.curve.get_point_position(a_point_index) - (point_diffrence.normalized() * threat_distance) + local_random_offset)
		path.curve.add_point(new_pos, Vector2(0,0), Vector2(0,0), b_point_index)
		new_end_point = GeneratePoints(a_point_index + 1, b_point_index + 1)
	# If we're not but still greater than threat distance, put it on the half-way point to cover the gap
	elif (length > threat_distance):
		var new_pos = (path.curve.get_point_position(a_point_index) - (point_diffrence.normalized() * (length / 2)) + local_random_offset)
		path.curve.add_point(new_pos, Vector2(0,0), Vector2(0,0), b_point_index)
	#We return the Index of B so we can update the next set of nodes index finders
	return new_end_point
	
func SpawnThreats():
	var x = 0
	for points in path.curve.get_point_count():
		var spawn_location = path.curve.get_point_position(x)
		var threat = load(threat_path).instantiate()
		threat.position = spawn_location
		self.add_child(threat)
		x += 1
