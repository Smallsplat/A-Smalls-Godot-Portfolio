extends Node

class_name WeaponController

var movement_controller : MovementController
var character : CharacterBody2D
var inverted : bool = false
@onready var reload_timer : Timer = $"../ReloadTimer"
@onready var reload_time_out : Timer = $"../ReloadTimeOut"
@onready var fire_rate_timer : Timer = $"../FireRate"
@onready var visualisor = $"../WeaponVisualisor"
@onready var animator = $"../WeaponAnimationPlayer"

@export var shot_power : float = 1
@export var fire_rate : float = 5
@export var ammo_max : float = 1
@export var reload_speed : float = 5
@export var reload_time_out_length : float = 5
@export var shot_multi : float = 100

#These variables are used a lot on the UI controler, be sure to change there too if editing!
@export var power_range : Vector2 = Vector2(1, 5)
@export var fire_rate_range : Vector2 = Vector2(0.1, 5)
@export var ammo_range : Vector2 = Vector2(1, 50)
@export var reload_range : Vector2 = Vector2(0.1, 5)
#@export var time_out_range : Vector2 = Vector2(0.1, 10)

var energy : float = 80
var max_energy : float = 80
var ammo : float = ammo_max
var costs : Array = []

var first_spawn = true
var aim_direction = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func OnSpawned():
	movement_controller = character.movement_controller
	
	if first_spawn == true:
		#Create Cost Array
		costs.append(CostCalculation("power", (shot_power)))
		costs.append(CostCalculation("fire_rate", (fire_rate)))
		costs.append(CostCalculation("ammo", (ammo)))
		costs.append(CostCalculation("reload", (reload_speed)))
		
		first_spawn = false

	UpdateCost()
	
func _ready():
	animator.play("Ready")

func FireWeapon():
	if ammo > 0 and fire_rate_timer.time_left == 0:
		ammo -= 1
		character.ui_controller.UpdateAmmometer(ammo)
		ReloadTimeout()
		var LaunchDirection = aim_direction
			#Intended launch - player current, if less than Minimum, make minimum
		if inverted:
			movement_controller.FixedLaunchPlayer(LaunchDirection, (shot_power * shot_multi))
		else:
			movement_controller.FixedLaunchPlayer(-LaunchDirection, (shot_power * shot_multi))
		fire_rate_timer.start(fire_rate)
		animator.play("Loading")

func ReloadTimeout():
	reload_timer.paused = true
	reload_time_out.start(reload_time_out_length)
	
func ReloadTimeOutEnd():
	reload_timer.paused = false
	ReloadTimerEnd()

func ReloadTimer():
	reload_timer.start(reload_speed)

func ReloadTimerEnd():
	if ammo < ammo_max:
		ammo += 1
		character.ui_controller.UpdateAmmometer(ammo)
		if ammo < ammo_max:
			ReloadTimer()

func ManualUpdateAmmo(new_ammo : float):
	ammo = new_ammo
	character.ui_controller.UpdateAmmometer(ammo)

func ValidateStatChange(stat, value : float):
	var cost : float = CostCalculation(stat, value)
	# Work out cost calculations and validate ranges
	match stat:
		"power":
			if value >= power_range.x and value <= power_range.y:
				if not ValidateCostChange(0, cost): return false
			else: return false
		"fire_rate":
			if value >= fire_rate_range.x and value <= fire_rate_range.y:
				if not ValidateCostChange(1, cost): 
					return false
			else: 
				return false
		"ammo":
			if value >= ammo_range.x and value <= ammo_range.y:
				if not ValidateCostChange(2, cost): return false
			else: return false
		"reload":
			if value >= reload_range.x and value <= reload_range.y:
				if not ValidateCostChange(3, cost): return false
			else: return false
	
	#Update costs if we're returning true? --- Maybe don't do this and do it elsewhere???
	UpdateStat(stat, value)
	UpdateCost()
	return true

func UpdateStat(stat, value : float):
	match stat:
		"power":
			shot_power = value
		"fire_rate":
			fire_rate = value
		"ammo":
			ammo_max = value
			if ammo > ammo_max:
				ManualUpdateAmmo(ammo_max)
			elif ammo < ammo_max:
				ReloadTimeout()
		"reload":
			reload_speed = value

func UpdateCost():
	energy = 0
	for cost in costs:
		energy += cost
	character.ui_controller.UpdateWeaponEnergy(energy)

func ValidateCostChange(value : int, new_cost : float): #Input new cost
	var total = 0
	var counter = 0
	for cost in costs: #add all old costs exluding the value + the new cost
		if counter == value:
			total += new_cost
		else:
			total += cost
		counter += 1
		
	if total <= max_energy:
		costs[value] = new_cost
		return true
	else:
		return false
		
func CostCalculation(stat, value):
	var cost_bounds = []
	var stat_bounds = []
	match stat:
		"power":
			stat_bounds = [1,2,3,4,5]
			cost_bounds = [0,8,20,35,50]
		"fire_rate":
			stat_bounds = [0.1,0.2,0.5,1,2,3,4,5]
			cost_bounds = [50,40,30,20,15,10,5,0]
		"ammo":
			stat_bounds = [1,2,3,4,5,10,20,30,40,50]
			cost_bounds = [0,5,10,15,20,30,35,40,45,50]
		"reload":
			stat_bounds = [0.1,0.2,0.5,1,2,3,4,5]
			cost_bounds = [50,40,30,20,15,10,5,0]

	#Cost Calulcator
	var counter = 0
	for stat_bound in stat_bounds:
		if value == stat_bound:
			return cost_bounds[counter]
		if value < stat_bound:
			var upper_cost_bound = cost_bounds[counter]
			var lower_cost_bound = cost_bounds[counter -1]
			var upper_stat_bound = stat_bounds[counter]
			var lower_stat_bound = stat_bounds[counter -1]
			#Ratios inbetween numbers to scale properly depending on the bounds
			var value_ratio = 1 - (value - lower_stat_bound) / (upper_stat_bound - lower_stat_bound)
			var true_cost = upper_cost_bound - ((upper_cost_bound-lower_cost_bound) * value_ratio)
			
			return true_cost #stat_bounds[counter - 1]
		counter +=1
	#If we're out of bounds, invalidate by demanding over our max energy
	return max_energy + 1

func _process(_delta):
	#After first spawn track input variant
	if first_spawn == false:
		if character.ui_controller.MandK:
			aim_direction = (character.position - character.get_global_mouse_position()).normalized()
		else:
			aim_direction = -character.controllerAimDirection.normalized()
	#Move Direction Indicator
	if inverted:
		visualisor.global_position = character.position + (aim_direction * 50)
	else:
		visualisor.global_position = character.position + (-aim_direction * 50)
	
	#Change UI visuals
	if fire_rate_timer.time_left == 0 and animator.current_animation == "Loading":
		animator.play("Ready")
