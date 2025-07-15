extends Node

var motive_manager: Node

func _ready():
	motive_manager = MotiveManager
	assert(motive_manager != null, "Could not find the MotiveManager singleton.")

# --- Public Methods for Actions ---
func sleep(amount = 25, duration = 5.0):
	if not motive_manager or duration <= 0: return

	var sleep_change_per_sec = amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.ENERGY, sleep_change_per_sec, duration)
	
	var hygiene_change_per_sec = - (amount / 5.0) / duration
	motive_manager.apply_motive_modifier(MotiveManager.HYGIENE, hygiene_change_per_sec, duration)

	var bladder_change_per_sec = - (amount / 2.0) / duration
	motive_manager.apply_motive_modifier(MotiveManager.BLADDER, bladder_change_per_sec, duration)

func eat(amount = 25, duration = 3.0):
	if not motive_manager or duration <= 0: return
	
	var hunger_change_per_sec = amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.HUNGER, hunger_change_per_sec, duration)
	
	var bladder_change_per_sec = - (amount / 2.0) / duration
	motive_manager.apply_motive_modifier(MotiveManager.BLADDER, bladder_change_per_sec, duration)

func drink(amount = 25, duration = 2.0):
	if not motive_manager or duration <= 0: return

	var thirst_change_per_sec = amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.THIRST, thirst_change_per_sec, duration)
	
	var bladder_change_per_sec = - amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.BLADDER, bladder_change_per_sec, duration)

func use_toilet(amount = 75, duration = 5.0):
	if not motive_manager or duration <= 0: return

	var bladder_change_per_sec = amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.BLADDER, bladder_change_per_sec, duration)
	
	var hygiene_change_per_sec = -10.0 / duration
	motive_manager.apply_motive_modifier(MotiveManager.HYGIENE, hygiene_change_per_sec, duration)

func work_out(amount = 25, duration = 10.0):
	if not motive_manager or duration <= 0: return

	var fun_change_per_sec = amount / duration
	motive_manager.apply_motive_modifier(MotiveManager.FUN, fun_change_per_sec, duration)
	
	var hygiene_change_per_sec = -5.0 / duration
	motive_manager.apply_motive_modifier(MotiveManager.HYGIENE, hygiene_change_per_sec, duration)
	
	var energy_change_per_sec = -5.0 / duration
	motive_manager.apply_motive_modifier(MotiveManager.ENERGY, energy_change_per_sec, duration)
