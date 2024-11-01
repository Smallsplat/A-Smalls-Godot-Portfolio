extends Resource

class_name HealthResource

@export var health : float
@export var max_health : float

signal death

func _init(p_health = 1, p_max_health = 1):
	health = p_health
	max_health = p_max_health

func Damaged(damage):
	health -= damage
	if health <= 0:
		death.emit()

func Healed(heal):
	health += heal
	if health > max_health:
		health = max_health
