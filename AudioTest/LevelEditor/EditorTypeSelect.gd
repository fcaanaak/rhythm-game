extends Control


@onready var file_dialog = $FileDialog

@onready var song_info_entry = $LevelInfoContainer

@onready var level_options = $LevelOptionContainer


func has_letters(your_string):
	var regex = RegEx.new()
	regex.compile("[a-zA-Z]+")
	if regex.search(str(your_string)):
		return true
	else:
		return false
		


# Called when the node enters the scene tree for the first time.
func _ready():
	$LevelOptionContainer/EditLevel.grab_focus()
	$TransitionScreen.transition_out()
	

func _on_FileDialog_file_selected(path):
	"""
	Once the user has selected a file, check tos
	see if its an MP3 and if it is, allow them to 
	select a BPM, if it isn't, inform them
	"""
	
	if path.ends_with(".mp3"):
		Data.current_song_path = path
		
		Data.new_level_data["song_path"] = path
		
		
	else:
		$WrongFileWarning.popup_centered()
		

func _on_EditLevel_pressed():
	SongDataIntermediate.is_edit = true
	SongDataIntermediate.new_level = false
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
	
	#get_tree().change_scene("res://LevelSelect/LevelSelect.tscn")
		

func _on_BPMConfirm_pressed():
	"""
	When the user clicks the confirm button,
	read their text and check to see if its valid BPM
	"""
	var user_input = int($BPMInput/LineEdit.text)
	
	if 0 < user_input and 999 > user_input:
		get_tree().change_scene_to_file("res://LevelEditor/LevelEditor.tscn")
		Data.curr_song_bpm = user_input
		

func _on_NewLevel_pressed():
	"""
	When the user presses the button to create a new level
	display all the level creation GUI elements
	"""
	
	SongDataIntermediate.new_level = true
	SongDataIntermediate.is_edit = false
	$LevelInfoContainer/SongTitleEdit.grab_focus()
	level_options.visible = false
	song_info_entry.visible = true
	$BackButton.visible = true
	$ContinueButton.visible = true
	$BackMenuButton.visible = false


func _on_SongFileOpen_pressed():
	
	file_dialog.popup_centered()


func _on_SongCoverSelect_pressed():
	$ImageFileDialog.popup_centered()


func _on_BackButton_pressed():
	$LevelOptionContainer.visible = true
	$LevelInfoContainer.visible = false
	$BackButton.visible = false
	$ContinueButton.visible = false
	$BackMenuButton.visible = true


func _on_ImageFileDialog_file_selected(path):
	
	if path.ends_with(".png") or path.ends_with(".jpg") or path.ends_with(".jpeg"):
		
		Data.current_image_path = path
		
		Data.new_level_data["image_path"] = path
	
	else:
		$WrongFileWarning.popup_centered()


func _on_ContinueButton_pressed():
	
	if not has_letters($LevelInfoContainer/SongBPMEdit.text):
		
		Data.new_level_data["song_bpm"] = int($LevelInfoContainer/SongBPMEdit.text)
		Data.new_level_data["song_artist"] = $LevelInfoContainer/SongArtistEdit.text
		Data.new_level_data["song_title"] = $LevelInfoContainer/SongTitleEdit.text
		
		$TransitionScreen.transition_in("res://LevelEditor/LevelEditor.tscn")
		
		
		


func _on_BackMenuButton_pressed():
	$TransitionScreen.transition_in("res://MainMenu/MainMenu.tscn")
	



