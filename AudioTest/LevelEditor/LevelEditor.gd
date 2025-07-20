extends Node2D

var selected_beat = 0 # Which beat is the user currently editing

var current_note_type # What type of note is the user actively selecting


# A variable that will hold an index which will be used to determine
# which beat to snap to
var beat_add_index = 0

# A list of all the possible beat fractions
var beat_mods = [
4.0/4.0, # full beat or 4th note
4.0/8.0, # half beat or 8th note
4.0/12, # third of a beat or 12th note
4.0/16, # quarter beat or 16th note
4.0/24, # 6th of a beat or 24th note
4.0/32, # 8th of a beat or 32nd note
4.0/48, # 12th of a beat or 48th note
4.0/64, # 16th of a beat or 64th note
4.0/96, # 24th of a beat or 96th note
#4.0/128,# 32nd of a beat or 128th note
#4.0/192, # 48th of a beat or 192th note
]

# An array which will hold all of the different chart zooming configurations
var zoom_mods = [
	16,
	12,
	8,
	4
]

# A multiplier for how much space one beat should take on the screen
# For example if its 16, then each beat should take up one 16th of the screen
var beat_to_screen_mod = 16

var zoom_mod_index = 0

@export (PackedScene) var beat_marker

@onready var audio_player = $AudioStreamPlayer

# A camera to scroll through the editor
@onready var camera = $LevelScrollCamera

# A sprite to point to the current active beat
@onready var beat_pointer = $BeatPointer

@onready var tweener = $Tween

var bar_marker_num = 0# An integer which will be put next to each bar

# An array to hold each beat marker
var beat_marker_list = []

# An array to hold each note marker
var note_marker_list = []

var bar_marker_list = []

var hold_note_activators = {
	1: false,# NW
	2: false,# SW
	3: false,# NE
	4: false# SE
}

var hold_note_mode = false
# A dictionary to hold all the data for the song



# Note data will have information for an editor instance which will be the 
# note class, a beat which will be used for placement and track for which 
# direction it will approach from

@onready var song_data = {
	"song length":0,
	"song stream":null,
	"bpm":Data.new_level_data["song_bpm"],
	
	"song title":Data.new_level_data["song_title"],
	"song artist":Data.new_level_data["song_artist"],
	"image path":Data.new_level_data["image_path"],
	
	"song path":Data.new_level_data["song_path"],
	
	# The note data dictionary holds key value pairs of the tracks and arrays to hold note data
	"note data":{
		1:[],
		2:[],
		3:[],
		4:[]
	},
	
	
	"hold note data":{
		1:[],
		2:[],
		3:[],
		4:[],
	}
	
}


# A variable to hold the dimensions of one bar, this will allow the 
# beat pointer arrow to stay in the same place regardless of screen size
var bar_line_rect

var track_to_note_pos = {
	
}

var total_beats

var note_snap_on = false

var first_save = true

var is_exiting = false# A boolean used to detect when the user is holding the escaoe button to quit
var exit_timer = false

func beat_to_screen_length(beat):
	var length = Data.screen_size.y * (beat+1)/beat_to_screen_mod
	
	return length
	

func hold_note_overlap_remove(is_end): 
	"""
	A function which will check to see if any hold notes are currently
	overlapping any tap notes and if so, will remove the tap notes. 
	"""
	
	var end_checker
	
	if !is_end:
		end_checker = selected_beat

	# For every hold note
	for track in song_data["hold note data"]:
		
		for hold_note in song_data["hold note data"][track]:
		
			# If the hold note in the hold note data dict is currently being edited
			if hold_note["is current"]:
				
				# Look for all the notes in the edited hold notes track
				for tap_note_track in song_data["note data"]:
					
						if is_end:
							
							end_checker = hold_note["end beat"]
							
						# For every tap note in the respective track
						for tap_note in song_data["note data"][track]:
							
							# If we current beat we are on is on a note (This means we moved the hold note 
							# to the position of a tap note), then remove the tap note
							
							if beat_to_screen_length(hold_note["start beat"]) <= beat_to_screen_length(tap_note["beat"]):
								
								if beat_to_screen_length(selected_beat) >= beat_to_screen_length(tap_note["beat"]):
									
									tap_note["editor instance"].queue_free()
									song_data["note data"][track].erase(tap_note)

func same_track_check(note_1,note_2):
	"""
	A simple function to check if two notes are in the same track, this works as
	when a note is placed in a track, its x position remains constant no matter
	where in the track is is placed. 
	"""
	if note_1["editor instance"].position.x == note_2["editor instance"].position.x:
		return true
	
	return false
	

