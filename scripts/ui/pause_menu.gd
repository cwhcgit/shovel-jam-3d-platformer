extends Control

@onready var continue_button = $ColorRect/VBoxContainer/ContinueButton
@onready var how_to_play_button = $ColorRect/VBoxContainer/HowToPlayButton
@onready var controls_button = $ColorRect/VBoxContainer/ControlsButton

@onready var how_to_play_menu = $"../HowToPlayMenu"
@onready var controls_menu = $"../ControlsMenu"

func _ready():
	hide()
	continue_button.pressed.connect(_on_continue_button_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	controls_button.pressed.connect(_on_controls_button_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		# Only process 'pause' if no sub-menu is currently visible
		if not how_to_play_menu.visible and not controls_menu.visible:
			if visible:
				hide_menu()
			else:
				show_menu()
			get_viewport().set_input_as_handled() # Consume the event here

func show_menu():
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_menu():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_continue_button_pressed():
	hide_menu()

func _on_how_to_play_button_pressed():
	hide()
	how_to_play_menu.show_menu()

func _on_controls_button_pressed():
	hide()
	controls_menu.show_menu()
