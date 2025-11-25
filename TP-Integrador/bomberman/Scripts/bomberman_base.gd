extends Area2D

class_name Bomberman

# Señal para detectar muerte
signal player_died

# Constantes
const MACRO_SPEED = 75
const MACRO_MAX_BOMBS = 1
var is_alive = true

# Nodos Hijo
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var rayCasts: RayCasts = $RayCasts
@onready var bomb_placed_system: BombPlacementSystem = $BombPlacementSystem
@onready var power_up_system: PowerUpSystem = $PowerUpSystem

# Variables de movimiento
var movement: Vector2 = Vector2.ZERO
@export var movement_speed: float = MACRO_SPEED
var max_bombs = MACRO_MAX_BOMBS

@export var has_wall_pass: bool = false

# Configuracion Multijugador
@export_group("Configuración Jugador")
@export var animation_prefix: String = "black" 
@export var input_up: String = "move_up"
@export var input_down: String = "move_down"
@export var input_left: String = "move_left"
@export var input_right: String = "move_right"
@export var input_bomb: String = "place_bomb"

# ID de Red
@export var player_id := 1 :
	set(id):
		player_id = id
		set_multiplayer_authority(id)

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	self.collision_layer = 1   
	self.collision_mask = 64   

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var collisions = rayCasts.check_collisions(has_wall_pass)
	if collisions.has(movement):
		return
	position += movement * delta * movement_speed

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

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

func play_anim(direction_suffix: String):
	var anim_name = animation_prefix + "_" + direction_suffix
	if animated_sprite_2d.sprite_frames.has_animation(anim_name):
		animated_sprite_2d.play(anim_name)

@rpc("any_peer", "call_local")
func die():
	is_alive = false
	
	# Cliente verifica localmente si debe mostrar game over
	if is_multiplayer_authority():
		show_game_over()

	# Solo el servidor emite la señal
	if multiplayer.is_server():
		player_died.emit()
	
	# Sincronizar visualmente la muerte
	die_sync()

func die_sync():
	play_anim("die") 
	movement = Vector2.ZERO
	set_process_input(false)
	await get_tree().create_timer(1.5).timeout
	queue_free()

func show_game_over():
	const CUSTOM_FONT = preload("res://Assets/Fonts/PressStart2P-Regular.ttf")
	
	var overlay = CanvasLayer.new()
	overlay.name = "GameOverOverlay"
	overlay.layer = 100
	
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.3, 0.3, 0.3, 0.8)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(color_rect)
	
	var label = Label.new()
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.pivot_offset = label.size / 2
	
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	
	# Aplicada fuente retro
	label.label_settings.font = CUSTOM_FONT
	label.label_settings.font_size = 64
	label.label_settings.font_color = Color.RED
	label.label_settings.outline_size = 4
	label.label_settings.outline_color = Color.BLACK
	
	# Agregado de sombra
	label.label_settings.shadow_size = 10
	label.label_settings.shadow_color = Color.BLACK
	label.label_settings.shadow_offset = Vector2(4, 4)
	
	overlay.add_child(label)
	get_tree().root.add_child(overlay)


func _on_area_entered(area: Area2D) -> void:
	if area is PowerUp:
		power_up_system.enable_power_up((area as PowerUp).type)
		area.queue_free()
