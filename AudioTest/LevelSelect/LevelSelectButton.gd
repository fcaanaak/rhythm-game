extends Sprite2D


var song_data


var pressed = false

func _input(event):
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			pressed = true
	
	else:
		pressed = false
		
	
			
			
func _ready():
	pass
	#label_style.size = 20
	#song_name_label.text = "hello world"
	

	
	
