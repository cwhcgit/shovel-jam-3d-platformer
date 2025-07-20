extends Node

signal motives_initialized(motive_data)
signal motive_updated(motive_name, new_value)
signal game_over()

const HUNGER = "Hunger"
const THIRST = "Thirst"
const FUN = "Fun"
const BLADDER = "Bladder"
const ENERGY = "Energy"
const HYGIENE = "Hygiene"

const HIGH_THRESHOLD = 0.6 # green
const MEDIUM_THRESHOLD = 0.35 # orange
const LOW_THRESHOLD = 0.2 # red

var motive_data = {
	HUNGER: { "value": 100, "depletion_rate": 0, "modifiers": [] },
	THIRST: { "value": 100, "depletion_rate": 0, "modifiers": [] },
	FUN: { "value": 100, "depletion_rate": 0, "modifiers": [] },
	BLADDER: { "value": 100, "depletion_rate": 0, "modifiers": [] },
	ENERGY: { "value": 100, "depletion_rate": 0, "modifiers": [] },
	HYGIENE: { "value": 100, "depletion_rate": 0, "modifiers": [] }
}

var random = RandomNumberGenerator.new()
var game_is_over = false

func _ready():
	random.randomize()
	reset_game_state()

func _process(delta):
	if game_is_over:
		return

	for motive_name in motive_data:
		var motive = motive_data[motive_name]
		
		# Base depletion rate
		var change = - motive.depletion_rate * delta * (random.randf() + 0.5)
		
		# Apply active modifiers
		var remaining_modifiers = []
		for modifier in motive.modifiers:
			change += modifier.change_per_second * delta
			modifier.duration -= delta
			if modifier.duration > 0:
				remaining_modifiers.append(modifier)
		motive.modifiers = remaining_modifiers
		
		# Update value if there was any change
		if change != 0:
			motive.value += change
			motive.value = clamp(motive.value, 0, 100)
			emit_signal("motive_updated", motive_name, motive.value, change)

		if motive.value <= 0:
			game_is_over = true
			emit_signal("game_over")
			return # Stop processing motives if game is over


# --- Timed Modifiers ---

func apply_motive_modifier(motive_name, change_per_second, duration):
	if motive_data.has(motive_name):
		var modifier = {
			"change_per_second": change_per_second,
			"duration": duration
		}
		motive_data[motive_name].modifiers.append(modifier)

# --- Getter/Setter and State Management ---

func get_all_motives():
	return motive_data

func get_motive(motive_name):
	if motive_data.has(motive_name):
		return motive_data[motive_name].value
	return 0

func set_motive(motive_name, new_value, change):
	if motive_data.has(motive_name):
		# var old_value = motive_data[motive_name].value
		motive_data[motive_name].value = clamp(new_value, 0, 100)
		# var change = motive_data[motive_name].value - old_value
		emit_signal("motive_updated", motive_name, motive_data[motive_name].value, change)

func reset_game_state():
	game_is_over = false
	for motive_name in motive_data:
		var motive = motive_data[motive_name]
		motive.depletion_rate = random.randf_range(0.3, 1.5)
		motive.value = random.randi_range(60, 80)
		motive.modifiers = [] # Reset modifiers
	emit_signal("motives_initialized", motive_data)
