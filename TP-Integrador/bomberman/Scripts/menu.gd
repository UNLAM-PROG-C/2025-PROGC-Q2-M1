extends Control

const PORT = 7000
const DEFAULT_IP = "127.0.0.1" # IP Local (tu propia PC)

func _on_host_pressed() -> void:
	# 1. Creamos el peer (el conector)
	var peer = ENetMultiplayerPeer.new()
	
	# 2. Intentamos crear el Servidor
	var error = peer.create_server(PORT)
	if error != OK:
		print("Error al crear servidor: " + str(error))
		return
		
	# 3. Asignamos el conector al sistema multijugador global
	multiplayer.multiplayer_peer = peer
	
	# 4. ¡Arrancamos el juego!
	start_game()

func _on_join_pressed() -> void:
	# 1. Creamos el peer
	var peer = ENetMultiplayerPeer.new()
	
	# 2. Intentamos conectar como Cliente a la IP (Localhost por ahora)
	# Si quisieras jugar con un amigo en otra casa, cambiarías DEFAULT_IP por su IP pública.
	var error = peer.create_client(DEFAULT_IP, PORT)
	if error != OK:
		print("Error al intentar unirse: " + str(error))
		return
		
	# 3. Asignamos el conector
	multiplayer.multiplayer_peer = peer
	
	# 4. Arrancamos el juego (El cliente cargará el mapa y esperará a que el servidor le mande datos)
	start_game()

func start_game():
	# Cargamos la escena principal
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
