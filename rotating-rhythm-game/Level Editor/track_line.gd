class_name TrackLine extends Line2D

const WIDTH_BAR = 5
const WIDTH_LINE = 2

const LEFT_POINT_INDEX = 0
const RIGHT_POINT_INDEX = 1
const SCREEN_WIDTH_FRACTION:float = 1/2.0

static var bar_num = 0
var local_bar_num = 0
var line_number

func length()->float:
	"""
	Gets the length of the lines
	
	Returns:
		The distance between both points of the lines (aka the length)
	"""
	return get_point_position(LEFT_POINT_INDEX).distance_to(get_point_position(RIGHT_POINT_INDEX))


func _init(height:float,is_bar:bool=false) -> void:
	
	var points_new = PackedVector2Array()
	points_new.append(Vector2(Globals.screen_center.x-SCREEN_WIDTH_FRACTION*Globals.screen_dimensions.x/2.0,height))
	points_new.append(Vector2(Globals.screen_center.x+SCREEN_WIDTH_FRACTION*Globals.screen_dimensions.x/2.0,height))
	
	set_points(points_new)
	
	width = WIDTH_BAR if is_bar else WIDTH_LINE
	
	add_to_group("track_lines")

func line_number_init():
	"""
	A function that will create and place a the number the current line is on
	"""
	line_number = Label.new()
	
	line_number.text = "%.3f" % bar_num
	local_bar_num = bar_num
	
	bar_num += SongData.beat_resolution # Change this to be the current beat resolution we are on so 4/4, 4/8, 4/12 etc
	
	line_number_position()
	
	add_child(line_number)

func line_number_position():
	"""
	Move the line number to be next to the current line instance
	"""
	var text_size = line_number.get_rect().size
	
	line_number.position.y = get_point_position(LEFT_POINT_INDEX).y - text_size.y
	line_number.position.x = get_point_position(LEFT_POINT_INDEX).x 
	

func _ready()->void:
	line_number_init()
	
	
	
	
	

	
	
