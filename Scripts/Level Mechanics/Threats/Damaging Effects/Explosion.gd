extends Sprite2D

@onready var animator = $AnimationPlayer
@export var damage_logic : DamageResource

# Called when the node enters the scene tree for the first time.
func _ready():
	animator.play("Explosion", -1, 2)
	var rng = RandomNumberGenerator.new()
	var random_rotation = rng.randf_range(0, 360)
	self.rotation_degrees = random_rotation
	
func _on_animation_player_animation_finished(_anim_name):
	queue_free()
