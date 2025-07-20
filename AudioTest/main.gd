extends Node2D


var song_pos #position of the song in seconds

var song_pos_in_beats# The current position of the song in beats

var sec_per_beat # How long one beat lasts in seconds

var song_time # How much time passed since the song stared

var bpm  = SongManager.song_db["sakura_mankai"]# Song BPM for Sakura Mankai

var notes = []# The position in beats of all the notes in a song

# The index of the next note to be spawned like notes[next_index]
var next_index = 0

var beats_shown_in_advance = 0

@onready var audio = $AudioStreamPlayer

@export (PackedScene) var note

@export (PackedScene) var hold_note

@export (PackedScene) var note_goal

@onready var tween = $Tween


@onready var pos_test = $PosTester


var preview_song_data

# How far from the center of the screen the notes stop moving
# Expressed as a proportion.
# This will get a
var screen_split_proportion = 16

# Variable to be used with the note_timing_step() function to set the first beat to the 
var first_note_check = true

# A dictionary which will hold 4 arrays to be filled with the beats of notes
# in each respective track
var gameplay_note_manager = {
	1:[],
	2:[],
	3:[],
	4:[],
}

# A dictionary similar to the one above, but with hold notes instead
var gameplay_hold_note_manager = {
	1:[],
	2:[],
	3:[],
	4:[],
}

# A dictionary that will hold numbers corresponding to the 4 tracks and booleans 
# to see if the user is currently holding down on a hold note in that track
var held_tracks = {
	1:false,
	2:false,
	3:false,
	4:false
}

enum note_types {
	TAP_NOTE,
	HOLD_NOTE_START,
	HOLD_NOTE_END
}

# The note distance is set as a percentage of how far the note is away
# from the center of the screen

# Example: If a  notes distance is screen_center * 0.75 
# The note is 1 beat away from the center of the screen or 75% close to the screen
#
# On the flipside, notes that extend past the boundaries of the screen will have
# a negative multiplier 
#
# Example: If a note's distance is screen_center * -0.25 it is 
# 125% away from the screen and is 5 beats 

func load_tap_notes():
	"""
	A method that will take all the tap notes in the song data dictionary 
	received, instanciate them and load them so they can begin motion
	"""
	
	# Loop through all the tap notes in each track
	for track in preview_song_data["note data"]:
		
		for tap_note in preview_song_data["note data"][track]:
			
			var new_note = note.instantiate()
			
			add_child(new_note)
			
			tap_note["editor instance"] = new_note

			new_note.setup(tap_note["beat"],track-1)
	
	tap_note_start()

func tap_note_start():
	"""
	A function which will animate the position of all the notes such that they move independently of 
	frame rate towards their goal
	"""
	
	for track in preview_song_data["note data"]:
		
		for tap_note in preview_song_data["note data"][track]:
			
			var note_obj = tap_note["editor instance"]
			
			note_obj.look_at(Data.track_seek_position[track])
	
			tween.interpolate_property(
				
				note_obj,#object
				"position",#objects property
				note_obj.position,#initial state
				Data.screen_center,#final state
				tap_note["beat"] * sec_per_beat,#time
				Tween.TRANS_LINEAR,#transition type
				Tween.EASE_IN_OUT)#idk
				
			tween.start()
	
func tap_note_timing_setup():
	"""
	A function which will create a dictionary filled with the beats of 
	all the tap notes on screen
	"""
	
	for track in preview_song_data["note data"]:
		
		for tap_note in preview_song_data["note data"][track]:
			
			gameplay_note_manager[track].append(tap_note["beat"])
			
	for track in gameplay_note_manager:
		gameplay_note_manager[track].sort()
		
func hold_note_timing_setup():
	"""
	A function which will fill the gameplay hold note dictionary with the start
	and end beats of all the hold notes
	"""
	
	# dictionary which will only hold the start beats of every hold note in the 
	# preview song data dictionary
	var pure_start_beats = {
		1:[],
		2:[],
		3:[],
		4:[]
	}
	
	
	# Add all the start beats to the pure start beats dictionary
	for track in preview_song_data["hold note data"]:
		
		for hold_note in preview_song_data["hold note data"][track]:
			
			pure_start_beats[track].append(hold_note["start beat"])
			
	
	# Sort each track's start beats
	for track in pure_start_beats:
		pure_start_beats[track].sort()
	
	
	# With each track sorted, we can now loop through each hold note in
	# the preview song data dictionary and add information about start and 
	# end beats to the gameplay hold note manager
	for track in preview_song_data["hold note data"]:
		
		for hold_note in preview_song_data["hold note data"][track]:
			
			
			for start_beat in pure_start_beats[track]:
				
				if hold_note["start beat"] == start_beat:
					gameplay_hold_note_manager[track] = [ start_beat, hold_note["end beat"] ] 

	
		

