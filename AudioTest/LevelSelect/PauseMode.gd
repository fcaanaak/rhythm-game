extends Node


func pause_checker():
	"""
	A method to check if the user has paused or unpaused the game
	"""
	
	if Input.is_action_just_pressed("pause_game"):
		get_tree().paused = !get_tree().paused


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(delta):
	pause_checker()
