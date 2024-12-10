extends Resource

class_name Set1LevelList

#Enum list is the dropdown table of all threats, in order of the below Array
@export_enum("Silo 1", "Silo 2", "Silo 3", "Clifftops", "Slopes", "Droploop", "Radar Dish", "Death Drop") var level_choice : int

#Add new Mobile threats to the preload array.
var SetLevelList = [
preload("res://Levels/Level 1 Tiles/Set1 - Silo 1.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - Silo 2.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - Silo 3.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - CliffTops.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - Slopes.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - DropLoop.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - RadarDish.tscn"),
preload("res://Levels/Level 1 Tiles/Set1 - DeathDrop.tscn"),
]

#Summon the threat via code in the spawner
func GetLevel(level_request):
		return SetLevelList[level_request]
