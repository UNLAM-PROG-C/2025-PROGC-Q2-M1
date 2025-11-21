extends Area2D

class_name WhiteBomberman
const MACRO_SPEED = 75
const MACRO_MAX_BOMBS = 1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var rayCasts : RayCasts = $RayCasts
@onready var bomb_placed_system : BombPlacementSystem = $BombPlacementSystem

var movement: Vector2 = Vector2.ZERO

@export var movement_speed: float = MACRO_SPEED
var max_bombs = MACRO_MAX_BOMBS

func _process(delta: float) -> void:
	
	var collisions = rayCasts.check_collisions()
	if collisions.has(movement):
		return
	
	position += movement * delta * movement_speed
	
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("white_right"):
		movement = Vector2.RIGHT
		animated_sprite_2d.play("white_right")
	elif Input.is_action_pressed("white_left"):
		movement = Vector2.LEFT
		animated_sprite_2d.play("white_left")
	elif Input.is_action_pressed("white_down"):
		movement = Vector2.DOWN
		animated_sprite_2d.play("white_down")
	elif Input.is_action_pressed("white_up"):
		movement = Vector2.UP
		animated_sprite_2d.play("white_up")
	elif Input.is_action_just_pressed("white_bomb"):
		bomb_placed_system.place_bomb()
	else:
		movement = Vector2.ZERO
		animated_sprite_2d.stop()
	
	
	
