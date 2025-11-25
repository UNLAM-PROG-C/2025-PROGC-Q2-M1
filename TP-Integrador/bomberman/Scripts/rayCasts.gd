extends Node2D

class_name RayCasts

@onready var right_horizontal_raycasts: Array[RayCast2D] = [
	$Horizontal/Right/RightHorizontalBottom,
	$Horizontal/Right/RightHorizontalTop
]

@onready var left_horizontal_raycasts: Array[RayCast2D] = [
	$Horizontal/Left/LeftHorizontalBottom,
	$Horizontal/Left/LeftHorizontalTop
]

@onready var top_vertical_raycasts: Array[RayCast2D] = [
	$Vertical/Top/TopVerticalRight,
	$Vertical/Top/TopVerticalLeft
]

@onready var bottom_vertical_raycasts: Array[RayCast2D] = [
	$Vertical/Bottom/BottomVerticalRight,
	$Vertical/Bottom/BottomVerticalLeft
]

func check_collisions(has_wall_pass: bool = false) -> Array[Vector2]:
	var collisions: Array[Vector2] = []
	
	var is_left_colliding = check_direction_collision(left_horizontal_raycasts, has_wall_pass)
	if is_left_colliding:
		collisions.append(Vector2.LEFT)
		
	var is_right_colliding = check_direction_collision(right_horizontal_raycasts, has_wall_pass)
	if is_right_colliding:
		collisions.append(Vector2.RIGHT)
		
	var is_top_colliding = check_direction_collision(top_vertical_raycasts, has_wall_pass)
	if is_top_colliding:
		collisions.append(Vector2.UP)
		
	var is_bottom_colliding = check_direction_collision(bottom_vertical_raycasts, has_wall_pass)
	if is_bottom_colliding:
		collisions.append(Vector2.DOWN)
	
	return collisions

func check_direction_collision(raycasts: Array[RayCast2D], has_wall_pass: bool) -> bool:
	for raycast in raycasts:
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			
			# Si tiene wall_pass, solo ignora brick_wall
			if has_wall_pass and collider.is_in_group("brick_wall"):
				continue
			
			# Cualquier otra colisión detiene el movimiento
			return true
	return false

func is_raycast_colliding(acc: bool, next: RayCast2D) -> bool:
	return next.is_colliding() || acc
