extends Area2D

func _process(delta: float) -> void:
	get_node('Sprite2D').rotation += delta*10

func _on_area_entered(area: Area2D) -> void:
	area.get_parent().hurt(20,global_position.direction_to(area.global_position),100)
	print(global_position.direction_to(area.global_position))
