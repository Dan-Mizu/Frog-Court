extends CanvasLayer
class_name PhasePanel

class PhasePanelData:
	var hint: String = ""
	var examples: Array[String] = []
	var has_response_count: bool = false

	func init(_hint: String = "", _examples: Array[String] = [], _has_response_count: bool = false) -> PhasePanelData:
		hint = _hint
		examples = _examples
		has_response_count = _has_response_count
		return self

# data
var phase_panels_data: Dictionary[State.Phase, PhasePanelData] = {
	State.Phase.ACCUSATION: PhasePanelData.new().init("!accuse <user> <claim>", [
			"!accuse Nymn Didn't go live on time.",
			"!accuse Erobb221 Scamming a charity.",
			"!accuse Chatter Posting an ascii phallus in chat.",
			"!accuse Chatter Furry tendencies.",
			"!accuse Pokelawls Swollen balls.",
			"!accuse Forsen Primary suspect in nina's disappearance."
		], true),
	State.Phase.DEFENSE: PhasePanelData.new().init("defend yourself"),
	State.Phase.DELIBERATION: PhasePanelData.new().init("did the defendant do it? vote !yea/!nay")
}

# signals
signal finished

# references
@onready var command_hint_label: Label = %CommandHint
@onready var response_count_label: Label = %MessageCount
@onready var examples: HBoxContainer = %Examples
@onready var example_label: Label = %ExampleLabel
@onready var example_timer: Timer = %ExampleTimer
@onready var info: HBoxContainer = %Info
@onready var time_remaining_bar: ProgressBar = %TimeRemainingBar
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@export_group("SFX")
@export var show_sfx: AudioStream
@export var hide_sfx: AudioStream

# properties
var wait_time_seconds: float = 30.0

# state
@onready var phase: State.Phase = State.round_data.phase

# internal
var _response_count: int = 0
var _elapsed_time: float = 0.0
var _ended: bool = false

# get data on initialization
func init(_wait_time_seconds: float = 30.0, _phase: State.Phase = State.round_data.phase) -> PhasePanel:
	phase = _phase
	wait_time_seconds = _wait_time_seconds
	return self

func _ready() -> void:
	# set progress bar range
	time_remaining_bar.min_value = 0.0
	time_remaining_bar.max_value = wait_time_seconds
	time_remaining_bar.value = wait_time_seconds

	# phase based initialization
	match phase:
		State.Phase.ACCUSATION:
			# connect to new response signal
			State.round_data.accusations.response_added.connect(_on_response_added)

	# get phase data
	var phase_data: PhasePanelData = phase_panels_data.get(phase)

	# setup ui labels
	command_hint_label.text = phase_data.hint

	# examples
	if not phase_data.examples.is_empty():
		# show examples
		examples.visible = true

		# setup example pool
		_reset_example_pool()
		_cycle_example()

		# start cycling through provided examples
		example_timer.start()
	else: examples.visible = false

	# info
	if phase_data.has_response_count: info.visible = true
	else: info.visible = false

func _process(delta: float) -> void:
	# count up to provided wait time
	if _elapsed_time < wait_time_seconds:
		# add elapsed time from last tick
		_elapsed_time += delta

		# update progress bar (decreases over time)
		time_remaining_bar.value = clamp(wait_time_seconds - _elapsed_time, 0.0, wait_time_seconds)

	# finished waiting
	elif not _ended and _elapsed_time >= wait_time_seconds:
		_end()

func _end() -> void:
	# set timer bar to end
	time_remaining_bar.value = 0.0

	# update state
	_ended = true

	# play hide animation
	animation_player.play("hide")

#region Events
func _on_finished() -> void:
	# emit finished event
	finished.emit()

	# delete
	self.queue_free()

func _on_show() -> void:
	SoundManager.play_sound_with_pitch(show_sfx, 0.8, "UI")
func _on_hide() -> void:
	SoundManager.play_sound_with_pitch(hide_sfx, 0.8, "UI")

func _on_end_button_pressed() -> void:
	_end()

func _on_response_added(_response: State.Response) -> void:
	# store
	_response_count += 1

	# update response count display
	response_count_label.text = str(_response_count)
#endregion

#region Examples
var _example_pool: Array[String] = []
func _reset_example_pool() -> void:
	# sets up the pool of examples for this phase
	var phase_data: PhasePanelData = phase_panels_data.get(phase)

	# no examples
	if phase_data.examples.is_empty(): return

	# get examples
	_example_pool = phase_data.examples.duplicate()

	# randomize the order of examples
	_example_pool.shuffle()

func _cycle_example() -> void:
	# used up all the examples, restart
	if _example_pool.is_empty(): _reset_example_pool()

	# set the next (initially randomized) example
	if not _example_pool.is_empty(): example_label.text = _example_pool.pop_back()
#endregion