func hold_note_hold_overlap_remove():
	"""
	A function to handle behavior for what happens if two
	hold notes overlap each other while one is being created
	in the editor
	"""
	
	var new_start_beat
	
	var current_hold_notes = []
	var new_end_beat
	var new_track
	
	# First make an array of all the current hold notes that are being edited
	for track in song_data["hold note data"]:
			
		for hold_note in song_data["hold note data"][track]:
			
			if hold_note["is current"]:
				current_hold_notes.append(hold_note)
	
	# Note loop through all the hold notes and check 
	for track in song_data["hold note data"]:
			
		for hold_note in song_data["hold note data"][track]:
			
			if not hold_note["is current"]:
				
				for curr_hold_note in current_hold_notes:
					
					if same_track_check(hold_note,curr_hold_note):
						
						if curr_hold_note["end beat"] >= hold_note["start beat"]:
							
							if curr_hold_note["start beat"] <= hold_note["start beat"]:
								new_start_beat = curr_hold_note["start beat"]
								new_end_beat = hold_note["end beat"]
								new_track = track
								
								curr_hold_note["editor instance"].queue_free()
								hold_note["editor instance"].queue_free()
								
								song_data["hold note data"][track].erase(hold_note)
								song_data["hold note data"][track].erase(curr_hold_note)
						
	
func master_input_detect():
	
	# Check to see if the user placed any notes
	note_place()
	
	if Input.is_action_just_pressed("ui_down"):
		
		# If the user holds down the ctrl key, expand the editor so they can see more
		if Input.is_action_pressed("zoom_enable"):
			zoom_in()

		else:
			
			if note_snap_on:
				nearest_beat_snap("down")
				
			elif Input.is_action_pressed("del_down_note"):
					nearest_beat_delete("down",0)
				
			else:
				# If the user isn't zooming, increment the beat
				hold_note_overlap_remove(false)
				beat_increment()
				
				# Use this when creating hold notes to remove any tap notes that 
				# we go over when creating a hold note
				hold_note_overlap_remove(false)
				
				hold_note_hold_overlap_remove()
				
				hold_note_grow_picker()

	if Input.is_action_just_pressed("ui_up"):
		
		# If the user has pressed both the ctrl key and navigated up to zoom out 
		if Input.is_action_pressed("zoom_enable"):
			zoom_out()
				
			
		else:
				if note_snap_on:
					nearest_beat_snap("up")
					
				elif Input.is_action_pressed("del_down_note"):
					nearest_beat_delete("up",0)
					
				else:
					# If we are currently editing a hold note, make sure that the user cannot
					# go above the hold notes starting position
					if hold_note_boundary_check():
						
						beat_decrement()
					
						hold_note_grow_picker()
			

	# Left and right are for moving through the beat mod array
	if Input.is_action_just_pressed("ui_left"):
		
		# if not on the first beat add index option
		previous_beat_mod()
			
		
	if Input.is_action_just_pressed("ui_right"):
		#if not on the last beat mod option
		next_beat_mod()
	
	if Input.is_action_just_pressed("clear_all_notes"):
		clearall()
	
	# Hold note stuff
	if Input.is_action_just_pressed("hold_note_enable"):
		hold_note_mode = true
		
		
	if Input.is_action_just_released("hold_note_enable"):
		hold_note_mode = false
	
	
	# Inputs for snapping to the closest note
	if Input.is_action_pressed("nearest_beat_snap"):
		note_snap_on = true
	
		
	if Input.is_action_just_released("nearest_beat_snap"):
		note_snap_on = false
	
	if Input.is_action_just_pressed("beatmap_preview"):
		beatmap_preview()
		
	if Input.is_action_just_pressed("manual_save"):
		
		level_save()
	
	#
	# REMEMBER TO DELETE THIS AS WE ONLY WANT TO DELETE ALL THE FILES FOR DEBUG PURPOSES
	#
	if Input.is_action_just_pressed("data_file_reset"):
		SongDataIntermediate.level_data_reset()
		SongDataIntermediate.level_data_load()
	
	
	if Input.is_action_just_pressed("level_edit_exit"):
		is_exiting = true
		
	if Input.is_action_just_released("level_edit_exit"):
		is_exiting = false
		
	

func hold_note_boundary_check():
	"""
	A function which check to see if the current beat is on the beginning
	of a hold note that is being created, this is meant to prevent the user
	from creating hold notes where the start beat is greater than the end beat
	"""
	
	var curr_list = []
		
	# Append all the start beats of the hold notes currently being created to an array
	for track in song_data["hold note data"]:
		
		for hold_note in song_data["hold note data"][track]:
		
			if hold_note["is current"]:
				curr_list.append(hold_note["start beat"])
			
	
	# If the current beat is NOT equal to the hold note with the greatest start note
	# return true
	if selected_beat != curr_list.max():
		return true
		
	
########################################################
# FUNCTIONS FOR ZOOMING IN AND OUT OF THE BEATMAP
########################################################
func other_zoom_update():
	"""A method to update the other nodes such as the camera
	and beat pointer when the editor is zoomed"""
	
	camera.position.y = Data.screen_size.y * selected_beat/beat_to_screen_mod +(Data.screen_size.y/beat_to_screen_mod)	
	beat_pointer.position.y = (selected_beat + 1)/beat_to_screen_mod * Data.screen_size.y

func note_zoom_update():
	"""A method that will update all the notes that have been currently placed
	and move them to the current beat they occupy by placing them on a beat marker
	with the same beat as the note
	"""
	
	for track in song_data["note data"]:
		
		for tap_note in song_data["note data"][track]:
		
			tap_note["editor instance"].position.y = Data.screen_size.y * tap_note["beat"]/beat_to_screen_mod \
			+ (Data.screen_size.y/beat_to_screen_mod)
	
