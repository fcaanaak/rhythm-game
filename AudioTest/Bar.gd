extends Sprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.

func init_pos_set(bar_num):
	position.x  = Data.screen_center.x * (bar_num * 0.25)
	
func _ready():
	position.y = Data.screen_center.y
	position.x = Data.screen_center.x * 0.25
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
