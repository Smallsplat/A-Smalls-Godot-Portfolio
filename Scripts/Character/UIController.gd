extends Node

class_name UIController

@export var character : CharacterBody2D

const WeaponUIPath = preload("res://Scripts/Character/Weapon/WeaponUI.tscn")

var MandK : bool = true #Mouse N keyboard or Controller Tracker
var WeaponUI : Panel

#UI Variables
var player_camera
var speedometer
var ammometer
var timeout_bar
var reload_bar

var mouse_lockout : bool = false

# Called when the node enters the scene tree for the first time.
func OnSpawned():
	speedometer = player_camera.find_child("Speedometer")
	ammometer = player_camera.find_child("Ammometer")
	timeout_bar = player_camera.find_child("Reload Timeout Bar")
	reload_bar = player_camera.find_child("Reload Bar")
	
	UpdateAmmometer(character.weapon_controller.ammo)
	timeout_bar.max_value = character.weapon_controller.reload_time_out_length
	reload_bar.max_value = character.weapon_controller.reload_speed
	
	WeaponUI = WeaponUIPath.instantiate()
	player_camera.find_child("HUD").add_child.call_deferred(WeaponUI)
	WeaponUI.player_camera = self
	ToggleWeaponModulation()

func _input(event : InputEvent) -> void:
	if (event is InputEventKey) or (event is InputEventMouseButton) or (event is InputEventMouseMotion):
		MandK = true
	elif (event is InputEventJoypadButton) or (event is InputEventJoypadMotion):
		MandK = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#Update Speedometer
	UpdateSpeedometer(snapped(character.velocity.length(), 1))
	
	#UpdateReload bars
	UpdateReloadBar(character.weapon_controller.reload_speed - character.weapon_controller.reload_timer.time_left)
	UpdateTimeoutBar(character.weapon_controller.reload_time_out_length - character.weapon_controller.reload_time_out.time_left)
	
func UpdateSpeedometer(speed):
	speedometer.text = str("Speed : ", speed)

func UpdateAmmometer(ammo):
	ammometer.text = str("Ammo : ", ammo)

func UpdateTimeoutBar(value):
	timeout_bar.value = value
	timeout_bar.max_value = character.weapon_controller.reload_time_out_length

func UpdateReloadBar(value):
	reload_bar.value = value
	reload_bar.max_value = character.weapon_controller.reload_speed
	
func ToggleWeaponModulation():
	if WeaponUI.visible:
		WeaponUI.visible = false
		mouse_lockout = false
	else:
		WeaponUI.visible = true
		mouse_lockout = true
		WeaponUI.find_child("PowerSlider").grab_focus()


func InvertSlider(value, max_value, min_value):
	return ((value - min_value) * -1) + max_value
	# DO NOT ROUND HERE, Vector 2 decmimals have a floating point error that must not be corrected until after calulcations.
	# use Snapped() on visable numbers directly.

