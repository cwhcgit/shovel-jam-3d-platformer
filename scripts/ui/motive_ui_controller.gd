extends Control

const MotiveBar = preload("res://scenes/ui/motive_bar.tscn")

@onready var grid_container = $GridContainer

var motive_bars = {}

func _ready():
	# Connect to the update signal to get latest motive values
	MotiveManager.motive_updated.connect(on_motive_updated)

	# Fetch the initial data directly from the singleton
	var motive_data = MotiveManager.get_all_motives()
	on_motives_initialized(motive_data)

func on_motives_initialized(motive_data):
	for motive_name in motive_data:
		var motive = motive_data[motive_name]
		var motive_bar = MotiveBar.instantiate()
		motive_bar.name = motive_name
		motive_bar.motive_name = motive_name
		grid_container.add_child(motive_bar)
		motive_bar.set_motive_value(motive.value, 0)
		motive_bars[motive_name] = motive_bar

func on_motive_updated(motive_name, new_value, change):
	if motive_bars.has(motive_name):
		motive_bars[motive_name].set_motive_value(new_value, change)
