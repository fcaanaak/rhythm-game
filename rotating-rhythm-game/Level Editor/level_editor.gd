extends Node2D

# TODO: 
# - Comment all the code so far
# - Add automatic camera snapping to the nearest beat when we change zoom options (look in old code)
# - Make it so the camera doesn't move when on the first beat and we press down. This is so the beat
# arrow always has track lines above and below it
# - General refactoring

##############################
# CONSTANTS
##############################
const TEST_MAX_HEIGHT:int = 10000

# A multiplier for how much space one beat should take on the screen
# For example if its 16, then each beat should take up one 16th of the screen

var zoom_mod_index = 0

# A list of all the possible beat fractions
const beat_mods = [
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

# A variable that will hold an index which will be used to determine
# which beat to snap to
var beat_add_index = 0

var manager_preload = preload("res://Level Editor/TrackLineManager.tscn")
var manager_instance

@onready var level_cam = $LevelCam
@onready var current_beat_arrow = $CurrentBeatArrow
##############################
# SIGNALS
##############################

signal camera_moved(distance,max_boundary)
signal lines_redrawn(new_beat:float,bar_lines:int)
signal jump_to_beat(beat:float) # For CurrentBeatArrow node


##############################
# MAIN CODE BODY
##############################

func master_input_collect():
	"""
	Collect and process all inputs
	
	NOTE: This function should mostly make calls to other parts of code
	"""
	
	
	# Pressing up or down on the keyboard will increment or decrement the current beat
	# and move down the chart accordingly
	if(Input.is_action_just_pressed("ui_up")):
		SongData.selected_beat = clamp(SongData.selected_beat - beat_mods[SongData.beat_res_index],0,100)
		
		current_beat_arrow.position.y = Globals.beat_to_pixels(SongData.selected_beat)
		
		
		emit_signal("camera_moved",-Globals.beat_to_pixels(beat_mods[SongData.beat_res_index]),TEST_MAX_HEIGHT)
		
	if(Input.is_action_just_pressed("ui_down")):
		SongData.selected_beat = clamp(SongData.selected_beat + beat_mods[SongData.beat_res_index],0,100)
		
		current_beat_arrow.position.y = Globals.beat_to_pixels(SongData.selected_beat)
		emit_signal("camera_moved",Globals.beat_to_pixels(beat_mods[SongData.beat_res_index]),TEST_MAX_HEIGHT)
		
	# Pressing left or right will decrease or increase the beat resolution 
	# allowing you to more precisely place notes on the screen
	if(Input.is_action_just_pressed("ui_left")):
		var old_idx = SongData.beat_res_index
		
		SongData.beat_res_index = clamp(SongData.beat_res_index-1,0,beat_mods.size()-1)
		SongData.beat_resolution = beat_mods[SongData.beat_res_index]
		
		if (old_idx != SongData.beat_res_index):
			emit_signal("lines_redrawn",SongData.beat_resolution,100)
			SongData.selected_beat -= (fposmod(SongData.selected_beat,beat_mods[beat_add_index]))
			level_cam.position.y = Globals.screen_dimensions.y * (SongData.selected_beat +1)/SongData.beats_per_screen
			
			current_beat_arrow.position.y = Globals.beat_to_pixels(SongData.selected_beat)
			emit_signal("camera_moved",Globals.beat_to_pixels(beat_mods[SongData.beat_res_index]),TEST_MAX_HEIGHT)
			
			
		
	if(Input.is_action_just_pressed("ui_right")):
		var old_idx = SongData.beat_res_index
		
		SongData.beat_res_index = clamp(SongData.beat_res_index+1,0,beat_mods.size()-1)
		SongData.beat_resolution = beat_mods[SongData.beat_res_index]
		
		if (old_idx != SongData.beat_res_index):
			print(SongData.selected_beat)
			emit_signal("lines_redrawn",SongData.beat_resolution ,100)
			emit_signal("jump_to_beat",SongData.selected_beat)
			
			#emit_signal("camera_moved",Globals.beat_to_pixels(beat_mods[SongData.beat_res_index]),TEST_MAX_HEIGHT)
		
		
func _ready():
	
	# Instantiate the track line manager which 
	# manages all the lines displayed on the level editor screen
	manager_instance = manager_preload.instantiate()
	add_child(manager_instance)
	manager_instance.display_lines(Globals.screen_dimensions.y/SongData.beats_per_screen,100)
	
	current_beat_arrow.position.x = 100


func _process(delta):
	master_input_collect()
