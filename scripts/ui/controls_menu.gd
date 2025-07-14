extends Control

@onready var back_button = $ColorRect/BackButton
@onready var pause_menu = $"../PauseMenu"

func _ready():
	hide()
	back_button.pressed.connect(_on_back_button_pressed)

func _input(event):
	if event.is_action_pressed("pause") and not pause_menu.is_visible() and self.is_visible():
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()

func show_menu():
	show()

func hide_menu():
	hide()

func _on_back_button_pressed():
	hide_menu()
	pause_menu.show_menu()
