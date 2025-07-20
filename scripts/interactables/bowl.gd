extends Interactable
class_name Bowl

@export var food_scene: PackedScene
@export var channel_time: float = 10.0

var is_channeling: bool = false
var channel_timer: float = 0.0
var player_interacting: Node = null

const SCORE = 25

@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar

func _ready():
	add_to_group("interactables")
	progress_bar.visible = false

func _process(delta):
	if is_channeling:
		channel_timer += delta
		progress_bar.value = (channel_timer / channel_time) * 100
		if channel_timer >= channel_time:
			_finish_channeling()

func interact(player):
	if is_channeling:
		_cancel_channeling()
	else:
		_start_channeling(player)

func _start_channeling(player):
	is_channeling = true
	player_interacting = player
	channel_timer = 0.0
	progress_bar.visible = true
	player.set_channeling(true)

func _cancel_channeling():
	is_channeling = false
	if player_interacting:
		player_interacting.set_channeling(false)
	player_interacting = null
	progress_bar.visible = false

func _finish_channeling():
	is_channeling = false
	if player_interacting:
		player_interacting.set_channeling(false)
	player_interacting = null
	progress_bar.visible = false
	
	if food_scene:
		var food_instance = food_scene.instantiate()
		add_child(food_instance)
		food_instance.position = Vector3(0, 0.2, 0)
		# Add score for doing action
		ScoreTimeManager.add_score(SCORE)
