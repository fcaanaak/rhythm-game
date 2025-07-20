extends Sprite2D


# Variables for the positioning of the note
var start_beat
var end_beat
var track

# The position on the screen (in coordinates where the note needs to end up)
var end_position
var start_position


var id = "hold_note"

# The final position of the note passed to the tween function after some 
# calculations are performed
var tween_end_position = Vector2.ZERO

var start_coords

var shrink_adjust = false

var finished = false

var is_shrinking = false

func spawn_beat():
	
	"""
	A function that will place the hold note directly in the middle of its start and 
	end beats 
	"""
	
	start_coords = Data.gameplay_beat_to_coords(start_beat,track)
	var end_coords = Data.gameplay_beat_to_coords(end_beat,track)
	
	
	# Spawn the note directly between the start and end notes
	position = Data.midpoint_finder(
		Data.gameplay_beat_to_coords(start_beat,track),
		Data.gameplay_beat_to_coords(end_beat,track)
	)
	
	look_at(
		Data.track_seek_position[track]
	)
	

	var diameter = get_rect().size.x
	
	
	# Scale initially scale the sprite a certain way I genuinely forgot how this works
	scale = Vector2(
		 sqrt(pow((start_coords.y - end_coords.y),2) + pow((start_coords.x - end_coords.x),2))/diameter,
		1
	)
	
	end_position = Data.track_seek_position[track]
	
	get_tween_end_pos()

func scale_move():

	
	position.x = Data.screen_center.x + (get_rect().size.x - get_length())/2 * cos(rotation)
	position.y = Data.screen_center.y + (get_rect().size.y - get_length())/2 * sin(rotation)


func get_tween_end_pos():
	"""
	A function which will modify where the hold note needs to end in the tween function. This is needed
	as without it, the hold notes will stop when the center of their sprites are at the goal, rather than
	their start portions. This is done by subtracting the end position by the horizontal and vertical components
	of the dimensions of the hold note sprite
	"""
	
	tween_end_position.x = end_position.x - (get_length()/2 * cos(rotation))
			
	tween_end_position.y = end_position.y - (get_length()/2 * sin(rotation))

	
func get_length():
	"""
	A function which when called, will return the total length of the of the hold note
	sprite as a vector
	"""
	
	# We're only concerned with the size x because it represents the length of the hold note sprite
	return (get_rect().size.x * scale.x)


func _process(delta):
	pass
	
func _ready():
	pass

