extends Area2D

class_name CentralExplosion
const EXPLOSION_SIZE = 1
const TILE_SIZE = 16
const DIRECTIONAL_EXPLOSION = preload("res://Scenes/directional_explosion.tscn")

@onready var raycasts: Array[RayCast2D] = [
	$RayCasts/RayCastsUp,
	$RayCasts/RayCastsRight,
	$RayCasts/RayCastsDown,
	$RayCasts/RayCastsLeft
]
@onready var audio_explosion: AudioStreamPlayer2D = $AudioExplosion

var size = EXPLOSION_SIZE
var animation_names = ["explosion_up", "explosion_right", "explosion_down", "explosion_left"]
var animation_directions = [
	Vector2(0, -TILE_SIZE),
	Vector2(TILE_SIZE, 0),
	Vector2(0, TILE_SIZE),
	Vector2(-TILE_SIZE, 0)
]

func _ready() -> void:
	# Solo el servidor calcula colisiones
	if multiplayer.is_server():
		check_raycasts()

	audio_explosion.play()

func check_raycasts():
	for i in raycasts.size():
		check_raycasts_for_direction(animation_names[i], raycasts[i], animation_directions[i])

func check_raycasts_for_direction(animation_name: String, raycasts: RayCast2D, animation_direction: Vector2):
	raycasts.target_position = raycasts.target_position * size
	raycasts.force_raycast_update()
	if !raycasts.is_colliding():
		create_explosion_for_size(size, animation_name, animation_direction)
	else:
		var size_of_explosion = calculate_size_of_explosion(raycasts)
		#Esta linea me difine contra que choque
		var collider = raycasts.get_collider()
		if size_of_explosion != null:
			create_explosion_for_size(size_of_explosion, animation_name, animation_direction)
		execute_explosion_collision(collider)
		
func create_explosion_for_size(size: int, animation_name: String, animation_position: Vector2):
	for i in size:
		if i < size - 1:
			# Hasta llegar al ultimo tile, se crean animaciones intermedias
			create_explosion_animation_slice("%s_middle" % animation_name, animation_position * (i+1))
		else:
			create_explosion_animation_slice("%s_end" % animation_name, animation_position * (i+1))

func create_explosion_animation_slice(anim_name: String, anim_position: Vector2):
	var directional_explosion = DIRECTIONAL_EXPLOSION.instantiate()
	
	# 1. Sumamos nuestra posición actual (global_position) al offset
	directional_explosion.global_position = self.global_position + anim_position
	
	# 2. Asignamos el nombre
	directional_explosion.animation_name = anim_name 
	
	# 3. Agregamos al arbol (dispara el Spawner y manda los datos anteriores)
	get_tree().current_scene.get_node("Players").add_child(directional_explosion, true)
	
func calculate_size_of_explosion(raycasts: RayCast2D):
	var collider = raycasts.get_collider()
	if collider is TileMapLayer:
		var collision_point = raycasts.get_collision_point()
		var distance_to_collider = raycasts.global_position.distance_to(collision_point)
		var size_of_explosion_before_collider = max(roundi(absf(distance_to_collider) / TILE_SIZE - 1), 0)
		return	size_of_explosion_before_collider	

func execute_explosion_collision(collider: Object):
	if collider is BrickWall:
		(collider as BrickWall).rpc("destroy")

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()

#Godot envía la señal por detras, cuandos dos nodos del tipos Area2D se tocan
#Es por eso que es del tipo _on_area_entered
#Este tipo de función son callback de señales. Nosotros la escribimos nomas y la conectamos.
func _on_area_entered(area: Area2D) -> void:
	if area is Bomberman:
		if multiplayer.is_server():
			(area as Bomberman).die.rpc()
