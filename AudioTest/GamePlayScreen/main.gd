extends Node2D


var song_pos #position of the song in seconds

var song_pos_in_beats# The current position of the song in beats

var sec_per_beat # How long one beat lasts in seconds

var song_time # How much time passed since the song stared

var bpm 

var notes = []# The position in beats of all the notes in a song

# The index of the next note to be spawned like notes[next_index]
var next_index = 0

var beats_shown_in_advance = 0

@onready var audio = $AudioStreamPlayer

@export (PackedScene) var note

@export (PackedScene) var hold_note

@export (PackedScene) var note_goal

@onready var tween = $Tween


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

var is_paused = false # A boolean to see if the game is paused

# The player's numerical score
var player_score = 0

var note_velocity

##########################################################
# METHODS FOR TAP NOTE BEHAVIOR AND SETUP
##########################################################

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
			
			
			# Make a unit beat with a beat of one and a note position of 1 beat from the goal
			
#			var unit_coords = Data.gameplay_beat_to_coords(1,track)
#
#			var total_distance = sqrt( pow(unit_coords.x - Data.screen_center.x,2) + pow(unit_coords.y - Data.screen_center.y,2) )
#
#			note_velocity = 1
#			#note_velocity = total_distance/(sec_per_beat)
			
			
#			print(note_obj.position)
#
#			print("time " + str(tap_note["beat"] * sec_per_beat))
			
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
		

func timing_compare(beat,note_enter_threshold = 0.25):
	"""
	A function that will compare the players timing to the perfect timing
	of a specified beat (AKA the time a note on that beat should reach the goal)
	"""
	var true_time = beat*sec_per_beat - sec_per_beat * Data.goal_pos_in_beats
	var player_time = song_pos + AudioServer.get_time_since_last_mix()
	
	player_time -= AudioServer.get_output_latency()
	
	#var note_enter_threshold = 0.25
	
	
	if (true_time - player_time) < note_enter_threshold:
			# This will print the perfect ideal time (AKA the time it takes for the note to reach the goal)
			
			#print("True time: ",true_time)
		
			# This will print the player's time
			#print("Player time: ",player_time)
			
			# In the future this needs to return the difference between player time and true time
			
			return [true,true_time-player_time]
	
	return [false,true_time-player_time]
	
	
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
		
		var hit_info = timing_compare(current_beat)
		
		if hit_info[0]:
			
			timing_judge(hit_info[1])
			$ScoreLabel.global_position = Data.screen_center
			
			gameplay_note_delete(track,current_beat)

func timing_judge(time):
	"""
	A function which will take in a timing for when the user hit the note compared to 
	perfect timing and return a score for that note 
	
	The three scores are GOOD, GREAT, and PERFECT
	"""
	
	
	if time <= 0.13 and time >= -0.005:

		$ScoreLabel.global_position = Data.screen_center
		
		player_score += 500
		score_label_update("PERFECT")
		#$ScoreLabel.text = "PERFECT " + str(time)+ " SCORE: " + str(player_score)
		
		

	elif abs(time) > 0.005:
		$ScoreLabel.global_position = Data.screen_center
		
		player_score += 300
		score_label_update("GREAT")
		#$ScoreLabel.text = "GREAT " + str(time) + " SCORE: " + str(player_score)

	
			
			
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
			
			
##########################################################
# METHODS FOR TAP NOTE BEHAVIOR AND SETUP (END)
##########################################################



##########################################################
# METHODS FOR HOLD NOTE BEHAVIOR AND SETUP 
##########################################################

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
			
			arrowhead.texture = load("res://resources/images/hold_note_arrow.png")
			arrowhead.scale = Vector2(1.3,1.3)
			
			add_child(arrowhead)
			
			editor_hold_note["arrow"] = arrowhead
	
	
			new_hold_note.spawn_beat()
			
			
	hold_note_translate()

func hold_note_offset_calc():
	
	var unit_coords = Data.gameplay_beat_to_coords(1,1)

	var total_distance = sqrt( pow(unit_coords.x - Data.screen_center.x,2) + pow(unit_coords.y - Data.screen_center.y,2) )

	
	note_velocity = total_distance/(sec_per_beat)
	
	var center_to_goal = Data.length_finder(Data.track_seek_position[1],Data.screen_center)
			
	var offset = center_to_goal/note_velocity
	
	return offset
	

func hold_note_translate():
	"""
	A function that will animate the hold notes such that they move towards their respective goal on the 
	track and shrink as they approach
	"""
	

				
	for track in preview_song_data["hold note data"]:
		
		for hold_note in preview_song_data["hold note data"][track]:
			
			
			var hold_note_obj = hold_note["editor instance"]
			hold_note["arrow"].rotation = hold_note_obj.rotation
			
			
			
		
			
			tween.interpolate_property(
				hold_note_obj, # object to be tweened
				"position", # property to tween 
				hold_note_obj.position, # initial state
				hold_note_obj.tween_end_position,# final state
				hold_note["start beat"] * sec_per_beat - hold_note_offset_calc(),#time 
				Tween.TRANS_LINEAR,#transition type
				Tween.EASE_IN_OUT
			)
				
			
			tween.start()
		
		
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
					gameplay_hold_note_manager[track].append([ start_beat, hold_note["end beat"] ])


