extends Node

# --- 1. LISTA DE ESCENAS DE JUGADORES ---
# En lugar de cargar solo uno, cargamos los 4 en un Array.
# El orden aquí define quién es el Jugador 1, 2, 3 y 4.
var character_scenes = [
	preload("res://Scenes/WhiteBomberman.tscn"), # Jugador 1 (Index 0)
	preload("res://Scenes/RedBomberman.tscn"),   # Jugador 2 (Index 1)
	preload("res://Scenes/BlackBomberman.tscn"), # Jugador 3 (Index 2)
	preload("res://Scenes/GreenBomberman.tscn")  # Jugador 4 (Index 3)
]

# 2. REFERENCIA AL CONTENEDOR
@onready var players_container = $Players

# 3. PUNTOS DE APARICIÓN (Ajustados para que no caigan en la pared)
# Estos valores suelen funcionar mejor si tus tiles son de 64px.
# Si quedan mal, puedes volver a poner los tuyos (48, 48).
var spawn_points = [
	Vector2(16, 16),     # J1: Arriba Izquierda - OK
	Vector2(16, 208),   # J2: Arriba Derecha - Por transform
	Vector2(208, 16),    # J3: Abajo Izquierda - Por transform
	Vector2(208, 208)   # J4: Abajo Derecha - OK
]

func _ready():
	# --- LÓGICA DE SERVIDOR ---
	if not multiplayer.is_server():
		return
	
	print("Soy el Host, iniciando gestión de jugadores...")
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# Crear al Host (Jugador 1)
	add_player(1)
	
	# Crear a los que ya estén conectados
	for peer_id in multiplayer.get_peers():
		add_player(peer_id)

func add_player(id: int):
	print("Generando personaje para ID: ", id)
	
	# 1. CALCULAR ÍNDICE
	# Contamos cuántos niños hay ya en el contenedor para saber si toca el J1, J2, etc.
	var index = players_container.get_child_count()
	
	# Usamos el operador % (módulo) para que si entra un 5º jugador,
	# vuelva a usar el skin del primero (rotación cíclica).
	var character_index = index % character_scenes.size()
	var spawn_index = index % spawn_points.size()
	
	# 2. ELEGIR LA ESCENA CORRECTA
	# Aquí ocurre la magia: sacamos la escena específica del Array
	var scene_to_spawn = character_scenes[character_index]
	var player_instance = scene_to_spawn.instantiate()
	
	# 3. CONFIGURAR
	player_instance.name = str(id) # El nombre debe ser el ID para la red
	player_instance.player_id = id
	player_instance.position = spawn_points[spawn_index]
	
	# 4. AÑADIR AL JUEGO
	# Al añadirlo, el MultiplayerSpawner detectará QUÉ escena es (White, Red, etc.)
	# y le dirá al cliente que cargue esa misma.
	players_container.add_child(player_instance, true)

func remove_player(id: int):
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

# Nota: Borré la función _asignar_color porque ya no hace falta pintar nada.
# Los colores ahora vienen "de fábrica" en cada escena (.tscn).
