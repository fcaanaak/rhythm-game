extends Node

# A dictionary which will hold the song information from the level editor 
var curr_song_data = {}

# A larger dictionary which will hold song data dictionaries for all the levels created and saved
# It contains 2 keys for all the IDs in use and data for levels
var level_data = {
	
	"level ids":[],
	
	"song data":[],
	
	
}

var reload = false

var level_data_path = "user://level_data.dat"

var is_previewing = false # A boolean used to determine if the user is previewing a level or if they're actually playing it

# A boolean used to see if the level selected is being edited or played, this will be used to differentiate how the gameplay screen behaves
var is_edit = false

var new_level = true# boolean used to see if the level being edited is a new level or a pre-existing one

func level_data_check():
	"""
	A simple function which will check to see if a level data file exists and 
	if none exists, to create a new empty level data file
	"""
	
	var data_file = File.new()
	
	var template = {
		
		"level ids":[],
	
		"song data":[],
	}
	
	# If no level data file exists
	if not data_file.file_exists(level_data_path):
		
		# Open the file in writing mode and upload an empty dictionary to it
		data_file.open(level_data_path,File.WRITE)
		
		data_file.store_var(template)
		
		data_file.close()
		print("new file created")
		return false
	
	else:
		return true
		

func level_data_load():
	"""
	A function that will be called whenever the game begins. It will
	load level data from the stored level_data.dat file and place it in the 
	level_data dictionary so it can be easily accessed in the program
	"""
	
	# If there are levels present
	if level_data_check():
		
		var data_file = File.new()
		
		# Open the level data file and upload all the level dictionaries into the
		# level data dictionary
		data_file.open(level_data_path,File.READ)
		
		level_data = data_file.get_var()
		
		data_file.close()
		
		level_data_debug_disp()
		
		

func level_data_save():
	"""
	A function which will save the level_data dictionary to a file so its contents
	can be accessed later, allowing for the user to save levels
	"""
	
	var data_file = File.new()
	
	data_file.open(level_data_path,File.READ_WRITE)
	
	
	data_file.store_var(level_data)
	
	data_file.close()
	
	#level_data_debug_disp()

func level_data_debug_disp():
	"""
	A function which will display the contents of the file for debugging
	"""
	
	var data_file = File.new()
	
	data_file.open(level_data_path,File.READ)
	
	#print(data_file.get_var())
	
	data_file.close()
	

func level_data_reset():
	var data_file = File.new()
	
	var template = {
		"level ids":[],
	
		"song data":[],
	}
	
	data_file.open(level_data_path,File.WRITE)
	

	data_file.store_var(template)
	
	data_file.close()

func _ready():
	
	level_data_load()
