extends Node2D

var player : Node2D
var rotation_speed : float =  2
var speed : float = 600
var min_speed : float = 200
var damage = 1

const explosion = preload("res://Scripts/Level Mechanics/Threats/Damaging Effects/LargeExplosion.tscn")


var velocity : Vector2 = Vector2.ZERO
var acceleration : Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		print_debug("A missile has failed to find a player")
	else:
		player = players[0]
		self.look_at(player.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player:
		velocity += CalculateVector(player.position)
		velocity = velocity.limit_length(speed)
		if velocity.length() < min_speed:
			velocity = velocity.normalized() * min_speed
		
		self.rotation = velocity.angle()
		self.position += velocity * delta
		

func CalculateVector(target : Vector2):
	var target_vector = (target - self.position).normalized() * speed
	return (target_vector - velocity).normalized() * rotation_speed

func Collision(object):
	var instanced_exposion = explosion.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_exposion)
	instanced_exposion.position = self.position
	instanced_exposion.TryDamage(object, damage)
	queue_free()
