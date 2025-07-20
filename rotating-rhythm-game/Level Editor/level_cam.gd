extends Camera2D


const MINIMUM_BEAT = 1

# A small camera offset so that beat 0 isnt directly displayed as 
# being right on the top of the camera
@onready var minimum_beat_offset = Globals.beat_to_pixels(MINIMUM_BEAT)

func _ready():
	position = Vector2(Globals.screen_center.x,minimum_beat_offset)
	

func _on_level_editor_camera_moved(distance, max_boundary):
	
	position.y = clamp(position.y + distance,minimum_beat_offset,max_boundary)

func _on_level_editor_jump_to_beat(beat):
	position.y = Globals.beat_to_pixels(beat)
