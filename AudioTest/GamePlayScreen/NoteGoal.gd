extends Sprite2D


var track 

func setup(track_arg):
	track = track_arg
	
	var seek_pos = Data.track_seek_position[track]
	
	var scale_factor = 100
	look_at(Data.screen_center)
#	match track:
#		1:
#			look_at(
#				Vector2(seek_pos.x+scale_factor,seek_pos.y+scale_factor)
#			)
#			print("A")
#		2:
#			look_at(
#				Vector2(seek_pos.x+scale_factor,seek_pos.y-scale_factor)
#			)
#		3:
#			look_at(
#				Vector2(seek_pos.x-scale_factor,seek_pos.y+scale_factor)
#			)
#		4:
#			look_at(
#				Vector2(seek_pos.x-scale_factor,seek_pos.y-scale_factor)
#			)
		
	position = Data.track_seek_position[track]

func _process(delta):
	look_at(Data.screen_center)
