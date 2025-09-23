extends CanvasLayer
class_name PhasePanel

# data
var PhaseData: Dictionary[State.Phase, Dictionary] = {
	State.Phase.ACCUSATION: {
		"hint": "!accuse <user> <claim>",
		"examples": [
			"!accuse Nymn Didn't go live on time today."
		],
		"has_response_count": true
	},
	State.Phase.DEFENSE: {
		"hint": "defend yourself"
	},
	State.Phase.DELIBERATION: {
		"hint": "did the defendant do it? vote !yea/!nay"
	}
}

# signals
signal finished

# references
@onready var command_hint_label: Label = %CommandHint
@onready var response_count_label: Label = %MessageCount
@onready var examples: HBoxContainer = %Examples
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
	var phase_data: Dictionary = PhaseData.get(phase)

	# setup ui labels
	command_hint_label.text = phase_data.get("hint")

	# examples
	if phase_data.has("examples"): examples.visible = true
	else: examples.visible = false

	# info
	if phase_data.has("has_response_count"): info.visible = true
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