func zoom_in():
	"""A function which will effectively 'zoom' the screen by increasing the
	margins between beats in the editor. This is done by changing the beat_to_screen_mod
	variable which is responsible for dividing the screen into beats."""
	
	# If we are not on the last option of the zoom mods array
	if zoom_mods[zoom_mod_index] != zoom_mods[-1]:
				
				zoom_mod_index += 1
				beat_to_screen_mod = zoom_mods[zoom_mod_index]
				
				beat_marker_zoom_update()# Update all the beat markers
				
				# Keeping this in stops stuff from breaking so its staying
				selected_beat -= (fposmod(selected_beat,beat_mods[beat_add_index])) 
				
				other_zoom_update()# Update other nodes like cameras
				
				note_zoom_update()# Update all the current notes placed in the beatmap
				
				hold_note_grow_picker(true)
				

func zoom_out():
	"""
	A function complimentary to zoom_in() which will instead zoom the editor out.
	This will effectively compress the chart.
	"""
	
	# if we aren't on the first zoom mod option
	if zoom_mod_index > 0:
		
		zoom_mod_index -= 1
		beat_to_screen_mod = zoom_mods[zoom_mod_index]
				
		beat_marker_zoom_update()
				
		# Keeping this in stops stuff from breaking so its staying
		selected_beat -= (fposmod(selected_beat,beat_mods[beat_add_index])) 
		
		camera.position.y = Data.screen_size.y * selected_beat/beat_to_screen_mod +(Data.screen_size.y/beat_to_screen_mod)
			
		beat_pointer.position.y = (selected_beat + 1)/beat_to_screen_mod * Data.screen_size.y
				
		note_zoom_update()
		
		hold_note_grow_picker(true)
	

func beat_marker_zoom_update():
	
	"""
	A function which will change the position of the
	beat markers after the user has zoomed in or out of the
	editor
	"""
	
	# Loop through the beat marker list array which contains dictionaries
	for beat_mark_data in beat_marker_list:
		
		# for each key in the dictionary in the array
		for current_beat_mark in beat_mark_data:
			
			# The key is an beat mark sprite so we place it at a the screens distance multiplied by the 
			# current beat we are on but divided by how much 
#			current_beat_mark.position.y = Data.screen_size.y * (beat_mark_data[current_beat_mark])/beat_to_screen_mod \
#		+ (Data.screen_size.y/beat_to_screen_mod)

			current_beat_mark.position.y = beat_to_screen_length(beat_mark_data[current_beat_mark]-1) \
		+ (Data.screen_size.y/beat_to_screen_mod)
			
			# If the current beat being zoomed is actually a bar
			if beat_mark_data[current_beat_mark] % 4 == 0:
				
				# Check through the list of bar marker labels and place the label
				# next to the corresponding bar
				for bar_marker in bar_marker_list:
					
					# We divide by 4 because the beats of the bars will be in 4's
					if int(bar_marker.text) == beat_mark_data[current_beat_mark]/4:
						
						bar_marker.position.y = current_beat_mark.position.y

########################################################
# FUNCTIONS FOR ZOOMING IN AND OUT OF THE BEATMAP ((END))
########################################################


########################################################
# FUNCTIONS FOR MOVING UP AND DOWN THE BEATMAP
########################################################

func beat_increment():
	"""
	A method meant to effectively progress through the beatmap chart by
	increasing the current beat and moving the camera and beat pointer
	accordingly.
	"""
	
	# Add increment the selected beat by the current beat modifier 
	selected_beat += beat_mods[beat_add_index]
	
	# Increment the camera's y position by the current beat multiplied
	# by the beat_to_screen_mod scale variable and the size of the screen vertically
	camera.position.y += (beat_mods[beat_add_index])/beat_to_screen_mod * Data.screen_size.y 
	
	beat_pointer.position.y = (selected_beat + 1)/beat_to_screen_mod * Data.screen_size.y
	
func beat_decrement():
	"""
	A complimentary method to beat_increment() which will instead decrement the current
	beat and adjust the camera and beat pointer
	"""
	
	# Decrement the current beat
	selected_beat -= beat_mods[beat_add_index]
	
	# If the current beat is less than zero (user tried to decrement at 0)
	if selected_beat < 0:
		selected_beat = 0
		
	# Not decrementing on 0, adjust the camera and pointer
	else:
		camera.position.y -= (beat_mods[beat_add_index] )/beat_to_screen_mod * Data.screen_size.y 
		
		beat_pointer.position.y = (selected_beat + 1)/beat_to_screen_mod * Data.screen_size.y
	

func beat_snap():
	"""
	A method which will snap the camera and beat pointer to the nearest note whenever
	a beat_mods option is changed
	"""
	
	# This step is crucial as it will round the beats up or down
	# to fit the current note timing we are on.
	# For example, if we are on 8th notes (half beat)
	# are on beat 2.5, and we want to switch to 
	# a quarter note (whole beats), when we switch, 
	# we'd need to subtract the selected beat by the remainder
	# of the selected beat and the current timing mode to round it 
	# to 2.
	selected_beat -= (fposmod(selected_beat,beat_mods[beat_add_index])) 
			
	camera.position.y = Data.screen_size.y * (selected_beat +1)/beat_to_screen_mod
	beat_pointer.position.y = (selected_beat + 1)/beat_to_screen_mod * Data.screen_size.y

