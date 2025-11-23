extends Area2D

class_name Bomb

const CENTRAL_EXPLOSION = preload("res://Scenes/central_explosion.tscn")
const MACRO_EXPLOSION_SIZE = 1

var explosion_size = MACRO_EXPLOSION_SIZE

func _on_timer_timeout() -> void:
# --- CAMBIO: Solo el servidor hace los cálculos ---
	if not multiplayer.is_server():
		return

	var explosion = CENTRAL_EXPLOSION.instantiate()
	explosion.position = position
	explosion.size = explosion_size
	
	# Agregamos a la escena actual (main) para que el Spawner la replique
	get_tree().current_scene.add_child(explosion, true)
	
	queue_free()
