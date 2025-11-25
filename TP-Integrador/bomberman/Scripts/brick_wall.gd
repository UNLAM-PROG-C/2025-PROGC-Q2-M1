extends Area2D
class_name BrickWall

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
const POWER_UP_SCENE = preload("res://Scenes/power_up.tscn")

@export var power_up_res: PowerUpRes

func _ready():
	add_to_group("brick_wall")

@rpc("call_local")
func destroy():
	animated_sprite_2d.play("destroy")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "destroy":
		if multiplayer.is_server():
			if power_up_res != null:
				spawn_power_up()
		
		queue_free()

func spawn_power_up():
	var power_up = POWER_UP_SCENE.instantiate()
	power_up.global_position = global_position
	
	if power_up_res:
		power_up.type = power_up_res.type
	
	var players_node = get_tree().current_scene.get_node("Players")
	players_node.add_child(power_up, true)
