extends HBoxContainer

# This script changes the color of the progress bar based on its value.
# It will tint the bar from green (low value) to red (high value).

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	# We need to create a unique StyleBox for each instance to modify its color independently.
	var stylebox_fill = StyleBoxFlat.new()
	progress_bar.add_theme_stylebox_override("fill", stylebox_fill)
	
	# Connect the value_changed signal to our update function
	progress_bar.value_changed.connect(_on_value_changed)
	# Set initial color
	_on_value_changed(progress_bar.value)

func _on_value_changed(new_value):
	# Create a color that interpolates from green to red.
	var red_component = new_value / 100.0
	var green_component = 1.0 - red_component
	
	# Get the unique stylebox override and change its background color.
	var stylebox = progress_bar.get_theme_stylebox("fill")
	if stylebox is StyleBoxFlat:
		stylebox.bg_color = Color(red_component, green_component, 0)
