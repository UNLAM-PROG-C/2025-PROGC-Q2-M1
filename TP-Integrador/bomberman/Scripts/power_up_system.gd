extends Node

class_name PowerUpSystem

var player: WhiteBomberman
@onready var bomb_placement_system: BombPlacementSystem = $"../BombPlacementSystem"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var speed_up_timer: Timer = $SpeedUpTimer

const SPEED_MULTIPLIER = 2

func _ready() -> void:
	player = get_parent()

func enable_power_up(power_up_type: utils.PowerUpType):
	match power_up_type:
		utils.PowerUpType.BOMB_UP:
			player.max_bombs += 1
		utils.PowerUpType.FIRE_UP:
			bomb_placement_system.explosion_size += 1
		utils.PowerUpType.SPEED_UP:
			player.movement_speed *= SPEED_MULTIPLIER
			animated_sprite_2d.speed_scale = 2
			speed_up_timer.start()
		utils.PowerUpType.WALL_PASS:
			var raycasts_nodes = get_tree().get_nodes_in_group("raycasts") as Array[RayCast2D]
			for raycast in raycasts_nodes:
				raycast.set_collision_mask_value(3, false)

func _on_speed_up_timer_timeout() -> void:
	player.movement_speed /= SPEED_MULTIPLIER
	animated_sprite_2d.speed_scale = 1
