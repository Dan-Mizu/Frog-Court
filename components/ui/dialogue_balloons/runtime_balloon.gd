extends CanvasLayer
class_name RuntimeBalloon

signal finished

# references
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@export_group("SFX")
@export var letter_sfx: Dictionary[String, AudioStream]
@export var next_sfx: AudioStream
@export var show_balloon_sfx: AudioStream
func _on_show() -> void:
	SoundManager.play_sound(show_balloon_sfx.duplicate(), "UI")
@export var hide_balloon_sfx: AudioStream
func _on_hide() -> void:
	pass
	#SoundManager.play_sound(hide_balloon_sfx.duplicate(), "UI")

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

func _ready() -> void:
	# connect to new chat messages from accused chatter
	State.new_message_from_accused.connect(_on_new_message_from_accused)

	# set name
	character_label.text = State.round_data.selected_accusation.accused_name

	# Connect dialogue label typing signals (from Dialogue Manager)
	dialogue_label.spoke.connect(_on_dialogue_label_spoke)

var message_queue: Array[String] = []
var typing := false

func _on_new_message_from_accused(text: String) -> void:
	# disable bbcode
	dialogue_label.bbcode_enabled = false

	# add message
	message_queue.append(text)
	_process_queue()

func _process_queue() -> void:
	if typing or message_queue.is_empty():
		return
	typing = true

	var line := DialogueLine.new()
	line.text = message_queue.pop_front()
	dialogue_label.dialogue_line = line
	dialogue_label.type_out()
	await dialogue_label.finished_typing
	typing = false
	_process_queue()

func _on_dialogue_label_spoke(letter: String, _letter_index: int, _speed: float) -> void:
	# format letter
	var _letter = letter.to_lower()

	# letter has a sound
	if letter_sfx.has(_letter):
		# vary pitch
		var pitch: float = randf_range(1.5, 2.0)

		# play sound
		SoundManager.play_sound_with_pitch(letter_sfx.get(_letter), pitch, "Voices")

func _on_finished_typing() -> void: pass

func _on_finished() -> void:
	finished.emit()
	self.queue_free()
