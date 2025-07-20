extends Sprite2D

const PLACEHOLDER_X = 100

func _init()->void:
	position = Vector2(PLACEHOLDER_X,0)
	
func _on_level_editor_jump_to_beat(beat:float)->void:
	position.y = Globals.beat_to_pixels(beat)
