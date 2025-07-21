# FloatingNumber.gd - Attach to a Control node
extends Control
class_name FloatingNumber

@onready var label: Label = $Label
@onready var tween: Tween

var base_font_size = 24
var duration = 1.5

func _ready():
	# Make sure we don't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_number(value: int, world_position: Vector3, camera: Camera3D):
	# Set the text and scale based on score value
	label.text = "+" + str(value)
	
	# Scale font size based on score value (minimum 20, scales up)
	var font_size = base_font_size + (value / 10)
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	label.label_settings.font_size = font_size
	
	# Set color based on score value
	if value >= 50:
		label.label_settings.font_color = Color.GOLD
	elif value >= 25:
		label.label_settings.font_color = Color.ORANGE
	else:
		label.label_settings.font_color = Color.WHITE
	
	# Add outline for better visibility
	label.label_settings.outline_size = 2
	label.label_settings.outline_color = Color.BLACK
	
	# Convert world position to screen position
	var screen_pos = camera.unproject_position(world_position)
	
	# Center the label on the screen position
	position = screen_pos - size / 2
	
	# Start invisible and scale from 0
	modulate.a = 0.0
	scale = Vector2.ZERO
	
	# Show the control
	show()
	
	# Create and configure tween
	tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	
	# Fade in and scale up quickly
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Move upward
	tween.tween_property(self, "position:y", position.y - 100, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Fade out at the end
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(duration - 0.3)
	
	# Remove after animation
	tween.tween_callback(queue_free).set_delay(duration)