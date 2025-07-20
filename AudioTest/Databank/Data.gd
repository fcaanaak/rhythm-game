extends Node2D


@onready var screen_center = Vector2(
	get_viewport_rect().size.x/2,
	get_viewport_rect().size.y/2)
	
var current_song_path

var current_image_path
var curr_song_bpm


var new_level_data = {
	
	"song_path":"",
	"song_bpm":0,
	"image_path":"",
	"song_artist":"",
	"song_title":"",
	
	
}

# The reciprocal of how many beats can fit on the screen (eg 0.25 = 1/4) meaning 4 beats can fit on the screen
var game_beats_per_screen = 0.25

# How far from the center the goal for each note should be (for example if this value is 4, then the goal will be 
# placed at the center of the screen + or - the screen size divided by the <screen_split_proportion>)
var screen_split_proportion = 10

@onready var screen_size = Vector2(
	get_viewport_rect().size.x,
	get_viewport_rect().size.y
)

# A dictionary which will store the position of each ending note 
@onready var track_seek_position = {

	# This will cause the location of the end to be at the center of the screen + or - a fraction of the size of the screen
	# For example if screen_split_proportion is 16, then it would cause the value to be the center of the screen + or - 1/16th of the screen size
	1: Vector2(screen_center.x - screen_size.x/screen_split_proportion, screen_center.y - screen_size.y/screen_split_proportion),
	
	2: Vector2(screen_center.x - screen_size.x/screen_split_proportion, screen_center.y + screen_size.y/screen_split_proportion),
	
	3: Vector2(screen_center.x + screen_size.x/screen_split_proportion, screen_center.y - screen_size.y/screen_split_proportion),
	
	4: Vector2(screen_center.x + screen_size.x/screen_split_proportion, screen_center.y + screen_size.y/screen_split_proportion)
	
}


# A variable which holds the position of the goal in beats by using the inverse of the function which
# converts beats to coordinates
@onready var goal_pos_in_beats = (1/game_beats_per_screen)*(1-track_seek_position[1].x/Data.screen_center.x)

# a vraible to see if the screen has transitioned 
var is_transitioned = false

# A variable used to see the current level select group we are on
var curr_group_index = 0

var stored_score = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func midpoint_finder(start_coords,end_coords):
	
	"""
	A function that will use the midpoint formula on two different sets of points
	and return a vector that represents the points in between them 
	"""
	
	return Vector2(
		(end_coords.x + start_coords.x)/2, 
		(end_coords.y + start_coords.y)/2
	)

func length_finder(vect1,vect2):
	
	return sqrt(pow(vect1.x - vect2.x,2) + pow(vect1.y - vect2.y,2))
	
func gameplay_beat_to_coords(beat,track):
	
	"""
	A general purpose function that will convert the beats to on screen coordinates
	but only in the gameplay screen (This is independent from the level editor 
	beat to screen coords method)
	"""
	
	var dist_mult
	
	var coords
	
	match track:
		
		
		1:
			
			dist_mult = (-game_beats_per_screen * beat) + 1
			
			coords = Vector2(screen_center.x * dist_mult,screen_center.y * dist_mult)
			

		2:
			dist_mult = (game_beats_per_screen * beat) + 1
			
			coords = Vector2(
				screen_center.x * (-(game_beats_per_screen * beat) + 1),
				screen_center.y * dist_mult
			)
			
#			position.y = screen_center.y * dist_mult 
#			position.x = screen_center.x * (-(game_beats_per_screen * beat) + 1)

		3:
			dist_mult = (-game_beats_per_screen * beat) + 1
			
			# this is the same as taking the center of the screen and adding
			# it by quarter times itself times the beat
			coords = Vector2(
				screen_center.x * (game_beats_per_screen * beat + 1),
				screen_center.y * dist_mult
			)
#			position.x = screen_center.x * (game_beats_per_screen * beat + 1)
#			position.y = screen_center.y * dist_mult

		4:
			
			dist_mult = (game_beats_per_screen * beat) + 1
			#position.x = screen_center.x * dist_mult
			coords = Vector2(
				screen_center.x * dist_mult,
				screen_center.y * dist_mult
			)
		
	return coords