func timing_compare(beat):
	"""
	A function that will compare the players timing to the perfect timing
	of a specified beat (AKA the time a note on that beat should reach the goal)
	"""
	var true_time = beat*sec_per_beat - sec_per_beat * Data.goal_pos_in_beats
	var player_time = song_pos
	
	var note_enter_threshold = 0.25
	
	if (true_time - player_time) < note_enter_threshold:
			
			# This will print the perfect ideal time (AKA the time it takes for the note to reach the goal)
			
			#print("True time: ",true_time)
		
			# This will print the player's time
			#print("Player time: ",player_time)
			
			# In the future this needs to return the difference between player time and true time
			return true
	
	return false
	
	
func tap_note_hit(track):
	"""
	A function which will program for the behavior of tap notes when they are hit.
	It will do this by comparing song times for when the note is supposed to be at the goal
	vs when the user made an input.
	"""
	
	# A variable to represent the 
	var current_beat

	# If there are still notes left in the track, set the current beat to the closest beat
	if len (gameplay_note_manager[track]) > 0:
		
		current_beat = gameplay_note_manager[track][0]
		
		if timing_compare(current_beat):
			
			gameplay_note_delete(track,current_beat)
			
			
func hold_note_start_hit(track):
	
	var curr_start_beat
	
	if len(gameplay_hold_note_manager[track]) > 0:
		
		
		curr_start_beat = gameplay_hold_note_manager[track][0]# access the start beat of the first occuring hold note
		
		if timing_compare(curr_start_beat):
			print("START")
			held_tracks[track] = true
		
func hold_note_end_hit(track):
	
	var curr_end_beat
	if len(gameplay_hold_note_manager[track]) > 0:
		
		
		curr_end_beat = gameplay_hold_note_manager[track][1]# access the start beat of the first occuring hold note
		
		if timing_compare(curr_end_beat):
			held_tracks[track] = false
			print("END")
		
	
func master_game_input_handle():
	"""
	A function meant to capture all input and call various methods ti deal with different
	cases in which different inputs are needed
	"""
	
	# If the user presses any of the buttons corresponding to track 1, 2, 3 or 4 
	if Input.is_action_just_pressed("gameplay_track_1"):
		print("Track 1")
		
		tap_note_hit(1)
		hold_note_start_hit(1)
	
	if Input.is_action_just_pressed("gameplay_track_2"):
		print("Track 2")
		tap_note_hit(2)
		hold_note_start_hit(2)
	
	if Input.is_action_just_pressed("gameplay_track_3"):
		print("Track 3")
		tap_note_hit(3)
		hold_note_start_hit(3)
	
	if Input.is_action_just_pressed("gameplay_track_4"):
		print("Track 4")
		tap_note_hit(4)
		hold_note_start_hit(4)
	
	
	# If the user lets go any one of the previous input buttons
	if Input.is_action_just_released("gameplay_track_1"):
		if held_tracks[1]:
			hold_note_end_hit(1)
	
	if Input.is_action_just_released("gameplay_track_2"):
		if held_tracks[2]:
			hold_note_end_hit(2)
	
	if Input.is_action_just_released("gameplay_track_3"):
		if held_tracks[3]:
			hold_note_end_hit(3)
	
	if Input.is_action_just_released("gameplay_track_4"):
		if held_tracks[4]:
			hold_note_end_hit(4)
			
			






func arrowhead_update():
	"""
	A function that will keep the arrowheads centered on the hold notes start position
	as they move towards the goal
	"""
	
	for track in preview_song_data["hold note data"]:
		for hold_note in preview_song_data["hold note data"][track]:
			
			
			var hold_note_obj = hold_note["editor instance"]
			
			if not hold_note_obj.is_shrinking:
				# Get half the length of the hold note
				var length = hold_note_obj.get_length()/2
				
				# Get the hold notes angle
				var ang =  hold_note_obj.rotation
				
				# From the total length and angle, calculate the x and y components of the 
				# right angle triangle formed by the angled hold note
				var x_length = length * cos(ang)
				
				var note_start_pos_x =  hold_note_obj.position.x + x_length
				
				var y_length = length * sin(ang)
				var note_start_pos_y =  hold_note_obj.position.y + y_length
				
				hold_note["arrow"].position = Vector2(note_start_pos_x,note_start_pos_y)


func hold_note_start():
	"""
	A function that will animate the hold notes such that they move towards their respective goal on the 
	track and shrink as they approach
	"""
	
	for track in preview_song_data["hold note data"]:
		
		for hold_note in preview_song_data["hold note data"][track]:
			
			
			var hold_note_obj = hold_note["editor instance"]
			hold_note["arrow"].rotation = hold_note_obj.rotation
			
			tween.interpolate_property(
				hold_note_obj,
				"position",
				hold_note_obj.position,
				hold_note_obj.tween_end_position,
				hold_note["start beat"] * sec_per_beat,
				Tween.TRANS_LINEAR,#transition type
				Tween.EASE_IN_OUT
			)
			
			tween.start()


