extends Resource

class_name MobileThreatsList

#Enum list is the dropdown table of all threats, in order of the below Array
@export_enum("Basic Missile") var threat_choice : int

#Add new Mobile threats to the preload array.
var MobileThreatList = [
preload("res://Scripts/Level Mechanics/Threats/Mobile Threats/Missile.tscn")
]

#Summon the threat via code in the spawner
func GetThreat():
	return MobileThreatList[threat_choice]

# TO ADD A NEW THREAT
	# >  Add the Preload to the MobileThreatList
	# >  Add a name for it to the Enum, as it just acts as a Int ""Pointer""
