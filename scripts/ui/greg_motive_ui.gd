extends Control

@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerBar
@onready var poop_bar: ProgressBar = $VBoxContainer/PoopBar

var greg: Node = null

func _process(_delta):
	if not is_instance_valid(greg):
		# Try to find Greg if we don't have a reference
		greg = get_tree().get_first_node_in_group("greg")
		if not is_instance_valid(greg):
			# If Greg is not in the scene, hide the UI
			visible = false
			return
	
	# If Greg is found, make sure the UI is visible
	visible = true
	
	# Update the bars with Greg's current needs, as a percentage of the threshold
	if greg.has_method("get_hunger"):
		hunger_bar.value = (greg.get_hunger() / greg.HUNGER_THRESHOLD) * 100
	
	if greg.has_method("get_poop_urgency"):
		poop_bar.value = (greg.get_poop_urgency() / greg.POOP_THRESHOLD) * 100
