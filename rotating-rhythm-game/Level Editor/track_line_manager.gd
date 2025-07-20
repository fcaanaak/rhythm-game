extends Node2D

var track_lines:Array = Array()

func display_lines(spacing:int,line_num:int)->void:
	
	var new_line
	
	for i in range(0,line_num):
		new_line = TrackLine.new(spacing*i,i%int(4/SongData.beats_per_screen)==0)
		add_child(new_line)
	
	
func clear_lines()->void:
	get_tree().call_group("track_lines","queue_free")


func _on_level_editor_lines_redrawn(new_beat:float,bar_lines:int)->void:
	var sample_line = TrackLine.new(0,false)
	sample_line.bar_num = 0
	clear_lines()
	display_lines(Globals.beat_to_pixels(new_beat),bar_lines)
	
