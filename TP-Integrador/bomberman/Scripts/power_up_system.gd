extends Node

class_name PowerUpSystem

var player: Bomberman

@onready var bomb_placement_system: BombPlacementSystem = $"../BombPlacementSystem"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var speed_up_timer: Timer = $SpeedUpTimer

const SPEED_MULTIPLIER = 2

func _ready() -> void:
	player = get_parent()

func enable_power_up(power_up_type: Utils.PowerUpType):
	match power_up_type:
		Utils.PowerUpType.BOMB_UP:
			player.max_bombs += 1
			
		Utils.PowerUpType.FIRE_UP:
			bomb_placement_system.explosion_size += 1
			
		Utils.PowerUpType.SPEED_UP:
			player.movement_speed *= SPEED_MULTIPLIER
			animated_sprite_2d.speed_scale = SPEED_MULTIPLIER
			speed_up_timer.start()
			
		Utils.PowerUpType.WALL_PASS:
			player.has_wall_pass = true
		
		Utils.PowerUpType.MYSTERY:
			var posibles_premios = [
				Utils.PowerUpType.BOMB_UP, #Indice 0
				Utils.PowerUpType.FIRE_UP,
				Utils.PowerUpType.SPEED_UP,
				Utils.PowerUpType.WALL_PASS
			]
			#randi(), me da un numero aleatorio
			var azar = randi() % (posibles_premios.size() + 1)
			
			if(azar == posibles_premios.size()):
				print("Muerte")
				player.die()
			else:
				print("Obtuviste el power up: ", Utils.PowerUpType.keys()[azar])
				#Aplicamos recursividad
				enable_power_up(posibles_premios[azar])
				

func _on_speed_up_timer_timeout() -> void:
	player.movement_speed /= SPEED_MULTIPLIER
	animated_sprite_2d.speed_scale = 1
