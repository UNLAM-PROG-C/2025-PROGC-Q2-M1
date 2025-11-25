extends Node

const CUSTOM_FONT = preload("res://Assets/Fonts/PressStart2P-Regular.ttf")

# El orden define quien es jugador 1, 2, 3 y 4.
var character_scenes = [
	preload("res://Scenes/WhiteBomberman.tscn"), # Jugador 1 (Index 0)
	preload("res://Scenes/RedBomberman.tscn"),   # Jugador 2 (Index 1)
	preload("res://Scenes/BlackBomberman.tscn"), # Jugador 3 (Index 2)
	preload("res://Scenes/GreenBomberman.tscn")  # Jugador 4 (Index 3)
]

@onready var players_container = $Players

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
	
	var index = players_container.get_child_count()
	var character_index = index % character_scenes.size()
	var spawn_index = index % spawn_points.size()
	
	var scene_to_spawn = character_scenes[character_index]
	var player_instance = scene_to_spawn.instantiate()
	
	player_instance.name = str(id)
	player_instance.player_id = id
	player_instance.position = spawn_points[spawn_index]
	
	# Conectar señal de muerte
	player_instance.player_died.connect(_on_player_died)
	players_container.add_child(player_instance, true)

func _on_player_died():
	# Solo el servidor verifica
	if not multiplayer.is_server():
		return
	
	# Esperar un frame para asegurar que el estado se actualizó
	await get_tree().process_frame
	check_for_winner()

func remove_player(id: int):
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func check_for_winner():
	if not multiplayer.is_server():
		return
	
	# Contar bomberman vivos
	var alive_players = []
	for child in players_container.get_children():
		if child is Bomberman and child.is_alive:
			alive_players.append(child)
	
	print("Jugadores vivos: ", alive_players.size())  # Debug
	
	# Si solo queda 1 vivo, es el ganador
	if alive_players.size() == 1:
		var winner = alive_players[0]
		var winner_color = winner.animation_prefix.capitalize()
		show_winner_rpc.rpc(winner_color, winner.player_id)
	elif alive_players.size() == 0:
		# Empate - todos murieron al mismo tiempo
		show_winner_rpc.rpc("Nadie", 0)

# RPC para mostrar la pantalla de victoria a todos
@rpc("authority", "call_local")
func show_winner_rpc(winner_name: String, winner_id: int):
	var tree = get_tree()

	# Eliminar todos los overlays existentes
	for child in tree.root.get_children():
		if "Overlay" in child.name or child is CanvasLayer:
			if child.name != "menu" and child != tree.current_scene:
				child.queue_free()
	
	# Esperar a que se procese la eliminación
	await tree.process_frame

	# Crear overlay de victoria
	var overlay = CanvasLayer.new()
	overlay.name = "VictoryOverlay"
	overlay.layer = 100
	
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.1, 0.1, 0.1, 0.85)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(color_rect)
	
	var label = Label.new()
	if multiplayer.get_unique_id() == winner_id:
		label.text = "¡VICTORIA!\n%s Bomberman Ganó" % winner_name
	else:
		label.text = "%s Bomberman\nHA GANADO" % winner_name
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# AQUI ESTA EL CAMBIO DE ESTETICA
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	
	# ASIGNAMOS LA FUENTE
	label.label_settings.font = CUSTOM_FONT 
	label.label_settings.font_size = 48 # Ajusta el tamaño
	label.label_settings.font_color = Color.GOLD
	
	# SOMBRA PARA QUE SE LEA MEJOR
	label.label_settings.shadow_size = 10
	label.label_settings.shadow_color = Color.BLACK
	label.label_settings.shadow_offset = Vector2(4, 4)
	
	
	overlay.add_child(label)
	tree.root.add_child(overlay)
	
	# Mostrar por 3 segundos
	await tree.create_timer(10.0).timeout
	overlay.queue_free()
	
	# Limpiar overlays que puedan haber quedado
	for child in tree.root.get_children():
		if "Overlay" in child.name or (child is CanvasLayer and child != tree.current_scene):
			child.queue_free()
	
	# Esperar 2 frames para asegurar limpieza completa
	await tree.process_frame
	await tree.process_frame
	
	# Cambiar de escena
	if tree:
		tree.change_scene_to_file("res://Scenes/menu.tscn")
