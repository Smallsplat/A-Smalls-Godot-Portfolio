extends Node2D

@export var threat_path : String
@export var spawn_up : bool
@export var spawn_down : bool
@export var spawn_sides : bool = true
@export var spawn_attempts : int = 10
@export var spawn_amount : int = 5

func _ready():
	if not threat_path:
		push_warning("Offscreen spawner ", self.name , " does not have a threat attached! Copy a Threat Path.tscn into the Threat path box!")
	if not (spawn_up or spawn_down or spawn_sides):
		push_warning("Offscreen spawner ", self.name , " does not have a spawn direction! Select a side!")

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		Trigger(body)

func Trigger(player : PlayerCharacter):
	#Get the Maths
	var player_direction : Vector2 = player.velocity.normalized()
	var player_camera_position : Vector2 = player.player_camera.position
	var window_size : Vector2 = DisplayServer.window_get_size()
	
	#Get the draw space for raycasting
	var space_state = get_world_2d().direct_space_state
	var target_spawn_point : Vector2 = Vector2.ZERO
	
	var valid_spawns = []
	
	if spawn_sides:
		#Get forward/backwards calculations
		var direction_multi = 1
		if player_direction.x > 0:
			direction_multi = -1
			
		print ("Player Camera is ",player_camera_position, " Player Window size is ",window_size)
		
		#Get the X based on camera postion and window size
		target_spawn_point.x = (player_camera_position.x + ((window_size.x /3) * direction_multi))
		
		print (target_spawn_point.x)
		
		for attempt in spawn_attempts:
			#get the Y based on (camera location + half window size) - ((window size / spawm attempts) * attempt)
			target_spawn_point.y = ((player_camera_position.y + (window_size.y/3)) - ((window_size.y/spawn_attempts) * (spawn_attempts - (attempt + 1))))
			var query = PhysicsRayQueryParameters2D.create(player_camera_position, target_spawn_point)
			var result = space_state.intersect_ray(query)

			
			if not result:
				valid_spawns.append(target_spawn_point)
	
		print ("valid Spawns: ",valid_spawns.size())
		if valid_spawns.size() > 0:
			for spawn in spawn_amount:
				var counter = spawn
				var spawn_offset = Vector2.ZERO
				while (valid_spawns.size() -1 < counter):
					counter -= valid_spawns.size()
					spawn_offset += Vector2(50,50) * direction_multi

				var threat = load(threat_path).instantiate()
				threat.position = valid_spawns[counter] + spawn_offset
				get_parent().call_deferred("add_child", threat)



# Get player direction
# Get game window size
	#translate this into world space corodiates? check if theres a command for this already!
# get player in window location if possible
# Draw raycasts in directions base on exported boolians
	# One every X from center up and down until hitting window borders
# If raycast does not collide, validate spawn location
# For each valid spawn location,
	# pawn threat until out of threat spawns
# If theres no valid spawns do nothing?
