extends Node2D

var player : PlayerCharacter
@export var rotation_speed : float =  2
@export var speed : float = 600
@export var min_speed : float = 200
@export var damage = 1
@export var damage_logic : DamageResource

const explosion = preload("res://Scripts/Level Mechanics/Threats/Damaging Effects/LargeExplosion.tscn")

@onready var indicator :Sprite2D = $"Sprite Indicator"
var indi_offset : Vector2 = Vector2.ZERO

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
		
	indi_offset.x = (indicator.texture.get_width() * 0.5)
	indi_offset.y = (indicator.texture.get_height() * 0.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player:
		velocity += CalculateVector(player.position)
		velocity = velocity.limit_length(speed)
		if velocity.length() < min_speed:
			velocity = velocity.normalized() * min_speed
		
		self.rotation = velocity.angle()
		self.position += velocity * delta
		
		var cam_Rect2 = get_canvas_transform().affine_inverse() * get_viewport_rect()
		var global_pos = self.get_global_position()
		
		if global_pos.x < cam_Rect2.position.x or global_pos.y < cam_Rect2.position.y or global_pos.x > (cam_Rect2.position.x + cam_Rect2.size.x) or global_pos.y > (cam_Rect2.position.y + cam_Rect2.size.y):
			indicator.show()
			$"Sprite Indicator Missile".show()
			var indicator_pos = global_pos
			indicator_pos.x = clamp(indicator_pos.x, (cam_Rect2.position.x + indi_offset.x), ((cam_Rect2.position.x + cam_Rect2.size.x) - indi_offset.x))
			indicator_pos.y = clamp(indicator_pos.y, (cam_Rect2.position.y + indi_offset.y), ((cam_Rect2.position.y + cam_Rect2.size.y - indi_offset.y)))
			indicator.global_position = indicator_pos
			indicator.look_at(self.global_position)
		else:
			indicator.hide()
			$"Sprite Indicator Missile".hide()

func CalculateVector(target : Vector2):
	var target_vector = (target - self.position).normalized() * speed
	return (target_vector - velocity).normalized() * rotation_speed

func Collision(object):
	var instanced_exposion = explosion.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_exposion)
	instanced_exposion.position = self.position
	TryDamage(object, damage)
	queue_free()
	
func TryDamage(object, amount):
	if damage_logic:
		damage_logic.damage = amount
		damage_logic.Damage(object)

