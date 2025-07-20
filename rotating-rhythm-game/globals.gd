extends Node

@onready var screen_dimensions = get_viewport().get_visible_rect().size
@onready var screen_center = 0.5*screen_dimensions

func beat_to_pixels(beat:float)->float:
	"""
	Converts a beat spacing into pixels
	
	Args:
		beat: How many beats to convert to pixels
		
	Returns: how many pixels that beat takes up on the screen
	
	"""
	
	# Formula uses unitary rates:
	# beats / (beats/screen) * (pixels/screen)
	var pixels_per_beat = Globals.screen_dimensions.y/float(SongData.beats_per_screen)
	return beat*(pixels_per_beat)
