extends Control

var placement_vectors = []
var vector_positions = []

@export (PackedScene) var level_select_button
@export (PackedScene) var song_name_label


@onready var grid_data = {
	
	"x":{
		
		# The an array which holdest the coordinates of the smallest and largest x boundaries
		"coord range":[
			Data.screen_size.x/3, Data.screen_size.x
		],
		
		"placement positions":[],
		
		"section split":5
		
	},
	
	"y":{
		
		"coord range":[
			0, Data.screen_size.y
		],
		
		"placement positions":[],
		
		"section split": 5
		
	}
	
}


@onready var level_info_data = {
	
	"x":{
		
		"coord range":[
			0, grid_data["x"]["coord range"][0]
		]
	},
	
	"y":{
		
		"coord range":[
			0, Data.screen_size.y
		]
		
	}
	
}
# NODE VARIABLES

@onready var grid_bg = $LevelGridBG
@onready var level_info = $LevelInfoData

# Specficic scaling factor foudn thorugh testing that cannot be changed
var sprite_scale_factor = Vector2(
	(20.0/3.0),
	(45.0/8.0)
	
)


var level_sections = []# An array to hold all the unordered levels

var master_level_array = [] # An array to hold all the groups of levels to be cycled through



var selected_level

# A boolean to see if we are deleting a level or not
var delete_mode = false

func level_grid_setup():
	"""
	A function which will take information from the grid_data dict 
	and use it to add to lists of points on the x and y axis for where 
	level should be placed
	
	NOTE THIS ONLY CREATES 2 ARRAYS OF RAW X AND Y COORDINATES
	
	SORTING THESE COORDINATES INTO VECTORS HAPPENS IN A LATER STEP
	
	"""
	
	
	for axis in grid_data:
		
		# I do not want to type grid_data[axis]["coord range"] every two seconds
		var easy_access_coords = grid_data[axis]["coord range"]
		
		# A variable which will store where the current coordinate will be
		var current_pos = easy_access_coords[0]
		
		# How long is one section of the level grid after we split it 
		var section_length = (easy_access_coords[1] - easy_access_coords[0])/grid_data[axis]["section split"]
		
		
		# Go through and add the coordinates
		for i in range(grid_data[axis]["section split"]-1):
			
			current_pos += section_length
			
			grid_data[axis]["placement positions"].append(current_pos)
			
			
func vector_setup():
	
	"""
	A function which works with the grid data's x and y coordinate arrays to 
	create an array of vectors that store points for where each level select 
	block should go
	"""
	for y_val in grid_data["y"]["placement positions"]:
		for x_val in grid_data["x"]["placement positions"]:
		
			placement_vectors.append(Vector2(x_val,y_val))
			vector_positions.append(Vector2(x_val,y_val))


func test_place():
	"""
	A function which will place some sample sprites in the positions
	of the vectors in placement_vectors to visually represent where things are going
	"""
	
	for i in range(len(placement_vectors)):
		
		var test_sprite = level_select_button.instantiate()
		test_sprite.texture = load("res://resources/level_select_button.png")
		test_sprite.position = placement_vectors[i]
		
		
		add_child(test_sprite)
		
		# scale the sprite so that they keep the same placement ratio regardless of screen size NOTE THAT THE SPRITES MUST BE 64x64
		test_sprite.scale.x =((grid_data["x"]["coord range"][1] - grid_data["x"]["coord range"][0]) * (1.0/sprite_scale_factor.x))/ test_sprite.get_rect().size.x 
		
		test_sprite.scale.y =((grid_data["y"]["coord range"][1] - grid_data["y"]["coord range"][0]) * (1.0/sprite_scale_factor.y))/ test_sprite.get_rect().size.y
		
		level_sections.append(test_sprite)



func shrink_to(sprite):
	"""
	A function which will take in a sprite with a given texture
	and shrink it down to a target number of  pixels
	"""
	
	var target_scale = 64
	
	sprite.scale = Vector2(
		
		target_scale/sprite.get_rect().size.x,
		target_scale/sprite.get_rect().size.y
		
	)
	
	