func load_hold_notes():
	"""
	A method which will load all the hold notes onto the screen
	"""
	
	for track in preview_song_data["hold note data"]:
		
		for editor_hold_note in preview_song_data["hold note data"][track]:
			
			
			# Create an instance of a gameplay hold note
			var new_hold_note = hold_note.instantiate()
			add_child(new_hold_note)
			
			# Give the gameplay hold note the necessary parameters
			new_hold_note.start_beat = editor_hold_note["start beat"]
			new_hold_note.end_beat = editor_hold_note["end beat"]
			new_hold_note.track = track
			
			editor_hold_note["editor instance"] = new_hold_note
			
			var arrowhead = Sprite2D.new()
			arrowhead.texture = load("res://resources/hold_note_arrow.png")
			#arrowhead.scale = Vector2(1.3,1.3)
			add_child(arrowhead)
			
			editor_hold_note["arrow"] = arrowhead
			
			
			new_hold_note.spawn_beat()
			
	hold_note_start()


func hold_note_shrink(hold_note_obj):
	"""
	A function which will shrink a hold note in a single direction
	once it stops moving (aka has reached the goal)
	"""
	
	# This makes sure that we only tween the hold note once because for some reason
	# it just does that which is bad :(
	if not hold_note_obj.finished:
		
		
		# First tween the hold notes scale in order to shrink it 
		
		tween.interpolate_property(
			hold_note_obj,
			"scale:x",
			hold_note_obj.scale.x,
			0, # Shrink it to zero FOR NOW
			
			# The length is the number of beats in the hold note
			(hold_note_obj.end_beat - hold_note_obj.start_beat) * sec_per_beat,
			
			Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT
		)
		
		# Now tween its position. This step is crucial because its key to giving the 
		# illusion that the note is shrinking in one direction
		
		tween.interpolate_property(
			hold_note_obj,
			"position",
			hold_note_obj.position,

			# In later stages, since we dont want the hold note to completely dissapear but rather shrink
			# to the size of the goal and then dissapear 
			
			# Have the final destination be the 
			Vector2(
				hold_note_obj.end_position.x + hold_note_obj.get_rect().size.x/2 * cos(hold_note_obj.rotation),
				
				hold_note_obj.end_position.y + hold_note_obj.get_rect().size.y/2 * sin(hold_note_obj.rotation)
			),

			(hold_note_obj.end_beat - hold_note_obj.start_beat) * sec_per_beat,
			
			Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT

		)
		
		hold_note_obj.finished = true
		tween.start()
		

################
#
# Methods for dealing with signals
#
################

func miss_note_delete(note):
	
	"""
	A function that will specifically take in one note and delete it. To
	be used after a tween for a note has been fully completed AKA when the user 
	has missed a note
	"""
	
	for track in gameplay_note_manager:
		
		if track == note.curr_track+1:
			#print(gameplay_note_manager)
			for beat in gameplay_note_manager[track]:
				
				if beat == note.curr_beat:
					gameplay_note_manager[track].erase(beat)

	note.queue_free()


func gameplay_note_delete(track,current_beat):
	"""
	A function used for deleting notes when the user has hit them 
	"""
	
	# Iterate through all the tap notes
	for tap_note in preview_song_data["note data"][track]:
		
		if tap_note["beat"] == current_beat:
			
			tap_note["editor instance"].queue_free()
			
			gameplay_note_manager[track].erase(current_beat)
			
	
func _on_Tween_tween_completed(object, key):
	"""
	The signal function called whenever tweening is finished. 
	"""
	#print(key)
	# Object is the node and key is the property animated
	if object.id == "hold_note":
		#print(key)
		object.is_shrinking = true
		hold_note_shrink(object)
		
		if key == ":scale:x":
			held_tracks[object.track] = false
			print("DONE")
		
	else:
		miss_note_delete(object)
		

################
#
# Methods for dealing with signals (END)
#
################

func note_goal_spawn():
	for i in range(4):
		var curr_note_goal = note_goal.instantiate()
		add_child(curr_note_goal)
		curr_note_goal.setup(i+1)

func _ready():
	
	preview_song_data = SongDataIntermediate.curr_song_data
	
	note_goal_spawn()
	$Camera2D.position = Vector2(Data.screen_center.x,get_viewport_rect().size.y/2)

	sec_per_beat = 60.0/bpm

	song_time = audio.get_playback_position()
	
	load_tap_notes()
	load_hold_notes()
	audio.play()
	tap_note_timing_setup()
	hold_note_timing_setup()
	pos_test.position = Data.track_seek_position[1]
	#print("AUDIO IS PLAYING BUT THE EDITOR IS MUTED IN THE SOUND MIXER")


func _process(delta):
	
	song_pos = audio.get_playback_position() - song_time
	
	song_pos_in_beats = song_pos / sec_per_beat
	
	master_game_input_handle()
	
	arrowhead_update()
	
			
	if Input.is_action_just_pressed("beatmap_preview"):
		get_tree().change_scene_to_file("res://LevelEditor/LevelEditor.tscn")
