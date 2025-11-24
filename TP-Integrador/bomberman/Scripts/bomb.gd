extends Area2D

class_name Bomb

const CENTRAL_EXPLOSION = preload("res://Scenes/central_explosion.tscn")
const MACRO_EXPLOSION_SIZE = 1

var explosion_size = MACRO_EXPLOSION_SIZE

func _on_timer_timeout() -> void:
	# Servidor decide cuándo explotar
	if not multiplayer.is_server():
		return

	var explosion = CENTRAL_EXPLOSION.instantiate()
	explosion.position = position
	explosion.size = explosion_size
	get_tree().current_scene.get_node("Players").add_child(explosion, true)

	queue_free()
