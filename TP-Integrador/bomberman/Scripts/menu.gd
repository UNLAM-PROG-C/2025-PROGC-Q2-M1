extends Control

const PORT = 7000
const INITIAL_TIME = 60.0
const FINISH_TIME = 0
const INITIAL_PLAYERS = 0
const MINIMUN_PLAYERS = 2
const MAX_PLAYERS = 4

# Referencias a la UI
@onready var menu_panel = $TextureRect
@onready var lobby_panel = $Lobby
@onready var player_count_label = $Lobby/VBoxContainer/PlayerCount
@onready var timer_label = $Lobby/VBoxContainer/Timer
@onready var start_button = $Lobby/VBoxContainer/Start
@onready var join_panel = $Join
@onready var ip_input = $Join/CenterContainer/VBoxContainer/IP
@onready var connect_button = $Join/CenterContainer/VBoxContainer/ButtonsContainer/Conectar
@onready var cancel_button = $Join/CenterContainer/VBoxContainer/ButtonsContainer/Cancelar

var players_connected = INITIAL_PLAYERS
var lobby_timer = INITIAL_TIME
var waiting_for_players = false

func _ready():
	# Limpiar cualquier conexión previa (por juego anterior)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Desconectar señales previas si existen (por juego anterior)
	if multiplayer.peer_connected.is_connected(_on_player_connected):
		multiplayer.peer_connected.disconnect(_on_player_connected)
	if multiplayer.peer_disconnected.is_connected(_on_player_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_player_disconnected)
	
	# Resetear variables
	players_connected = INITIAL_PLAYERS
	lobby_timer = INITIAL_TIME
	waiting_for_players = false
	
	# UI inicial
	if lobby_panel:
		lobby_panel.visible = false
	if menu_panel:
		menu_panel.visible = true
	if join_panel:
		join_panel.visible = false
	
	if connect_button:
		connect_button.pressed.connect(_on_connect_button_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_button_pressed)

func _on_host_pressed() -> void:
	# Limpiar peer anterior si existe (por juego previo)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Error al crear servidor: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Desconectar señales previas antes de reconectar (por juego anterior)
	if multiplayer.peer_connected.is_connected(_on_player_connected):
		multiplayer.peer_connected.disconnect(_on_player_connected)
	if multiplayer.peer_disconnected.is_connected(_on_player_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_player_disconnected)
	
	# Conectar señales
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	print("Servidor creado. Esperando jugadores...")
	
	players_connected = 1
	waiting_for_players = true
	show_lobby()

func _on_join_pressed() -> void:
	menu_panel.visible = false
	join_panel.visible = true
	ip_input.grab_focus()  # Poner cursor en el campo de texto

func _on_connect_button_pressed() -> void:
	var address = ip_input.text.strip_edges()
	
	if address.is_empty():
		print("Error: Debes ingresar una IP")
		return
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Error al unirse: " + str(error))
		# Volver al menú si falla
		join_panel.visible = false
		menu_panel.visible = true
		return
		
	multiplayer.multiplayer_peer = peer
	print("Conectando a: " + address)
	
	# Ocultar panel de join y mostrar espera
	join_panel.visible = false
	show_waiting_screen()

func _on_cancel_button_pressed() -> void:
	join_panel.visible = false
	menu_panel.visible = true

func _on_player_connected(id: int):
	print("Jugador conectado: ", id)
	players_connected += 1
	update_lobby_ui()
	
	# Si llegamos a 4, empezar automáticamente
	if players_connected >= MAX_PLAYERS:
		start_game_for_all()

func _on_player_disconnected(id: int):
	print("Jugador desconectado: ", id)
	players_connected -= 1
	update_lobby_ui()

func show_lobby():
	menu_panel.visible = false
	lobby_panel.visible = true
	if start_button:
		start_button.disabled = true  # Deshabilitado hasta tener 2 o mas
	update_lobby_ui()

func show_waiting_screen():
	# Para clientes: mostrar mensaje simple
	menu_panel.visible = false
	lobby_panel.visible = true
	player_count_label.text = "Esperando al host..."
	if timer_label:
		timer_label.visible = false
	if start_button:
		start_button.visible = false

func update_lobby_ui():
	if player_count_label:
		player_count_label.text = "Jugadores: %d/4" % players_connected
	
	if timer_label:
		timer_label.text = "Tiempo restante: %d segundos" % int(lobby_timer)
	
	if start_button:
		start_button.disabled = players_connected < MINIMUN_PLAYERS

func _process(delta):
	if not waiting_for_players:
		return
	
	lobby_timer -= delta
	
	if lobby_timer <= FINISH_TIME:
		# Si solo está el host, volver al menú
		if players_connected < MINIMUN_PLAYERS:
			print("Tiempo agotado. No se unieron jugadores. Volviendo al menú...")
			reset_lobby()
			return
		
		# Si hay 2 o mas jugadores, iniciar partida
		if multiplayer.is_server():
			start_game_for_all()
		lobby_timer = INITIAL_TIME
	
	update_lobby_ui()

func reset_lobby():
	waiting_for_players = false
	lobby_timer = INITIAL_TIME
	players_connected = INITIAL_PLAYERS
	
	# Desconectar peer
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Volver al menú
	if lobby_panel:
		lobby_panel.visible = false
	if menu_panel:
		menu_panel.visible = true
	
	print("Lobby cerrado. De vuelta al menú principal.")

func _on_start_button_pressed():
	# Solo el host inicia el juego
	if multiplayer.is_server() and players_connected >= MINIMUN_PLAYERS:
		start_game_for_all()

func start_game_for_all():
	waiting_for_players = false
	# Notificar a todos que empiece el juego
	start_game_rpc.rpc()

@rpc("authority", "call_local")
func start_game_rpc():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