func hold_note_start_hit(track):
	"""
	A function that will detect if the user has pressed the start beat of a hold note on the valid time
	"""
	var curr_start_beat
	
	if len(gameplay_hold_note_manager[track]) > 0:
		
		
		curr_start_beat = gameplay_hold_note_manager[track][0][0]# access the start beat of the first occuring hold note
		
		if timing_compare(curr_start_beat)[0]:
			#print("START")
			
			
			held_tracks[track] = true
			#print(gameplay_hold_note_manager)


func hold_note_end_hit(track):
	"""
	A function that will detect when the user has released a hold note
	"""
	var curr_end_beat
	
	# If there are any hold notes left
	if len(gameplay_hold_note_manager[track]) > 0:
		
		
		curr_end_beat = gameplay_hold_note_manager[track][0][1]# access the endbeat of the first occuring hold note
		
		# If the user has successfully held the note to the end
		if timing_compare(curr_end_beat,0.05)[0]:
			
			held_tracks[track] = false
			
			
			
			
			# If the player lands the hold note, update their score by the 100* the number of beats
			# in the hold note
			player_score += 100*(gameplay_hold_note_manager[track][0][1] - gameplay_hold_note_manager[track][0][0])
			
			score_label_update("OK")
			gameplay_hold_note_manager[track].pop_front()
		
			#print("END")
		
		# If the user lets go early
		else:
			print("MISS")
			
			
			for hold_note in preview_song_data["hold note data"][track]:
					
				if hold_note["end beat"] == curr_end_beat:
					
					hold_note_miss_mode(hold_note["editor instance"])
						#hold_note_miss_mode(hold_note["arrow"])

					gameplay_hold_note_manager[track].pop_front()
						
			held_tracks[track] = false

func hold_note_miss_mode(hold_note_obj):
	"""
	A function which will take in a hold note object and change the hold note's appearance when the user has 
	missed the hold note
	"""
	
	hold_note_obj.modulate = Color(0.3,0.3,0.3)
	get_note_from_obj(hold_note_obj)["arrow"].modulate = Color(0.3,0.3,0.3)


func hold_note_miss_checker():
	"""
	A function which will check all the hold note start positions and check to see
	"""
	
	# Loop through all the tacks in the dictionary that only holds start and end beats for hold notes
	for track in gameplay_hold_note_manager:
		
		# Make sure the track has hold notes in it
		if len(gameplay_hold_note_manager[track]) > 0:
			
			# Get the current hold note beat
			var curr_start_beat = gameplay_hold_note_manager[track][0][0]
			
			
			# If the song has progressed past the time it takes for the start beat of the hold note
			# to reach its goal and the user hasnt made an input, inform them of a miss
			if song_pos > curr_start_beat * sec_per_beat + 0.25:
				
				if not held_tracks[track]:
					
					
					# Get the current hold note
					var curr_hold_note = get_note_from_data(curr_start_beat,track,true)
					
					hold_note_miss_mode(curr_hold_note["editor instance"])
					
					
	
	
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


##########################################################
# METHODS FOR HOLD NOTE BEHAVIOR AND SETUP 
##########################################################

func master_game_input_handle():
	"""
	A function meant to capture all input and call various methods ti deal with different
	cases in which different inputs are needed
	"""
	
	if not is_paused:
		# If the user presses any of the buttons corresponding to track 1, 2, 3 or 4 
		if Input.is_action_just_pressed("gameplay_track_1"):
		
			tap_note_hit(1)
			hold_note_start_hit(1)
		
		if Input.is_action_just_pressed("gameplay_track_2"):
			
			tap_note_hit(2)
			hold_note_start_hit(2)
		
		if Input.is_action_just_pressed("gameplay_track_3"):
			
			tap_note_hit(3)
			hold_note_start_hit(3)
		
		if Input.is_action_just_pressed("gameplay_track_4"):
			
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
		
		if Input.is_action_just_pressed("pause_game"):
			game_pause()
			get_tree().paused = true
			is_paused = true
		
		if Input.is_action_just_pressed("level_retry"):
			get_tree().change_scene_to_file("res://GamePlayScreen/main.tscn")
		
		if Input.is_action_just_pressed("info_display"):
			print(song_pos)
			
			
	else:
		if Input.is_action_just_pressed("pause_game"):
			get_tree().paused = false
			$PauseMenu.visible = false
			is_paused = false
		

