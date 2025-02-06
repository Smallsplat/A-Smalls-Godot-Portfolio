extends Node

class_name WeaponUIController

var character = PlayerCharacter 
var MandK : bool = true #Mouse N keyboard or Controller Tracker

#UI Variables
var player_camera

@onready var power_slider = $"Power Group/PowerSlider"
@onready var fire_rate_slider = $"Fire Group/FireRateSlider"
@onready var reload_slider = $"Reload Group/ReloadSlider"
@onready var ammo_slider = $"Ammo Group/AmmoSlider"

@onready var power_insert = $"Power Group/Value_Power"
@onready var fire_rate_insert = $"Fire Group/Value_Fire rate"
@onready var reload_insert = $"Reload Group/Value_Reload"
@onready var ammo_insert = $"Ammo Group/Value_ Ammo"

@onready var energy_bar = $WeaponEnergyBar

var mouse_lockout : bool = false

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		print_debug("A missile has failed to find a player")
	else:
		character = players[0]
	
	
	OnSpawned()

# Called when the node enters the scene tree for the first time.
func OnSpawned():
	#Find Sliders for Future Refrence
	#power_slider = player_camera.find_child("PowerSlider")
	#fire_rate_slider = player_camera.find_child("FireRateSlider")
	#reload_slider = player_camera.find_child("ReloadSlider")
	#ammo_slider = player_camera.find_child("AmmoSlider")
	
	#find editable values for future refrence
	#power_insert = player_camera.find_child("Value_Power")
	#fire_rate_insert = player_camera.find_child("Value_Fire rate")
	#reload_insert = player_camera.find_child("Value_Reload")
	#ammo_insert = player_camera.find_child("Value_ Ammo")
	
	#Connect Slider signals to Weapon Update
	power_slider.value_changed.connect(RequestWeaponUpdate.bind("power", Slider))
	fire_rate_slider.value_changed.connect(RequestWeaponUpdate.bind("fire_rate", Slider))
	reload_slider.value_changed.connect(RequestWeaponUpdate.bind("reload", Slider))
	ammo_slider.value_changed.connect(RequestWeaponUpdate.bind("ammo", Slider))

	power_insert.text_submitted.connect(RequestWeaponUpdate.bind("power", LineEdit))
	fire_rate_insert.text_submitted.connect(RequestWeaponUpdate.bind("fire_rate", LineEdit))
	reload_insert.text_submitted.connect(RequestWeaponUpdate.bind("reload", LineEdit))
	ammo_insert.text_submitted.connect(RequestWeaponUpdate.bind("ammo", LineEdit))

	#Assign slider min/maxes + assign default value
	power_slider.min_value = character.weapon_controller.power_range.x
	power_slider.max_value = character.weapon_controller.power_range.y
	power_slider.value = character.weapon_controller.shot_power
	
	fire_rate_slider.min_value = character.weapon_controller.fire_rate_range.x
	fire_rate_slider.max_value = character.weapon_controller.fire_rate_range.y
	fire_rate_slider.value = InvertSlider(character.weapon_controller.fire_rate, character.weapon_controller.fire_rate_range.y, character.weapon_controller.fire_rate_range.x)
	
	ammo_slider.min_value = character.weapon_controller.ammo_range.x
	ammo_slider.max_value = character.weapon_controller.ammo_range.y
	ammo_slider.value = character.weapon_controller.ammo_max
	
	reload_slider.min_value = character.weapon_controller.reload_range.x
	reload_slider.max_value = character.weapon_controller.reload_range.y
	reload_slider.value = InvertSlider(character.weapon_controller.reload_speed, character.weapon_controller.reload_range.y, character.weapon_controller.reload_range.x)
	
	#Assign inserts default values
	power_insert.text = str(character.weapon_controller.shot_power)
	fire_rate_insert.text = str(character.weapon_controller.fire_rate)
	ammo_insert.text = str(character.weapon_controller.ammo_max)
	reload_insert.text = str(character.weapon_controller.reload_speed)

	#Assign inserts "placeholder" values
	power_insert.placeholder_text = str(character.weapon_controller.shot_power)
	fire_rate_insert.placeholder_text = str(character.weapon_controller.fire_rate)
	ammo_insert.placeholder_text = str(character.weapon_controller.ammo_max)
	reload_insert.placeholder_text = str(character.weapon_controller.reload_speed)
	
	energy_bar.max_value = character.weapon_controller.max_energy

func _input(event : InputEvent) -> void:
	
	if (event is InputEventKey) or (event is InputEventMouseButton) or (event is InputEventMouseMotion):
		MandK = true
	elif (event is InputEventJoypadButton) or (event is InputEventJoypadMotion):
		MandK = false
	
	
func ToggleWeaponModulation():
	var panel : Panel = player_camera.find_child("Weapon Modulation Panel")
	if panel.visible:
		panel.visible = false
		mouse_lockout = false
	else:
		panel.visible = true
		mouse_lockout = true
		player_camera.find_child("PowerSlider").grab_focus()

func RequestWeaponUpdate(value, stat, type):
	#Validate Input
	if value is String and value.is_valid_float():
		value = value.to_float()
	elif not (value is float):
		#Kill the funtion if we're not dealing with a float
		return false
	
	#Flip value if input is Slider value
	if type == Slider:
		match stat:
			"fire_rate":
				value = InvertSlider(value, character.weapon_controller.fire_rate_range.y, character.weapon_controller.fire_rate_range.x)
			"reload":
				value = InvertSlider(value, character.weapon_controller.reload_range.y, character.weapon_controller.reload_range.x)
	
	#Check if this is a valid request
	character.weapon_controller.ValidateStatChange(stat, value)
	
	
	#Update sliders and Values to meet the current stats
	match stat:
		"power":
			power_slider.value = (character.weapon_controller.shot_power)
			power_insert.text = str(character.weapon_controller.shot_power)
			power_insert.placeholder_text = str(character.weapon_controller.shot_power)
		"fire_rate":
			fire_rate_slider.value = InvertSlider(character.weapon_controller.fire_rate, character.weapon_controller.fire_rate_range.y, character.weapon_controller.fire_rate_range.x)
			fire_rate_insert.text = str(snapped((character.weapon_controller.fire_rate), 0.1))
			fire_rate_insert.placeholder_text = str(snapped((character.weapon_controller.fire_rate), 0.1))
		"ammo":
			ammo_slider.value = character.weapon_controller.ammo_max
			ammo_insert.text = str(character.weapon_controller.ammo_max)
			ammo_insert.placeholder_text = str(character.weapon_controller.ammo_max)
		"reload":
			reload_slider.value = snapped(InvertSlider(character.weapon_controller.reload_speed, character.weapon_controller.reload_range.y, character.weapon_controller.reload_range.x), 0.1)
			reload_insert.text = str(snapped((character.weapon_controller.reload_speed), 0.1))
			reload_insert.placeholder_text = str(snapped((character.weapon_controller.reload_speed), 0.1))

	
func UpdateWeaponEnergy(energy):
	energy_bar.value = energy

func InvertSlider(value, max_value, min_value):
	return ((value - min_value) * -1) + max_value
	# DO NOT ROUND HERE, Vector 2 decmimals have a floating point error that must not be corrected until after calulcations.
	# use Snapped() on visable numbers directly.
	
func InvertedControls(inverted):
	character.weapon_controller.inverted = inverted
