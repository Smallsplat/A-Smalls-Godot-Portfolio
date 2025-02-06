extends Node2D

@export var threat_list : MobileThreatsList
@export var spawn_up : bool
@export var spawn_down : bool
@export var spawn_sides : bool = true
@export var spawn_attempts : int = 10
@export var spawn_amount : int = 5
@export var inverted : bool = false

var direction_multi = 1

func _ready():
	if not threat_list:
		push_warning("Offscreen spawner ", self.name , " does not have a threat attached! Copy a Threat Path.tscn into the Threat path box!")
	if not (spawn_up or spawn_down or spawn_sides):
		push_warning("Offscreen spawner ", self.name , " does not have a spawn direction! Select a side!")

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		Trigger(body)

func Trigger(player : PlayerCharacter):
	#Get the Maths
	var player_direction : Vector2 = player.velocity.normalized()
	var player_camera_position : Vector2 = player.player_camera.global_position
	var window_size : Vector2 = DisplayServer.window_get_size()
	
	#Get the draw space for raycasting
	var space_state = get_world_2d().direct_space_state
	var target_spawn_point : Vector2 = Vector2.ZERO
	
	var valid_spawns = []
	
	if spawn_sides:
		#Get forward/backwards calculations
		if player_direction.x > 0:
			direction_multi = -1
		else:
			direction_multi = 1

		if inverted:
			direction_multi *= -1

		#Get the X based on camera postion and window size
		target_spawn_point.x = (player_camera_position.x + ((window_size.x /3) * direction_multi))
		for attempt in spawn_attempts:
			#get the Y based on (camera location + half window size) - ((window size / spawm attempts) * attempt)
			target_spawn_point.y = ((player_camera_position.y + (window_size.y/3)) - ((window_size.y/spawn_attempts) * (spawn_attempts - (attempt + 1))))
			var query = PhysicsRayQueryParameters2D.create(player_camera_position, target_spawn_point)
			var result = space_state.intersect_ray(query)

			if not result:
				valid_spawns.append(target_spawn_point)
		
	if spawn_up:
		#Get the y based on camera postion and window size
		target_spawn_point.y = (player_camera_position.y - ((window_size.y /3) * direction_multi))
		for attempt in spawn_attempts:
			#get the x based on (camera location + half window size) - ((window size / spawm attempts) * attempt)
			target_spawn_point.x = ((player_camera_position.x + (window_size.x/2)) - ((window_size.x/spawn_attempts) * (spawn_attempts - (attempt + 1))))
			var query = PhysicsRayQueryParameters2D.create(player_camera_position, target_spawn_point)
			var result = space_state.intersect_ray(query)

			if not result:
				valid_spawns.append(target_spawn_point)
	if spawn_down:
		#Get the y based on camera postion and window size
		target_spawn_point.y = (player_camera_position.y + ((window_size.y) * direction_multi))
		for attempt in spawn_attempts:
			#get the x based on (camera location + half window size) - ((window size / spawm attempts) * attempt)
			target_spawn_point.x = ((player_camera_position.x + (window_size.x/2)) - ((window_size.x/spawn_attempts) * (spawn_attempts - (attempt + 1))))
			var query = PhysicsRayQueryParameters2D.create(player_camera_position, target_spawn_point)
			var result = space_state.intersect_ray(query)

			if not result:
				valid_spawns.append(target_spawn_point)
	
	if valid_spawns.size() > 0:
		for spawn in spawn_amount:
			var counter = spawn
			var spawn_offset = Vector2.ZERO
			while (valid_spawns.size() -1 < counter):
				counter -= valid_spawns.size()
				spawn_offset += Vector2(50,50) * direction_multi
				
			var threat = threat_list.GetThreat().instantiate()
			threat.position = valid_spawns[counter] + spawn_offset
			get_tree().get_root().add_child.call_deferred(threat)
	else:
		print ("No valid spawns!")