func next_beat_mod():
	"""
	A small method which will make the beat modifier smaller and more precise
	as well as snapping the beats into place
	"""
	if beat_mods[beat_add_index] != beat_mods[-1]:
			beat_add_index += 1
			
			beat_snap()

func previous_beat_mod():
	
	if beat_add_index > 0:
		
			beat_add_index -= 1
			
			beat_snap()

########################################################
# FUNCTIONS FOR MOVING UP AND DOWN BEATMAP ((END))
########################################################


########################################################
# FUNCTIONS FOR PLACING AND MANIPULATING NOTES
########################################################

func note_remove_checker(track):
	"""A method that will check through the song data 
	notes array and determine whether or not the note
	the user has selected already exist. If it does, it will delete 
	the note and return true, blocking the spawn_note_marker function from
	spawning a new note there"""
	
	var curr_index = 0# Keep track of where we are in the array

	for note in song_data["note data"][track]:
		
		# If the note the user has selected already exists i.e it has 
		# identical properties to a note that exists in the song data dict
		# remove it and return true 
		if str(note["beat"]) == str(selected_beat):
			note["editor instance"].queue_free()
			song_data["note data"][track].remove(curr_index)
			
			return true
			
		curr_index += 1

	# Because the prior code will return true and break out of the function if 
	# we delete a note, if we do not delete a tap note, we then check to see
	# if we need to delete a hold note 
	
	if hold_note_remove_checker(track):
		return true
	
	else:
		return false
		

func spawn_note_marker(track):
	"""A function which will take in a number for the corresponding 
	track and spawn in a note in that place"""
	
	if not note_remove_checker(track):
		var note_marker = Sprite2D.new()
		
		note_marker.texture = load("res://resources/images/note.png")
		
		# remove later and just make the note sprite smaller
		note_marker.scale = Vector2(0.5,0.5)
		
		note_marker.position.y = Data.screen_size.y * selected_beat/beat_to_screen_mod \
		+ (Data.screen_size.y/beat_to_screen_mod)
		
			
		# Depending on which track we are on, place arrange the notes in various
		# horizontal places
		match track:
			
			1:
				note_marker.position.x = Data.screen_center.x - bar_line_rect.size.y/2
			
			2:
				note_marker.position.x = Data.screen_center.x - bar_line_rect.size.y/6
				
			3:
				note_marker.position.x = Data.screen_center.x + bar_line_rect.size.y/6
				
			4:
				note_marker.position.x = Data.screen_center.x + bar_line_rect.size.y/2
		
		# Update the song data dictionary 
		song_data["note data"][track].append({
			"beat":selected_beat,
			"editor instance": note_marker,
		})
		
		
		add_child(note_marker)
		
		
func nearest_beat_seek(direction,track=0):
	
	"""

	A function that will look for the closest note relative to the 
	where the beat pointer currently is and return its beat
	"""
	
	# Values for comparison and to check if this is our first time iterating
	var current_lowest_beat = 0
	var first_iter = true
	
	# If no track has been selected
	if track == 0:
		
		# Search through all the notes
		for track in song_data["note data"]:
			
			for note in song_data["note data"][track]:
				
				var current_note_beat = note["beat"]
				
				# If the notes have a beat greater than the current beat we're on
				if direction == "down":
					if current_note_beat >= selected_beat:
					
						# if this is the first time iterating the set the current lowest
						# beat to the first beat
						if first_iter:
							current_lowest_beat = current_note_beat
							first_iter = false
						
						# If its not our first time iterating then check to see if 
						# any of the notes are smaller than the current lowest beat
						else:
							if current_note_beat <= current_lowest_beat:
								current_lowest_beat = current_note_beat
			
			
				elif direction == "up":
					if current_note_beat <= selected_beat:
					
						# if this is the first time iterating the set the current lowest
						# beat to the first beat
						if first_iter:
							current_lowest_beat = current_note_beat
							first_iter = false
						
						# If its not our first time iterating then check to see if 
						# any of the notes are smaller than the current lowest beat
						else:
							if current_note_beat >= current_lowest_beat:
								current_lowest_beat = current_note_beat

		
		return current_lowest_beat

func nearest_hold_beat_seek(direction,track):
	"""A function that will be used to find the position of the hold note closeset
	to the where the player currently is on the level editor"""
	
	var current_beat
	
	var first_iter = true
	
	var current_lowest_beat
	
	if track == 0:
		
		for track in song_data["hold note data"]:
			
			for hold_note in song_data["hold note data"][track]:
				
				if direction == "down":
					current_beat = hold_note["start beat"]
					
					if current_beat >= selected_beat:
						if first_iter:
							current_lowest_beat = current_beat
							
						else:
							if current_beat <= current_lowest_beat:
								current_beat = current_lowest_beat
								
	pass
	
	