func level_section_setup():
	"""
	A function which will place a specfic number of level sections depending on how
	many levels have already been created
	"""
	
	for song in SongDataIntermediate.level_data["song data"]:
		
		# Create the song section sprite
		var song_section = level_select_button.instantiate()
		
		song_section.texture = ResourceLoader.load(song["image path"])
		
		# First scale it down to 64 pixils since the proper scaling cant take place otherwise
		shrink_to(song_section)
		
		song_section.scale.x =((grid_data["x"]["coord range"][1] - grid_data["x"]["coord range"][0]) * (1.0/sprite_scale_factor.x))/ song_section.get_rect().size.x 
		song_section.scale.y =((grid_data["y"]["coord range"][1] - grid_data["y"]["coord range"][0]) * (1.0/sprite_scale_factor.y))/ song_section.get_rect().size.y
		
#		song_section.position = placement_vectors.pop_front()
		
		song_section.song_data = song
		
#		add_child(song_section)
		
		level_sections.append(song_section)
	
func level_group_order():
	
	"""
	A function which will sort the level section array into groups of up to 16 levels 
	and only display 1 group at a time
	"""

	
	var counter = 0# Used to keep track of which level we're on
	
	var curr_sub_array = []# Represents a group
	
	# Every iteration add a level to a group and once the group is full
	# put it in a bigger master list that holds all the groups
	for section in level_sections:
		
		
		counter += 1
		curr_sub_array.append(section)
		
		# If we are at the end of the level array add whatever is left into a group
		if counter == len(level_sections) and counter % 16 != 0:
			master_level_array.append(curr_sub_array)
			
		# Everytime a group fills up, add it to the master level array and clear the current group
		elif counter % 16 == 0:
			master_level_array.append(curr_sub_array)
			curr_sub_array = []
	
			

func level_section_place():
	"""
	A method which will go through all the levels in a group and place them onscreen
	"""
	if len(master_level_array) > 0:
		for level in master_level_array[Data.curr_group_index]:
			level.position = placement_vectors.pop_front()
			add_child(level)

	
func grid_bg_init():
	"""
	A function which will initially place the background for the level select grid 
	on the screen and properly scale it
	"""
	
	# Putting these in variables for ease of access
	var grid_coord_range_x = grid_data["x"]["coord range"]
	
	var grid_coord_range_y = grid_data["y"]["coord range"]
	
	# Place the level select grid in the center of the allocated space
	var grid_center = Vector2(
		
		(grid_coord_range_x[1] + grid_coord_range_x[0])/2,
		(grid_coord_range_y[1] + grid_coord_range_y[0])/2
		
	)
	
	grid_bg.position = grid_center


	# Scaling the grid BG
	grid_bg.scale = Vector2(
		(grid_coord_range_x[1] - grid_coord_range_x[0])/grid_bg.get_rect().size.x,
		(grid_coord_range_y[1] - grid_coord_range_y[0])/grid_bg.get_rect().size.y
		
	)


func level_info_change_check():
	"""
	A method to be called whenever the user clicks an level on the level select screen
	this will update the level information displayed
	"""
	
	for level in level_sections:
		
		if level.pressed:
			
			if SongDataIntermediate.is_edit:
				$EditSelectButton.visible = true
			
			else:
				$LevelPlayButton.visible = true# Display the play button so the user can only click play after they've picked a level
				
			selected_level = level
			
			# Set all these labels to show relevant information
			$LevelInfoData/SongTitle.text = "Title: " + level.song_data["song title"]
			$LevelInfoData/ArtistTitle.text = "Artist: " + level.song_data["song artist"]
			$LevelInfoData/BPMTitle.text = "BPM: " + str(level.song_data["bpm"])
			$LevelInfoData/SongDurationTitle.text = "Duration: " + str(round(level.song_data["song time"])) + "s"
			
			

