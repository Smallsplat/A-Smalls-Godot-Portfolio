extends Resource

class_name DamageResource

@export var damage : int

func Damage(object):
	var properties = object.get_property_list()
	for property in properties:
		if property.class_name == "HealthResource":
			object.get(property.name).Damaged(damage)
