extends Resource

class_name StaticThreatsList

#Enum list is the dropdown table of all threats, in order of the below Array
@export_enum("Medium Circle") var threat_choice : int

#Add new Static threats to the preload array.
var StaticThreatList = [
preload("res://Scripts/Level Mechanics/Threats/StaticThreats/AreaAttack.tscn")
]

#Summon the threat via code in the spawner
func GetThreat():
	return StaticThreatList[threat_choice]

# TO ADD A NEW THREAT
	# >  Add the Preload to the MobileThreatList
	# >  Add a name for it to the Enum, as it just acts as a Int ""Pointer""
