extends Node

#region Sounds
func play_and_wait_sound(sound: AudioStream, override_bus: String = "Ambience") -> void: await play_sound(sound, override_bus).finished

func play_sound(sound: AudioStream, override_bus: String = "Ambience") -> AudioStreamPlayer:
	if sound == null:
		push_warning("Attempted to play a null sound!")
		return null

	if not Engine.has_singleton("SoundManager"):
		push_warning("SoundManager singleton is not initialized!")
		return null

	var sm = Engine.get_singleton("SoundManager")

	# Clean up freed nodes from the pool
	sm.sound_effects.available_players = sm.sound_effects.available_players.filter(func(p):
		return is_instance_valid(p)
	)
	sm.sound_effects.busy_players = sm.sound_effects.busy_players.filter(func(p):
		return is_instance_valid(p)
	)

	# Try to get a player with the resource if it's a randomizer
	var player: AudioStreamPlayer = null
	if sound is AudioStreamRandomizer:
		player = sm.sound_effects.get_player_with_resource(sound)

	if player == null:
		if sm.sound_effects.available_players.size() == 0:
			sm.sound_effects.increase_pool()
		player = sm.sound_effects.get_available_player()

	player.stream = sound
	player.bus = override_bus if override_bus != "" else sm.sound_effects.bus
	player.volume_db = linear_to_db(1.0)
	player.pitch_scale = 1
	player.play()

	return player

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
