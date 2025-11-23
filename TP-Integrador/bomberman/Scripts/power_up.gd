extends Area2D
class_name PowerUp

@onready var sprite_2d: Sprite2D = $Sprite2D

# --- CAMBIO CLAVE ---
# Agregamos @export para que aparezca en el Inspector y en el Sincronizador.
# Agregamos 'set' para que cuando cambie el tipo, cambie el dibujo.
@export var type: Utils.PowerUpType = Utils.PowerUpType.BOMB_UP :
	set(value):
		type = value
		# Usamos call_deferred para esperar al siguiente frame si el nodo está ocupado
		if is_inside_tree():
			update_texture()
		else:
			# Si aun no nació, esperamos al _ready
			await ready
			update_texture()

func _ready():
	self.collision_layer = 64
	self.collision_mask = 1
	# Al nacer, nos aseguramos de tener la textura correcta
	update_texture()

func update_texture():
	# Aquí asignamos la textura. Como es complejo pasar recursos por red,
	# lo más fácil es tener un array precargado o cargarlo dinámicamente.
	# Ejemplo simple cargando desde disco (asegurate que los nombres coincidan):
	
	# Si prefieres usar tu sistema actual de 'init', avísame, pero en red
	# es mejor que el tipo (INT) dicte la textura.
	var texture_path = ""
	match type:
		Utils.PowerUpType.BOMB_UP: texture_path = "res://Assets/PowerUpBombUp.png"
		Utils.PowerUpType.FIRE_UP: texture_path = "res://Assets/PowerUpFireUp.png"
		Utils.PowerUpType.SPEED_UP: texture_path = "res://Assets/PowerUpSpeedUp.png"
		Utils.PowerUpType.WALL_PASS: texture_path = "res://Assets/PowerUpWallPass.png"
	
	if texture_path != "" and sprite_2d:
		sprite_2d.texture = load(texture_path)

func _on_body_entered(body: Node2D) -> void:
	if body is Bomberman:
		# Importante: Pasar el 'type' al sistema del jugador
		body.power_up_system.enable_power_up(type)
		queue_free()
