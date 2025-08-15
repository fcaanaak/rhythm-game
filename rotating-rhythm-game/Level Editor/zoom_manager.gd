extends Node


const zoom_multipliers = [
	1,
	2,
	3,
	4,
	6,
	8,
	12,
	16,
	24
]


var zoom = 1
var zoom_multipliers_index = 0



func _on_level_editor_increment_zoom(direction: int,max_index:int) -> void:
	zoom_multipliers_index = clamp(zoom_multipliers_index + direction,0,max_index)
	zoom = zoom_multipliers[zoom_multipliers_index]


func _on_level_editor_clamp_zoom(max_index: int) -> void:
	zoom_multipliers_index = 0
	zoom = zoom_multipliers[zoom_multipliers_index]
