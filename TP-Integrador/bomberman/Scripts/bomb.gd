extends Area2D

class_name Bomb

const MACRO_EXPLOSION_SIZE = 1

var explosion_size = MACRO_EXPLOSION_SIZE

func _on_timer_timeout() -> void:
	queue_free()