func nearest_beat_snap(direction, track=0,is_delete=false):
	"""
	A function which will take the user to the location of the nearest beat found
	
	NOTE: THIS WORKS TOP-DOWN MEANING THAT IT WILL LOOK FOR THE CLOSEST BEAT WITH A NOTE
	THAT IS BELOW THE CURRENT BEAT
	"""
	
	# Get the beat closest to where we are currently on the level editor
	var seek_beat

	seek_beat = nearest_beat_seek(direction,track)
	
	# if we are deleting the closest note
#	if is_delete:
#
#		# Look for all the notes that share the same beat as the closest beat
#		# found either up or down and delete all those notes
#		for track in song_data["note data"]:
#
#			for note in song_data["note data"][track]:
#
#				if note["beat"] == seek_beat:
#					note["editor instance"].queue_free()
#					song_data["note data"][track].erase(note)
#
#		# find the next nearest beat
#		seek_beat = nearest_beat_seek(direction,track)
#
#		# Move everything over 
#		$BeatPointer.position.y = beat_to_screen_length(seek_beat)
#		camera.position.y = beat_to_screen_length(seek_beat)
#
#		selected_beat = seek_beat# Dont forget to change this since this is snapping us to a new beat
		
	
		# Move everything over 
	$BeatPointer.position.y = beat_to_screen_length(seek_beat)
	camera.position.y = beat_to_screen_length(seek_beat)
		
	selected_beat = seek_beat

func nearest_beat_delete(direction,track):
	
	var closest_beat
	
	closest_beat = nearest_beat_seek(direction,track)

	# Look for all the notes that share the same beat as the closest beat
		# found either up or down and delete all those notes
	for track in song_data["note data"]:
		
		for note in song_data["note data"][track]:
			
			if note["beat"] == closest_beat:
				note["editor instance"].queue_free()
				song_data["note data"][track].erase(note)
		
		# find the next nearest beat
	closest_beat = nearest_beat_seek(direction,track)
	
	# Move everything over 
	$BeatPointer.position.y = beat_to_screen_length(closest_beat)
	camera.position.y = beat_to_screen_length(closest_beat)
	
	selected_beat = closest_beat# Dont forget to change this since this is snapping us to a new beat
	

func hold_note_remove_checker(track):
	"""
	A method which is used to remove any hold notes whenever the user
	spawns in a note in between the hold note
	"""
	
	for hold_note in song_data["hold note data"][track]:
		
	# if the selected beat is somwhere in between a hold note
		if hold_note["start beat"] <= selected_beat and selected_beat <= hold_note["end beat"]:
			
			hold_note["editor instance"].queue_free()
			print(song_data["hold note data"][track])
			song_data["hold note data"][track].erase(hold_note)
			return true
				
	return false

	
func start_note_remove_checker(track):
	"""
	A function which will remove any tap notes that collide with 
	a hold note as soon as its created
	"""
	
	for note in song_data["note data"][track]:
		
		
			
		if note["beat"] == selected_beat:
			
			note["editor instance"].queue_free()
			song_data["note data"].erase(note)

func spawn_hold_note_marker(track):
	
	"""
	A method that spawns in a hold note 
	and adds its information to the song data dictionary
	
	"""
	
	# This means that in the specified track, we are creating a hold note
	# This is used to stop the user from spawning tap notes at the same time
	# as hold notes
	hold_note_remove_checker(track)
	
	var hold_note_sprite = Sprite2D.new()
	hold_note_sprite.texture = load("res://resources/images/hold_note.png")
	hold_note_sprite.scale = Vector2(0.5,0.5)
	
	hold_note_sprite.position.y = Data.screen_size.y * selected_beat/beat_to_screen_mod \
		+ (Data.screen_size.y/beat_to_screen_mod)
		
		
		
	# Depending on which track we are on, place arrange the notes in various
	# horizontal places
	match track:
		
		1:
			hold_note_sprite.position.x = Data.screen_center.x - bar_line_rect.size.y/2
		
		2:
			hold_note_sprite.position.x = Data.screen_center.x - bar_line_rect.size.y/6
			
		3:
			hold_note_sprite.position.x = Data.screen_center.x + bar_line_rect.size.y/6
			
		4:
			hold_note_sprite.position.x = Data.screen_center.x + bar_line_rect.size.y/2
	
	add_child(hold_note_sprite)
	
	if not hold_note_activators[track]:
		hold_note_activators[track] = true
	
		# Add all the data to the song list
		song_data["hold note data"][track].append(
			{
				"start beat":selected_beat,
				"end beat": selected_beat,
				"is current": true,
				"editor instance":hold_note_sprite,
				
			}
		)
	

func hold_note_grow(hold_note,is_zoom):
	"""
	A function which will allow the hold notes to properly expand
	to the selected beat
	"""
	
	var start_pos = beat_to_screen_length(hold_note["start beat"])
	
	var end_beat
	
	if not is_zoom:
		end_beat = selected_beat
	else:
		end_beat = hold_note["end beat"]
	
	sprite_grow(hold_note["editor instance"],start_pos,end_beat)


