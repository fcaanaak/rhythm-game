extends Control




func _on_LevelSelect_pressed():
	
	$TransitionScreen.transition_in("res://LevelSelect/LevelSelect.tscn")


func _on_MainMenu_pressed():
	
	$TransitionScreen.transition_in("res://MainMenu/MainMenu.tscn")
	
	
func _ready():
	$TransitionScreen.transition_out()
	$ScoreLabel.global_position = Vector2(Data.screen_center.x-$ScoreLabel.get_rect().size.x,Data.screen_center.y - 100)
	$ScoreLabel.text = "Final Score: " + str(Data.stored_score)




