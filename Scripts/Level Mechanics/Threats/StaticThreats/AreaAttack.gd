extends Node2D

@onready var area = $Area2D
@onready var animator = $AnimationPlayer
@onready var sprite = $Sprite2D
var colliding = []
@export var damage : float = 1

@export var damage_logic : DamageResource

const explosion = preload("res://Scripts/Level Mechanics/Threats/Damaging Effects/LargeExplosion.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite.visible = false

func OnEntered(object):
	colliding.append(object)
	if object.is_in_group("Player"):
		Trigger()

func OnExit(object):
	var index = colliding.find(object)
	if index >= 0:
		colliding.remove_at(index)

func Trigger():
	sprite.visible = true
	animator.play("Warning", -1, 4)

func Detonate():
	var instanced_exposion = explosion.instantiate()
	get_tree().get_root().add_child.call_deferred(instanced_exposion)
	instanced_exposion.position = self.global_position
	for object in colliding:
		TryDamage(object, damage)
	print ("Instanced Explosion at ", instanced_exposion.position)
	queue_free()

func _on_animation_player_animation_finished(_anim_name):
	Detonate()

func TryDamage(object, amount):
	if damage_logic:
		damage_logic.damage = amount
		damage_logic.Damage(object)
