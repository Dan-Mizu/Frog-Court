extends CanvasLayer
class_name PhasePanel

signal finished

# references
@onready var command_hint: Label = %CommandHint
@onready var message_count: Label = %MessageCount
@onready var time_remaining_bar: ProgressBar = %TimeRemainingBar
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@export_group("SFX")
@export var show_sfx: AudioStream
@export var hide_sfx: AudioStream

# properties
@export var wait_time_seconds: float = 30.0

# internal
var _elapsed_time: float = 0.0
var _ended: bool = false

func _ready() -> void:
	# set progress bar range
	time_remaining_bar.min_value = 0.0
	time_remaining_bar.max_value = wait_time_seconds
	time_remaining_bar.value = wait_time_seconds

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
