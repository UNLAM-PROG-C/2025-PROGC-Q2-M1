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
	
	var my_id = multiplayer.get_unique_id()
	# Pedir al servidor que cree la bomba, pasando el ID del jugador
	request_bomb_spawn.rpc_id(SERVER_ID, bomberman.position, my_id)

@rpc("any_peer", "call_local") # call_local para que el host tambien ejecute
func request_bomb_spawn(pos_solicitada: Vector2, player_id: int):
	# Solo el servidor crea bombas
	if not multiplayer.is_server():
		return
	
	# Buscar el bomberman que pidió la bomba
	var players_node = get_tree().current_scene.get_node("Players")
	var requesting_player = players_node.get_node_or_null(str(player_id))
	
	if not requesting_player or not requesting_player is Bomberman:
		print("Error: No se encontró el jugador ", player_id)
		return
	
	var bomb_system = requesting_player.get_node("BombPlacementSystem")
	
	if bomb_system.bomb_placed >= requesting_player.max_bombs:
		print("El jugador ", player_id, " ya alcanzó el máximo de bombas")
		return
	
	# Crear la bomba
	var bomb = BOMB_SCENE.instantiate()

	var bomb_position = Vector2(
		round(pos_solicitada.x / MACRO_TILE_SIZE) * MACRO_TILE_SIZE,
		round(pos_solicitada.y / MACRO_TILE_SIZE) * MACRO_TILE_SIZE
	)
	bomb.position = bomb_position
	bomb.explosion_size = bomb_system.explosion_size
	bomb.name = "Bomb_P" + str(player_id) + "_" + str(Time.get_ticks_msec())
	
	players_node.add_child(bomb, true)
	
	print("Bomba creada: ", bomb.name, " en posición ", bomb_position)
	
	# Tengo una bomba activa en el mapa.
	bomb_system.bomb_placed += 1
	
	# Notificar al cliente para que actualice su contador
	bomb_system.sync_bomb_count.rpc_id(player_id, bomb_system.bomb_placed)
	
	# Reproducir sonido en todos
	play_sound_rpc.rpc()
	
	# Cuando la bomba explote, decrementar el contador
	bomb.tree_exiting.connect(func(): 
		bomb_system.bomb_placed -= 1
		bomb_system.sync_bomb_count.rpc_id(player_id, bomb_system.bomb_placed)
	)

@rpc("authority", "call_local")
func sync_bomb_count(new_count: int):
	bomb_placed = new_count
	print("Bombas actuales: ", bomb_placed, "/", bomberman.max_bombs)

@rpc("any_peer", "call_local")
func play_sound_rpc():
	if audio_bomb:
		audio_bomb.play()
