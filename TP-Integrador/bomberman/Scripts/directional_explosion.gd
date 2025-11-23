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
	# 1. CONEXIÓN VITAL: Le decimos al sprite que se autodestruya 
	#    cuando la animación termine.
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(self.queue_free)
		
	# 2. Aplicamos la animación que nos llegó por la red.
	#    (Esto es necesario para el estado inicial de sync).
	update_visuals()

func update_visuals():
	if animation_name != "" and animated_sprite_2d:
		animated_sprite_2d.play(animation_name)

# Esta función era la vieja, la mantenemos por compatibilidad o la borramos si actualizamos todo
# Pero ahora es mejor asignar la variable directamente desde afuera.
func play_animation(anim: String):
	animation_name = anim
	
func _on_area_entered(area: Area2D) -> void:
	if area is Bomberman:
		# Como esto corre en el cliente también, nos aseguramos de que
		# solo el servidor mate (o usamos RPC en el bomberman como ya tienes)
		if multiplayer.is_server():
			area.die() # O area.rpc("die")