func get_note_from_obj(obj):
	"""
	A function that will take in an object and search through all the note data arrays in the preview
	song data dictionary
	"""
	
	# First check the tap notes
	for track in preview_song_data["note data"]:
		
		# For all the tap notes, if the editor instance object of the tap note
		# is equal to the object passed in, return the entire tap note
		for tap_note in preview_song_data["note data"][track]:
			if tap_note["editor instance"] == obj:
				return tap_note
				
				
	# Reoeat the same process as above but this time with hold notes
	for track in preview_song_data["hold note data"]:
		
		for hold_note in preview_song_data["hold note data"][track]:
			if hold_note["editor instance"] == obj:
				return hold_note


func get_note_from_data(beat,track,is_hold):
	"""
	A function that will return a note by searching for notes or hold notes
	that fit the attributes passed into the function
	"""
	
	if is_hold:
		
		for hold_note in preview_song_data["hold note data"][track]:
			
			if hold_note["start beat"] == beat:
				
				return hold_note
	
	else:
		
		for tap_note in preview_song_data["note data"][track]:
			
			if tap_note["beat"] == beat:
				
				return tap_note


################
#
# Methods for dealing with signals
#
################

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
			player_score += 100*(object.end_beat - object.start_beat)
			
			score_label_update("OK")
		
			get_note_from_obj(object)["arrow"].queue_free()
			gameplay_hold_note_manager[object.track].pop_front()
			#print("DONE")
		
	else:
		miss_note_delete(object)
		

################
#
# Methods for dealing with signals (END)
#
################

################
#
# OTHER METHODS
#
################

func note_goal_spawn():
	for i in range(4):
		var curr_note_goal = note_goal.instantiate()
		add_child(curr_note_goal)
		curr_note_goal.setup(i+1)


func game_pause():
	"""
	A method to add behavior for whenever the user decides to pause the game
	"""
	
	$PauseMenu.visible = true
	
	$PauseMenu.global_position = Vector2(
		Data.screen_center.x - $PauseMenu.get_rect().size.x/2,
		Data.screen_center.y - $PauseMenu.get_rect().size.y/2)
		

func _on_ResumeButton_pressed():
	"""
	Handle behavior for whenever the user presses the button to resume the game
	"""
	is_paused = false
	get_tree().paused = false
	$PauseMenu.visible = false

func _on_RetryButton_pressed():
	"""
	Handle behavior for whenever the user presses the button to retry the level
	"""
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://GamePlayScreen/main.tscn")
	

func _on_MenuButton_pressed():
	"""
	Handle behavior for when you press the button to go back to the level select screen
	"""
	get_tree().paused = false
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
	
	#get_tree().change_scene("res://LevelSelect/LevelSelect.tscn")
	

func level_over_check():
	"""
	A function which will be called whenever the song for a level ends (indicating that the level is over)
	"""
	
	# This is a good enough way to detect if the song is over 
	if audio.stream.get_length() - song_pos < 0.04:
	
		audio.stop()# Stop the audio from playing again
		
		# Store the players score in the data file so that can be accessed by the 
		# level result screen
		Data.stored_score = player_score
		
		
		await get_tree().create_timer(1.0).timeout# Wait 1 second
		
		$TransitionScreen.transition_in("res://LevelResultsScreen/LevelResultScreen.tscn")
		
func score_label_update(message):
	$ScoreLabel.text = message + ": " + str(player_score)

func _ready():
	
	$TransitionScreen.transition_out()
	get_viewport().process_mode = Node.PROCESS_MODE_ALWAYS
	
	
	preview_song_data = SongDataIntermediate.curr_song_data
	bpm = preview_song_data["bpm"]
	note_goal_spawn()
	$Camera2D.position = Vector2(Data.screen_center.x,get_viewport_rect().size.y/2)
	
	audio.stream = load(preview_song_data["song path"])
	#print(preview_song_data["song path"])
	
	sec_per_beat = 60.0/bpm

	song_time = audio.get_playback_position()
	
	audio.connect("finished", Callable(self, "_on_audio_finished"))
	
	load_tap_notes()
	load_hold_notes()
	audio.play()
	tap_note_timing_setup()
	hold_note_timing_setup()
	
	#print(audio.stream.get_length())
	

	#print("AUDIO IS PLAYING BUT THE EDITOR IS MUTED IN THE SOUND MIXER")


func _process(delta):
	
	song_pos = audio.get_playback_position() - song_time
	
	song_pos_in_beats = song_pos / sec_per_beat
	
	master_game_input_handle()
	
	arrowhead_update()
	hold_note_miss_checker()
	
	if SongDataIntermediate.is_previewing:
		if Input.is_action_just_pressed("beatmap_preview"):
			get_tree().change_scene_to_file("res://LevelEditor/LevelEditor.tscn")
	
	level_over_check()
