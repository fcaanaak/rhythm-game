extends Node

@onready var group_deletion_bars = [
	$group_delete_bar_1,
	$group_delete_bar_2,
	$group_delete_bar_3,
	$group_delete_bar_4,
]


func _ready():
	var curr_track = 1
	
	for bar in group_deletion_bars:
		bar.track = curr_track
		curr_track += 1
		
