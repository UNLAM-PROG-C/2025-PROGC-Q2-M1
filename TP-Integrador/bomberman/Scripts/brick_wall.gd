extends Area2D
class_name BrickWall

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
const POWER_UP_SCENE = preload("res://Scenes/power_up.tscn")

@export var power_up_res: PowerUpRes

# --- CAMBIO 1: @rpc("call_local") ---
# Esto permite que el servidor le ordene a todos (incluyéndose) ejecutar esto.
@rpc("call_local")
func destroy():
	animated_sprite_2d.play("destroy")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "destroy":
		
		# --- CAMBIO 2: Solo el servidor crea el premio ---
		# El Spawner se encargará de mostrarlo a los demás.
		if multiplayer.is_server():
			if power_up_res != null:
				spawn_power_up()
		
		# --- CAMBIO 3: Todos borran su propia pared ---
		queue_free()

func spawn_power_up():
	var power_up = POWER_UP_SCENE.instantiate()
	power_up.global_position = global_position
	
	# Nota: Asegúrate de dwagregar el PowerUp a la escena correcta (Main)
	# para que el Spawner lo detecte.
	get_tree().current_scene.add_child(power_up)	
	if power_up_res:
		power_up.type = power_up_res.type
