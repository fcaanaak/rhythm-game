extends Node2D



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

@onready var level_cam = $LevelCam
@onready var current_beat_arrow = $CurrentBeatArrow
@onready var zoom_manager = $ZoomManager
@onready var directions = Directions
##############################
# SIGNALS
##############################

# Track line signal(s)
signal lines_redrawn(new_beat:float,bar_lines:int)

# Beat arrow signal(s)
signal update_arrow(beat:float)

# Camera signals
signal update_camera(beat:float, maximum_beat:float)
signal increment_camera(beat:float)

# Zoom signals
signal increment_zoom(direction,max_index:int)
signal clamp_zoom(max_index:int)

# put this here for now idfk
var max_beats = PLACEHOLDER_LEVEL_DATA["bpm"]/SECS_PER_MINUTE*PLACEHOLDER_LEVEL_DATA["length"]

##############################
# MAIN CODE BODY
##############################

func beat_resolution_change_correction()->void:
	"""Rounds down to the closest beat if we switch to a beat resolution
	while being on a beat not in that resolution (ex going to thirds while being
	on beat 2.5)"""
	SongData.selected_beat -= fposmod(SongData.selected_beat, SongData.beat_resolution*zoom_manager.zoom)

func handle_zoom(direction:int)->void:
	"""
	Emit signals to various nodes to respond to a user zoom event
	"""
	emit_signal("increment_zoom",direction,SongData.beat_res_index)
	emit_signal("lines_redrawn",SongData.beat_resolution*zoom_manager.zoom,max_beats/SongData.beat_resolution)
	emit_signal("update_camera",SongData.selected_beat*zoom_manager.zoom)
	
func level_chart_increment(direction)->void:
	"""Handle behavior when we move up or down the level chart"""
	SongData.selected_beat = clamp(SongData.selected_beat + direction*beat_mods[SongData.beat_res_index],0,max_beats)
	emit_signal("increment_camera",direction*SongData.beat_resolution*zoom_manager.zoom,max_beats)

func beat_resolution_update()->void:
	"""Update various nodes following a beat resolution change"""
	
	emit_signal("clamp_zoom",SongData.beat_res_index)
	emit_signal("lines_redrawn",SongData.beat_resolution,max_beats/SongData.beat_resolution)
	
	beat_resolution_change_correction()
	
	emit_signal("update_arrow",SongData.selected_beat)
	emit_signal("update_camera",SongData.selected_beat)
	
		
func beat_resolution_change(direction)->void:
	
	var old_idx = SongData.beat_res_index
	
	SongData.beat_res_index = clamp(SongData.beat_res_index + direction,0,beat_mods.size()-1)
	SongData.beat_resolution = beat_mods[SongData.beat_res_index]
	
	if (old_idx != SongData.beat_resolution):
		beat_resolution_update()
	
	
func master_input_collect()->void:
	"""
	Collect and process all inputs
	NOTE: This function should mostly make calls to other parts of code
	"""
	
	# Pressing up or down on the keyboard will increment or decrement the current beat
	# and move down the chart accordingly
	if(Input.is_action_just_pressed("ui_up")):
		
		if (Input.is_action_pressed("zoom_enable")):
			handle_zoom(directions.UP)
			
		else:
			
			level_chart_increment(directions.UP)
			
		emit_signal("update_arrow",SongData.selected_beat*zoom_manager.zoom)
		
			
	if(Input.is_action_just_pressed("ui_down")):
		
		if (Input.is_action_pressed("zoom_enable")):
			handle_zoom(directions.DOWN)
			
		else:
			
			level_chart_increment(directions.DOWN)
		
		emit_signal("update_arrow",SongData.selected_beat*zoom_manager.zoom)
		
	# Pressing left or right will decrease or increase the beat resolution 
	# allowing you to more precisely place notes on the screen
	if(Input.is_action_just_pressed("ui_left")):
		beat_resolution_change(directions.LEFT)
			
			
	if(Input.is_action_just_pressed("ui_right")):
		beat_resolution_change(directions.RIGHT)
			
					
func _ready():
	
	# Instantiate the track line manager which 
	# manages all the lines displayed on the level editor screen
	manager_instance = manager_preload.instantiate()
	add_child(manager_instance)
	
	manager_instance.display_lines(Globals.screen_dimensions.y/SongData.beats_per_screen,max_beats)


func _process(delta):
	master_input_collect()
