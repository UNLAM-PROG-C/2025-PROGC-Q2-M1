extends Node

class_name BombPlacementSystem

const BOMB_SCENE = preload("res://Scenes/bomb.tscn")
const MACRO_TILE_SIZE = 16 # Ajusta a tu tamaño de tile (64, 32, 16)

@onready var audio_bomb: AudioStreamPlayer2D = $"../AudioBomb"
var bomberman : Bomberman = null

# Variables de control
var bomb_placed = 0
var explosion_size = 1

func _ready() -> void:
	bomberman = get_parent()

# --- ESTA FUNCION SE LLAMA CUANDO APRETAS LA TECLA ---
func place_bomb():
	# 1. Validación Local (Para no spamear si ya no tienes bombas)
	if bomb_placed >= bomberman.max_bombs:
		return
	
	# 2. EN LUGAR DE PONERLA TU, SE LO PIDES AL SERVIDOR
	# rpc_id(1, ...) significa: "Ejecuta esta función SOLO en la máquina del ID 1 (Host)"
	rpc_id(1, "request_bomb_spawn", bomberman.position)


# --- ESTA FUNCION SOLO SE EJECUTA EN EL SERVIDOR ---
@rpc("any_peer", "call_local")
func request_bomb_spawn(pos_solicitada: Vector2):
	# El servidor vuelve a validar por seguridad
	if bomb_placed >= bomberman.max_bombs:
		return

	# El Servidor crea la bomba
	var bomb = BOMB_SCENE.instantiate()
	
	# La ajustamos a la grilla (Snap to grid)
	var bomb_position = Vector2(
		round(pos_solicitada.x / MACRO_TILE_SIZE) * MACRO_TILE_SIZE,
		round(pos_solicitada.y / MACRO_TILE_SIZE) * MACRO_TILE_SIZE
	)
	bomb.position = bomb_position
	bomb.explosion_size = explosion_size
	
	# Asignamos autoridad (Generalmente el servidor se queda con la autoridad de las bombas)
	bomb.set_multiplayer_authority(1)
	
	# IMPORTANTE: Añadir la bomba al contenedor vigilado por el Spawner (Players)
	# Si tu estructura es main -> Players, usa esto:
	var players_node = get_tree().current_scene.get_node("Players")
	players_node.add_child(bomb, true)
	
	# Sonido (RPC para que suene en todos)
	play_sound_rpc.rpc()
	
	# Lógica interna (opcional, si quieres limitar bombas)
	# bomb_placed += 1
	# bomb.tree_exiting.connect(on_bomb_exploded)

@rpc("call_local")
func play_sound_rpc():
	if audio_bomb:
		audio_bomb.play()

func on_bomb_exploded():
	bomb_placed -= 1
