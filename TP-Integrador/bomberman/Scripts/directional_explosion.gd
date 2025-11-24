extends Area2D
class_name DirectionalExplosion

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Creamos una variable que se pueda sincronizar
@export var animation_name: String = "" :
	set(value):
		animation_name = value
		# Si recibimos el dato, actualizamos el dibujo
		if is_inside_tree():
			update_visuals()

func _ready():
	# Sprite se destruye cuando animacion termina
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(self.queue_free)

	# Aplicar animacion que llego por red
	update_visuals()

func update_visuals():
	if animation_name != "" and animated_sprite_2d:
		animated_sprite_2d.play(animation_name)

func play_animation(anim: String):
	animation_name = anim

func _on_area_entered(area: Area2D) -> void:
	if area is Bomberman:
		if multiplayer.is_server():
			(area as Bomberman).die.rpc()
