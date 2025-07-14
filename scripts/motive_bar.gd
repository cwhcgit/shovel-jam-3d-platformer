extends ProgressBar

@export var motive_name: String = "Motive"

# Define Colors
const COLOR_HIGH = Color("28a745") # Green
const COLOR_MEDIUM = Color("ffc107") # Orange
const COLOR_LOW = Color("dc3545") # Red

var style_box

func _ready():
	$Label.text = motive_name

	# For colored progress bar
	style_box = StyleBoxFlat.new()
	add_theme_stylebox_override("fill", style_box)

	_update_bar_color()

func set_motive_value(new_value):
	value = clamp(new_value, 0, 100)
	_update_bar_color()

func _update_bar_color():
	var percentage = value / 100.0
	var color = COLOR_LOW

	if percentage > MotiveManager.HIGH_THRESHOLD:
		color = COLOR_HIGH
	elif percentage > MotiveManager.MEDIUM_THRESHOLD:
		var weight = (percentage - MotiveManager.MEDIUM_THRESHOLD) / (MotiveManager.HIGH_THRESHOLD - MotiveManager.MEDIUM_THRESHOLD)
		color = COLOR_MEDIUM.lerp(COLOR_HIGH, weight)
	elif percentage > MotiveManager.LOW_THRESHOLD:
		var weight = (percentage - MotiveManager.LOW_THRESHOLD) / (MotiveManager.MEDIUM_THRESHOLD - MotiveManager.LOW_THRESHOLD)
		color = COLOR_LOW.lerp(COLOR_MEDIUM, weight)

	style_box.bg_color = color
