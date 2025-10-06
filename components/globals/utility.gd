extends Node

#region Sounds
func play_and_wait_sound(sound: AudioStream, override_bus: String = "Ambience") -> void: await play_sound(sound, override_bus).finished

func play_sound(sound: AudioStream, override_bus: String = "Ambience") -> AudioStreamPlayer: return SoundManager.play_sound(sound, override_bus)

func fade_out_sound(player: AudioStreamPlayer, duration: float = 1.0) -> void: SoundManager.sound_effects.fade_volume(player, player.volume_db, -80.0, duration)
#endregion

#region Conversions
func enum_to_string(enum_value: int, enum_dict: Dictionary) -> String:
	# get the enum name as a string
	var enum_name = enum_dict.keys()[enum_dict.values().find(enum_value)]

	# replace underscores with spaces
	enum_name = enum_name.replace("_", " ")

	# capitalize every first letter
	var words = enum_name.split(" ")
	for i in range(words.size()):
		words[i] = words[i].capitalize()

	return " ".join(words)

func string_to_enum(anim_name: String, enum_dict: Dictionary) -> int:
	# normalize: remove spaces and uppercase to match enum key style
	var normalized = anim_name.replace(" ", "_").to_upper()

	# found enum
	if enum_dict.has(normalized): return enum_dict[normalized]

	# enum not found
	else:
		push_error("No matching enum for '%s'" % anim_name)
		return -1  # or some default value
#endregion
