extends Control


func _on_PlayLevelButton_pressed():
	SongDataIntermediate.is_edit = false
	$TransitionScreen.visible = true
	
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")
	
	

func _on_LevelEditorButton_pressed():

	SongDataIntermediate.is_edit = true
	$TransitionScreen.visible = true
	$TransitionScreen.transition_in("res://LevelEditor/EditorTypeSelect.tscn")


func _ready():
	
	$LevelEditorButton.grab_focus()
	
	if Data.is_transitioned:
		$TransitionScreen.visible = true
		$TransitionScreen/AnimationPlayer.play("fade_to_normal")
		
		
			
