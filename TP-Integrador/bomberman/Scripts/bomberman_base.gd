extends Area2D

class_name Bomberman

# --- CONSTANTES ---
const MACRO_SPEED = 75
const MACRO_MAX_BOMBS = 1

# --- NODOS HIJOS ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var rayCasts: RayCasts = $RayCasts
@onready var bomb_placed_system: BombPlacementSystem = $BombPlacementSystem
@onready var power_up_system: PowerUpSystem = $PowerUpSystem

# --- VARIABLES DE MOVIMIENTO ---
var movement: Vector2 = Vector2.ZERO
@export var movement_speed: float = MACRO_SPEED
var max_bombs = MACRO_MAX_BOMBS

# --- CONFIGURACIÓN MULTIJUGADOR ---
# Estas variables definen qué teclas usa este personaje específico
@export_group("Configuración Jugador")
@export var animation_prefix: String = "black" 
@export var input_up: String = "move_up"
@export var input_down: String = "move_down"
@export var input_left: String = "move_left"
@export var input_right: String = "move_right"
@export var input_bomb: String = "place_bomb"

# ID de Red: Identifica quién controla este muñeco (1 = Servidor, números largos = Clientes)
@export var player_id := 1 :
	set(id):
		player_id = id
		# Esto le dice al motor de Godot: "El jefe de este nodo es el jugador con este ID"
		set_multiplayer_authority(id)

# Se ejecuta cuando el personaje entra al juego
func _enter_tree():
	# Intentamos asignar la autoridad basándonos en el nombre del nodo
	# (El MultiplayerSpawner suele nombrar los nodos con el ID del jugador)
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# Configuración de físicas
	self.collision_layer = 1   
	self.collision_mask = 64   
	
	# CÓDIGO DE DIAGNÓSTICO
	var label = Label.new()
	label.text = animation_prefix
	label.position.y = -50 # Flota sobre la cabeza
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

func _process(delta: float) -> void:
	# --- BLOQUEO DE SEGURIDAD MULTIJUGADOR ---
	# Si este personaje NO es mío (es el clon de mi amigo en mi pantalla),
	# detengo la función aquí. Su movimiento lo manejará el MultiplayerSynchronizer.
	if not is_multiplayer_authority():
		return 
	# -----------------------------------------

	var collisions = rayCasts.check_collisions()
	
	if collisions.has(movement):
		return
	
	# Si soy la autoridad, calculo el movimiento y lo aplico
	position += movement * delta * movement_speed

func _input(event: InputEvent) -> void:
	# --- BLOQUEO DE SEGURIDAD MULTIJUGADOR ---
	# Si toco una tecla, solo debe reaccionar MI personaje.
	if not is_multiplayer_authority():
		return
	# -----------------------------------------

	if Input.is_action_pressed(input_right):
		movement = Vector2.RIGHT
		play_anim("right")
	elif Input.is_action_pressed(input_left):
		movement = Vector2.LEFT
		play_anim("left")
	elif Input.is_action_pressed(input_down):
		movement = Vector2.DOWN
		play_anim("down")
	elif Input.is_action_pressed(input_up):
		movement = Vector2.UP
		play_anim("up")
	elif Input.is_action_just_pressed(input_bomb):
		bomb_placed_system.place_bomb()
		
	else:
		movement = Vector2.ZERO
		animated_sprite_2d.stop()

# Función auxiliar para animaciones
func play_anim(direction_suffix: String):
	var anim_name = animation_prefix + "_" + direction_suffix
	if animated_sprite_2d.sprite_frames.has_animation(anim_name):
		animated_sprite_2d.play(anim_name)

# Función de muerte
func die():
	play_anim("die") 
	movement = Vector2.ZERO
	set_process_input(false)
	queue_free()

# Función de PowerUps
func _on_area_entered(area: Area2D) -> void:
	if area is PowerUp:
		power_up_system.enable_power_up((area as PowerUp).type)
		area.queue_free()
