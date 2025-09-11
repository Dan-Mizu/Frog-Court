extends Node

# constants
const FADE_OUT_SOUND_SPEED: float = 3.0

# internal
var path: String = "res://data"
var game: Dictionary = {}
var game_files: Array[String] = ["items"]
var sfx: Dictionary = {}
var sfx_files: Array[String] = ["interact", "inventory"]
var lang: Dictionary = {}
var lang_files: Array[String] = ["en_us"]
var fade_out_sounds: Array[AudioStreamPlayer] = []

# cache registry and data
func _ready() -> void:
	# game data
	for file in game_files:
		game[file] = _parse_json(path + "/game/" + file + ".json")

	# sounds
	for file in sfx_files:
		sfx[file] = _parse_json(path + "/sfx/" + file + ".json")

	# language
	for file in lang_files:
		lang[file] = _parse_json(path + "/lang/" + file + ".json")

func _process(delta: float) -> void:
	# fade out sounds
	for sound_index in range(fade_out_sounds.size() - 1, -1, -1):
		# lower volume over time
		fade_out_sounds[sound_index].volume_db = lerp(fade_out_sounds[sound_index].volume_db, -50.0, delta * FADE_OUT_SOUND_SPEED)

		# stop when done
		if floor(fade_out_sounds[sound_index].volume_db) <= -50:
			SoundManager.stop_sound(fade_out_sounds[sound_index].stream)
			fade_out_sounds[sound_index].volume_db = 0
			fade_out_sounds.remove_at(sound_index)

# parse data from specified json file
func _parse_json(file_path: String):
	# file doesn't exist
	if not FileAccess.file_exists(file_path):
		prints("ERROR: Attempting to access", file_path)
		return

	# open file and parse data
	var data_file = FileAccess.open(file_path, FileAccess.READ)
	var parsed_data = JSON.parse_string(data_file.get_as_text())

	# parsed data isnt formatted correctly
	if not parsed_data is Dictionary:
		prints("ERROR: Attempting to parse", file_path)
		return

	# successfuly parsed
	return parsed_data

# abstracts paths to return a single output from an array or single string
func one_from(input) -> String:
	if typeof(input) == TYPE_STRING:
		return input
	elif typeof(input) == TYPE_ARRAY:
		randomize()
		return input[randi() % input.size()]
	else:
		return "ERROR"

# resets a sound
func reset_sound(sound: AudioStreamPlayer) -> void:
	# remove sound from fade out if exists
	for sound_index in range(fade_out_sounds.size() - 1, -1, -1):
		if fade_out_sounds[sound_index].stream == sound.stream:
			fade_out_sounds.remove_at(sound_index)

	# reset volume
	sound.volume_db = 0

# fades out a given sound
func fade_out_sound(sound: AudioStreamPlayer) -> void:
	fade_out_sounds.push_front(sound)
