extends Sprite2D

const PLACEHOLDER_X = 100

func _init()->void:
	position = Vector2(PLACEHOLDER_X,0)
	


##############################
# Signal handlers
##############################
func _on_level_editor_update_arrow(beat: float) -> void:
	position.y = Globals.beat_to_pixels(beat)
