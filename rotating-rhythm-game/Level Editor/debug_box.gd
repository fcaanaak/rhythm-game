extends VBoxContainer

const DEFAULT_MESSAGE = "STANDBY"
@onready var beat_resolution_label = $BeatResolutionLabel
@onready var zoom_mod_index_label = $ZoomModIndexLabel
@onready var zoom_mod_label = $ZoomModLabel
@onready var selected_beat_label = $SelectedBeatLabel

func _ready()->void:
	beat_resolution_label.text = str(SongData.beat_resolution)
	zoom_mod_index_label.text = DEFAULT_MESSAGE
	zoom_mod_label.text = DEFAULT_MESSAGE
	selected_beat_label.text = str(SongData.selected_beat)
	position.x = 3/4.0*Globals.screen_dimensions.x


func _on_level_editor_update_debug_box(zoom_index: int, zoom_value: int) -> void:
	position.y = Globals.beat_to_pixels(SongData.selected_beat*zoom_value)
	beat_resolution_label.text = "Beat res: " + str(SongData.beat_resolution)
	zoom_mod_index_label.text = "Zoom index: " + str(zoom_index)
	zoom_mod_label.text = "Zoom level: " + str(zoom_value)
	selected_beat_label.text = "Selected beat: " + str(SongData.selected_beat)
	
