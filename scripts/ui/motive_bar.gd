extends ProgressBar

const ARROW_UP_SCENE = preload("res://scenes/ui/arrow_up.tscn")
const ARROW_DOWN_SCENE = preload("res://scenes/ui/arrow_down.tscn")

@export var motive_name: String = "Motive"

const COLOR_HIGH = Color("28a745") # Green
const COLOR_MEDIUM = Color("ffc107") # Orange
const COLOR_LOW = Color("dc3545") # Red

@onready var label = $Label
@onready var arrow_container = $ArrowContainer

var style_box
var last_value: float = 0.0

func _ready():
	label.text = motive_name
	last_value = value # Initialize last_value with the current value

	# For colored progress bar
	style_box = StyleBoxFlat.new()
	add_theme_stylebox_override("fill", style_box)

	_update_bar_color()

func set_motive_value(new_value: float, change: float):
	value = clamp(new_value, 0, 100)
	
	_update_bar_color()
	label.text = "%s: %d" % [motive_name, value]
	
	_update_arrows(change)

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

func _update_arrows(change_per_second: float):
	# Clear existing arrows
	for child in arrow_container.get_children():
		child.queue_free()
	
	arrow_container.visible = true # Make container visible when arrows are present

	var arrow_count = 0
	var arrow_scene = null

	if change_per_second >= 5.0:
		arrow_count = 3
		arrow_scene = ARROW_UP_SCENE
	elif change_per_second >= 2.0:
		arrow_count = 2
		arrow_scene = ARROW_UP_SCENE
	elif change_per_second >= 1.0:
		arrow_count = 1
		arrow_scene = ARROW_UP_SCENE
	elif change_per_second <= -5.0:
		arrow_count = 3
		arrow_scene = ARROW_DOWN_SCENE
	elif change_per_second <= -2.0:
		arrow_count = 2
		arrow_scene = ARROW_DOWN_SCENE
	elif change_per_second <= -1.0:
		arrow_count = 1
		arrow_scene = ARROW_DOWN_SCENE
	else:
		arrow_container.visible = false # Hide container if no arrows
		return

	for i in range(arrow_count):
		var arrow_instance = arrow_scene.instantiate()
		arrow_container.add_child(arrow_instance)
