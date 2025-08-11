extends Node2D


func display_lines(spacing:int,number_of_lines:int)->void:
	
	var new_line
	
	for current_line_number in range(number_of_lines):
		new_line = TrackLine.new(spacing*current_line_number,current_line_number%int(4.0/SongData.beat_resolution)==0)
		add_child(new_line)
	
	
func clear_lines()->void:
	get_tree().call_group("track_lines","queue_free")


func _on_level_editor_lines_redrawn(new_beat:float,bar_lines:int)->void:
	var sample_line = TrackLine.new(0,false)
	sample_line.bar_num = 0
	clear_lines()
	display_lines(Globals.beat_to_pixels(new_beat),bar_lines)
	
