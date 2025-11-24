extends Area2D

class_name Bomb

const CENTRAL_EXPLOSION = preload("res://Scenes/central_explosion.tscn")
const MACRO_EXPLOSION_SIZE = 1

var explosion_size = MACRO_EXPLOSION_SIZE

func _on_timer_timeout() -> void:
	# --- Solo el servidor decide cuándo explotar ---
	if not multiplayer.is_server():
		return

	var explosion = CENTRAL_EXPLOSION.instantiate()
	explosion.position = position
	explosion.size = explosion_size # Asumiendo que tu explosión tiene esta variable
	
	# --- CORRECCIÓN CLAVE ---
	# Buscamos el nodo "Players" dentro de la escena actual (main)
	# y añadimos la explosión allí, donde el Spawner está mirando.
	get_tree().current_scene.get_node("Players").add_child(explosion, true)
	
	queue_free()
