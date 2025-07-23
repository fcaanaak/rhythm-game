extends Camera2D


const MINIMUM_BEAT = 1
const MAX_PLACEHOLDER = 10E3
# A small camera offset so that beat 0 isnt directly displayed as 
# being right on the top of the camera
@onready var minimum_beat_offset = Globals.beat_to_pixels(MINIMUM_BEAT)



func _ready():
	position = Vector2(Globals.screen_center.x,minimum_beat_offset)
	

##############################
# Signal Handlers
##############################

func _on_level_editor_update_camera(beat: float) -> void:
	
	var beat_distance = Globals.beat_to_pixels(beat)
	
	position.y = clamp(position.y + beat_distance,minimum_beat_offset,MAX_PLACEHOLDER)
