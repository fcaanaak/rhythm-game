extends Sprite2D

var sec_per_beat

var dist_mult# A multiplier calculated for how far the note is from the origin

var curr_beat

var curr_track# Which track is the note placed on

enum tracks {NW,SE,SW,NE}

# This id variable is used to differentiate between tap notes and hold notes when the
# tween end signal has been called, allowing the main script to get the precise note
# and perform operations on it
var id = "tap_note"

# The final position on the screen for each note
var end_pos

# How many beats should fit on the screen 
var beats_per_screen = 0.25

# Variable to see if the note is done
var at_end = false


# A signal to be emitted whenever the notes get deleted
signal note_removed(beat,track)

# Called when the node enters the scene tree for the first time.
func _ready():
	
#	
	
	sec_per_beat = 60/SongDataIntermediate.curr_song_data["bpm"]
	
	
func setup(beat,track):
	curr_track = track
	set_pos_multiplier(beat)
	end_pos = Data.screen_center
	
	
func set_pos_multiplier(beat):
	
	match curr_track:
		
		# North West
		0:
			
		
			dist_mult = (-Data.game_beats_per_screen * beat) + 1
			position.y = Data.screen_center.y * dist_mult
			position.x = Data.screen_center.x * dist_mult
			

		#South Wast
		
		1:
			
			dist_mult = (Data.game_beats_per_screen * beat) + 1
			position.y = Data.screen_center.y * dist_mult 
			#position.x = Data.screen_center.x * dist_mult
			position.x = Data.screen_center.x * (-(0.25 * beat) + 1)
			

		
		# North East
		2:
			
			
			dist_mult = (-Data.game_beats_per_screen * beat) + 1
			# this is the same as taking the center of the screen and adding
			# it by quarter times itself times the beat
			position.x = Data.screen_center.x * (0.25 * beat + 1)
			position.y = Data.screen_center.y * dist_mult
			

		# SouthEast
		3:
			dist_mult = (Data.game_beats_per_screen * beat) + 1
			#position.x = Data.screen_center.x * dist_mult
			position.x = Data.screen_center.x * dist_mult
			position.y = Data.screen_center.y * dist_mult
			
	
	curr_beat = beat

#func end_check():
#
#
#	if not at_end:
#
#		if position == end_pos:
#
#			emit_signal("note_removed",1,2)
#
#			queue_free()
#
#			at_end = true

func _process(delta):
	pass
	#end_check()