func sprite_grow(sprite,start_pos,end_pos):

	"""
	A function which will take a sprite and 
	a start and end position and grow the sprite towards the target destination
	"""
	
	sprite.position.y = start_pos
	
	var diameter = sprite.get_rect().size.y
	
	var dist = abs(beat_to_screen_length(end_pos) - start_pos) + diameter/2
	
	var scale_factor = dist/diameter
	
	sprite.scale.y = scale_factor
	
	sprite.position.y += (sprite.get_rect().size.y*scale_factor/2)\
	- (sprite.get_rect().size.y/2)
		
		
func hold_note_grow_picker(is_zoom=false):
	"""
	A function which will take in a condition and determine
	whether to grow all the hold notes or just the ones begin edited.
	This is to differentiate between regrowing all the hold notes when the screen is zoomed
	and growing the hold notes that are currently being edited
	"""
	
	for track in song_data["hold note data"]:
		
		for hold_note in song_data["hold note data"][track]:
			
		
			# If the screen currently isnt being zoomed then the only thing that 
			# should be growing are current hold notes we are editing
			if not is_zoom:
				if hold_note["is current"]:
					hold_note_grow(hold_note,is_zoom)
			
			# If the screen is being zoomed there are two conditions we need to cover
			else:
				
				# If we are currently editing a note we need the notes final position
				# to be the selected beat
				if hold_note["is current"]:
					hold_note_grow(hold_note,false)
					
				# If we aren't editing a note we need the note's final growth position
				# to be its predefined end position
				else:
					 hold_note_grow(hold_note,is_zoom)
			


func hold_note_end(track):
	"""
	A method to finalize the position of the hold note
	and make sure that it is no longer currently being edited
	"""
	
	# This means that we are no longer creating a hold note and can 
	# once again place other notes in that track
	hold_note_activators[track] = false
	
	var curr_index = 0
	
	# Loop through all the hold notes
	for hold_note_mark in song_data["hold note data"][track]:
		
		
		# If the hold note in the current track is currently being modified
		if hold_note_mark["is current"]:
			
			# set this to false to that we dont end up changing the end position
			# of all the hold notes in this track
		
			if selected_beat == hold_note_mark["start beat"]:
				
				hold_note_mark["editor instance"].queue_free()
				song_data["hold note data"][track].erase(hold_note_mark)
				
			else:
				
				hold_note_mark["end beat"] = selected_beat
				hold_note_overlap_remove(true)
				
			hold_note_mark["is current"] = false
			
			

func note_decision_maker(track):
	"""
	A function which will take in a track and determine the behavior
	of the note 
	"""
	
	# If the user is holding shift and presses a button to place a note
	# and they arent already editing a hold note
	if hold_note_mode:
		
		if not hold_note_activators[track]:
			
			# Check to see if we placed a hold note directly on a preexisting tap note
			start_note_remove_checker(track)
			
			spawn_hold_note_marker(track)
			
	else:
			
			# If the hold note in the first track is already
			if hold_note_activators[track]:
				
				hold_note_end(track)
					
			else:
				
				spawn_note_marker(track)
	
func note_place():
	"""A function that will be used to place the notes in the 
	four respective tracks using the 1,2,3 and 4 keys
	NW: 1
	SW: 2
	NE: 3
	SE: 4
	"""
	
	if Input.is_action_just_pressed("nw_note_place"):

		 note_decision_maker(1)
	
	if Input.is_action_just_pressed("sw_note_place"):
		
		note_decision_maker(2)
	
	if Input.is_action_just_pressed("ne_note_place"):
		
		note_decision_maker(3)
	
	if Input.is_action_just_pressed("se_note_place"):
		
		note_decision_maker(4)


func clearall():
	"""
	A method which will first check to see if a hold note is being created, 
	"""
	
	var skip = false# A boolean to determine whether we should delete everything
	
	# This will check all the hold notes to determine if one of them is currently being
	# created, if so, set skip to true
	for track in song_data["hold note data"]:
		for hold_note in song_data["hold note data"][track]:
			if hold_note["is current"]:
				skip = true
	
	# If we are not creating a hold note, delete all the notes 
	if not skip:
		
		for track in song_data["note data"]:
			
			for note in song_data["note data"][track]:
				note["editor instance"].queue_free()
			
			song_data["note data"][track].clear()
			

		for track in song_data["hold note data"]:
			for hold_note in song_data["hold note data"][track]:
				hold_note["editor instance"].queue_free()
		
			song_data["hold note data"][track].clear()

########################################################
# FUNCTIONS FOR PLACING AND MANIPULATING NOTES ((END))
########################################################			

########################################################
# FUNCTIONS FOR PREVIEWING THE BEATMAP
########################################################			

func beatmap_preview():
	"""A function which will update a file that holds the song 
	data and switch to another scene which will preview the beatmap for the user"""
	
	SongDataIntermediate.curr_song_data = song_data
	SongDataIntermediate.reload = true
	SongDataIntermediate.is_previewing = true
	
	get_tree().change_scene_to_file("res://GamePlayScreen/main.tscn")


