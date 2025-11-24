extends Control

const PORT = 7000
# Para probar en la misma PC usa 127.0.0.1
# Para probar entre dos PCs en tu casa, pon la IP local del Servidor (ej: 192.168.0.X)
@export var address = "127.0.0.1" 

func _on_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Error al crear servidor: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	print("Servidor creado. Esperando jugadores...")
	
	# El HOST es quien fuerza el cambio de escena.
	start_game()

func _on_join_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Error al unirse: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	print("Conectando...")
	# NOTA: El cliente NO llama a start_game() manualmente si usas un Spawner.
	# Pero para este nivel de tutorial, lo dejaremos manual o esperaremos sync.
	# Lo más sencillo ahora es cargar la escena vacía y esperar que el Spawner llene todo.
	start_game()

func start_game():
	# IMPORTANTE: Asegúrate de que la ruta sea exacta (Mayúsculas/Minúsculas)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
