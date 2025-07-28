extends Node2D

# TODO: 
# - Make it so the zoom mod index only goes as high as the beat resolution index
# - Look for bugs regarding zooming and changing resolution
# - General refactoring

##############################
# CONSTANTS
##############################
const SECS_PER_MINUTE:float = 60.0
# A multiplier for how much space one beat should take on the screen
# For example if its 16, then each beat should take up one 16th of the screen

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

const PLACEHOLDER_LEVEL_DATA = {
	"bpm":123,
	"length":60,
	
}

# An array which will hold all of the different chart zooming configurations
var zoom_mods = [
	1,2,3,4,6,8,12,16,24
]

var zoom_mod_index = 0 

# A variable that will hold an index which will be used to determine
# which beat to snap to
var beat_add_index = 0

var manager_preload = preload("res://Level Editor/TrackLineManager.tscn")
var manager_instance

enum Directions { 
	UP, DOWN
}

@onready var level_cam = $LevelCam
@onready var current_beat_arrow = $CurrentBeatArrow
@onready var zoom_manager = $ZoomManager
##############################
# SIGNALS
##############################

signal camera_moved(distance,max_boundary)
signal lines_redrawn(new_beat:float,bar_lines:int)
signal update_arrow(beat:float)
signal update_camera(beat:float, maximum_beat:float)
signal update_zoom(direction:Directions)
signal increment_camera(beat:float)

var max_beats = PLACEHOLDER_LEVEL_DATA["bpm"]/SECS_PER_MINUTE*PLACEHOLDER_LEVEL_DATA["length"]

##############################
# MAIN CODE BODY
##############################

func beat_resolution_change_correction():
	SongData.selected_beat -= fposmod(SongData.selected_beat, SongData.beat_resolution*zoom_manager.zoom)


func master_input_collect():
	"""
	Collect and process all inputs
	
	NOTE: This function should mostly make calls to other parts of code
	"""
	
	
	# Pressing up or down on the keyboard will increment or decrement the current beat
	# and move down the chart accordingly
	if(Input.is_action_just_pressed("ui_up")):
		
		if (Input.is_action_pressed("zoom_enable")):
			
			emit_signal("update_zoom",SongData.Directions.UP)
			emit_signal("lines_redrawn",SongData.beat_resolution*zoom_manager.zoom,max_beats/SongData.beat_resolution)
			emit_signal("update_camera",SongData.selected_beat*zoom_manager.zoom)
			
		else:
			
			SongData.selected_beat = clamp(SongData.selected_beat - beat_mods[SongData.beat_res_index],0,max_beats)
		
			emit_signal("increment_camera",-SongData.beat_resolution*zoom_manager.zoom,max_beats)
			
		emit_signal("update_arrow",SongData.selected_beat*zoom_manager.zoom)
		
			
	if(Input.is_action_just_pressed("ui_down")):
		
		if (Input.is_action_pressed("zoom_enable")):
			
			emit_signal("update_zoom",SongData.Directions.DOWN)
			
			emit_signal("lines_redrawn",SongData.beat_resolution*zoom_manager.zoom,max_beats/SongData.beat_resolution)
			emit_signal("update_camera",SongData.selected_beat*zoom_manager.zoom)
			
		else:
			
			SongData.selected_beat = clamp(SongData.selected_beat + beat_mods[SongData.beat_res_index],0,max_beats)
			
			emit_signal("increment_camera",SongData.beat_resolution*zoom_manager.zoom,max_beats)
		
		emit_signal("update_arrow",SongData.selected_beat*zoom_manager.zoom)
		
	# Pressing left or right will decrease or increase the beat resolution 
	# allowing you to more precisely place notes on the screen
	if(Input.is_action_just_pressed("ui_left")):
		var old_idx = SongData.beat_res_index
		
		SongData.beat_res_index = clamp(SongData.beat_res_index-1,0,beat_mods.size()-1)
		SongData.beat_resolution = beat_mods[SongData.beat_res_index]
		
		if (old_idx != SongData.beat_res_index):# Only redraw if we have changed to a unique index
			emit_signal("lines_redrawn",SongData.beat_resolution,max_beats/SongData.beat_resolution)
			
			
			beat_resolution_change_correction()
			
			current_beat_arrow.position.y = Globals.beat_to_pixels(SongData.selected_beat)
			level_cam.position.y = Globals.beat_to_pixels(SongData.selected_beat)
			
			
			
		
	if(Input.is_action_just_pressed("ui_right")):
		var old_idx = SongData.beat_res_index
		
		SongData.beat_res_index = clamp(SongData.beat_res_index+1,0,beat_mods.size()-1)
		SongData.beat_resolution = beat_mods[SongData.beat_res_index]
		
		if (old_idx != SongData.beat_res_index):
			emit_signal("lines_redrawn",SongData.beat_resolution ,max_beats/SongData.beat_resolution)

			current_beat_arrow.position.y = Globals.beat_to_pixels(SongData.selected_beat)
			level_cam.position.y = Globals.beat_to_pixels(SongData.selected_beat)
			
				
func _ready():
	
	# Instantiate the track line manager which 
	# manages all the lines displayed on the level editor screen
	manager_instance = manager_preload.instantiate()
	add_child(manager_instance)
	
	# 100 is just a placeholder value for now
	manager_instance.display_lines(Globals.screen_dimensions.y/SongData.beats_per_screen,max_beats)


func _process(delta):
	master_input_collect()