func reload_notes():
	
	"""
	A which will be called when the user switches from a preview back the the main level editor.
	Because Godot will delete the editor instances when the preview is activated, they need to be
	reinstanciated whenever we switch back to the level editor view.
	"""
	
	for track in song_data["note data"]:
		
		for tap_note in song_data["note data"][track]:
			
			var note_marker = Sprite2D.new()
			note_marker.texture = load("res://resources/images/note.png")
			note_marker.scale = Vector2(0.5,0.5)
			
			
			add_child(note_marker)
			
			note_marker.position.x = track_to_note_pos[track]
			
			note_marker.position.y = beat_to_screen_length(tap_note["beat"])
			
			tap_note["editor instance"] = note_marker
			
			
func reload_hold_notes():
	"""
	A function similar to reload_notes but specifically to reload all the hold notes on screen
	with their correct data
	"""
	
	# For each track in the hold note data section
	for track in song_data["hold note data"]:
		
		for hold_note in song_data["hold note data"][track]:
			print(hold_note)
			
			var hold_note_marker = Sprite2D.new()
			hold_note_marker.texture = load("res://resources/images/hold_note.png")
			hold_note_marker.scale = Vector2(0.5,0.5)

			add_child(hold_note_marker)

			hold_note_marker.position.x = track_to_note_pos[track]

			hold_note_marker.position.y = beat_to_screen_length(hold_note["start beat"])

			sprite_grow(hold_note_marker,beat_to_screen_length(hold_note["start beat"]),hold_note["end beat"])
			
			hold_note["editor instance"] = hold_note_marker
		
		
func reload_check():
	"""
	A function that is called whenever the users switches from the level preview screen back to the 
	level editor. It will load all the contents passed to the song data intermediate back into the
	main song data dictionary and load all the notes back on screen
	"""
	
	if SongDataIntermediate.reload:
		
		song_data = SongDataIntermediate.curr_song_data
		
		reload_notes()
		reload_hold_notes()
		
		SongDataIntermediate.reload = false
	
	# If we are not reloading assign a new ID to the song data dictionary
	# This is put here as this would otherwise give a new ID to the song data dict each time
	# the level was reloaded in the editor had it been placed in the _ready function
	else:
		
		song_data_id_assign()
		
		
########################################################
# FUNCTIONS FOR PREVIEWING THE BEATMAP ((END))
########################################################		


##############################
# METHODS FOR SETTING UP THE LEVEL EDITOR
##############################

func song_data_id_assign():
	"""
	A function which will look at the ID's in the level data dict in the 
	song data intermediate data file and create and assign a new unique ID
	for the current level being created
	"""
	
	# The total number of unique ids that can ever be created
	# In this case I've set it to 500,000 because who is going to realistically make that many
	var id_limit = 500000
	
	# If there exist other levels 
	if len(SongDataIntermediate.level_data["level ids"]) > 0:
		
		# Give the current song data an ID that can never be naturally assigned to it
		song_data["id"] = randi() % id_limit
		
		# Keep randomly changing the ID of the song data until it no longer matches any IDs already found
		# in the level ID array
		while song_data["id"] in SongDataIntermediate.level_data["level ids"]:
			
			song_data["id"] = randi() % id_limit
		
		
		SongDataIntermediate.level_data["level ids"].append(song_data["id"])


	# If no levels have been created yet
	else:
		
		song_data["id"] = randi() % id_limit
		SongDataIntermediate.level_data["level ids"].append(song_data["id"])
		



func beat_marker_place(total_beats):
	"""A function to place all the beat markers
	on the level editor screen by looping through
	each beat in the list and placing it 1/16th of the 
	way down the screen multiplied by itself and the screen size"""
	
	for beat in range(total_beats):
		
		var beat_mark_instance = beat_marker.instance()
		
		add_child(beat_mark_instance)
		
		beat_marker_list.append({beat_mark_instance:beat})
		# For every fourth beat, make it longer and thicker so it can be 
		# easily differentiated as a bar
		
		
		beat_mark_instance.position.x = Data.screen_center.x
		beat_mark_instance.position.y = Data.screen_size.y * beat/beat_to_screen_mod #\
#		+ (Data.screen_size.y/beat_to_screen_mod)
		
		if beat % 4 == 0:
			
			# Scale the bar line so it looks different from the other beats 
			#beat_mark_instance.scale.y *= 1.1
			beat_mark_instance.scale.x *= 6
			
			# On the first beat, store the dimensions of a single bar
			# so we can horizontally place the beat pointer there
			if beat == 0:
				bar_line_rect = beat_mark_instance.get_rect()
				
				track_to_note_pos = {
					1:Data.screen_center.x - bar_line_rect.size.y/2,
					2:Data.screen_center.x - bar_line_rect.size.y/6,
					3:Data.screen_center.x + bar_line_rect.size.y/6,
					4:Data.screen_center.x + bar_line_rect.size.y/2,
					
				}
				
				# This complicated line of cryptic garbage will move the 
				# beat pointer horizontally such that it will always be 
				# positioned relative to the first bar in the chart,
				# taking into account the size of the bar and the size
				# of the arrow
				beat_pointer.position.x = beat_mark_instance.position.x\
				- (beat_mark_instance.get_rect().size.y/2) - beat_pointer.get_rect().size.x*1.1
			
			# Create a new label positioned next to the bar and update the 
			# current bar number
			var bar_marker = Label.new()
			
			bar_marker.position.y = beat_mark_instance.position.y -10
			
			bar_marker.position.x = beat_mark_instance.position.x + \
			abs(beat_mark_instance.get_rect().size.y)/2 + 30

			bar_marker.text = str(bar_marker_num)
			
			bar_marker_list.append(bar_marker) # Add the label to a list so it can be updated during zoom
			bar_marker_num += 1
			
			add_child(bar_marker)

