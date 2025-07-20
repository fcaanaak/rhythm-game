extends CanvasLayer


var change_path 

func _ready():
	pass


func transition_in(scene_path):
	visible = true
	change_path = scene_path
	

	
	$AnimationPlayer.play("fade_to_black")
	
	
func transition_out():
	visible = true
	$AnimationPlayer.play("fade_to_normal")
	


func _on_AnimationPlayer_animation_finished(anim_name):
	
	if anim_name == "fade_to_black":
		Data.is_transitioned = true
		
		get_tree().change_scene_to_file(change_path)
	
	if anim_name == "fade_to_normal":
		if Data.is_transitioned:
			visible = false
			Data.is_transitioned = false
		
