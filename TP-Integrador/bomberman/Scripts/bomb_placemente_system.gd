extends Node

class_name BombPlacementSystem
const BOMB_SCENE = preload("res://Scenes/bomb.tscn")
const MACRO_TILE_SIZE = 16
const MACRO_BOMB_PLACED = 0
const MACRO_EXPLOSION_SIZE = 1

var white_bomberman : WhiteBomberman = null
var bomb_placed = MACRO_BOMB_PLACED
var explosion_size = MACRO_EXPLOSION_SIZE

func _ready() -> void:
	white_bomberman = get_parent()

func place_bomb():
	if bomb_placed == white_bomberman.max_bombs:
		return
	
	var bomb = BOMB_SCENE.instantiate()
	var bomberman_position = white_bomberman.position
	var bomb_position = Vector2(round(bomberman_position.x / MACRO_TILE_SIZE) * MACRO_TILE_SIZE, \
								round(bomberman_position.y / MACRO_TILE_SIZE) * MACRO_TILE_SIZE)
	
	bomb.explosion_size = explosion_size
	bomb.position = bomb_position
	get_tree().root.add_child(bomb)
	bomb_placed += 1
	
	bomb.tree_exiting.connect(on_bomb_exploded)
	
func on_bomb_exploded():
	bomb_placed -= 1