func nav_button_setup():
	"""
	A function which will place the navigation buttons to move up and down the level groups in their
	respective initial positions
	"""
	var grid_coord_range_y = grid_data["y"]["coord range"]
	
	var level_grid_center_y =  (grid_coord_range_y[1] + grid_coord_range_y[0])/2
	
	$LevelGroupUp.set_position(Vector2(grid_data["x"]["coord range"][0]-$LevelGroupUp.get_rect().size.x,level_grid_center_y -$LevelGroupUp.get_rect().size.y))
	
	$LevelGroupDown.set_position(Vector2(grid_data["x"]["coord range"][0]-$LevelGroupDown.get_rect().size.x,level_grid_center_y + $LevelGroupDown.get_rect().size.y)) 

func nav_button_disabled_check():
	"""
	A function which will disable certain nav buttons depending on which level group index we are on
	"""
	
	# if we are on the first level group
	if Data.curr_group_index == 0:
		$LevelGroupUp.disabled = true
	
	# If we are on the last level group
	if Data.curr_group_index == len(master_level_array) - 1:
		$LevelGroupDown.disabled = true
	
	

func _on_LevelPlayButton_pressed():
	
	"""
	A method to be called whenever the user presses the level play button
	"""

	SongDataIntermediate.curr_song_data = selected_level.song_data
	SongDataIntermediate.reload = true
	SongDataIntermediate.is_previewing = false
	SongDataIntermediate.is_edit = false
	
	$TransitionScreen.transition_in("res://GamePlayScreen/main.tscn")
	

func _on_BackButton_pressed():
	"""
	changes the scene back to the main menu when you press the back button
	"""
	#Data.is_transitioned =true
	
	$TransitionScreen.transition_in("res://MainMenu/MainMenu.tscn")
	#get_tree().change_scene("res://MainMenu/MainMenu.tscn")


func _on_EditSelectButton_pressed():
	
	if not delete_mode:
		
		SongDataIntermediate.reload = true
		SongDataIntermediate.curr_song_data = selected_level.song_data
		
		$TransitionScreen.transition_in("res://LevelEditor/LevelEditor.tscn")
		
	else:
		
		# If we are deleting a level
		# remove it from the song data dictionary and then save the song data dictionary to file
		SongDataIntermediate.level_data["level ids"].erase(selected_level.song_data["id"])
		SongDataIntermediate.level_data["song data"].erase(selected_level.song_data)
		SongDataIntermediate.level_data_save()
		
		# Do a transition to reload the screen so that the levels get placed back where 
		# they need to be
		$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
		
		
func _on_DeleteButton_pressed():
	"""
	If we press the button to delete a song, turn on the delete mode which will 
	allow the user to select a level to be removed
	"""
	
	delete_mode = !delete_mode# Switch the deletion mode
	
	if delete_mode:
		$EditSelectButton.text = "Delete"
	else:
		$EditSelectButton.text = "Edit"
		

func _on_LevelGroupDown_pressed():
	"""
	If we pressed the button to navigate down to the next level group
	Advance the level group index by 1 
	"""
	
	
	if Data.curr_group_index < len(master_level_array) - 1:
		Data.curr_group_index += 1
		
	else:
		$LevelGroupDown.disabled = true
		
	
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
	

func _on_LevelGroupUp_pressed():
	"""
	If we pressed the button to navigate upto the next level group. Check to see
	if we are on the first level group index and disable the button if so
	"""
	
	Data.curr_group_index -= 1
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")

func _ready():
	
	# Begin the intro transition (we never start here, we will always transition in)
	$TransitionScreen.transition_out()
	$BackButton.grab_focus()
	# Set up the grid system and the background sprite for the grid
	level_grid_setup()
	grid_bg_init()
	
	# Organize the loose grid coordinates into vectors that can be used to place sprites down
	vector_setup()
	
	# Place the sprites that represent the level sections down
	#level_section_setup()
	level_section_setup()
	level_group_order()
	level_section_place()
	nav_button_setup()
	nav_button_disabled_check()
	
	# Show or hide the delete button depending on if we are playing or editing a level
	if SongDataIntermediate.is_edit:
		$DeleteButton.visible = true
	else:
		$DeleteButton.visible = false
	

func _process(delta):
	level_info_change_check()



