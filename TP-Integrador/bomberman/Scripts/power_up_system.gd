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

func _on_speed_up_timer_timeout() -> void:
	player.movement_speed /= SPEED_MULTIPLIER
	animated_sprite_2d.speed_scale = 1
