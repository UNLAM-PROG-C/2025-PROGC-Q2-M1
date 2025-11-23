extends Node

# --- 1. PRECARGAMOS LOS 4 SABORES DE BOMBERMAN ---
const PLAYER_SCENES = [
	preload("res://Scenes/WhiteBomberman.tscn"), # Jugador 0 (Host)
	preload("res://Scenes/BlackBomberman.tscn"), # Jugador 1
	preload("res://Scenes/RedBomberman.tscn"),   # Jugador 2
	preload("res://Scenes/GreenBomberman.tscn")  # Jugador 3
]
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
# --- 2. DEFINIMOS LAS 4 ESQUINAS (COORDENADAS) ---
# IMPORTANTE: Ajusta estos números (X, Y) para que caigan en las esquinas libres de tu mapa real.
# Puedes ver las coordenadas poniendo el mouse sobre el mapa en el editor.
const SPAWN_POSITIONS = [
	Vector2(16, 16),     # Esquina Superior Izquierda (Para el Blanco)
	Vector2(208, 208),   # Esquinsda Inferior Derecha (Para el Negro)
	Vector2(216, 24),    # Esquina Superior Derecha (Para el Rojo)
	Vector2(24, 184)     # Esquina Inferior Izquierda (Para el Verde)
]

# Contador para saber qué "turno" le toca al que entra
var players_loaded = 0

func _ready():
	# Solo el servidor se encarga de gestionar quién entra y quién sale
		
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		# El servidor se spawnea a sí mismo (ID 1) apenas inicia
		_on_peer_connected(1)

# Esta función se ejecuta SOLO EN EL SERVIDOR cada vez que alguien se conecta
func _on_peer_connected(id: int):
	if players_loaded >= 4:
		print("Sala llena")
		return

	var index = players_loaded
	print("--- SPAWNEANDO JUGADOR NUEVO ---")
	print("ID de Red: ", id)
	print("Índice de turno: ", index)
	
	# Verificar que no nos salimos del array
	if index >= SPAWN_POSITIONS.size():
		print("ERROR: ¡No hay más posiciones configuradas en SPAWN_POSITIONS!")
		return

	var spawn_pos = SPAWN_POSITIONS[index]
	print("Posición elegida: ", spawn_pos)
	
	var player_scene = PLAYER_SCENES[index]
	var player = player_scene.instantiate()
	
	player.name = str(id)
	player.player_id = id
	
	# Asignamos la posición
	player.global_position = spawn_pos
	print("Posición asignada al nodo: ", player.global_position)
	
	add_child(player)
	players_loaded += 1

func _on_peer_disconnected(id: int):
	# Si alguien se va, lo borramos del juego
	if has_node(str(id)):
		get_node(str(id)).queue_free()
		# Nota: No restamos players_loaded para evitar que si sale el Negro (1)
		# y entra otro, le den el Negro de nuevo y se superponga con la lógica.
		# (Para un juego simple esto está bien).