##############################
# METHODS FOR SETTING UP THE LEVEL EDITOR (END)
##############################

##############################
# METHODS FOR SAVING THE SONG ONTO THE USERS DRIVE
##############################

func level_save():
	
	"""
	A function which will save the current song data dictionary onto the hard drive
	"""
	
	
	var level_song_data = SongDataIntermediate.level_data["song data"]
	
	#print("LEVEL SONGS: ", level_song_data)
	
	# If previous levels have been created

	var target_id = song_data["id"]
	
	
	if len(level_song_data) > 0:
		
		# Loop through all the levels
		for level in level_song_data:
			
			
			# If there exists a level whose ID matches the ID of our current level
			# overwrite it
			
			if level["id"] - song_data["id"] == 0:
				
				
				level_song_data.pop_at(level_song_data.find(level))
				level_song_data.append(song_data)

			
			else:
				if first_save:
					
					if not SongDataIntermediate.is_edit:
						
						
						level_song_data.append(song_data)
						first_save = false
					
				
	
	# If there are no levels that currently exist, just add the level to the level dictionary
	else:
		
		level_song_data.append(song_data)
	
	SongDataIntermediate.level_data_save()
	
	
##############################
# METHODS FOR SAVING THE SONG ONTO THE USERS DRIVE (END)
##############################

func exit_check(delta):
	"""
	If the user holds the button to exit the level for a set amount of time
	quit back to the menu.
	"""
	
	var max_exit_time = 1
	
	if is_exiting:
		$ExitText.visible = true
		exit_timer += delta
		
		if exit_timer > max_exit_time:
			
			if SongDataIntermediate.new_level:
				$TransitionScreen.transition_in("res://LevelEditor/EditorTypeSelect.tscn")
				
			else:
				$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
				
			
			
	else:
		exit_timer = 0
		$ExitText.visible = false
		
		
func hold_note_creation_check():
	"""
	A function which will check to see if a hold note is currently being created
	and will return true or false
	"""
	
	for track in hold_note_activators:
		if hold_note_activators[track]:
			return true
	
	return false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$TransitionScreen.transition_out()
	
	# Call this function so that every time we create an ID, its unique
	randomize()
	
	# incredibly shitty temporary solution to the camera snapping way too 
	# high when the user switches beat types for the first time	
	
	camera.position.y = Data.screen_size.y * (selected_beat +1)/beat_to_screen_mod
	
	
	if not SongDataIntermediate.reload:
		
		# Load the song from the given path
		var song_stream = load(Data.new_level_data["song_path"])
		audio_player.stream = song_stream
		
		# Update the song databank with audio info
		#song_data["song path"] = Data.new_level_data["song path"]
		song_data["song stream"] = song_stream
		song_data["song time"] = song_stream.get_length()
		
		var beats_per_second = song_data["bpm"]/60.0
	
		# Calculate the total beats in the song, this will be used to 
		# determine the length the beat map area which can be edited
		total_beats = ceil(beats_per_second * song_data["song time"])
		
		beat_marker_place(total_beats)
		beat_marker_zoom_update()
		
		reload_check()

	
	else:
		
		var beats_per_second = SongDataIntermediate.curr_song_data["bpm"]/60.0
	
		# Calculate the total beats in the song, this will be used to 
		# determine the length the beat map area which can be edited
		total_beats = ceil(beats_per_second * SongDataIntermediate.curr_song_data["song time"])
		
		beat_marker_place(total_beats)
		beat_marker_zoom_update()
	
		reload_check()
		
	
	# place the beat pointer somewhere for now i dont care
	beat_pointer.position.y = Data.screen_size.y/beat_to_screen_mod * (selected_beat+1)
	
	
	
	
func _process(delta):
	
	master_input_detect()
	exit_check(delta)
	
	var raw_info_text = "beat mod: %s \ncurr beat: %s \nhold mode: %s \nCurrent song time: %ss \nTotal song time: %ss"
	
	var controls_text = """
	
	Controls:
	Place tap notes: (1-4)
	Create hold note: shift+(1-4)
	Delete all notes: ctrl+x
	Snap up or down (if not on note): tab+(up/down)
	beat mode up (more precise): right arrow
	beat mode down (less precise): left arrow
	"""
	

	$LevelInfo.text = raw_info_text % [
		str(beat_mods[beat_add_index]), 
		str(selected_beat), str(hold_note_creation_check()), 
		str( (60.0/song_data["bpm"]) * selected_beat),
		str(song_data["song time"]),
		
	]
	
	$LevelInfo.position = Vector2(10,camera.position.y-Data.screen_center.y/2)
	$ControlInfo.global_position = Vector2(10,camera.position.y-Data.screen_center.y/2 + $LevelInfo.get_rect().size.y)
	
	$ExitText.global_position = Vector2(10,camera.position.y-Data.screen_center.y+10)
	
