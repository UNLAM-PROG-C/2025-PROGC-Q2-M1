extends Node

class_name BombPlacementSystem

const BOMB_SCENE = preload("res://Scenes/bomb.tscn")
const SERVER_ID = 1
const MACRO_TILE_SIZE = 16
const INITIAL_BOMBS = 0
const INITIAL_EXPLOSION_SIZE = 1

@onready var audio_bomb: AudioStreamPlayer2D = $"../AudioBomb"
var bomberman : Bomberman = null

# Variables de control
var bomb_placed = INITIAL_BOMBS
var explosion_size = INITIAL_EXPLOSION_SIZE

func _ready() -> void:
	bomberman = get_parent()

func place_bomb():
	# Validacion Local
	if bomb_placed >= bomberman.max_bombs:
		return
	
	# Pedir al servidor que cree la bomba
	rpc_id(SERVER_ID, "request_bomb_spawn", bomberman.position)

@rpc("any_peer", "call_local")
func request_bomb_spawn(pos_solicitada: Vector2):
	if bomb_placed >= bomberman.max_bombs:
		return

	var bomb = BOMB_SCENE.instantiate()

	var bomb_position = Vector2(
		round(pos_solicitada.x / MACRO_TILE_SIZE) * MACRO_TILE_SIZE,
		round(pos_solicitada.y / MACRO_TILE_SIZE) * MACRO_TILE_SIZE
	)
	bomb.position = bomb_position
	bomb.explosion_size = explosion_size
	bomb.set_multiplayer_authority(SERVER_ID)

	var players_node = get_tree().current_scene.get_node("Players")
	players_node.add_child(bomb, true)
	
	play_sound_rpc.rpc()
	
	# Incrementar contador y conectar señal
	bomb_placed += 1
	bomb.tree_exiting.connect(on_bomb_exploded)

@rpc("any_peer", "call_local")
func play_sound_rpc():
	if audio_bomb:
		audio_bomb.play()

func on_bomb_exploded():
	bomb_placed -= 1
