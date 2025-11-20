extends Area2D

class_name white_bomberman

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var movement: Vector2 = Vector2.ZERO

@export var movement_speed: float = 75

func _process(delta: float) -> void:
	
	position += movement * delta * movement_speed

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("derecha"):
		movement = Vector2.RIGHT
		animated_sprite_2d.play("white_right")
	elif Input.is_action_pressed("izquierda"):
		movement = Vector2.LEFT
		animated_sprite_2d.play("white_left")
	elif Input.is_action_pressed("abajo"):
		movement = Vector2.DOWN
		animated_sprite_2d.play("white_down")
	elif Input.is_action_pressed("arriba"):
		movement = Vector2.UP
		animated_sprite_2d.play("white_up")
	else:
		movement = Vector2.ZERO
		animated_sprite_2d.stop()
	
	
	
