extends Node

signal motives_initialized(motive_data)
signal motive_updated(motive_name, new_value)
signal game_over()

const HIGH_THRESHOLD = 0.6 # green
const MEDIUM_THRESHOLD = 0.35 # orange
const LOW_THRESHOLD = 0.2 # red

var motive_data = {
	"Hunger": { "value": 100, "depletion_rate": 0 },
	"Thirst": { "value": 100, "depletion_rate": 0 },
	"Fun": { "value": 100, "depletion_rate": 0 },
	"Bladder": { "value": 100, "depletion_rate": 0 },
	"Energy": { "value": 100, "depletion_rate": 0 },
	"Hygiene": { "value": 100, "depletion_rate": 0 }
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
		# randomize depletion rate so each run has different priorities user might have to do
		motive.value -= motive.depletion_rate * delta * (random.randf() + 0.5)
		motive.value = clamp(motive.value, 0, 100)
		emit_signal("motive_updated", motive_name, motive.value)

		if motive.value <= 0:
			game_is_over = true
			emit_signal("game_over")
			return # Stop processing motives if game is over

func get_all_motives():
	return motive_data

func get_motive(motive_name):
	if motive_data.has(motive_name):
		return motive_data[motive_name].value
	return 0

func set_motive(motive_name, new_value):
	if motive_data.has(motive_name):
		motive_data[motive_name].value = clamp(new_value, 0, 100)
		emit_signal("motive_updated", motive_name, motive_data[motive_name].value)

func reset_game_state():
	game_is_over = false
	for motive_name in motive_data:
		var motive = motive_data[motive_name]
		motive.depletion_rate = random.randf_range(0.3, 1.5)
		motive.value = random.randi_range(60, 80)
	emit_signal("motives_initialized", motive_data)
