extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


@onready var screen_center = Vector2(
	get_viewport_rect().size.x/2,
	get_viewport_rect().size.y/2)
	

	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
